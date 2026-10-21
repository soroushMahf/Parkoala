//
//  CarParkSearchService.swift
//  Parkoala
//
//  Created by Soroush Mahfoozi on 19/10/2026.
//

// Searches for neary parking facilities using Apple Maps

import Foundation
import MapKit

@MainActor
final class CarParkSearchService {
    
    func searchNearby(coordinate: Coordinate) async throws -> [MKMapItem] {
        
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            ),
            span: MKCoordinateSpan(
                latitudeDelta: 0.03,
                longitudeDelta: 0.03
            )
        )
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "parking"
        request.region = region
        request.resultTypes = .pointOfInterest
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        return response.mapItems
    }
}
