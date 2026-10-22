//
//  EnterParkingSignSheet.swift
//  Parkoala
//
//  Created by Huệ Dương on 21/10/2026.
//

import SwiftUI

/// Sheet where the driver copies in the sign they parked next to.
/// Hands the checked sign back through `onSave`.
struct EnterParkingSignSheet: View {
    @State private var model: EnterParkingSignViewModel
    @Environment(\.dismiss) private var dismiss
    private let onSave: (ParkingRestriction) -> Void

    /// - Parameters:
    ///   - restriction: The sign to start from, e.g. the last one used.
    ///   - onSave: Called with the checked sign when the driver taps Save Sign.
    init(restriction: ParkingRestriction = .twoHourWeekdaySign, onSave: @escaping (ParkingRestriction) -> Void) {
        _model = State(initialValue: EnterParkingSignViewModel(restriction: restriction))
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            Form {
                ParkingSignFields(restriction: $model.restriction)
                if let problemMessage = model.problemMessage {
                    Section {
                        Label(problemMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Parking Sign")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save Sign", action: saveSign)
                }
            }
        }
    }

    private func saveSign() {
        guard let restriction = model.signReadyToSave() else { return }
        onSave(restriction)
        dismiss()
    }
}

#Preview("Light") {
    EnterParkingSignSheet { _ in }
}

#Preview("Dark") {
    EnterParkingSignSheet { _ in }
        .preferredColorScheme(.dark)
}

#Preview("Largest text") {
    EnterParkingSignSheet { _ in }
        .dynamicTypeSize(.accessibility5)
}
