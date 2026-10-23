//
//  CanIParkScreen.swift
//  Parkoala
//
//  Created by Heather

import SwiftUI

/// "Can I park here?": the driver copies in the sign and gets a move-by time.
struct CanIParkScreen: View {
    @State private var model = CanIParkViewModel()

    var body: some View {
        NavigationStack {
            Form {
                if let headline = model.answerHeadline, let explanation = model.answerExplanation {
                    Section {
                        answer(headline: headline, explanation: explanation)
                    }
                }
                if let problemMessage = model.problemMessage {
                    Section {
                        Label(problemMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    }
                }
                ParkingSignFields(restriction: $model.restriction)
            }
            .navigationTitle("Can I park here?")
            .safeAreaInset(edge: .bottom) {
                checkButton
            }
        }
    }

    // Parts of the screen

    /// Full-width button pinned above the tab bar, so it's always in reach.
    private var checkButton: some View {
        Button {
            model.checkParking()
        } label: {
            Text("Check This Sign")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .padding()
        .background(.bar)
    }

    private func answer(headline: String, explanation: String) -> some View {
        VStack(alignment: .leading) {
            Label(headline, systemImage: "checkmark.circle.fill")
                .font(.headline)
                .foregroundStyle(.tint)
            Text(explanation)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Light") {
    CanIParkScreen()
}

#Preview("Dark") {
    CanIParkScreen()
        .preferredColorScheme(.dark)
}

#Preview("Largest text") {
    CanIParkScreen()
        .dynamicTypeSize(.accessibility5)
}
