import Foundation
@testable import Parkoala

// Keeps sessions in memory so tests never touch SwiftData
final class MockSessionRepository: SessionRepository {

    var sessions: [ParkingSession] = []
    var shouldThrow = false

    func activeSession(for vehicleID: UUID) async throws -> ParkingSession? {
        if shouldThrow { throw RepositoryError.fetchFailed }
        return sessions.first { $0.vehicleID == vehicleID && $0.isActive }
    }

    func sessions(inMonthOf date: Date) async throws -> [ParkingSession] {
        if shouldThrow { throw RepositoryError.fetchFailed }
        return sessions.filter { Calendar.current.isDate($0.startDate, equalTo: date, toGranularity: .month) }
    }

    func save(_ session: ParkingSession) async throws {
        if shouldThrow { throw RepositoryError.saveFailed }
        sessions.removeAll { $0.id == session.id }
        sessions.append(session)
    }

    func delete(id: UUID) async throws {
        if shouldThrow { throw RepositoryError.saveFailed }
        sessions.removeAll { $0.id == id }
    }
}
