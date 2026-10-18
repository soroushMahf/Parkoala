import Foundation

// A monthly parking budget. month is any date inside that month.
struct Budget: Identifiable, Hashable {
    let id: UUID
    var month: Date
    var limit: Decimal

    init(id: UUID = UUID(), month: Date, limit: Decimal) {
        self.id = id
        self.month = month
        self.limit = limit
    }
}
