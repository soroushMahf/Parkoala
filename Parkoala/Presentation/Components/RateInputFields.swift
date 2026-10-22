// Shared hourly / flat / early-bird rate input, used both when starting
// a session (if the rate is already known) and when adding a cost to
// a finished one.

import SwiftUI

enum RateKind: String, CaseIterable, Identifiable {
    case hourly = "Hourly"
    case flat = "Flat"
    case earlyBird = "Early bird"

    var id: String { rawValue }
}

// Holds the raw text/date input for a rate and turns it into a RateRule.
struct RateInput {
    var kind: RateKind = .hourly
    var hourlyPrice = ""
    var flatPrice = ""
    var earlyBirdPrice = ""
    var enterBeforeTime = Date.now
    var leaveAfterTime = Date.now

    // The rate described by the current input, or nil while required fields are incomplete.
    var rate: RateRule? {
        switch kind {
        case .hourly:
            guard let price = Decimal(string: hourlyPrice), price > 0 else { return nil }
            return .hourly(price: price)
        case .flat:
            guard let price = Decimal(string: flatPrice), price >= 0 else { return nil }
            return .flat(price: price)
        case .earlyBird:
            guard let price = Decimal(string: earlyBirdPrice), price >= 0 else { return nil }
            let calendar = Calendar.current
            let enterBefore = calendar.component(.hour, from: enterBeforeTime) * 60
                + calendar.component(.minute, from: enterBeforeTime)
            let leaveAfter = calendar.component(.hour, from: leaveAfterTime) * 60
                + calendar.component(.minute, from: leaveAfterTime)
            return .earlyBird(price: price, enterBeforeMinute: enterBefore, leaveAfterMinute: leaveAfter)
        }
    }
}

struct RateInputFields: View {

    @Binding var input: RateInput

    var body: some View {
        Picker("Type", selection: $input.kind) {
            ForEach(RateKind.allCases) { kind in
                Text(kind.rawValue).tag(kind)
            }
        }
        .pickerStyle(.segmented)

        switch input.kind {
        case .hourly:
            priceField("Price per hour", text: $input.hourlyPrice)
        case .flat:
            priceField("Flat price", text: $input.flatPrice)
        case .earlyBird:
            priceField("Early bird price", text: $input.earlyBirdPrice)
            DatePicker("Enter before", selection: $input.enterBeforeTime, displayedComponents: .hourAndMinute)
            DatePicker("Leave after", selection: $input.leaveAfterTime, displayedComponents: .hourAndMinute)
        }
    }

    private func priceField(_ title: String, text: Binding<String>) -> some View {
        HStack {
            Text(title)
            Spacer()
            TextField("$0.00", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
        }
    }
}
