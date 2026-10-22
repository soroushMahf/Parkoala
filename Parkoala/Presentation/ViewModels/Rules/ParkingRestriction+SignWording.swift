//
//  File.swift
//  Parkoala
//
//  Created by Heather

import Foundation

extension Weekday {
    /// Short day name in the phone's language, e.g. "Mon".
    var shortName: String { Calendar.current.shortWeekdaySymbols[rawValue - 1] }

    /// Full day name in the phone's language, e.g. "Monday".
    var fullName: String { Calendar.current.weekdaySymbols[rawValue - 1] }
}

extension ParkingRestriction {
    /// The sign as it reads on the kerb, e.g. "2P 8:00 am – 6:00 pm Mon–Fri".
    var signWording: String {
        "\(timeLimitLabel) \(Self.clockTimeText(minute: startMinute)) – \(Self.clockTimeText(minute: endMinute)) \(signDays)"
    }

    /// The time limit in minutes (120 for 2P), or 0 when there isn't one.
    var timeLimitMinutes: Int {
        guard let maxStay, let minutes = Int(exactly: (maxStay / 60).rounded(.towardZero)) else { return 0 }
        return minutes
    }

    /// The time limit as printed on signs, e.g. "2P".
    var timeLimitLabel: String { Self.timeLimitLabel(minutes: timeLimitMinutes) }

    /// The days as a sign shows them: "Mon–Fri", "Every day", or a list such as "Mon, Wed, Sat".
    var signDays: String {
        if days == Weekday.mondayToFriday { return "Mon–Fri" }
        if days.count == Weekday.allCases.count { return "Every day" }
        return Weekday.mondayFirst
            .filter { days.contains($0) }
            .map { $0.shortName }
            .formatted(.list(type: .and, width: .narrow))
    }

    /// A time limit as printed on signs: "¼P", "½P", "1P", "2P"…
    static func timeLimitLabel(minutes: Int) -> String {
        switch minutes {
        case 15: "¼P"
        case 30: "½P"
        default: "\(minutes / 60)P"
        }
    }

    /// A time limit spelled out for pickers and VoiceOver, e.g. "2 hours" or "15 minutes".
    static func timeLimitSpokenText(minutes: Int) -> String {
        Duration.seconds(minutes * 60).formatted(.units(allowed: [.hours, .minutes], width: .wide))
    }

    /// A time of day in the phone's clock format, e.g. "8:30 am". 1440 shows as midnight.
    /// Uses a fixed GMT date so daylight-saving days can't shift the label.
    static func clockTimeText(minute: Int) -> String {
        let date = Date(timeIntervalSinceReferenceDate: TimeInterval(minute % 1440 * 60))
        return date.formatted(Date.FormatStyle(date: .omitted, time: .shortened, timeZone: .gmt))
    }
}
