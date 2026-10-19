//
//  LocationViewModel.swift
//  Parkoala
//
//  Created by Soroush Mahfoozi on 19/10/2026.
//

// Manages location-related UI state and coordinates
// Core Location with the parking location use case

import Foundation
import CoreLocation

@MainActor
@Observable
final class LocationViewModel {
    
    private let locationService: LocationService
    private let locationUseCase: ManageParkingLocationUseCase
    
    private(set) var parkedLocation: ParkingLocation?
    private(set) var errorMessage: String?
    private(set) var isLoading = false
    
    var currentLocation: Coordinate? {
        locationService.currentLocation
    }
    
    var authorizatonStatus: CLAuthorizationStatus {
        locationService.authorizationStatus
    }
    
    init(
        locationService: LocationService,
        locationUseCase: ManageParkingLocationUseCase
    ) {
        self.locationService = locationService
        self.locationUseCase = locationUseCase
    }
    
    func requestPermission() {
        locationService.requestPermission()
    }
    
    // starts continuous uodates when the map is visible
    func startLocationUpdates() {
        locationService.startUpdatingLocation()
    }
    
    // stops continuous updates when the map is no longer visible
    func stopLocationUpdates() {
        locationService.stopUpdatingLocation()
    }
    
    // requesting a single GPS reading
    func requestCurrentLocation() {
        locationService.requestLocation()
    }
    
    // saves the supplied parking location to the active session
    func saveParkingLocation(vehicleID: UUID, location: ParkingLocation) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await locationUseCase.saveLocation(vehicleID: vehicleID, location: location)
            
            parkedLocation = location
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // Retrieves the vehicle's previously saved parking location
    func loadParkedLocation(vehicleID: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            parkedLocation = try await locationUseCase.getParkedLocation(vehicleID: vehicleID)
            
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
