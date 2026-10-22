import Foundation

struct ParkingSession: Identifiable, Hashable {
    let id: UUID
    var vehicleID: UUID
    var startDate: Date
    var expiryDate: Date
    // nil while the session is still running.
    var endDate: Date?
    var restriction: ParkingRestriction?
    var location: ParkingLocation?
    var savedSpotID: UUID?
    // Set once the session ends and the cost is worked out.
    var cost: Decimal?

    var isActive: Bool { endDate == nil }

    init(
        id: UUID = UUID(),
        vehicleID: UUID,
        startDate: Date,
        expiryDate: Date,
        endDate: Date? = nil,
        restriction: ParkingRestriction? = nil,
        location: ParkingLocation? = nil,
        savedSpotID: UUID? = nil,
        cost: Decimal? = nil
    ) {
        self.id = id
        self.vehicleID = vehicleID
        self.startDate = startDate
        self.expiryDate = expiryDate
        self.endDate = endDate
        self.restriction = restriction
        self.location = location
        self.savedSpotID = savedSpotID
        self.cost = cost
    }
}
