// Saves and loads vehicles with SwiftData.
// Converts between VehicleEntity and the Vehicle domain model.

import Foundation
import SwiftData

final class SwiftDataVehicleRepository: VehicleRepository {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func allVehicles() async throws -> [Vehicle] {
        let descriptor = FetchDescriptor<VehicleEntity>(sortBy: [SortDescriptor(\.name)])

        do {
            return try context.fetch(descriptor).map { $0.toDomain() }
        } catch {
            throw RepositoryError.fetchFailed
        }
    }

    func defaultVehicle() async throws -> Vehicle? {
        let descriptor = FetchDescriptor<VehicleEntity>(predicate: #Predicate { $0.isDefault })

        do {
            return try context.fetch(descriptor).first?.toDomain()
        } catch {
            throw RepositoryError.fetchFailed
        }
    }

    // Replaces the stored copy if the vehicle already exists
    func save(_ vehicle: Vehicle) async throws {
        do {
            if let existing = try entity(id: vehicle.id) {
                context.delete(existing)
            }
            context.insert(VehicleEntity(vehicle: vehicle))
            try context.save()
        } catch {
            throw RepositoryError.saveFailed
        }
    }

    func delete(id: UUID) async throws {
        do {
            guard let existing = try entity(id: id) else {
                throw RepositoryError.notFound
            }
            context.delete(existing)
            try context.save()
        } catch let error as RepositoryError {
            throw error
        } catch {
            throw RepositoryError.saveFailed
        }
    }

    private func entity(id: UUID) throws -> VehicleEntity? {
        let descriptor = FetchDescriptor<VehicleEntity>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }
}
