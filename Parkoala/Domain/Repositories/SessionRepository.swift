import Foundation

protocol SessionRepository {
    func activeSession(for vehicleID: UUID) async throws -> ParkingSession?
    // Sessions in the month containing the given date, newest first.
    func sessions(inMonthOf date: Date) async throws -> [ParkingSession]
    func save(_ session: ParkingSession) async throws
    func delete(id: UUID) async throws
}
