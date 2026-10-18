import Foundation

struct Vehicle: Identifiable, Hashable {
    let id: UUID
    var name: String
    var numberPlate: String
    var isDefault: Bool

    init(id: UUID = UUID(), name: String, numberPlate: String, isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.numberPlate = numberPlate
        self.isDefault = isDefault
    }
}
