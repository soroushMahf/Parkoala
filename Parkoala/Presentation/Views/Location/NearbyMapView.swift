//
//  NearbyMapView.swift
//  Parkoala
//
//  Created by Soroush Mahfoozi on 19/10/2026.
//

// Displays an interactive map with nearby parking facilities

import SwiftUI
import MapKit

struct NearbyMapView: View {
    
    let viewModel: LocationViewModel
    
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var hasCenteredOnUser = false
    @State private var visibleRegion: MKCoordinateRegion?
    
    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition) {
                UserAnnotation() // user's current location
                
                // Nearby parking facilities
                ForEach(viewModel.nearbyCarParks, id: \.self) { carPark in
                    Marker(
                        carPark.name ?? "Parking",
                        systemImage: "parkingsign.square.fill",
                        coordinate: carPark.placemark.coordinate
                    )
                    .tint(.blue)
                }
            }
            .mapControls {
                MapCompass()
                MapScaleView()
            }
            .mapStyle(.standard(
                elevation: .realistic,
                pointsOfInterest: .excludingAll
            ))
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
            .onMapCameraChange(frequency: .onEnd) { context in
                visibleRegion = context.region
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    searchVisibleArea()
                } label: {
                    if viewModel.isSearching {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Label(
                            "Search This Area",
                            systemImage: "magnifyingglass"
                        )
                        .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isSearching)
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
                
                Task {
                    await viewModel.searchNearbyParking(at: newLocation)
                }
            }
            .alert(
                "Parking Search Error",
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
        }
    }
    
    private let previewCoordinate = Coordinate(
        latitude: -33.8830,
        longitude: 151.2000
    )

    private func centreOnUser() {
        guard let location = viewModel.currentLocation else {
            centreMap(on: previewCoordinate)
            return
        }

        centreMap(on: location)
    }
    
//    private func centreOnUser() {
//        guard let location = viewModel.currentLocation else {
//            viewModel.requestCurrentLocation()
//            return
//        }
//        
//        centreMap(on: location)
//    }
    
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
    
    private func searchVisibleArea() {
        guard let region = visibleRegion else { return }
        
        let coordinate = Coordinate(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        )
        
        Task {
            await viewModel.searchNearbyParking(at: coordinate)
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
