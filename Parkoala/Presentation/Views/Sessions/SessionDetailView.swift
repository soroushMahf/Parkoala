// Shows everything about one finished parking session.

import SwiftUI

struct SessionDetailView: View {

    let session: ParkingSession
    let locationViewModel: LocationViewModel?

    var body: some View {
        List {
            Section {
                LabeledContent("Date", value: session.startDate.formatted(date: .complete, time: .omitted))
                LabeledContent("Parked", value: SessionFormat.duration(session))
            }

            Section("Times") {
                LabeledContent("Started", value: session.startDate.formatted(date: .omitted, time: .shortened))
                LabeledContent("Expiry", value: session.expiryDate.formatted(date: .omitted, time: .shortened))
                if let endDate = session.endDate {
                    LabeledContent("Ended", value: endDate.formatted(date: .omitted, time: .shortened))
                }
            }

            if let overstay = SessionFormat.overstay(session) {
                Section {
                    Label("You stayed \(overstay) past the expiry time.", systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                }
            }

            if let parkedLocation = session.location {
                Section("Where you parked") {

                    if let levelAndBay = parkedLocation.levelAndBay,
                       !levelAndBay.isEmpty {
                        LabeledContent("Level / Bay", value: levelAndBay)
                    }

                    if parkedLocation.coordinate != nil,
                       let locationViewModel {

                        NavigationLink {
                            FindMyCarView(
                                parkedLocation: parkedLocation,
                                viewModel: locationViewModel
                            )
                        } label: {
                            Label(
                                "View Parked Location",
                                systemImage: "mappin.and.ellipse"
                            )
                        }
                    }
                }
            }

            if let cost = session.cost {
                Section("Cost") {
                    LabeledContent("Estimated cost", value: cost.formatted(.currency(code: "AUD")))
                }
            }
        }
        .navigationTitle("Session")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// Shared text formatting for the history list and detail screens
enum SessionFormat {

    static func timeRange(_ session: ParkingSession) -> String {
        let start = session.startDate.formatted(date: .omitted, time: .shortened)
        let end = (session.endDate ?? session.expiryDate).formatted(date: .omitted, time: .shortened)
        return "\(start) to \(end)"
    }

    // How long the car was parked, for example "1h 25m"
    static func duration(_ session: ParkingSession) -> String {
        let end = session.endDate ?? session.expiryDate
        let seconds = max(0, end.timeIntervalSince(session.startDate))
        return format(seconds)
    }

    // How long the car stayed after the expiry time, or nil if it left in time
    static func overstay(_ session: ParkingSession) -> String? {
        guard let endDate = session.endDate else { return nil }
        let extra = endDate.timeIntervalSince(session.expiryDate)
        return extra >= 60 ? format(extra) : nil
    }

    private static func format(_ seconds: TimeInterval) -> String {
        Duration.seconds(seconds).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }
}

#Preview {
    let start = Date.now.addingTimeInterval(-3 * 60 * 60)
    NavigationStack {
        SessionDetailView(
            session: ParkingSession(
                vehicleID: UUID(),
                startDate: start,
                expiryDate: start.addingTimeInterval(2 * 60 * 60),
                endDate: start.addingTimeInterval(2 * 60 * 60 + 20 * 60),
                location: ParkingLocation(
                    coordinate: Coordinate(
                        latitude: -33.8830,
                        longitude: 151.2000
                    ),
                    levelAndBay: "Level 2, Bay 41"
                )
            ),
            locationViewModel: .preview()
        )
    }
}
