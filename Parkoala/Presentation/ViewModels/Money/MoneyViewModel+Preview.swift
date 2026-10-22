//
//MoneyViewModel+Preview.swift
//Parkoala
//
//  Created by jessica dao on 22/10/2026.

// Sample view model for SwiftUI previews only, kept in memory.

import Foundation

extension MoneyViewModel {

    static func preview(withSamples: Bool) -> MoneyViewModel {
        let sessions = InMemorySessionRepository()
        let vehicles = InMemoryVehicleRepository()

        if withSamples {
            let vehicleID = UUID()

            let costedStart = Date.now.addingTimeInterval(-2 * 24 * 60 * 60)
            sessions.add(ParkingSession(
                vehicleID: vehicleID,
                startDate: costedStart,
                expiryDate: costedStart.addingTimeInterval(2 * 60 * 60),
                endDate: costedStart.addingTimeInterval(90 * 60),
                cost: 12.50
            ))

            let uncostedStart = Date.now.addingTimeInterval(-1 * 24 * 60 * 60)
            sessions.add(ParkingSession(
                vehicleID: vehicleID,
                startDate: uncostedStart,
                expiryDate: uncostedStart.addingTimeInterval(3 * 60 * 60),
                endDate: uncostedStart.addingTimeInterval(2 * 60 * 60)
            ))
        }

        let sessionUseCase = ManageParkingSessionUseCase(sessionRepository: sessions, vehicleRepository: vehicles)
        let costUseCase = CalculateParkingCostsUseCase(sessionRepository: sessions)
        return MoneyViewModel(sessionUseCase: sessionUseCase, costUseCase: costUseCase)
    }
}

private final class InMemorySessionRepository: SessionRepository {
    private var sessions: [ParkingSession] = []

    func add(_ session: ParkingSession) {
        sessions.append(session)
    }

    func activeSession(for vehicleID: UUID) async throws -> ParkingSession? {
        sessions.first { $0.vehicleID == vehicleID && $0.isActive }
    }

    func sessions(inMonthOf date: Date) async throws -> [ParkingSession] {
        sessions.filter { Calendar.current.isDate($0.startDate, equalTo: date, toGranularity: .month) }
    }

    func save(_ session: ParkingSession) async throws {
        sessions.removeAll { $0.id == session.id }
        sessions.append(session)
    }

    func delete(id: UUID) async throws {
        sessions.removeAll { $0.id == id }
    }
}

private final class InMemoryVehicleRepository: VehicleRepository {
    private var vehicles: [Vehicle] = []

    func allVehicles() async throws -> [Vehicle] { vehicles }
    func defaultVehicle() async throws -> Vehicle? { vehicles.first { $0.isDefault } }

    func save(_ vehicle: Vehicle) async throws {
        vehicles.removeAll { $0.id == vehicle.id }
        vehicles.append(vehicle)
    }

    func delete(id: UUID) async throws {
        vehicles.removeAll { $0.id == id }
    }
}
