import Foundation

// Display wording for a car park's live availability. Built entirely from
// CarPark's existing optional fields — nil totalSpaces/availableSpaces means
// "Data unavailable", there is no separate availability model to keep in sync.
extension CarPark {
    // Below this fraction of spots free, show "Almost full" instead of a number.
    static let almostFullThresholdFraction: Double = 0.1

    private enum AvailabilityLevel {
        case unavailable
        case full
        case almostFull
        case estimate(spaces: Int)
    }

    private var availabilityLevel: AvailabilityLevel {
        guard let availableSpaces, let totalSpaces, totalSpaces > 0 else {
            return .unavailable
        }

        let spaces = max(0, availableSpaces)

        if spaces < 1 {
            return .full
        }

        if Double(spaces) / Double(totalSpaces) < Self.almostFullThresholdFraction {
            return .almostFull
        }

        return .estimate(spaces: spaces)
    }

    var availabilityText: String {
        switch availabilityLevel {
        case .unavailable: "Data unavailable"
        case .full: "Full"
        case .almostFull: "Almost full"
        case .estimate(let spaces): "~\(spaces) spaces"
        }
    }

    // Used to build VoiceOver labels, e.g. "Bella Vista Park and Ride, about 42 spaces available, estimate".
    var accessibilityAvailabilityText: String {
        switch availabilityLevel {
        case .unavailable: "data unavailable"
        case .full: "full, no spaces available"
        case .almostFull: "almost full"
        case .estimate(let spaces): "about \(spaces) spaces available, estimate"
        }
    }

    var updatedAtText: String? {
        guard let lastUpdated else { return nil }

        let minutes = max(0, Int(Date.now.timeIntervalSince(lastUpdated) / 60))

        switch minutes {
        case 0: return "Updated just now"
        case 1: return "Updated 1 min ago"
        default: return "Updated \(minutes) min ago"
        }
    }
}
