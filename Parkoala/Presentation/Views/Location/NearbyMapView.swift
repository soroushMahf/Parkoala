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
    
    @State private var selectedCarParkID: String?
    
    @State private var isParkingSheetPresented = false
    @State private var selectedCarParkIndex: Int?
    
    @State private var isCenteredOnUser = false
    
    @State private var isShowingNoResults = false
    @State private var trackingClientID = UUID()
    
    var body: some View {
        NavigationStack {
            Map(position: $cameraPosition, selection: $selectedCarParkID) {
                UserAnnotation() // user's current location
                
                // Nearby parking facilities
                ForEach(0..<viewModel.nearbyCarParks.count, id: \.self) { index in
                    let carPark = viewModel.nearbyCarParks[index]
                    
                    Marker(
                        carPark.name ?? "Parking",
                        systemImage: "parkingsign.square.fill",
                        coordinate: carPark.placemark.coordinate
                    )
                    .tint(.blue)
                    .tag(String(index))
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
                VStack(alignment: .trailing, spacing: 12) {
                    Button {
                        centreOnUser()
                    } label : {
                        Image(systemName: isCenteredOnUser ? "location.fill" : "location")
                            .font(.title3)
                            .frame(width: 48, height: 48)
                            .background(.regularMaterial, in: Circle())
                    }
                    .accessibilityLabel("Center map on my location")
                    
                    if !viewModel.nearbyCarParks.isEmpty {
                        Button {
                            showNearbyParkingList()
                        } label : {
                            Image(systemName: "parkingsign.circle.fill")
                                .font(.title3)
                                .frame(width: 48, height: 48)
                                .background(.regularMaterial, in: Circle())
                        }
                    }
                }
                .padding()
                
            }
            .onMapCameraChange(frequency: .onEnd) { context in
                visibleRegion = context.region
                
                // checks if location is on centered on user.
                // If it's not, it'll trigger isCenteredOnUser to be false
                if let userLocation = viewModel.currentLocation {
                    let mapCenter = CLLocation(
                        latitude: context.region.center.latitude,
                        longitude: context.region.center.longitude
                    )
                    
                    let userCoordinate = CLLocation(
                        latitude: userLocation.latitude,
                        longitude: userLocation.longitude
                    )
                    
                    isCenteredOnUser = mapCenter.distance(from:userCoordinate) < 10
                }
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
                viewModel.startLocationUpdates(for: trackingClientID)
            }
            .onDisappear() {
                viewModel.stopLocationUpdates(for: trackingClientID)
            }
            .onChange(of: selectedCarParkID) { _, newValue in
                guard let newValue,
                      let index = Int(newValue),
                      viewModel.nearbyCarParks.indices.contains(index)
                else { return }
                
                selectedCarParkIndex = index
                isParkingSheetPresented = true
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
            .alert("No Parking Found", isPresented: $isShowingNoResults) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("No parking facilities were found in this area. Try searching another location")
            }
            .sheet(isPresented: $isParkingSheetPresented, onDismiss: {
                selectedCarParkID = nil
                selectedCarParkIndex = nil
            }) {
                Group {
                    if let index = selectedCarParkIndex,
                       viewModel.nearbyCarParks.indices.contains(index) {
                            
                        CarParkDetailView(
                            carPark: viewModel.nearbyCarParks[index]
                        )
                    
                    } else {
                        NearbyParkingListView(
                            carParks: Array(viewModel.sortedNearbyCarParks.prefix(6))
                        ) { carPark in
                            if let index = viewModel.nearbyCarParks.firstIndex(of: carPark) {
                                selectedCarParkIndex = index
                                selectedCarParkID = String(index)
                            }
                        }
                    }
                }
                .presentationDetents([.height(340), .medium, .large])
                .presentationDragIndicator(.visible)
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
        
        isCenteredOnUser = true
    }
    
    private func searchVisibleArea() {
        guard let region = visibleRegion else { return }

        let coordinate = Coordinate(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        )

        Task {
            await viewModel.searchNearbyParking(at: coordinate)

            guard viewModel.errorMessage == nil else { return }

            selectedCarParkID = nil
            selectedCarParkIndex = nil

            if !viewModel.nearbyCarParks.isEmpty {
                isParkingSheetPresented = true
            } else {
                isShowingNoResults = true
            }
        }
    }
    
    private func showNearbyParkingList() {
        selectedCarParkID = nil
        selectedCarParkIndex = nil
        isParkingSheetPresented = true
    }
}


#Preview {
    NearbyMapView(
        viewModel: .preview()
    )
}
