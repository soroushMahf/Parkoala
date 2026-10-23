//
//  ParkingActivityAttributes.swift
//  Parkoala
//
//  Created by Đức Anh on 21/10/26.
//


import ActivityKit
import Foundation

nonisolated struct ParkingActivityAttributes: ActivityAttributes {

    struct ContentState: Codable, Hashable {
        let expiryDate: Date
        let isEnded: Bool
    }

    let sessionID: UUID
}
