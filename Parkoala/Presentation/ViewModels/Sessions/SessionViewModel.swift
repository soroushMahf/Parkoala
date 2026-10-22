// Holds the state of the Park tab and passes start and end
// requests to ManageParkingSessionUseCase.

import Foundation

@MainActor
@Observable
final class SessionViewModel {

    private let useCase: ManageParkingSessionUseCase
    private let alertsUseCase: ManageParkingAlertsUseCase
    private let liveActivityService: LiveActivityService
    private let costUseCase: CalculateParkingCostsUseCase

    private(set) var activeSession: ParkingSession?
    // The session just ended, shown on the "Parking Session Ended" summary.
    private(set) var lastEndedSession: ParkingSession?
    private(set) var isLoading = false
    var errorMessage: String?

    init(
        useCase: ManageParkingSessionUseCase,
        alertsUseCase: ManageParkingAlertsUseCase,
        liveActivityService: LiveActivityService,
        costUseCase: CalculateParkingCostsUseCase
    ) {
        self.useCase = useCase
        self.alertsUseCase = alertsUseCase
        self.liveActivityService = liveActivityService
        self.costUseCase = costUseCase
    }

    func load() async {
        await run {
            self.activeSession = try await self.useCase.activeSession()
        }
    }

    // Returns true when the session started, so the sheet can close
    @discardableResult
    func startSession(duration: TimeInterval, plannedRate: RateRule? = nil) async -> Bool {
        await run {
            let session = try await self.useCase.startSession(
                duration: duration,
                plannedRate: plannedRate
            )

            self.activeSession = session

            do {
                try await self.alertsUseCase.scheduleExpiryReminders(
                    expiryDate: session.expiryDate
                )
            } catch {
                print("Failed to schedule parking alerts: \(error)")
            }

            do {
                try await self.liveActivityService.startActivity(
                    sessionID: session.id,
                    expiryDate: session.expiryDate
                )
            } catch {
                print("Failed to start Live Activity: \(error)")
            }
        }
    }

    func endSession() async {
        await run {
            var session = try await self.useCase.endSession()

            self.alertsUseCase.cancelExpiryReminders()

            await self.liveActivityService.endActivity()

            // The user already told us the rate when they started, so price the
            // stay straight away instead of sending them to the Money tab for it.
            if let plannedRate = session.plannedRate, let endDate = session.endDate {
                do {
                    let estimate = try self.costUseCase.calculateFee(
                        for: session,
                        endingAt: endDate,
                        rates: [plannedRate]
                    )
                    session = try await self.costUseCase.recordEstimatedCost(estimate.amount, for: session)
                } catch {
                    print("Failed to auto-calculate parking cost: \(error)")
                }
            }

            self.activeSession = nil
            self.lastEndedSession = session
        }
    }

    // Clears the "Ended" summary once the user dismisses it.
    func dismissEndedSessionSummary() {
        lastEndedSession = nil
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
