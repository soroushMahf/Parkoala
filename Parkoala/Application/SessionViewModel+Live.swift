// Builds the real Sessions view models with the shared SwiftData store.
// Kept here so the view model itself never imports SwiftData.

import Foundation
import SwiftData

extension ManageParkingSessionUseCase {

    static func live() -> ManageParkingSessionUseCase {
        let context = PersistenceController.shared.container.mainContext
        return ManageParkingSessionUseCase(
            sessionRepository: SwiftDataSessionRepository(context: context),
            vehicleRepository: SwiftDataVehicleRepository(context: context)
        )
    }
}

extension SessionViewModel {

    static func live() -> SessionViewModel {
        SessionViewModel(
            useCase: .live(),
            alertsUseCase: .live()
        )
    }
}

extension SessionHistoryViewModel {

    static func live() -> SessionHistoryViewModel {
        SessionHistoryViewModel(useCase: .live())
    }
}

extension ManageParkingAlertsUseCase {

    static func live() -> ManageParkingAlertsUseCase {
        ManageParkingAlertsUseCase(
            notificationService: UserNotificationService()
        )
    }
}
