import Foundation

protocol SpotRepository {
    func allSpots() async throws -> [SavedSpot]
    func save(_ spot: SavedSpot) async throws
    func delete(id: UUID) async throws
}
