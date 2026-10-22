//
//  ManageParkingRestrictionsUseCase.swift
//  Parkoala
//
//  Created by Heather

import Foundation

/// Checks a parking sign the driver typed in, and works out how long they can stay.
///
/// Business rules:
/// - Parkoala only times simple time-limit signs from ¼P to 4P.
/// - A sign's hours run forwards within one day, such as 8 am to 6 pm.
/// - A sign applies on at least one day of the week.
struct ManageParkingRestrictionsUseCase {
    private let calendar: Calendar

    /// Tests pass a fixed Sydney calendar so the answers don't depend on the computer.
    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    // Validate the sign

    /// Throws a `ParkingRestrictionsError` when the sign, as typed in, can't be used.
    func validateSign(_ restriction: ParkingRestriction) throws {
        guard restriction.kind == .timeLimited,
              let maxStay = restriction.maxStay,
              ParkingRestriction.supportedTimeLimitMinutes.contains(where: { TimeInterval($0 * 60) == maxStay }) else {
            throw ParkingRestrictionsError.unsupportedSign
        }
        guard (0..<1440).contains(restriction.startMinute),
              (1...1440).contains(restriction.endMinute),
              restriction.startMinute < restriction.endMinute else {
            throw ParkingRestrictionsError.invalidHours
        }
        guard !restriction.days.isEmpty else {
            throw ParkingRestrictionsError.noDaysSelected
        }
    }

    // Can I park here?

    /// Works out whether the sign's time limit applies when the driver parks, and until when.
    ///
    /// Business rule: while the sign applies, the driver may stay until the time limit
    /// runs out or the sign's hours end, whichever comes first. This is a guide,
    /// not legal advice, so screens always tell the driver to check the sign itself.
    func checkParking(under restriction: ParkingRestriction, at arrival: Date) throws -> ParkingVerdict {
        try validateSign(restriction)

        let weekdayNumber = calendar.component(.weekday, from: arrival)
        guard let arrivalDay = Weekday(rawValue: weekdayNumber), restriction.days.contains(arrivalDay) else {
            return .noTimeLimitNow(limitStartsAt: nil)
        }

        let signStarts = clockTime(minute: restriction.startMinute, on: arrival)
        let signEnds = clockTime(minute: restriction.endMinute, on: arrival)
        if arrival < signStarts {
            return .noTimeLimitNow(limitStartsAt: signStarts)
        }
        if arrival >= signEnds {
            return .noTimeLimitNow(limitStartsAt: nil)
        }

        let timeLimitRunsOut = arrival.addingTimeInterval(restriction.maxStay ?? 0)
        return .timeLimitApplies(moveCarBy: min(timeLimitRunsOut, signEnds))
    }

    // Helpers

    /// The clock time `minute` minutes after midnight on the same day as `date`.
    /// 1440 means midnight at the end of that day.
    private func clockTime(minute: Int, on date: Date) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        guard minute < 1440 else {
            return calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        }
        return calendar.date(bySettingHour: minute / 60, minute: minute % 60, second: 0, of: startOfDay) ?? startOfDay
    }
}
