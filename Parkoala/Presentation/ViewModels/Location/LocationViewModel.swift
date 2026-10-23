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
    private let carParkRepository: CarParkRepository
    private let mergeNearbyCarParksUseCase = MergeNearbyCarParksUseCase()
    
    private(set) var parkedLocation: ParkingLocation?
    private(set) var errorMessage: String?
    private(set) var isLoading = false
    
    private(set) var nearbyCarParks: [MKMapItem] = []
    private(set) var liveCarParks: [CarPark] = []
    private(set) var isSearching = false
    
    var locationErrorMessage: String? {
        locationService.errorMessage
    }
    
    var currentLocation: Coordinate? {
        locationService.currentLocation
    }
    
    var hasFreshLocation: Bool {
        guard let timeStamp = locationService.locationTimeStamp, currentLocation != nil else {
            return false
        }
        
        let age = Date.now.timeIntervalSince(timeStamp)
        
        return age >= 0 && age <= 30
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
    
    // MapKit results plus live TfNSW availability, deduped by proximity and
    // sorted by distance. This is what the Nearby list shows.
    var nearbyCarParksWithAvailability: [NearbyCarPark] {
        guard let currentLocation else { return [] }
        
        let mapKitCarParks = nearbyCarParks.map { mapItem -> CarPark in
            let coordinate = mapItem.placemark.coordinate
            return CarPark(
                id: "\(coordinate.latitude),\(coordinate.longitude),\(mapItem.name ?? "")",
                name: mapItem.name ?? "Parking",
                coordinate: Coordinate(latitude: coordinate.latitude, longitude: coordinate.longitude),
                source: .mapSearch,
                totalSpaces: nil,
                availableSpaces: nil,
                lastUpdated: nil
            )
        }
        
        let merged = mergeNearbyCarParksUseCase.merge(
            mapKitResults: mapKitCarParks,
            liveResults: liveCarParks,
            userCoordinate: currentLocation
        )
        
        let userLocation = CLLocation(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        
        return merged.map { carPark in
            let facilityLocation = CLLocation(latitude: carPark.coordinate.latitude, longitude: carPark.coordinate.longitude)
            let distance = userLocation.distance(from: facilityLocation)
            return NearbyCarPark(carPark: carPark, distanceMeters: distance)
        }
    }
    
    init(
        locationService: LocationService,
        locationUseCase: ManageParkingLocationUseCase,
        carParkSearchService: CarParkSearchService? = nil,
        carParkRepository: CarParkRepository? = nil
    ) {
        self.locationService = locationService
        self.locationUseCase = locationUseCase
        self.carParkSearchService = carParkSearchService ?? CarParkSearchService()
        self.carParkRepository = carParkRepository ?? TfNSWCarParkRepository()
    }
    
    func requestPermission() {
        locationService.requestPermission()
    }
    
    // starts continuous uodates when the map is visible
    func startLocationUpdates(for clientID: UUID) {
        locationService.startUpdatingLocation(for: clientID)
    }
    
    // stops continuous updates when the map is no longer visible
    func stopLocationUpdates(for clientID: UUID) {
        locationService.stopUpdatingLocation(for: clientID)
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
    
    // Searches for parking facilities around the specific location, both on
    // MapKit and the live TfNSW availability feed. A failure to load live
    // availability never blocks or errors the MapKit-backed list.
    func searchNearbyParking(at coordinate: Coordinate) async {
        guard !isSearching else { return }
        
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }
        
        async let mapKitSearch = carParkSearchService.searchNearby(coordinate: coordinate)
        async let liveSearch = fetchLiveCarParks(at: coordinate)
        
        do {
            nearbyCarParks = try await mapKitSearch
        } catch {
            errorMessage = "Unable to find nearby parking. Please try again."
        }
        
        liveCarParks = await liveSearch
    }
    
    private func fetchLiveCarParks(at coordinate: Coordinate) async -> [CarPark] {
        (try? await carParkRepository.nearbyCarParks(around: coordinate, radiusInKilometres: 5)) ?? []
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

struct NearbyCarPark: Identifiable {
    let carPark: CarPark
    let distanceMeters: Double
    
    var id: String { carPark.id }
    
    var formattedDistance: String {
        if distanceMeters < 1000 {
            return "\(Int(distanceMeters.rounded())) m"
        }
        
        return String(format: "%.1f km", distanceMeters / 1000)
    }
}
