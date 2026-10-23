//
//  ParkoalaWidgetsLiveActivity.swift
//  ParkoalaWidgets
//
//  Created by Đức Anh on 21/10/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ParkoalaWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ParkingActivityAttributes.self) { context in
            // Lock Screen / banner UI
            VStack(alignment: .leading, spacing: 8) {
                Text("Parking active")
                    .font(.headline)

                Text(
                    timerInterval: Date.now...context.state.expiryDate,
                    countsDown: true
                )
                .font(.title2)
                .monospacedDigit()

                Text("Expires at \(context.state.expiryDate, style: .time)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "parkingsign.circle.fill")
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.expiryDate, style: .time)
                        .font(.caption)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    Text(
                        timerInterval: Date.now...context.state.expiryDate,
                        countsDown: true
                    )
                    .monospacedDigit()
                }
            } compactLeading: {
                Image(systemName: "parkingsign.circle.fill")
            } compactTrailing: {
                Text(
                    timerInterval: Date.now...context.state.expiryDate,
                    countsDown: true
                )
                .monospacedDigit()
            } minimal: {
                Image(systemName: "parkingsign.circle.fill")
            }
        }
    }
}
