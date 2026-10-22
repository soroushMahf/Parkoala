//
//  CarParkDetailView.swift
//  Parkoala
//
//  Created by Soroush Mahfoozi on 20/10/2026.
//

import SwiftUI
import MapKit

struct CarParkDetailView: View {
    
    let carPark: MKMapItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            Text(carPark.name ?? "Parking Facility")
                .font(.title2)
                .bold()
            
            Label(
                carPark.placemark.title ?? "Address unavailable",
                systemImage: "mappin.and.ellipse"
            )
            
            Button {
                carPark.openInMaps(
                    launchOptions: [
                        MKLaunchOptionsDirectionsModeKey:
                            MKLaunchOptionsDirectionsModeDriving
                    ]
                )
            } label: {
                Label("Get Directions", systemImage: "arrow.trianglehead.turn.up.right.diamond.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            
            Spacer(minLength: 0)
        }
        .padding(30)
        .presentationDetents([.height(240), .medium])
        .presentationDragIndicator(.visible)
    }
}
