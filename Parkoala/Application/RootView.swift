import SwiftUI

// The main tabs of the app. Each module owner swaps their placeholder
// for their real screen once it is built.
struct RootView: View {
    
    //temporary repository from NearbyMapView for testing
    @State private var locationViewModel = LocationViewModel(
        locationService: LocationService(),
        locationUseCase: ManageParkingLocationUseCase(
            sessionRepository: PreviewSessionRepository()
        )
    )
    
    var body: some View {
        TabView {
            Tab("Park", systemImage: "car.fill") {
                placeholder("Parking session", owner: "Sessions")
            }
            Tab("Nearby", systemImage: "map.fill") {
//                placeholder("Nearby car parks", owner: "Location")
                NearbyMapView(viewModel: locationViewModel)
            }
            Tab("Money", systemImage: "dollarsign.circle.fill") {
                placeholder("Parking costs", owner: "Money")
            }
        }
    }

    private func placeholder(_ title: String, owner: String) -> some View {
        ContentUnavailableView(title, systemImage: "hammer", description: Text("Coming soon from the \(owner) module."))
    }
}

#Preview {
    RootView()
}
