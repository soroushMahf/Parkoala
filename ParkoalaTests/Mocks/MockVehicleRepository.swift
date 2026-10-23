import Foundation
@testable import Parkoala

// Keeps vehicles in memory so tests never touch SwiftData
final class MockVehicleRepository: VehicleRepository {

    var vehicles: [Vehicle] = []
    var shouldThrow = false

    func allVehicles() async throws -> [Vehicle] {
        if shouldThrow { throw RepositoryError.fetchFailed }
        return vehicles
    }

    func defaultVehicle() async throws -> Vehicle? {
        if shouldThrow { throw RepositoryError.fetchFailed }
        return vehicles.first { $0.isDefault }
    }

    func save(_ vehicle: Vehicle) async throws {
        if shouldThrow { throw RepositoryError.saveFailed }
        vehicles.removeAll { $0.id == vehicle.id }
        vehicles.append(vehicle)
    }

    func delete(id: UUID) async throws {
        if shouldThrow { throw RepositoryError.saveFailed }
        vehicles.removeAll { $0.id == id }
    }
}
