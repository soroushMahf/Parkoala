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
    // Entered when starting, if the user already knows the car park's rate.
    var plannedRate: RateRule?
    // Set once the session ends and the cost is worked out.
    var cost: Decimal?
    // Optionally entered by the user once they know what they were actually charged.
    var actualCost: Decimal?

    var isActive: Bool { endDate == nil }

    init(
        id: UUID = UUID(),
        vehicleID: UUID,
        startDate: Date,
        expiryDate: Date,
        endDate: Date? = nil,
        restriction: ParkingRestriction? = nil,
        location: ParkingLocation? = nil,
        plannedRate: RateRule? = nil,
        cost: Decimal? = nil,
        actualCost: Decimal? = nil
    ) {
        self.id = id
        self.vehicleID = vehicleID
        self.startDate = startDate
        self.expiryDate = expiryDate
        self.endDate = endDate
        self.restriction = restriction
        self.location = location
        self.plannedRate = plannedRate
        self.cost = cost
        self.actualCost = actualCost
    }
}
