import Foundation

protocol FineRepository {
    // Fines not yet paid, sorted by due date.
    func unpaidFines() async throws -> [Fine]
    func save(_ fine: Fine) async throws
    func delete(id: UUID) async throws
}
