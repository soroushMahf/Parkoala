// Saves and loads parking sessions with SwiftData.
// Converts between ParkingSessionEntity and the ParkingSession domain model.

import Foundation
import SwiftData

final class SwiftDataSessionRepository: SessionRepository {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func activeSession(for vehicleID: UUID) async throws -> ParkingSession? {
        let descriptor = FetchDescriptor<ParkingSessionEntity>(
            predicate: #Predicate { $0.vehicleID == vehicleID && $0.endDate == nil }
        )

        do {
            return try context.fetch(descriptor).first?.toDomain()
        } catch {
            throw RepositoryError.fetchFailed
        }
    }

    func sessions(inMonthOf date: Date) async throws -> [ParkingSession] {
        guard let month = Calendar.current.dateInterval(of: .month, for: date) else {
            return []
        }
        let start = month.start
        let end = month.end

        let descriptor = FetchDescriptor<ParkingSessionEntity>(
            predicate: #Predicate { $0.startDate >= start && $0.startDate < end },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )

        do {
            return try context.fetch(descriptor).map { $0.toDomain() }
        } catch {
            throw RepositoryError.fetchFailed
        }
    }

    // Replaces the stored copy if the session already exists
    func save(_ session: ParkingSession) async throws {
        do {
            if let existing = try entity(id: session.id) {
                context.delete(existing)
            }
            context.insert(ParkingSessionEntity(session: session))
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

    private func entity(id: UUID) throws -> ParkingSessionEntity? {
        let descriptor = FetchDescriptor<ParkingSessionEntity>(predicate: #Predicate { $0.id == id })
        return try context.fetch(descriptor).first
    }
}
