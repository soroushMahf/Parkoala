//
//AddSessionCostView.swift
//Parkoala
//
//  Created by jessica dao on 22/10/2026.

// Lets the user enter the rate that applied to a finished session,
// shows the resulting estimate, and saves it to the session.

import SwiftUI

struct AddSessionCostView: View {

    let session: ParkingSession
    let viewModel: MoneyViewModel

    @Environment(\.dismiss) private var dismiss

    @State private var rateInput = RateInput()
    @State private var actualCostText = ""

    @State private var estimate: CostEstimate?
    @State private var calculationError: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Rate") {
                    RateInputFields(input: $rateInput)
                }

                Section {
                    if let estimate {
                        LabeledContent("Estimated cost", value: estimate.amount.formatted(.currency(code: "AUD")))
                    } else if let calculationError {
                        Label(calculationError, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }

                Section("Actual cost (optional)") {
                    TextField("Amount charged", text: $actualCostText)
                        .keyboardType(.decimalPad)
                }

                if let message = viewModel.errorMessage {
                    Section {
                        Label(message, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Add cost")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear(perform: recalculate)
            .onChange(of: rateInput.kind) { _, _ in recalculate() }
            .onChange(of: rateInput.hourlyPrice) { _, _ in recalculate() }
            .onChange(of: rateInput.flatPrice) { _, _ in recalculate() }
            .onChange(of: rateInput.earlyBirdPrice) { _, _ in recalculate() }
            .onChange(of: rateInput.enterBeforeTime) { _, _ in recalculate() }
            .onChange(of: rateInput.leaveAfterTime) { _, _ in recalculate() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task { await save() }
                    }
                    .disabled(estimate == nil || viewModel.isLoading)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func recalculate() {
        guard let rate = rateInput.rate else {
            estimate = nil
            calculationError = nil
            return
        }

        do {
            estimate = try viewModel.estimate(for: session, rates: [rate])
            calculationError = nil
        } catch {
            estimate = nil
            calculationError = error.localizedDescription
        }
    }

    private func save() async {
        guard let estimate else { return }
        guard await viewModel.saveEstimate(estimate, for: session) else { return }

        if let actualAmount = Decimal(string: actualCostText) {
            await viewModel.saveActualCost(actualAmount, for: session)
        }

        dismiss()
    }
}

#Preview {
    AddSessionCostView(
        session: ParkingSession(
            vehicleID: UUID(),
            startDate: Date.now.addingTimeInterval(-2 * 60 * 60),
            expiryDate: Date.now.addingTimeInterval(-60 * 60),
            endDate: Date.now
        ),
        viewModel: .preview(withSamples: false)
    )
}
