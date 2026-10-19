import Foundation

// A plain latitude and longitude, so the Domain layer does not need CoreLocation.
struct Coordinate: Hashable {
    var latitude: Double
    var longitude: Double
}
