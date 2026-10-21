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
}
