import Foundation
import Testing
@testable import Parkoala

struct CarParkAvailabilityTests {

    private func makeCarPark(totalSpaces: Int?, availableSpaces: Int?, lastUpdated: Date? = .now) -> CarPark {
        CarPark(
            id: "26",
            name: "Tallawong P1",
            coordinate: Coordinate(latitude: -33.69, longitude: 150.91),
            source: .parkAndRide,
            totalSpaces: totalSpaces,
            availableSpaces: availableSpaces,
            lastUpdated: lastUpdated
        )
    }

    @Test("Plenty of spaces shows an estimate")
    func estimateWording() {
        let carPark = makeCarPark(totalSpaces: 100, availableSpaces: 50)
        #expect(carPark.availabilityText == "~50 spaces")
    }

    @Test("Below the almost-full threshold shows Almost full")
    func almostFullWording() {
        // 5/100 = 5%, below the 10% threshold.
        let carPark = makeCarPark(totalSpaces: 100, availableSpaces: 5)
        #expect(carPark.availabilityText == "Almost full")
    }

    @Test("Exactly at the almost-full threshold still shows an estimate")
    func thresholdBoundaryWording() {
        // 10/100 = 10%, not below the threshold.
        let carPark = makeCarPark(totalSpaces: 100, availableSpaces: 10)
        #expect(carPark.availabilityText == "~10 spaces")
    }

    @Test("Zero spaces shows Full")
    func fullWording() {
        let carPark = makeCarPark(totalSpaces: 100, availableSpaces: 0)
        #expect(carPark.availabilityText == "Full")
    }

    @Test("A negative available count clamps to Full instead of crashing")
    func negativeAvailableClampsToFull() {
        let carPark = makeCarPark(totalSpaces: 100, availableSpaces: -3)
        #expect(carPark.availabilityText == "Full")
    }

    @Test("Missing totalSpaces shows Data unavailable")
    func missingTotalShowsUnavailable() {
        let carPark = makeCarPark(totalSpaces: nil, availableSpaces: 50)
        #expect(carPark.availabilityText == "Data unavailable")
    }

    @Test("Missing availableSpaces shows Data unavailable")
    func missingAvailableShowsUnavailable() {
        let carPark = makeCarPark(totalSpaces: 100, availableSpaces: nil)
        #expect(carPark.availabilityText == "Data unavailable")
    }

    @Test("A total of zero shows Data unavailable rather than dividing by zero")
    func zeroTotalShowsUnavailable() {
        let carPark = makeCarPark(totalSpaces: 0, availableSpaces: 0)
        #expect(carPark.availabilityText == "Data unavailable")
    }

    @Test("Accessibility text spells out the estimate")
    func accessibilityEstimateWording() {
        let carPark = makeCarPark(totalSpaces: 100, availableSpaces: 42)
        #expect(carPark.accessibilityAvailabilityText == "about 42 spaces available, estimate")
    }

    @Test("No lastUpdated means no updated-at text")
    func noUpdatedAtTextWhenMissing() {
        let carPark = makeCarPark(totalSpaces: 100, availableSpaces: 50, lastUpdated: nil)
        #expect(carPark.updatedAtText == nil)
    }

    @Test("A recent update reads as just now")
    func justNowWording() {
        let carPark = makeCarPark(totalSpaces: 100, availableSpaces: 50, lastUpdated: Date.now.addingTimeInterval(-30))
        #expect(carPark.updatedAtText == "Updated just now")
    }

    @Test("A three minute old update reads as 3 min ago")
    func minutesAgoWording() {
        let carPark = makeCarPark(totalSpaces: 100, availableSpaces: 50, lastUpdated: Date.now.addingTimeInterval(-200))
        #expect(carPark.updatedAtText == "Updated 3 min ago")
    }
}
