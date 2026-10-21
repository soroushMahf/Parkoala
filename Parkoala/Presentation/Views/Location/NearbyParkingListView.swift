//
//  NearbyParkingListView.swift
//  Parkoala
//
//  Created by Soroush Mahfoozi on 20/10/2026.
//

import SwiftUI
import MapKit

struct NearbyParkingListView: View {
    
    let carParks: [NearbyParkingResult]
    let onSelect: (MKMapItem) -> Void
    
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
                    ForEach(carParks) { result in
                        VStack(alignment: .leading, spacing: 8) {
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(result.mapItem.name ?? "Parking")
                                        .font(.headline)
                                    
                                    Label(
                                        result.formattedDistance + " away",
                                        systemImage: "location"
                                    )
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                            }
                            
                            HStack {
                                Button("View Details") {
                                    onSelect(result.mapItem)
                                }
                                .buttonStyle(.bordered)
                                
                                Button {
                                    result.mapItem.openInMaps(
                                        launchOptions: [
                                            MKLaunchOptionsDirectionsModeKey:
                                                MKLaunchOptionsDirectionsModeDriving
                                        ]
                                    )
                                } label: {
                                    Label("Directions", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        
                        Divider()
                    }
                }
            }
        }
        .padding(30)
    }
}

//#Preview {
//    NearbyParkingListView()
//}
