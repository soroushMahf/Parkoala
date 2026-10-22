//
//  VehicleEntity.swift
//  Parkoala
//
//  Created by Soroush Mahfoozi on 19/10/2026.
//

// SwiftData representation of a Vehicle for local persistence.
// Converts between the stored entity and the Vehicle domain model.

import Foundation
import SwiftData

@Model
final class VehicleEntity {
    
    @Attribute(.unique)
    var id: UUID
    
    var name: String
    var numberPlate: String
    var isDefault: Bool
    
    init(vehicle: Vehicle) {
        self.id = vehicle.id
        self.name = vehicle.name
        self.numberPlate = vehicle.numberPlate
        self.isDefault = vehicle.isDefault
    }
    
    func toDomain() -> Vehicle {
        Vehicle(
            id: id,
            name: name,
            numberPlate: numberPlate,
            isDefault: isDefault
        )
    }
}
