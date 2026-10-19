//
//  LocationService.swift
//  Parkoala
//
//  Created by Soroush Mahfoozi on 19/10/2026.
//

// Manages location permissions and retrieves the user's current coordinates

import Foundation
import CoreLocation

@MainActor
@Observable
final class LocationService: NSObject, CLLocationManagerDelegate {
    
    private let manager = CLLocationManager()
    
    private(set) var authorizationStatus: CLAuthorizationStatus
    private(set) var currentLocation: Coordinate?
    private(set) var errorMessage: String?
    
    private var isTracking = false
    
    override init() {
        authorizationStatus = manager.authorizationStatus
        super.init()
        
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    // Requests location permission when needed
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    // Requests the user's location once
    func requestLocation() {
        guard isAuthorized else {
            handleUnauthorized()
            return
        }
        
        errorMessage = nil
        manager.requestLocation()
    }
    
    // Starts continuous location updates while using viewing the map
    func startUpdatingLocation() {
        guard isAuthorized else {
            handleUnauthorized()
            return
        }
        
        guard !isTracking else { return }
        
        errorMessage = nil
        isTracking = true
        
        manager.startUpdatingLocation()
    }
    
    // Stops continuous location updates when they're no longer needed
    func stopUpdatingLocation() {
        guard isTracking else { return }
        
        manager.stopUpdatingLocation()
        isTracking = false
    }
    
    // Checks whether location permission has been granted
    private var isAuthorized: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }
    
    // Handles location permission being unavailable
    private func handleUnauthorized() {
        switch authorizationStatus {
        case .notDetermined:
            requestPermission()
        
        case .denied, .restricted:
            errorMessage = ParkingLocationError.permissionDenied.localizedDescription
            
        default:
            errorMessage = ParkingLocationError.locationUnavailable.localizedDescription
        }
    }
    
    // Receives both one-time and continious location updates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = Coordinate(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude
        )
        
        errorMessage = nil
    }
    
    // Handles location retrieval failures
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
    
    // Responds to changes in location permissions
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        if isAuthorized {
            errorMessage = nil
        } else {
            stopUpdatingLocation()
            currentLocation = nil
            
            if authorizationStatus == .denied || authorizationStatus == .restricted {
                errorMessage = ParkingLocationError.permissionDenied.localizedDescription
            }
        }
    }
}

