import Foundation
import Testing
@testable import Parkoala

struct MergeNearbyCarParksUseCaseTests {

    private let useCase = MergeNearbyCarParksUseCase()
    private let userCoordinate = Coordinate(latitude: -33.70, longitude: 150.90)

    private func makeCarPark(
        id: String,
        latitudeOffset: Double,
        source: CarPark.Source,
        availableSpaces: Int? = nil
    ) -> CarPark {
        CarPark(
            id: id,
            name: id,
            coordinate: Coordinate(latitude: -33.70 + latitudeOffset, longitude: 150.90),
            source: source,
            totalSpaces: availableSpaces == nil ? nil : 100,
            availableSpaces: availableSpaces,
            lastUpdated: availableSpaces == nil ? nil : .now
        )
    }

    @Test("A MapKit result within 150m of a live facility merges into the live row")
    func mergesNearbyDuplicate() {
        // ~0.0005 degrees latitude is roughly 55m — comfortably inside the 150m radius.
        let mapKitResult = makeCarPark(id: "mapkit-1", latitudeOffset: 0.0005, source: .mapSearch)
        let liveResult = makeCarPark(id: "26", latitudeOffset: 0, source: .parkAndRide, availableSpaces: 42)

        let merged = useCase.merge(mapKitResults: [mapKitResult], liveResults: [liveResult], userCoordinate: userCoordinate)

        #expect(merged.count == 1)
        #expect(merged.first?.id == "26")
        #expect(merged.first?.availableSpaces == 42)
    }

    @Test("A MapKit result more than 150m from a live facility is kept separate")
    func keepsFarApartResultsSeparate() {
        // ~0.01 degrees latitude is roughly 1.1km — well outside the 150m radius.
        let mapKitResult = makeCarPark(id: "mapkit-1", latitudeOffset: 0.01, source: .mapSearch)
        let liveResult = makeCarPark(id: "26", latitudeOffset: 0, source: .parkAndRide, availableSpaces: 42)

        let merged = useCase.merge(mapKitResults: [mapKitResult], liveResults: [liveResult], userCoordinate: userCoordinate)

        #expect(merged.count == 2)
    }

    @Test("A live-only facility MapKit never returned is still included")
    func includesLiveOnlyFacility() {
        let liveResult = makeCarPark(id: "26", latitudeOffset: 0, source: .parkAndRide, availableSpaces: 42)

        let merged = useCase.merge(mapKitResults: [], liveResults: [liveResult], userCoordinate: userCoordinate)

        #expect(merged.count == 1)
        #expect(merged.first?.id == "26")
    }

    @Test("Results are sorted by distance from the user")
    func sortsByDistance() {
        let far = makeCarPark(id: "far", latitudeOffset: 0.02, source: .mapSearch)
        let near = makeCarPark(id: "near", latitudeOffset: 0.005, source: .mapSearch)
        let nearest = makeCarPark(id: "nearest", latitudeOffset: 0.001, source: .mapSearch)

        let merged = useCase.merge(mapKitResults: [far, near, nearest], liveResults: [], userCoordinate: userCoordinate)

        #expect(merged.map(\.id) == ["nearest", "near", "far"])
    }
}
