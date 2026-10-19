import Foundation

// Where the car was left, including notes for multi-storey car parks.
struct ParkingLocation: Hashable {
    var coordinate: Coordinate?
    var levelAndBay: String?
}
