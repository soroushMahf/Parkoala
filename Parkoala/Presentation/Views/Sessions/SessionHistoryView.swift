// Lists finished parking sessions from the last few months, grouped by month.

import SwiftUI

struct SessionHistoryView: View {

    @State private var viewModel: SessionHistoryViewModel

    init(viewModel: SessionHistoryViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        Group {
            if let message = viewModel.errorMessage {
                ContentUnavailableView {
                    Label("Couldn't load history", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try again") {
                        Task { await viewModel.load() }
                    }
                    .buttonStyle(.bordered)
                }
            } else if viewModel.isEmpty && !viewModel.isLoading {
                ContentUnavailableView(
                    "No parking history",
                    systemImage: "clock",
                    description: Text("Sessions you end will show up here.")
                )
            } else {
                List {
                    ForEach(viewModel.months) { group in
                        Section(group.month.formatted(.dateTime.month(.wide).year())) {
                            ForEach(group.sessions) { session in
                                NavigationLink {
                                    SessionDetailView(session: session)
                                } label: {
                                    HistoryRow(session: session)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("History")
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
    }
}

private struct HistoryRow: View {

    let session: ParkingSession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.startDate.formatted(.dateTime.weekday(.wide).day().month()))
                .font(.headline)

            HStack {
                Text(SessionFormat.timeRange(session))
                Spacer()
                Text(SessionFormat.duration(session))
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            if SessionFormat.overstay(session) != nil {
                Label("Stayed past expiry", systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }
}

#Preview("With sessions") {
    NavigationStack {
        SessionHistoryView(viewModel: .preview(withSamples: true))
    }
}

#Preview("Empty") {
    NavigationStack {
        SessionHistoryView(viewModel: .preview(withSamples: false))
    }
}
