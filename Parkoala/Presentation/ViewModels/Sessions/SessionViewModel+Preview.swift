// Sample view models for SwiftUI previews only, kept in memory.

import Foundation

extension SessionViewModel {

    static func preview(parkedFor duration: TimeInterval? = nil) -> SessionViewModel {
        let sessions = InMemorySessionRepository()
        let useCase = ManageParkingSessionUseCase(
            sessionRepository: sessions,
            vehicleRepository: InMemoryVehicleRepository()
        )
        let viewModel = SessionViewModel(useCase: useCase)

        if let duration {
            Task { await viewModel.startSession(duration: duration) }
        }
        return viewModel
    }
}

private final class InMemorySessionRepository: SessionRepository {
    private var sessions: [ParkingSession] = []

    func activeSession(for vehicleID: UUID) async throws -> ParkingSession? {
        sessions.first { $0.vehicleID == vehicleID && $0.isActive }
    }

    func sessions(inMonthOf date: Date) async throws -> [ParkingSession] {
        sessions
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
