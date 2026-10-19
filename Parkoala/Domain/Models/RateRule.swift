import Foundation

// One way a car park charges. A saved spot can have several.
enum RateRule: Hashable {
    case hourly(price: Decimal)
    case flat(price: Decimal)
    // Enter before and leave after the given minutes after midnight.
    case earlyBird(price: Decimal, enterBeforeMinute: Int, leaveAfterMinute: Int)
    case freePeriod(minutes: Int)
}
