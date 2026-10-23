//
//  ParkingRestrictionsError.swift
//  Parkoala
//
//  Created by Heather
//

import Foundation

/// Reasons a parking sign the driver typed in can't be used.
///
/// The words the driver sees for each case are in `ParkingRestrictionsMessage`.
nonisolated enum ParkingRestrictionsError: Error, Hashable, Sendable {
    /// The sign's start time isn't before its end time, such as 6 pm to 8 am.
    case invalidHours
    /// No day of the week is ticked, so the sign would never apply.
    case noDaysSelected
    /// The sign isn't a ¼P to 4P time limit, for example a 45-minute limit, No Parking, No Stopping or a loading zone.
    case unsupportedSign
}
