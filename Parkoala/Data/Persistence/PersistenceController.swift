//
//  PersistenceController.swift
//  Parkoala
//
//  Created by Soroush Mahfoozi on 19/10/2026.
//

// Configures the shared SwiftData container used to persist
// vehicles and parking sessions locally on the device

import Foundation
import SwiftData

@MainActor
final class PersistenceController {
    
    static let shared = PersistenceController()
    
    let container: ModelContainer
    
    private init() {
        do {
            let schema = Schema([
                VehicleEntity.self,
                ParkingSessionEntity.self
            ])
            
            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            
            container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )
        } catch {
            fatalError("Failed to initialise SwiftData: \(error)")
        }
    }
    
}
