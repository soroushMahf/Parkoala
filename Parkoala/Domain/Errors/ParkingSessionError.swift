//
//  ParkingSessionError.swift
//  Parkoala
//
//  Created by Soroush Mahfoozi on 19/10/2026.
//

// Errors when starting or ending a parking session

import Foundation

enum ParkingSessionError: Error, LocalizedError, Equatable {

    case sessionAlreadyActive
    case noActiveSession
    case invalidDuration
    case exceedsTimeLimit

    var errorDescription: String? {
        switch self {
        case .sessionAlreadyActive:
            return "You already have a parking session running. End it before starting a new one."

        case .noActiveSession:
            return "There is no parking session running to end."

        case .invalidDuration:
            return "Choose a parking time between 1 minute and 24 hours."

        case .exceedsTimeLimit:
            return "That is longer than the sign allows. Choose a shorter time."
        }
    }
}
