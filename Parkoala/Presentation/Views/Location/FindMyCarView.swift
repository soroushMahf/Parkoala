//
//  FindMyCarView.swift
//  Parkoala
//
//  Created by Soroush Mahfoozi on 20/10/2026.
//

import SwiftUI
import MapKit

struct FindMyCarView: View {
    
    // ParkingLocation is passed directly as a temporary parking location
    // This will be removed once UC1 is integrated to retrieve the parked
    // location through ManageParkingLocationUseCase using the active vehicle ID
    let parkedLocation: ParkingLocation
    
    let viewModel: LocationViewModel
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    
    private var parkedCoordinate: CLLocationCoordinate2D? {
        guard let coordinate = parkedLocation.coordinate else {
            return nil
        }
        
        return CLLocationCoordinate2D(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            
            if let parkedCoordinate {
                Map(position: $cameraPosition) {
                    UserAnnotation()
                    
                    Marker(
                        "My Car",
                        systemImage: "car.fill",
                        coordinate: parkedCoordinate
                    )
                    .tint(.blue)
                }
                .mapStyle(.standard(pointsOfInterest: .excludingAll))
                .mapControls { MapCompass() }
                .overlay(alignment: .bottomTrailing) {
                    Button {
                        centreOnCar()
                    } label : {
                        Image(systemName: "car.fill")
                            .font(.title3)
                            .frame(width: 48, height: 48)
                            .background(.regularMaterial, in: Circle())
                    }
                    .accessibilityLabel("Center map on my parked car")
                    .padding()
                }
                .onAppear {
                    centreOnCar()
                    viewModel.startLocationUpdates()
                }
                .onDisappear {
                    viewModel.stopLocationUpdates()
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    
                    Label("Parked Vehicle", systemImage: "car.fill")
                        .font(.headline)
                    
                    if let levelAndBay = parkedLocation.levelAndBay,
                       !levelAndBay.isEmpty {
                        Label(levelAndBay, systemImage: "parkingsign.circle")
                            .foregroundStyle(.secondary)
                    }
                    
                    Button {
                        openWalkingDirections()
                    } label: {
                        Label("Get Walking Directons", systemImage: "figure.walk")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                ContentUnavailableView(
                    "Parking Location Unavailable",
                    systemImage: "location.slash",
                    description: Text("No GPS coordinates have been saved for this vehicle")
                )
            }
        }
        .navigationTitle("Parked Location")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func centreOnCar() {
        guard let parkedCoordinate else { return }
        
        withAnimation {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: parkedCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                )
            )
        }
    }
    
    private func openWalkingDirections() {
        guard let parkedCoordinate else { return }
        
        let destination = MKMapItem(
            placemark: MKPlacemark(coordinate: parkedCoordinate)
        )
        
        destination.name = "My Parked Car"
        
        destination.openInMaps(
            launchOptions: [
                MKLaunchOptionsDirectionsModeKey:
                    MKLaunchOptionsDirectionsModeWalking
            ]
        )
    }
}

#Preview {

    // TEMPORARY PREVIEW DATA
    // need to remove this sample location when real sessions are integrated
    
    let sampleParkingLocation = ParkingLocation(
        coordinate: Coordinate(
            latitude: -33.8830,
            longitude: 151.2000
        ),
        levelAndBay: "Level B2, Bay 15"
    )

    NavigationStack {
        FindMyCarView(
            // TEMPORARY as its directly supplying a parked location.
            parkedLocation: sampleParkingLocation,
            viewModel: .preview()
        )
    }
}
