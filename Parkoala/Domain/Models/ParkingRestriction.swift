import Foundation

// What a parking sign allows, for example "2P 8am-6pm Mon-Fri".
struct ParkingRestriction: Identifiable, Hashable {
    enum Kind: Hashable {
        case timeLimited
        case noStopping
        case clearway
        case unrestricted
    }

    let id: UUID
    var kind: Kind
    // Longest stay allowed in seconds. nil when there is no time limit.
    var maxStay: TimeInterval?
    // Times the sign applies, as minutes after midnight (8am = 480).
    var startMinute: Int
    var endMinute: Int
    var days: Set<Weekday>

    init(
        id: UUID = UUID(),
        kind: Kind,
        maxStay: TimeInterval? = nil,
        startMinute: Int = 0,
        endMinute: Int = 24 * 60,
        days: Set<Weekday> = Set(Weekday.allCases)
    ) {
        self.id = id
        self.kind = kind
        self.maxStay = maxStay
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.days = days
    }
}

// Raw values match Calendar's weekday numbers (Sunday = 1).
enum Weekday: Int, CaseIterable, Hashable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
}
