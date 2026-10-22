//
//  NearbyParkingListView.swift
//  Parkoala
//
//  Created by Soroush Mahfoozi on 20/10/2026.
//

import SwiftUI
import MapKit

struct NearbyParkingListView: View {
    
    let carParks: [NearbyCarPark]
    let onSelect: (CarPark) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Text("Closest Parking")
                .font(.title2)
                .bold()
            
            Text("Approximate distance from your location")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(carParks) { nearbyCarPark in
                        let carPark = nearbyCarPark.carPark
                        
                        VStack(alignment: .leading, spacing: 8) {
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(carPark.name)
                                        .font(.headline)
                                    
                                    Label(
                                        nearbyCarPark.formattedDistance + " away",
                                        systemImage: "location"
                                    )
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    
                                    availabilityLabel(for: carPark)
                                }
                                
                                Spacer()
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel(accessibilityLabel(for: carPark, distance: nearbyCarPark.formattedDistance))
                            
                            HStack {
                                Button("View Details") {
                                    onSelect(carPark)
                                }
                                .buttonStyle(.bordered)
                                
                                Button {
                                    openDirections(to: carPark)
                                } label: {
                                    Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .frame(minHeight: 44)
                        
                        Divider()
                    }
                }
            }
            
            Text("Availability is estimated and not guaranteed.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(30)
    }
    
    @ViewBuilder
    private func availabilityLabel(for carPark: CarPark) -> some View {
        if carPark.availableSpaces != nil, carPark.totalSpaces != nil {
            VStack(alignment: .leading, spacing: 2) {
                Text(carPark.availabilityText)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if let updatedAtText = carPark.updatedAtText {
                    Text(updatedAtText)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        } else {
            Text(carPark.availabilityText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private func accessibilityLabel(for carPark: CarPark, distance: String) -> String {
        "\(carPark.name), \(distance) away, \(carPark.accessibilityAvailabilityText)"
    }
    
    private func openDirections(to carPark: CarPark) {
        let coordinate = CLLocationCoordinate2D(
            latitude: carPark.coordinate.latitude,
            longitude: carPark.coordinate.longitude
        )
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = carPark.name
        
        mapItem.openInMaps(
            launchOptions: [
                MKLaunchOptionsDirectionsModeKey:
                    MKLaunchOptionsDirectionsModeDriving
            ]
        )
    }
}

//#Preview {
//    NearbyParkingListView()
//}
