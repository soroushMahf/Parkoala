import Foundation
import CoreLocation

// Backs CarParkRepository with the TfNSW Car Park API. An actor because the
// in-memory cache is mutated across calls that may overlap (e.g. scrolling the
// map while a search is in flight).
actor TfNSWCarParkRepository: CarParkRepository {
    // Historical-only Metro entries; never shown.
    private nonisolated static let excludedFacilityIDs: Set<String> = ["1", "2", "3", "4", "5"]
    private nonisolated static let cacheLifetime: TimeInterval = 60
    private nonisolated static let staleAfter: TimeInterval = 30 * 60

    // Set once at init and never mutated again, so it's safe to leave
    // unisolated — that also sidesteps the actor-init isolation checker
    // tripping over a non-Sendable protocol type.
    private nonisolated(unsafe) let client: TfNSWCarParkClient?
    private var cache: (carParks: [CarPark], fetchedAt: Date)?

    init(client: TfNSWCarParkClient?) {
        self.client = client
    }

    
    init() {
        self.init(client: URLSessionTfNSWCarParkClient(apiKey: Self.readAPIKeyFromBundledSecretsFile()))
    }

    private static func readAPIKeyFromBundledSecretsFile() -> String? {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "xcconfig"),
              let contents = try? String(contentsOf: url, encoding: .utf8)
        else {
            return nil
        }

        for line in contents.split(separator: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.hasPrefix("//"), let equalsIndex = trimmed.firstIndex(of: "=") else {
                continue
            }

            let key = trimmed[trimmed.startIndex..<equalsIndex].trimmingCharacters(in: .whitespaces)
            guard key == "TFNSW_API_KEY" else { continue }

            let value = trimmed[trimmed.index(after: equalsIndex)...].trimmingCharacters(in: .whitespaces)
            return value.isEmpty ? nil : value
        }

        return nil
    }

    func nearbyCarParks(around coordinate: Coordinate, radiusInKilometres: Double) async throws -> [CarPark] {
        guard let client else { return [] }

        let allFacilities: [CarPark]
        do {
            allFacilities = try await freshFacilities(using: client)
        } catch {
            // Offline or a bad response: fall back to whatever we last had,
            // however old, so the screen can show its age instead of nothing.
            if let cache {
                allFacilities = cache.carParks
            } else {
                throw error
            }
        }

        let radiusInMetres = radiusInKilometres * 1000
        let userLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        return allFacilities.filter { carPark in
            let facilityLocation = CLLocation(latitude: carPark.coordinate.latitude, longitude: carPark.coordinate.longitude)
            return userLocation.distance(from: facilityLocation) <= radiusInMetres
        }
    }

    private func freshFacilities(using client: TfNSWCarParkClient) async throws -> [CarPark] {
        if let cache, Date.now.timeIntervalSince(cache.fetchedAt) < Self.cacheLifetime {
            return cache.carParks
        }

        let facilities = try await client.fetchAllFacilities()
            .filter { dto in
                guard let facilityID = dto.facilityID else { return false }
                return !Self.excludedFacilityIDs.contains(facilityID)
            }
            .compactMap(carPark(from:))

        cache = (facilities, .now)
        return facilities
    }

    private func carPark(from dto: TfNSWCarParkDTO) -> CarPark? {
        guard let facilityID = dto.facilityID,
              let latitude = dto.location?.latitude,
              let longitude = dto.location?.longitude
        else {
            return nil
        }

        let isFresh = dto.messageDate.map { Date.now.timeIntervalSince($0) <= Self.staleAfter } ?? false

        var totalSpaces: Int?
        var availableSpaces: Int?
        var lastUpdated: Date?

        if isFresh, let spots = dto.spots, let occupied = dto.occupancy?.total {
            totalSpaces = spots
            availableSpaces = max(0, spots - occupied)
            lastUpdated = dto.messageDate
        }

        return CarPark(
            id: facilityID,
            name: dto.facilityName ?? "Parking",
            coordinate: Coordinate(latitude: latitude, longitude: longitude),
            source: .parkAndRide,
            totalSpaces: totalSpaces,
            availableSpaces: availableSpaces,
            lastUpdated: lastUpdated
        )
    }
}
