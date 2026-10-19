//
//  NearbyMapView.swift
//  Parkoala
//
//  Created by Soroush Mahfoozi on 19/10/2026.
//

import SwiftUI
import MapKit

struct NearbyMapView: View {
    
    let viewModel: LocationViewModel
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var hasCenteredOnUser = false
    
    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition) {
                UserAnnotation()
            }
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .mapStyle(.standard(elevation: .realistic))
            .overlay(alignment: .bottomTrailing) {
                Button {
                    centreOnUser()
                } label : {
                    Image(systemName: "location.fill")
                        .font(.title3)
                        .frame(width: 48, height: 48)
                        .background(.regularMaterial, in: Circle())
                }
                .accessibilityLabel("Center map on my location")
                .padding()
            }
            .navigationTitle("Nearby Parking")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear() {
                viewModel.startLocationUpdates()
            }
            .onDisappear() {
                viewModel.stopLocationUpdates()
            }
            .onChange(of: viewModel.currentLocation) {_, newLocation in
                guard !hasCenteredOnUser, let newLocation else { return }
                
                centreMap(on: newLocation)
                hasCenteredOnUser = true
            }
        }
    }
    
    private func centreOnUser() {
        guard let location = viewModel.currentLocation else {
            viewModel.requestCurrentLocation()
            return
        }
        
        centreMap(on: location)
    }
    
    private func centreMap(on coordinate: Coordinate) {
        withAnimation {
            cameraPosition = .region(
                MKCoordinateRegion(
                    center: CLLocationCoordinate2D(
                        latitude: coordinate.latitude, longitude: coordinate.longitude
                    ),
                    span: MKCoordinateSpan(
                        latitudeDelta: 0.01, longitudeDelta: 0.01
                    )
                )
            )
        }
    }
}

#Preview {
    NearbyMapView(
        viewModel: LocationViewModel(
            locationService: LocationService(),
            locationUseCase: ManageParkingLocationUseCase(
                sessionRepository: PreviewSessionRepository()
            )
        )
    )
}

// temp repository for preview
private struct PreviewSessionRepository: SessionRepository {

    func activeSession(for vehicleID: UUID) async throws -> ParkingSession? {
        nil
    }

    func sessions(inMonthOf date: Date) async throws -> [ParkingSession] {
        []
    }

    func save(_ session: ParkingSession) async throws {}

    func delete(id: UUID) async throws {}
}
