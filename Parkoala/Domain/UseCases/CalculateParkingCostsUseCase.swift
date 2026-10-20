//
//  CalculateParkingCostsUseCase.swift
//  Parkoala
//
//  Created by Soroush Mahfoozi on 19/10/2026.
//

import Foundation

// Result of a fee calculation, shown as "Estimated cost" on the Session Ended sheet.
struct CostEstimate: Equatable {
    let amount: Decimal
    let durationMinutes: Int
    let appliedRate: RateRule
    // True when the stay ran past the free parking period and no paid rate was entered.
    let exceededFreePeriod: Bool
}

// Totals for the History screen: "Monthly Spending", "Sessions".
struct CostSummary: Equatable {
    let totalSpent: Decimal
    let sessionCount: Int

    var averageCost: Decimal {
        sessionCount == 0 ? 0 : CalculateParkingCostsUseCase.roundedToCents(totalSpent / Decimal(sessionCount))
    }

    static let empty = CostSummary(totalSpent: 0, sessionCount: 0)
}

struct CalculateParkingCostsUseCase {

    private let sessionRepository: SessionRepository
    var maximumDuration: TimeInterval = 24 * 60 * 60
    // for early-bird rates
    var calendar: Calendar = .current

    init(sessionRepository: SessionRepository) {
        self.sessionRepository = sessionRepository
    }


    // Estimates fee for start and end of session
    // free period is applied first then the cheapest paid rate that applies is used.
    func calculateFee(from start: Date, to end: Date, rates: [RateRule]) throws -> CostEstimate {
        guard !rates.isEmpty else { throw ParkingCostError.noRateSet }
        try validate(rates)
        let minutes = try validatedMinutes(from: start, to: end)

        let freeMinutes = rates.compactMap { rule -> Int? in
            if case let .freePeriod(minutes) = rule { return minutes }
            return nil
        }.first

        if let freeMinutes, minutes <= freeMinutes {
            return CostEstimate(amount: 0, durationMinutes: minutes,
                                appliedRate: .freePeriod(minutes: freeMinutes), exceededFreePeriod: false)
        }

        let chargeableMinutes = minutes - (freeMinutes ?? 0)
        let options: [(rule: RateRule, price: Decimal)] = rates.compactMap { rule in
            switch rule {
            case let .hourly(price):
                let startedHours = (chargeableMinutes + 59) / 60
                return (rule, Decimal(startedHours) * price)
            case let .flat(price):
                return (rule, price)
            case let .earlyBird(price, enterBefore, leaveAfter):
                return qualifiesForEarlyBird(start: start, end: end,
                                             enterBeforeMinute: enterBefore,
                                             leaveAfterMinute: leaveAfter) ? (rule, price) : nil
            case .freePeriod:
                return nil
            }
        }

        guard let cheapest = options.min(by: { $0.price < $1.price }) else {
            // if free parking period is entered and runs out
            if let freeMinutes {
                return CostEstimate(amount: 0, durationMinutes: minutes,
                                    appliedRate: .freePeriod(minutes: freeMinutes), exceededFreePeriod: true)
            }
            throw ParkingCostError.noApplicableRate
        }

        return CostEstimate(amount: Self.roundedToCents(cheapest.price),
                            durationMinutes: minutes,
                            appliedRate: cheapest.rule,
                            exceededFreePeriod: false)
    }

    func calculateFee(from start: Date, to end: Date, rate: RateRule?) throws -> CostEstimate {
        try calculateFee(from: start, to: end, rates: rate.map { [$0] } ?? [])
    }

    // For session ending, prices the stay from the session's start date to end.
    func calculateFee(for session: ParkingSession, endingAt end: Date, rates: [RateRule]) throws -> CostEstimate {
        try calculateFee(from: session.startDate, to: end, rates: rates)
    }


    // History screen: "Monthly Spending" and "Sessions".
    func monthlySummary(for date: Date) async throws -> CostSummary {
        let sessions = try await sessionRepository.sessions(inMonthOf: date)
        return summariseCosts(for: sessions)
    }

    // Totals completed sessions, optionally only those that ended inside period.
    // Active sessions are skipped because they have no cost yet.
    func summariseCosts(for sessions: [ParkingSession], in period: DateInterval? = nil) -> CostSummary {
        let completed = sessions.filter { session in
            guard let end = session.endDate else { return false }
            guard let period else { return true }
            return end >= period.start && end < period.end
        }
        let total = completed.reduce(Decimal.zero) { $0 + ($1.cost ?? 0) }
        return CostSummary(totalSpent: Self.roundedToCents(total), sessionCount: completed.count)
    }

    // Validates the amount typed into "Add Actual Cost" before it is saved as the session's cost.
    func validateActualCost(_ amount: Decimal) throws -> Decimal {
        guard amount >= 0, amount < 10_000 else { throw ParkingCostError.invalidActualCost }
        return Self.roundedToCents(amount)
    }


    // Checks the duration is positive and not long past max duration.
    func validatedMinutes(from start: Date, to end: Date) throws -> Int {
        let seconds = end.timeIntervalSince(start)
        guard seconds > 0, seconds <= maximumDuration else { throw ParkingCostError.invalidDuration }
        return Int((seconds / 60).rounded(.up))
    }

    // Checks every rule has sensible values and there is at most one free period.
    func validate(_ rates: [RateRule]) throws {
        var freePeriodCount = 0
        for rule in rates {
            switch rule {
            case let .hourly(price):
                guard price > 0 else { throw ParkingCostError.invalidRate }
            case let .flat(price):
                guard price >= 0 else { throw ParkingCostError.invalidRate }
            case let .earlyBird(price, enterBefore, leaveAfter):
                let dayMinutes = 0..<(24 * 60)
                guard price >= 0,
                      dayMinutes.contains(enterBefore),
                      dayMinutes.contains(leaveAfter),
                      enterBefore < leaveAfter
                else { throw ParkingCostError.invalidRate }
            case let .freePeriod(minutes):
                freePeriodCount += 1
                guard minutes > 0 else { throw ParkingCostError.invalidRate }
            }
        }
        guard freePeriodCount <= 1 else { throw ParkingCostError.invalidRate }
    }

    // Early bird applies when the car arrived by the cut-off and left after the release time on the same day.
    func qualifiesForEarlyBird(start: Date, end: Date, enterBeforeMinute: Int, leaveAfterMinute: Int) -> Bool {
        guard calendar.isDate(start, inSameDayAs: end) else { return false }
        return minuteOfDay(start) <= enterBeforeMinute && minuteOfDay(end) >= leaveAfterMinute
    }

    //helpers

    private func minuteOfDay(_ date: Date) -> Int {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
    }

    static func roundedToCents(_ value: Decimal) -> Decimal {
        var input = value
        var result = Decimal()
        NSDecimalRound(&result, &input, 2, .bankers)
        return result
    }
}
