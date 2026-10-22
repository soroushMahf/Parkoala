import Foundation
import Testing
@testable import Parkoala

@MainActor
struct TfNSWCarParkRepositoryTests {

    private let sydneyCoordinate = Coordinate(latitude: -33.69, longitude: 150.91)

    private func makeDTO(
        facilityID: String,
        spots: Int? = 100,
        occupied: Int? = 60,
        messageDate: Date? = .now,
        latitude: Double = -33.69,
        longitude: Double = 150.91
    ) -> TfNSWCarParkDTO {
        TfNSWCarParkDTO(
            facilityID: facilityID,
            facilityName: "Facility \(facilityID)",
            spots: spots,
            occupancy: .init(total: occupied),
            location: .init(latitude: latitude, longitude: longitude),
            messageDate: messageDate
        )
    }

    @Test("Available spaces is spots minus occupancy, clamped at zero")
    func computesAvailableSpaces() async throws {
        let client = MockTfNSWCarParkClient()
        client.result = .success([makeDTO(facilityID: "26", spots: 100, occupied: 60)])
        let repository = TfNSWCarParkRepository(client: client)

        let results = try await repository.nearbyCarParks(around: sydneyCoordinate, radiusInKilometres: 5)

        #expect(results.first?.totalSpaces == 100)
        #expect(results.first?.availableSpaces == 40)
    }

    @Test("Occupancy greater than spots clamps available spaces to zero")
    func clampsOverOccupiedFacility() async throws {
        let client = MockTfNSWCarParkClient()
        client.result = .success([makeDTO(facilityID: "26", spots: 50, occupied: 80)])
        let repository = TfNSWCarParkRepository(client: client)

        let results = try await repository.nearbyCarParks(around: sydneyCoordinate, radiusInKilometres: 5)

        #expect(results.first?.availableSpaces == 0)
    }

    @Test("A facility with unparseable numbers becomes unavailable, not dropped")
    func unparseableNumbersBecomeUnavailable() async throws {
        let client = MockTfNSWCarParkClient()
        client.result = .success([makeDTO(facilityID: "26", spots: nil, occupied: nil)])
        let repository = TfNSWCarParkRepository(client: client)

        let results = try await repository.nearbyCarParks(around: sydneyCoordinate, radiusInKilometres: 5)

        #expect(results.count == 1)
        #expect(results.first?.totalSpaces == nil)
        #expect(results.first?.availableSpaces == nil)
    }

    @Test("Facility IDs 1 through 5 are excluded as historical-only")
    func excludesHistoricalFacilities() async throws {
        let client = MockTfNSWCarParkClient()
        client.result = .success((1...5).map { makeDTO(facilityID: "\($0)") } + [makeDTO(facilityID: "26")])
        let repository = TfNSWCarParkRepository(client: client)

        let results = try await repository.nearbyCarParks(around: sydneyCoordinate, radiusInKilometres: 5)

        #expect(results.map(\.id) == ["26"])
    }

    @Test("A facility missing coordinates is dropped rather than crashing")
    func dropsFacilityMissingLocation() async throws {
        let client = MockTfNSWCarParkClient()
        let dtoWithoutLocation = TfNSWCarParkDTO(
            facilityID: "26",
            spots: 100,
            occupancy: .init(total: 60),
            location: nil,
            messageDate: .now
        )
        client.result = .success([dtoWithoutLocation])
        let repository = TfNSWCarParkRepository(client: client)

        let results = try await repository.nearbyCarParks(around: sydneyCoordinate, radiusInKilometres: 5)

        #expect(results.isEmpty)
    }

    @Test("MessageDate older than 30 minutes makes a facility unavailable")
    func staleMessageDateBecomesUnavailable() async throws {
        let client = MockTfNSWCarParkClient()
        client.result = .success([makeDTO(facilityID: "26", messageDate: Date.now.addingTimeInterval(-31 * 60))])
        let repository = TfNSWCarParkRepository(client: client)

        let results = try await repository.nearbyCarParks(around: sydneyCoordinate, radiusInKilometres: 5)

        #expect(results.first?.totalSpaces == nil)
        #expect(results.first?.availableSpaces == nil)
        #expect(results.first?.lastUpdated == nil)
    }

    @Test("A missing MessageDate makes a facility unavailable")
    func missingMessageDateBecomesUnavailable() async throws {
        let client = MockTfNSWCarParkClient()
        client.result = .success([makeDTO(facilityID: "26", messageDate: nil)])
        let repository = TfNSWCarParkRepository(client: client)

        let results = try await repository.nearbyCarParks(around: sydneyCoordinate, radiusInKilometres: 5)

        #expect(results.first?.totalSpaces == nil)
    }

    @Test("A second call within the cache lifetime does not refetch")
    func cachesWithinLifetime() async throws {
        let client = MockTfNSWCarParkClient()
        client.result = .success([makeDTO(facilityID: "26")])
        let repository = TfNSWCarParkRepository(client: client, cacheLifetime: 60)

        _ = try await repository.nearbyCarParks(around: sydneyCoordinate, radiusInKilometres: 5)
        _ = try await repository.nearbyCarParks(around: sydneyCoordinate, radiusInKilometres: 5)

        #expect(client.fetchCallCount == 1)
    }

    @Test("A call after the cache lifetime expires refetches")
    func refetchesAfterExpiry() async throws {
        let client = MockTfNSWCarParkClient()
        client.result = .success([makeDTO(facilityID: "26")])
        let repository = TfNSWCarParkRepository(client: client, cacheLifetime: 0.05)

        _ = try await repository.nearbyCarParks(around: sydneyCoordinate, radiusInKilometres: 5)
        try await Task.sleep(nanoseconds: 100_000_000)
        _ = try await repository.nearbyCarParks(around: sydneyCoordinate, radiusInKilometres: 5)

        #expect(client.fetchCallCount == 2)
    }

    @Test("A fetch failure with no prior cache propagates the error")
    func propagatesErrorWithNoCache() async {
        let client = MockTfNSWCarParkClient()
        client.result = .failure(NetworkError.offline)
        let repository = TfNSWCarParkRepository(client: client)

        await #expect(throws: NetworkError.offline) {
            try await repository.nearbyCarParks(around: sydneyCoordinate, radiusInKilometres: 5)
        }
    }

    @Test("A missing API key means no client, so the repository returns an empty list instead of throwing")
    func missingKeyReturnsEmpty() async throws {
        let repository = TfNSWCarParkRepository(client: nil)

        let results = try await repository.nearbyCarParks(around: sydneyCoordinate, radiusInKilometres: 5)

        #expect(results.isEmpty)
    }

    @Test("Facilities outside the search radius are filtered out")
    func filtersByRadius() async throws {
        let client = MockTfNSWCarParkClient()
        client.result = .success([
            makeDTO(facilityID: "near", latitude: -33.69, longitude: 150.91),
            makeDTO(facilityID: "far", latitude: -34.50, longitude: 151.50)
        ])
        let repository = TfNSWCarParkRepository(client: client)

        let results = try await repository.nearbyCarParks(around: sydneyCoordinate, radiusInKilometres: 5)

        #expect(results.map(\.id) == ["near"])
    }
}
