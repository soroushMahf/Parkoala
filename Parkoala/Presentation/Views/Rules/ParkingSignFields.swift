//
//  Parkoala
//
//  Created by Heather
//

import SwiftUI

/// The parts of a parking sign the driver copies in: time limit, hours and days.
struct ParkingSignFields: View {
    @Binding var restriction: ParkingRestriction

    var body: some View {
        Section("Time limit") {
            Picker("Time limit", selection: timeLimitMinutes) {
                ForEach(ParkingRestriction.supportedTimeLimitMinutes, id: \.self) { minutes in
                    Text("\(ParkingRestriction.timeLimitLabel(minutes: minutes)) · \(ParkingRestriction.timeLimitSpokenText(minutes: minutes))")
                        .tag(minutes)
                }
            }
        }

        Section {
            Picker("From", selection: $restriction.startMinute) {
                ForEach(Self.signStartTimes, id: \.self) { minute in
                    Text(ParkingRestriction.clockTimeText(minute: minute)).tag(minute)
                }
            }
            Picker("Until", selection: $restriction.endMinute) {
                ForEach(Self.signEndTimes, id: \.self) { minute in
                    Text(ParkingRestriction.clockTimeText(minute: minute)).tag(minute)
                }
            }
        } header: {
            Text("Sign hours")
        } footer: {
            Text("Use the times printed on the sign.")
        }

        Section("Days the sign applies") {
            ForEach(Weekday.mondayFirst, id: \.self) { day in
                Toggle(day.fullName, isOn: applies(on: day))
            }
        }
    }

    // Helpers

    /// Every half hour from midnight to 11:30 pm.
    private static let signStartTimes = Array(stride(from: 0, to: 1440, by: 30))
    /// Every half hour from 12:30 am to midnight.
    private static let signEndTimes = Array(stride(from: 30, through: 1440, by: 30))

    /// The time limit in minutes, stored in the restriction as seconds.
    private var timeLimitMinutes: Binding<Int> {
        Binding(
            get: { restriction.timeLimitMinutes },
            set: { restriction.maxStay = TimeInterval($0 * 60) }
        )
    }

    /// Whether the sign applies on `day`. Switching it on or off adds or removes that day.
    private func applies(on day: Weekday) -> Binding<Bool> {
        Binding(
            get: { restriction.days.contains(day) },
            set: { isOn in
                if isOn {
                    restriction.days.insert(day)
                } else {
                    restriction.days.remove(day)
                }
            }
        )
    }
}

#Preview {
    @Previewable @State var restriction = ParkingRestriction.twoHourWeekdaySign
    Form {
        ParkingSignFields(restriction: $restriction)
    }
}
