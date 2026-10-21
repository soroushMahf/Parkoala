//
//  LocationViewModel+Preview.swift
//  Parkoala
//
//  Created by Soroush Mahfoozi on 21/10/2026.
//

// provides the ability to preview location screens using an in-memory SwiftData database

import Foundation
import SwiftData

extension LocationViewModel {

    static func preview() -> LocationViewModel {
        do {
            let schema = Schema([
                VehicleEntity.self,
                ParkingSessionEntity.self
            ])

            let configuration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )

            let container = try ModelContainer(
                for: schema,
                configurations: [configuration]
            )

            let repository = SwiftDataSessionRepository(
                context: container.mainContext
            )

            return LocationViewModel(
                locationService: LocationService(),
                locationUseCase: ManageParkingLocationUseCase(
                    sessionRepository: repository
                )
            )
        } catch {
            fatalError("Failed to create preview database: \(error)")
        }
    }
}
