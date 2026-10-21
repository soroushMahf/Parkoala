//
//  ManageParkingSessionUseCase.swift
//  Parkoala
//
//  Created by Soroush Mahfoozi on 19/10/2026.
//

// Starts and ends parking sessions.
// Only one session can run at a time, and its length must fit
// between 1 minute, 24 hours and the sign's time limit.

import Foundation

struct ManageParkingSessionUseCase {

    static let maximumDuration: TimeInterval = 24 * 60 * 60

    private let sessionRepository: any SessionRepository
    private let vehicleRepository: any VehicleRepository
    private let now: () -> Date

    // now can be replaced in tests so times are predictable
    init(
        sessionRepository: any SessionRepository,
        vehicleRepository: any VehicleRepository,
        now: @escaping () -> Date = Date.init
    ) {
        self.sessionRepository = sessionRepository
        self.vehicleRepository = vehicleRepository
        self.now = now
    }

    // Starts a session for the default vehicle and returns it
    func startSession(
        duration: TimeInterval,
        restriction: ParkingRestriction? = nil,
        location: ParkingLocation? = nil
    ) async throws -> ParkingSession {

        guard duration >= 60, duration <= Self.maximumDuration else {
            throw ParkingSessionError.invalidDuration
        }

        if let maxStay = restriction?.maxStay, duration > maxStay {
            throw ParkingSessionError.exceedsTimeLimit
        }

        let vehicle = try await defaultVehicle()

        if try await sessionRepository.activeSession(for: vehicle.id) != nil {
            throw ParkingSessionError.sessionAlreadyActive
        }

        let startDate = now()
        let session = ParkingSession(
            vehicleID: vehicle.id,
            startDate: startDate,
            expiryDate: startDate.addingTimeInterval(duration),
            restriction: restriction,
            location: location
        )

        try await sessionRepository.save(session)
        return session
    }

    // Ends the running session and returns it with its end time set
    func endSession() async throws -> ParkingSession {

        let vehicle = try await defaultVehicle()

        guard var session = try await sessionRepository.activeSession(for: vehicle.id) else {
            throw ParkingSessionError.noActiveSession
        }

        session.endDate = now()
        try await sessionRepository.save(session)
        return session
    }

    // The running session, or nil when the user is not parked
    func activeSession() async throws -> ParkingSession? {
        let vehicle = try await defaultVehicle()
        return try await sessionRepository.activeSession(for: vehicle.id)
    }

    // Finished sessions from the last few months, newest first
    func recentSessions(monthsBack: Int = 3) async throws -> [ParkingSession] {
        let calendar = Calendar.current
        var sessions: [ParkingSession] = []

        for offset in 0..<monthsBack {
            guard let month = calendar.date(byAdding: .month, value: -offset, to: now()) else { continue }
            sessions += try await sessionRepository.sessions(inMonthOf: month)
        }

        return sessions
            .filter { !$0.isActive }
            .sorted { $0.startDate > $1.startDate }
    }

    // The app tracks one car, so a default one is made the first time it is needed
    private func defaultVehicle() async throws -> Vehicle {
        if let vehicle = try await vehicleRepository.defaultVehicle() {
            return vehicle
        }

        let vehicle = Vehicle(name: "My car", numberPlate: "", isDefault: true)
        try await vehicleRepository.save(vehicle)
        return vehicle
    }
}
