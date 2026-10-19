import Foundation

protocol VehicleRepository {
    func allVehicles() async throws -> [Vehicle]
    func defaultVehicle() async throws -> Vehicle?
    func save(_ vehicle: Vehicle) async throws
    func delete(id: UUID) async throws
}
