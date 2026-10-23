// Shown right after a parking session ends: the estimated cost and a
// summary of the stay, using the rate entered when the session started.

import SwiftUI

struct SessionEndedView: View {

    let session: ParkingSession

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(.green.opacity(0.35))
                                .frame(width: 96, height: 96)
                            Image(systemName: "checkmark")
                                .font(.system(size: 36, weight: .bold))
                        }
                        .padding(.top, 16)

                        Text("Estimated Cost")
                            .font(.headline)
                            .foregroundStyle(.secondary)

                        if let cost = session.cost {
                            Text(cost.formatted(.currency(code: "AUD")))
                                .font(.system(size: 40, weight: .bold, design: .rounded))
                        } else {
                            Text("Not calculated")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("SESSION SUMMARY")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)

                        VStack(spacing: 0) {
                            summaryRow("Duration", value: SessionFormat.duration(session))
                            Divider().padding(.leading)
                            summaryRow("Time", value: SessionFormat.timeRange(session))
                            Divider().padding(.leading)
                            summaryRow(
                                "Rate",
                                value: session.plannedRate.map { SessionFormat.rateDescription($0) } ?? "Not set"
                            )
                        }
                        .background(.background.secondary, in: .rect(cornerRadius: 16))
                    }
                }
                .padding()
            }
            .navigationTitle("Parking Session Ended")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func summaryRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 14)
    }
}

#Preview {
    SessionEndedView(
        session: ParkingSession(
            vehicleID: UUID(),
            startDate: Date.now.addingTimeInterval(-90 * 60),
            expiryDate: Date.now.addingTimeInterval(60 * 60),
            endDate: Date.now,
            plannedRate: .hourly(price: 5),
            cost: 10
        )
    )
}
