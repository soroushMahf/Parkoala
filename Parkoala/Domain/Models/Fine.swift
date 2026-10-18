import Foundation

struct Fine: Identifiable, Hashable {
    let id: UUID
    var sessionID: UUID?
    var amount: Decimal
    var issueDate: Date
    var dueDate: Date
    var isPaid: Bool
    var photoFileName: String?

    init(
        id: UUID = UUID(),
        sessionID: UUID? = nil,
        amount: Decimal,
        issueDate: Date,
        dueDate: Date,
        isPaid: Bool = false,
        photoFileName: String? = nil
    ) {
        self.id = id
        self.sessionID = sessionID
        self.amount = amount
        self.issueDate = issueDate
        self.dueDate = dueDate
        self.isPaid = isPaid
        self.photoFileName = photoFileName
    }
}
