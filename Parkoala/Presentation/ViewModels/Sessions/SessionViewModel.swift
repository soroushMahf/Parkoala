// Holds the state of the Park tab and passes start and end
// requests to ManageParkingSessionUseCase.

import Foundation

@MainActor
@Observable
final class SessionViewModel {

    private let useCase: ManageParkingSessionUseCase
    private let alertsUseCase: ManageParkingAlertsUseCase

    private(set) var activeSession: ParkingSession?
    private(set) var isLoading = false
    var errorMessage: String?

    init(
        useCase: ManageParkingSessionUseCase,
        alertsUseCase: ManageParkingAlertsUseCase
    ) {
        self.useCase = useCase
        self.alertsUseCase = alertsUseCase
    }

    func load() async {
        await run {
            self.activeSession = try await self.useCase.activeSession()
        }
    }

    // Returns true when the session started, so the sheet can close
    @discardableResult
    func startSession(duration: TimeInterval) async -> Bool {
        await run {
            let session = try await self.useCase.startSession(
                duration: duration
            )

            self.activeSession = session

            do {
                try await self.alertsUseCase.scheduleExpiryReminders(
                    expiryDate: session.expiryDate
                )
            } catch {
                // Parking session still starts even if alerts cannot be scheduled.
                print("Failed to schedule parking alerts: \(error)")
            }
        }
    }

    func endSession() async {
        await run {
            _ = try await self.useCase.endSession()

            self.alertsUseCase.cancelExpiryReminders()

            self.activeSession = nil
        }
    }

    // Shows any error as a message the user can read
    @discardableResult
    private func run(_ work: () async throws -> Void) async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            try await work()
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
