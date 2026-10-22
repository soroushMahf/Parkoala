//
//  ParkingSessionEntity.swift
//  Parkoala
//
//  Created by Soroush Mahfoozi on 19/10/2026.
//

// SwiftData representation of a ParkingSession for local persistence.
// Stores session details, parking location and restrictions as persistable properties.
// Converts between the stored entity and the ParkingSession domain model.

import Foundation
import SwiftData

@Model
final class ParkingSessionEntity {
    
    @Attribute(.unique)
    var id: UUID
    
    var vehicleID: UUID
    var startDate: Date
    var expiryDate: Date
    var endDate: Date?
    
    var cost: Decimal?
    
    // parking location
    var latitude: Double?
    var longitude: Double?
    var levelAndBay: String?
    
    //parking restriction
    var restrictionID: UUID?
    var restrictionKind: String?
    var restrictionMaxStay: TimeInterval?
    var restrictionStartMinute: Int?
    var restrictionEndMinute: Int?
    var restrictionDays: [Int]?
    
    init(session: ParkingSession) {
        self.id = session.id
        self.vehicleID = session.vehicleID
        self.startDate = session.startDate
        self.expiryDate = session.expiryDate
        self.endDate = session.endDate
        
        self.cost = session.cost
        
        // parking location
        self.latitude = session.location?.coordinate?.latitude
        self.longitude = session.location?.coordinate?.longitude
        self.levelAndBay = session.location?.levelAndBay
        
        // parking restriction
        self.restrictionID = session.restriction?.id
        self.restrictionKind = session.restriction.map {
            String(describing: $0.kind)
        }
        self.restrictionMaxStay = session.restriction?.maxStay
        self.restrictionStartMinute = session.restriction?.startMinute
        self.restrictionEndMinute = session.restriction?.endMinute
        self.restrictionDays = session.restriction?.days.map { $0.rawValue }
    }
    
    func toDomain() -> ParkingSession {
        
        let coordinate: Coordinate?

        if let latitude, let longitude {
            coordinate = Coordinate(latitude: latitude, longitude: longitude)
        } else {
            coordinate = nil
        }

        let location: ParkingLocation?

        if coordinate != nil || levelAndBay != nil {
            
            location = ParkingLocation(
                coordinate: coordinate,
                levelAndBay: levelAndBay
            )
            
        } else {
            location = nil
        }
        
        let restriction: ParkingRestriction?

        if let restrictionKind,
           let restrictionID,
           let restrictionStartMinute,
           let restrictionEndMinute,
           let restrictionDays {

            let kind: ParkingRestriction.Kind?

            switch restrictionKind {
            case "timeLimited":
                kind = .timeLimited
            case "noStopping":
                kind = .noStopping
            case "clearway":
                kind = .clearway
            case "unrestricted":
                kind = .unrestricted
            default:
                kind = nil
            }

            if let kind {
                restriction = ParkingRestriction(
                    id: restrictionID,
                    kind: kind,
                    maxStay: restrictionMaxStay,
                    startMinute: restrictionStartMinute,
                    endMinute: restrictionEndMinute,
                    days: Set(restrictionDays.compactMap {
                        Weekday(rawValue: $0)
                    })
                )
            } else {
                restriction = nil
            }

        } else {
            restriction = nil
        }

        return ParkingSession(
            id: id,
            vehicleID: vehicleID,
            startDate: startDate,
            expiryDate: expiryDate,
            endDate: endDate,
            restriction: restriction,
            location: location,
            cost: cost
        )
    }
    
}
