//
//  SaveParkingLocationView.swift
//  Parkoala
//
//  Created by Soroush Mahfoozi on 20/10/2026.
//

import SwiftUI

struct SaveParkingLocationView: View {
    
    let vehicleID: UUID
    let viewModel: LocationViewModel
    
    @State private var levelAndBay = ""
    @State private var hasSaved = false
    
    var body: some View {
        Form {
            Section("Parking Location") {
                if let coordinate = viewModel.currentLocation {
                    Label("GPS location acquired", systemImage: "location.fill")
                        .foregroundStyle(.green)
                    
                    Text("Latitude: \(coordinate.latitude), Longitude: \(coordinate.longitude)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Label("Waiting for your location...", systemImage: "location.slash")
                        .foregroundStyle(.secondary)
                    
                    Button("Get Current Location") {
                        viewModel.requestCurrentLocation()
                    }
                }
            }
            
            Section("Additional Details (Optional)") {
                TextField("Level or Bay Number (e.g. B2, Bay 15)", text: $levelAndBay)
            }
            
            Section {
                Button {
                    Task {
                        await saveLocation()
                    }
                } label : {
                    if viewModel.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label ("Save Parking Location", systemImage: "mappin.and.ellipse")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(viewModel.currentLocation == nil || viewModel.isLoading || hasSaved)
            }
        }
        .navigationTitle("Save Parking Location")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.startLocationUpdates()
        }
        .alert(
            "Location Error",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.clearError() } }
            )
        ) {
            Button("OK", role: .cancel) {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Location Saved", isPresented: $hasSaved) {
            Button("OK") {}
        } message: {
            Text("Your parking location has been saved successfully")
        }
    }
    
    private func saveLocation() async {
        guard let coordinate = viewModel.currentLocation else {
            return
        }
        
        let details = levelAndBay.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let location = ParkingLocation(
            coordinate: coordinate,
            levelAndBay: details.isEmpty ? nil : details
        )
        
        await viewModel.saveParkingLocation(vehicleID: vehicleID, location: location)
        
        if viewModel.errorMessage == nil {
            hasSaved = true
        }
    }
}

// using the same temporary preview session repository from NearbyMapView to preview
#Preview {
    NavigationStack {
        SaveParkingLocationView(
            vehicleID: UUID(),
            viewModel: LocationViewModel(
                locationService: LocationService(),
                locationUseCase: ManageParkingLocationUseCase(
                    sessionRepository: PreviewSessionRepository()
                )
            )
        )
    }
}
