import Foundation

// A car park or street the user parks at often, with their own rates.
struct SavedSpot: Identifiable, Hashable {
    let id: UUID
    var name: String
    var coordinate: Coordinate
    var rates: [RateRule]

    init(id: UUID = UUID(), name: String, coordinate: Coordinate, rates: [RateRule] = []) {
        self.id = id
        self.name = name
        self.coordinate = coordinate
        self.rates = rates
    }
}
