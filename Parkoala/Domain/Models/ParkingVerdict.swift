//
//  ParkingVerdict.swift
//  Parkoala
//
//  Created by Heather
//

import Foundation

/// Provide answer to a driver asking "Can I park here now?" for one sign.
nonisolated enum ParkingVerdict: Equatable {
    /// The sign's time limit applies now. The driver must move the car by `moveCarBy`.
    case timeLimitApplies(moveCarBy: Date)
    /// No time limit applies right now. `limitStartsAt` is when the sign starts
    /// later today, or nil if it doesn't apply again today.
    case noTimeLimitNow(limitStartsAt: Date?)
}
