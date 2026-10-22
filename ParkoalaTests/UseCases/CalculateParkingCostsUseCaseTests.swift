import XCTest
@testable import Parkoala

@MainActor
final class CalculateParkingCostsUseCaseTests: XCTestCase {

    private var sessions: MockSessionRepository!
    private var useCase: CalculateParkingCostsUseCase!

    override func setUp() {
        super.setUp()
        sessions = MockSessionRepository()
        useCase = CalculateParkingCostsUseCase(sessionRepository: sessions)
    }

    func test_calculateFee_choosesCheapestApplicableRate() throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let end = start.addingTimeInterval(3 * 60 * 60)

        let estimate = try useCase.calculateFee(
            from: start,
            to: end,
            rates: [.hourly(price: 4), .flat(price: 20)]
        )

        XCTAssertEqual(estimate.amount, 12)
        XCTAssertEqual(estimate.appliedRate, .hourly(price: 4))
        XCTAssertFalse(estimate.exceededFreePeriod)
    }

    func test_calculateFee_roundsUpToTheNextStartedHour() throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let end = start.addingTimeInterval(61 * 60)

        let estimate = try useCase.calculateFee(from: start, to: end, rates: [.hourly(price: 5)])

        XCTAssertEqual(estimate.amount, 10)
    }

    func test_calculateFee_appliesFreePeriod_whenStayIsShortEnough() throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let end = start.addingTimeInterval(20 * 60)

        let estimate = try useCase.calculateFee(
            from: start,
            to: end,
            rates: [.freePeriod(minutes: 30), .hourly(price: 10)]
        )

        XCTAssertEqual(estimate.amount, 0)
        XCTAssertFalse(estimate.exceededFreePeriod)
    }

    func test_calculateFee_marksFreePeriodExceeded_whenNoPaidRateApplies() throws {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let end = start.addingTimeInterval(2 * 60 * 60)

        let estimate = try useCase.calculateFee(
            from: start,
            to: end,
            rates: [.freePeriod(minutes: 30)]
        )

        XCTAssertEqual(estimate.amount, 0)
        XCTAssertTrue(estimate.exceededFreePeriod)
    }

    func test_calculateFee_appliesEarlyBird_whenEnteredAndLeftWithinWindow() throws {
        let calendar = Calendar.current
        let start = try XCTUnwrap(calendar.date(bySettingHour: 6, minute: 30, second: 0, of: .now))
        let end = try XCTUnwrap(calendar.date(bySettingHour: 18, minute: 0, second: 0, of: .now))

        let estimate = try useCase.calculateFee(
            from: start,
            to: end,
            rates: [
                .hourly(price: 10),
                .earlyBird(price: 15, enterBeforeMinute: 7 * 60, leaveAfterMinute: 15 * 60)
            ]
        )

        XCTAssertEqual(estimate.amount, 15)
        XCTAssertEqual(
            estimate.appliedRate,
            .earlyBird(price: 15, enterBeforeMinute: 7 * 60, leaveAfterMinute: 15 * 60)
        )
    }

    func test_calculateFee_throwsNoRateSet_whenRatesAreEmpty() {
        let start = Date.now
        let end = start.addingTimeInterval(60 * 60)

        assertThrows(ParkingCostError.noRateSet) {
            _ = try self.useCase.calculateFee(from: start, to: end, rates: [])
        }
    }

    func test_calculateFee_throwsInvalidDuration_whenEndIsBeforeStart() {
        let start = Date.now
        let end = start.addingTimeInterval(-60)

        assertThrows(ParkingCostError.invalidDuration) {
            _ = try self.useCase.calculateFee(from: start, to: end, rates: [.flat(price: 5)])
        }
    }

    func test_validate_throwsInvalidRate_whenHourlyPriceIsNotPositive() {
        assertThrows(ParkingCostError.invalidRate) {
            try self.useCase.validate([.hourly(price: 0)])
        }
    }

    func test_validate_throwsInvalidRate_whenMoreThanOneFreePeriod() {
        assertThrows(ParkingCostError.invalidRate) {
            try self.useCase.validate([.freePeriod(minutes: 30), .freePeriod(minutes: 60)])
        }
    }

    func test_validateActualCost_roundsToCents_whenAmountIsValid() throws {
        let rounded = try useCase.validateActualCost(12.346)
        XCTAssertEqual(rounded, 12.35)
    }

    func test_validateActualCost_throwsInvalidActualCost_whenNegative() {
        assertThrows(ParkingCostError.invalidActualCost) {
            _ = try self.useCase.validateActualCost(-1)
        }
    }

    func test_summariseCosts_countsOnlyFinishedSessions() {
        let vehicleID = UUID()
        let finished = session(vehicleID: vehicleID, cost: 10, isActive: false)
        let active = session(vehicleID: vehicleID, cost: nil, isActive: true)

        let summary = useCase.summariseCosts(for: [finished, active])

        XCTAssertEqual(summary.totalSpent, 10)
        XCTAssertEqual(summary.sessionCount, 1)
    }

    func test_monthlySummary_usesSessionsFromTheRepository() async throws {
        let now = Date.now
        sessions.sessions = [
            session(vehicleID: UUID(), startDate: now, cost: 8, isActive: false),
            session(vehicleID: UUID(), startDate: now, cost: 4, isActive: false)
        ]

        let summary = try await useCase.monthlySummary(for: now)

        XCTAssertEqual(summary.totalSpent, 12)
        XCTAssertEqual(summary.sessionCount, 2)
    }

    func test_recordEstimatedCost_savesRoundedAmount_onTheSession() async throws {
        let original = session(vehicleID: UUID(), cost: nil, isActive: false)
        sessions.sessions = [original]

        let updated = try await useCase.recordEstimatedCost(9.999, for: original)

        XCTAssertEqual(updated.cost, 10)
        XCTAssertEqual(sessions.sessions.first?.cost, 10)
    }

    func test_recordActualCost_throwsInvalidActualCost_whenAmountIsTooLarge() async {
        let original = session(vehicleID: UUID(), cost: 10, isActive: false)
        sessions.sessions = [original]

        await assertThrowsAsync(ParkingCostError.invalidActualCost) {
            _ = try await self.useCase.recordActualCost(10_000, for: original)
        }
    }

    // MARK: - Helpers

    private func session(
        vehicleID: UUID,
        startDate: Date = .now,
        cost: Decimal?,
        isActive: Bool
    ) -> ParkingSession {
        ParkingSession(
            vehicleID: vehicleID,
            startDate: startDate,
            expiryDate: startDate.addingTimeInterval(60 * 60),
            endDate: isActive ? nil : startDate.addingTimeInterval(45 * 60),
            cost: cost
        )
    }

    private func assertThrows<E: Error & Equatable>(
        _ expected: E,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ work: () throws -> Void
    ) {
        do {
            try work()
            XCTFail("Expected \(expected) but nothing was thrown", file: file, line: line)
        } catch let error as E {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("Expected \(expected) but got \(error)", file: file, line: line)
        }
    }

    private func assertThrowsAsync<E: Error & Equatable>(
        _ expected: E,
        file: StaticString = #filePath,
        line: UInt = #line,
        _ work: () async throws -> Void
    ) async {
        do {
            try await work()
            XCTFail("Expected \(expected) but nothing was thrown", file: file, line: line)
        } catch let error as E {
            XCTAssertEqual(error, expected, file: file, line: line)
        } catch {
            XCTFail("Expected \(expected) but got \(error)", file: file, line: line)
        }
    }
}
