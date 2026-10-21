//
//  ManageParkingLocationUseCaseTests.swift
//  ParkoalaTests
//
//  Created by Soroush Mahfoozi on 21/10/2026.
//

import Foundation
import Testing
@testable import Parkoala

@MainActor
struct ManageParkingLocationUseCaseTests {

    // Test 1: A valid location is saved to the active session.
    @Test("Saving a valid location updates the active session")
    func saveValidLocation() async throws {
        let repository = MockSessionRepository()
        let useCase = ManageParkingLocationUseCase(sessionRepository: repository)

        let vehicleID = UUID()
        let start = Date.now

        repository.sessions = [
            ParkingSession(
                vehicleID: vehicleID,
                startDate: start,
                expiryDate: start.addingTimeInterval(3600)
            )
        ]

        let location = ParkingLocation(
            coordinate: Coordinate(
                latitude: -33.8830,
                longitude: 151.2000
            ),
            levelAndBay: "Level B2, Bay 15"
        )

        try await useCase.saveLocation(
            vehicleID: vehicleID,
            location: location
        )

        let updated = try await repository.activeSession(
            for: vehicleID
        )

        #expect(updated?.location == location)
        #expect(repository.sessions.count == 1)
    }

    // Test 2: Invalid coordinates should be rejected.
    @Test("Saving invalid coordinates throws an error")
    func rejectInvalidCoordinates() async {
        let repository = MockSessionRepository()
        let useCase = ManageParkingLocationUseCase(
            sessionRepository: repository
        )

        let vehicleID = UUID()
        let start = Date.now

        repository.sessions = [
            ParkingSession(
                vehicleID: vehicleID,
                startDate: start,
                expiryDate: start.addingTimeInterval(3600)
            )
        ]

        let location = ParkingLocation(
            coordinate: Coordinate(
                latitude: -100,
                longitude: 151.2000
            )
        )

        await #expect(throws: ParkingLocationError.invalidCoordinates) {
            try await useCase.saveLocation(
                vehicleID: vehicleID,
                location: location
            )
        }

        #expect(repository.sessions.first?.location == nil)
    }

    // Test 3: Saving requires an existing active session.
    @Test("Saving without an active session throws an error")
    func rejectMissingSession() async {
        let repository = MockSessionRepository()
        let useCase = ManageParkingLocationUseCase(
            sessionRepository: repository
        )

        let location = ParkingLocation(
            coordinate: Coordinate(
                latitude: -33.8830,
                longitude: 151.2000
            )
        )

        await #expect(throws: ParkingLocationError.noActiveSession) {
            try await useCase.saveLocation(
                vehicleID: UUID(),
                location: location
            )
        }
    }

    // Test 4: A previously saved location can be retrieved.
    @Test("Retrieving parked location returns the saved coordinates")
    func retrieveSavedLocation() async throws {
        let repository = MockSessionRepository()
        let useCase = ManageParkingLocationUseCase(
            sessionRepository: repository
        )

        let vehicleID = UUID()
        let start = Date.now

        let location = ParkingLocation(
            coordinate: Coordinate(
                latitude: -33.8830,
                longitude: 151.2000
            ),
            levelAndBay: "Level B2, Bay 15"
        )

        var session = ParkingSession(
            vehicleID: vehicleID,
            startDate: start,
            expiryDate: start.addingTimeInterval(3600)
        )

        session.location = location
        repository.sessions = [session]

        let result = try await useCase.getParkedLocation(
            vehicleID: vehicleID
        )

        #expect(result == location)
    }
}
