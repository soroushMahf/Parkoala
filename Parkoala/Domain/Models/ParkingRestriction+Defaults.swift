//
//  ParkingRestriction+Defaults.swift
//  Parkoala
//
//  Created by Heather
//
import Foundation

extension ParkingRestriction {
    /// The time limits Parkoala can time, in minutes: ¼P, ½P, 1P, 2P, 3P and 4P.
    static let supportedTimeLimitMinutes = [15, 30, 60, 120, 180, 240]

    /// The most common NSW sign, "2P 8am–6pm Mon–Fri". The sign form starts from it,
    /// so drivers usually change only one or two things.
    static var twoHourWeekdaySign: ParkingRestriction {
        ParkingRestriction(
            kind: .timeLimited,
            maxStay: 2 * 60 * 60,
            startMinute: 8 * 60,
            endMinute: 18 * 60,
            days: Weekday.mondayToFriday
        )
    }
}

extension Weekday {
    /// Monday first, the order NSW parking signs list days in.
    static let mondayFirst: [Weekday] = [.monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday]

    /// "Mon–Fri" on a sign.
    static let mondayToFriday: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
}
