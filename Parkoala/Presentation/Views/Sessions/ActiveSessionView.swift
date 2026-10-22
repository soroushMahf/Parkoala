// The Park tab. Shows the running session with its time left,
// or an empty state with a button to start parking.

import SwiftUI

struct ActiveSessionView: View {

    @State private var viewModel: SessionViewModel
    private let historyViewModel: SessionHistoryViewModel?
    private let locationViewModel: LocationViewModel?
    @State private var isShowingStartSheet = false
    @State private var isConfirmingEnd = false
    @State private var endedSession: ParkingSession?

    // Uses the real SwiftData store unless a view model is passed in (previews)
    init(
        viewModel: SessionViewModel? = nil,
        historyViewModel: SessionHistoryViewModel? = nil,
        locationViewModel: LocationViewModel? = nil
    ) {
        _viewModel = State(initialValue: viewModel ?? .live())
        self.historyViewModel = historyViewModel
        self.locationViewModel = locationViewModel
    }

    var body: some View {
        NavigationStack {
            Group {
                if let session = viewModel.activeSession {
                    sessionDetails(session)
                } else {
                    emptyState
                }
            }
            .navigationTitle("Park")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SessionHistoryView(
                            viewModel: historyViewModel ?? .live(),
                            locationViewModel: locationViewModel
                        )
                    } label: {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                }
            }
            .sheet(isPresented: $isShowingStartSheet) {
                StartParkingSheet(viewModel: viewModel)
            }
            .alert(
                "Something went wrong",
                isPresented: Binding(
                    get: { viewModel.errorMessage != nil && !isShowingStartSheet },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .task {
                await viewModel.load()
            }
            .onChange(of: locationViewModel?.parkedLocation) {_, newLocation in
                guard newLocation != nil else { return }
                
                Task {
                    await viewModel.load()
                }
            }
            .onChange(of: viewModel.lastEndedSession) { _, newValue in
                endedSession = newValue
            }
            .sheet(item: $endedSession, onDismiss: {
                viewModel.dismissEndedSessionSummary()
            }) { session in
                SessionEndedView(session: session)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Not parked", systemImage: "car")
        } description: {
            Text("Start a session when you park and Parkoala will track your time.")
        } actions: {
            Button("Start parking") {
                isShowingStartSheet = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
    }

    private func sessionDetails(_ session: ParkingSession) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // Redraws every second so the countdown stays live
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    CountdownCard(session: session, now: context.date)
                }

                VStack(spacing: 12) {
                    detailRow("Started", value: session.startDate.formatted(date: .omitted, time: .shortened))
                    detailRow("Expires", value: session.expiryDate.formatted(date: .omitted, time: .shortened))
                }
                .padding()
                .background(.background.secondary, in: .rect(cornerRadius: 16))
                
                if let locationViewModel {
                    NavigationLink {
                        SaveParkingLocationView(
                            vehicleID: session.vehicleID,
                            viewModel: locationViewModel
                        )
                    } label: {
                        Label(
                            session.location == nil
                                ? "Save Parking Location"
                                : "Update Parking Location",
                            systemImage: "mappin.and.ellipse"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    if let parkedLocation = session.location {
                        NavigationLink {
                            FindMyCarView(
                                parkedLocation: parkedLocation,
                                viewModel: locationViewModel
                            )
                        } label: {
                            Label("Find My Car", systemImage: "car.side")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Button("End parking", role: .destructive) {
                    isConfirmingEnd = true
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
                .confirmationDialog("End this parking session?", isPresented: $isConfirmingEnd, titleVisibility: .visible) {
                    Button("End parking", role: .destructive) {
                        Task { await viewModel.endSession() }
                    }
                }
            }
            .padding()
        }
    }

    private func detailRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .accessibilityElement(children: .combine)
    }
}

// The big time-left display. Turns red once the time has run out.
private struct CountdownCard: View {

    let session: ParkingSession
    let now: Date

    private var remaining: TimeInterval {
        session.expiryDate.timeIntervalSince(now)
    }

    private var isExpired: Bool {
        remaining <= 0
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(isExpired ? "Time is up" : "Time left")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(Self.format(abs(remaining)))
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(isExpired ? .red : .primary)

            if isExpired {
                Text("Your parking expired. Move your car to avoid a fine.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.red)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(.background.secondary, in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    // 1:05:09 style, or 5:09 when under an hour
    static func format(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview("Not parked") {
    ActiveSessionView(viewModel: .preview())
}

#Preview("Parked") {
    ActiveSessionView(viewModel: .preview(parkedFor: 2 * 60 * 60))
}
