import Foundation

// A car park shown on the nearby map.
struct CarPark: Identifiable, Hashable {
    enum Source: Hashable {
        case parkAndRide
        case mapSearch
    }

    let id: String
    var name: String
    var coordinate: Coordinate
    var source: Source
    var totalSpaces: Int?
    var availableSpaces: Int?
    // When the live numbers were last fetched. Used for the "Updated 2:14 pm" label.
    var lastUpdated: Date?
}
