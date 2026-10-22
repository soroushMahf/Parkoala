//
//MoneyViewModel.swift
//Parkoala
//
//  Created by jessica dao on 22/10/2026.

// Holds the state of the Money tab: this month's spending summary
// and any finished sessions that still need a cost entered.

import Foundation

@MainActor
@Observable
final class MoneyViewModel {

    private let sessionUseCase: ManageParkingSessionUseCase
    private let costUseCase: CalculateParkingCostsUseCase

    private(set) var monthSummary: CostSummary = .empty
    private(set) var uncostedSessions: [ParkingSession] = []
    private(set) var costedSessions: [ParkingSession] = []
    private(set) var isLoading = false
    var errorMessage: String?

    init(sessionUseCase: ManageParkingSessionUseCase, costUseCase: CalculateParkingCostsUseCase) {
        self.sessionUseCase = sessionUseCase
        self.costUseCase = costUseCase
    }

    func load() async {
        await run {
            let sessions = try await self.sessionUseCase.recentSessions()
            self.uncostedSessions = sessions.filter { $0.cost == nil }
            self.costedSessions = sessions.filter { $0.cost != nil }
            self.monthSummary = try await self.costUseCase.monthlySummary(for: .now)
        }
    }

    // Prices the stay with the rate(s) the user entered, without saving anything yet.
    func estimate(for session: ParkingSession, rates: [RateRule]) throws -> CostEstimate {
        guard let endDate = session.endDate else {
            throw ParkingCostError.invalidDuration
        }
        return try costUseCase.calculateFee(for: session, endingAt: endDate, rates: rates)
    }

    // Saves the estimate and moves the session out of "Needs a cost".
    @discardableResult
    func saveEstimate(_ estimate: CostEstimate, for session: ParkingSession) async -> Bool {
        let saved = await run {
            _ = try await self.costUseCase.recordEstimatedCost(estimate.amount, for: session)
        }
        if saved { await load() }
        return saved
    }

    // Saves what the user says they were actually charged.
    @discardableResult
    func saveActualCost(_ amount: Decimal, for session: ParkingSession) async -> Bool {
        let saved = await run {
            _ = try await self.costUseCase.recordActualCost(amount, for: session)
        }
        if saved { await load() }
        return saved
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
