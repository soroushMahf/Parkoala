//
//  ManageParkingLocationUseCase.swift
//  Parkoala
//
//  Created by Soroush Mahfoozi on 19/10/2026.
//

// Validates and saves a vehicle's parking location
// using its active parking session

import Foundation

struct ManageParkingLocationUseCase {
    
    private let sessionRepository: any SessionRepository
    
    init(sessionRepository: any SessionRepository) {
        self.sessionRepository = sessionRepository
    }
    
    // Saves a location to the selected vehicle's active parking session
    func saveLocation(vehicleID: UUID, location: ParkingLocation) async throws {
        
        // Validating coordinates
        if let coordinate = location.coordinate {
            guard coordinate.latitude.isFinite,
                  coordinate.longitude.isFinite,
                  (-90...90).contains(coordinate.latitude),
                  (-180...180).contains(coordinate.longitude) else {
                throw ParkingLocationError.invalidCoordinates
            }
        }
        
        // Retrieve active parking session
        guard var session = try await sessionRepository.activeSession(for: vehicleID) else {
            throw ParkingLocationError.noActiveSession
        }
        
        // Update location
        session.location = location
        
        // Persist updated session
        try await sessionRepository.save(session)
    }
    
    // Retrieves the parked location for the selected vehicle
    func getParkedLocation(vehicleID: UUID) async throws -> ParkingLocation? {
        
        let session = try await sessionRepository.activeSession(for: vehicleID)
        
        return session?.location
    }
}
