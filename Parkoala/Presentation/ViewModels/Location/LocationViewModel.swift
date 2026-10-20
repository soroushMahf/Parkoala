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
import MapKit

@MainActor
@Observable
final class LocationViewModel {
    
    private let locationService: LocationService
    private let locationUseCase: ManageParkingLocationUseCase
    private let carParkSearchService: CarParkSearchService
    
    private(set) var parkedLocation: ParkingLocation?
    private(set) var errorMessage: String?
    private(set) var isLoading = false
    
    private(set) var nearbyCarParks: [MKMapItem] = []
    private(set) var isSearching = false
    
    var currentLocation: Coordinate? {
        locationService.currentLocation
    }
    
    var authorizatonStatus: CLAuthorizationStatus {
        locationService.authorizationStatus
    }
    
    var sortedNearbyCarParks: [NearbyParkingResult] {
        guard let currentLocation else { return [] }
        
        let userLocation = CLLocation(
            latitude: currentLocation.latitude,
            longitude: currentLocation.longitude
        )
        
        return nearbyCarParks.map { carPark in
            let coordinate = carPark.placemark.coordinate
            
            let parkingLocation = CLLocation(
                latitude: carPark.placemark.coordinate.latitude,
                longitude: carPark.placemark.coordinate.longitude
            )
            
            let distance = userLocation.distance(from: parkingLocation)
            
            return NearbyParkingResult(
                id: "\(coordinate.latitude),\(coordinate.longitude),\(carPark.name ?? "")",
                mapItem: carPark,
                distanceMeters: distance
            )
        }
        .sorted { $0.distanceMeters < $1.distanceMeters }
    }
    
    init(
        locationService: LocationService,
        locationUseCase: ManageParkingLocationUseCase,
        carParkSearchService: CarParkSearchService? = nil
    ) {
        self.locationService = locationService
        self.locationUseCase = locationUseCase
        self.carParkSearchService = carParkSearchService ?? CarParkSearchService()
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
    
    // Searches for parking facilities around the specific location
    func searchNearbyParking(at coordinate: Coordinate) async {
        guard !isSearching else { return }
        
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }
        
        do {
            nearbyCarParks = try await carParkSearchService.searchNearby(coordinate: coordinate)
        } catch {
            errorMessage = "Unable to find nearby parking. Please try again."
        }
    }
    
    func clearError() {
        errorMessage = nil
    }
}

struct NearbyParkingResult: Identifiable {
    let id: String
    let mapItem: MKMapItem
    let distanceMeters: Double
    
    var formattedDistance: String {
        if distanceMeters < 1000 {
            return "\(Int(distanceMeters.rounded())) m"
        }
        
        return String(format: "%.1f km", distanceMeters / 1000)
    }
}
