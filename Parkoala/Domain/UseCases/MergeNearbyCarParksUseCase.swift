import Foundation

// Combines MapKit search results with live TfNSW facilities into one list for
// the Nearby screen: a MapKit result within ~150m of a TfNSW facility is
// treated as the same car park (the live data wins), TfNSW facilities MapKit
// didn't return are added, and everything is sorted by distance from the user.
struct MergeNearbyCarParksUseCase {
    private let dedupeRadiusMetres: Double = 150

    func merge(
        mapKitResults: [CarPark],
        liveResults: [CarPark],
        userCoordinate: Coordinate
    ) -> [CarPark] {
        var usedLiveIDs = Set<String>()
        var merged: [CarPark] = []

        for mapKitCarPark in mapKitResults {
            let nearestLiveMatch = liveResults
                .filter { !usedLiveIDs.contains($0.id) }
                .map { ($0, distanceInMetres(mapKitCarPark.coordinate, $0.coordinate)) }
                .filter { $0.1 <= dedupeRadiusMetres }
                .min { $0.1 < $1.1 }

            if let (liveCarPark, _) = nearestLiveMatch {
                usedLiveIDs.insert(liveCarPark.id)
                merged.append(liveCarPark)
            } else {
                merged.append(mapKitCarPark)
            }
        }

        for liveCarPark in liveResults where !usedLiveIDs.contains(liveCarPark.id) {
            merged.append(liveCarPark)
        }

        return merged.sorted {
            distanceInMetres(userCoordinate, $0.coordinate) < distanceInMetres(userCoordinate, $1.coordinate)
        }
    }

    // Haversine distance in metres. Domain stays free of CoreLocation, so this
    // can't just use CLLocation like the Presentation layer does.
    private func distanceInMetres(_ a: Coordinate, _ b: Coordinate) -> Double {
        let earthRadiusMetres = 6_371_000.0

        let lat1 = a.latitude * .pi / 180
        let lat2 = b.latitude * .pi / 180
        let deltaLat = (b.latitude - a.latitude) * .pi / 180
        let deltaLon = (b.longitude - a.longitude) * .pi / 180

        let sinLat = sin(deltaLat / 2)
        let sinLon = sin(deltaLon / 2)
        let h = sinLat * sinLat + cos(lat1) * cos(lat2) * sinLon * sinLon

        return 2 * earthRadiusMetres * asin(min(1, sqrt(h)))
    }
}
