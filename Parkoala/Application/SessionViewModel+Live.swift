// Builds the real Park tab view model with the shared SwiftData store.
// Kept here so the view model itself never imports SwiftData.

import Foundation
import SwiftData

extension SessionViewModel {

    static func live() -> SessionViewModel {
        let context = PersistenceController.shared.container.mainContext
        let useCase = ManageParkingSessionUseCase(
            sessionRepository: SwiftDataSessionRepository(context: context),
            vehicleRepository: SwiftDataVehicleRepository(context: context)
        )
        return SessionViewModel(useCase: useCase)
    }
}
