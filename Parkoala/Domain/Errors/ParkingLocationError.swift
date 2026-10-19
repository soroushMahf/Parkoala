//
//  ParkingLocationError.swift
//  Parkoala
//
//  Created by Soroush Mahfoozi on 19/10/2026.
//

// Errors associated with retrieving and saving parking locations

import Foundation

enum ParkingLocationError: Error, LocalizedError {
    
    case invalidCoordinates
    case locationUnavailable
    case permissionDenied
    case noActiveSession
    
    var errorDescription: String? {
        switch self {
        case .invalidCoordinates:
            return "The parking location contains invalid coordinates."
            
        case .locationUnavailable:
            return "Your current location could not be determined."
            
        case .permissionDenied:
            return "Location access is disabled. Please enable it in Settings."
            
        case .noActiveSession:
            return "There is no active parking session to save a location to."
        }
    }
}
