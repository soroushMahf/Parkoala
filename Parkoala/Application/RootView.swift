import SwiftUI

// The main tabs of the app. Each module owner swaps their placeholder
// for their real screen once it is built.
struct RootView: View {
    var body: some View {
        TabView {
            Tab("Park", systemImage: "car.fill") {
                ActiveSessionView()
            }
            Tab("Nearby", systemImage: "map.fill") {
                placeholder("Nearby car parks", owner: "Location")
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
