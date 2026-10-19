import Foundation

protocol CarParkRepository {
    // Live data first. Falls back to the cached copy when offline,
    // with lastUpdated set so the screen can show its age.
    func nearbyCarParks(around coordinate: Coordinate, radiusInKilometres: Double) async throws -> [CarPark]
}
