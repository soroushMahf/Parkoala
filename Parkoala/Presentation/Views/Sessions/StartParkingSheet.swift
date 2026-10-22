// Lets the user choose how long they are parking for, then starts the session.

import SwiftUI

struct StartParkingSheet: View {

    let viewModel: SessionViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var hours = 1
    @State private var minutes = 0
    @State private var knowsRate = false
    @State private var rateInput = RateInput()

    private let quickPicks: [(label: String, minutes: Int)] = [
        ("15 min", 15), ("30 min", 30), ("1 hr", 60), ("2 hr", 120), ("4 hr", 240)
    ]

    private var duration: TimeInterval {
        TimeInterval(hours * 3600 + minutes * 60)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Quick pick") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(quickPicks, id: \.minutes) { pick in
                                Button(pick.label) {
                                    hours = pick.minutes / 60
                                    minutes = pick.minutes % 60
                                }
                                .buttonStyle(.bordered)
                                .frame(minHeight: 44)
                            }
                        }
                    }
                }

                Section("How long are you parking?") {
                    Stepper("\(hours) hr", value: $hours, in: 0...24)
                    Stepper("\(minutes) min", value: $minutes, in: 0...55, step: 5)
                }

                Section {
                    LabeledContent("Expires at", value: Date.now.addingTimeInterval(duration).formatted(date: .omitted, time: .shortened))
                }

                Section {
                    Toggle("Add Parking Rate", isOn: $knowsRate.animation())

                    if knowsRate {
                        RateInputFields(input: $rateInput)
                    }
                } header: {
                    Text("Cost (Optional)")
                } footer: {
                    Text("If you know how this car park charges, Parkoala will estimate the cost when you end your session.")
                }

                if let message = viewModel.errorMessage {
                    Section {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Start parking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        viewModel.errorMessage = nil
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Start") {
                        Task {
                            let plannedRate = knowsRate ? rateInput.rate : nil
                            if await viewModel.startSession(duration: duration, plannedRate: plannedRate) {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading || (knowsRate && rateInput.rate == nil))
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    StartParkingSheet(viewModel: .preview())
}
