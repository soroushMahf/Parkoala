import XCTest
@testable import Parkoala

@MainActor
final class MoneyViewModelTests: XCTestCase {

    private var sessions: MockSessionRepository!
    private var vehicles: MockVehicleRepository!
    private var viewModel: MoneyViewModel!

    override func setUp() {
        super.setUp()
        sessions = MockSessionRepository()
        vehicles = MockVehicleRepository()
        let sessionUseCase = ManageParkingSessionUseCase(sessionRepository: sessions, vehicleRepository: vehicles)
        let costUseCase = CalculateParkingCostsUseCase(sessionRepository: sessions)
        viewModel = MoneyViewModel(sessionUseCase: sessionUseCase, costUseCase: costUseCase)
    }

    func test_load_splitsSessions_byWhetherTheyHaveACost() async {
        let vehicleID = UUID()
        let costed = finishedSession(vehicleID: vehicleID, daysAgo: 1, cost: 10)
        let uncosted = finishedSession(vehicleID: vehicleID, daysAgo: 2, cost: nil)
        sessions.sessions = [costed, uncosted]

        await viewModel.load()

        XCTAssertEqual(viewModel.costedSessions, [costed])
        XCTAssertEqual(viewModel.uncostedSessions, [uncosted])
    }

    func test_load_showsMessage_whenRepositoryFails() async {
        sessions.shouldThrow = true

        await viewModel.load()

        XCTAssertEqual(viewModel.errorMessage, RepositoryError.fetchFailed.errorDescription)
    }

    func test_estimate_calculatesFeeForTheSessionsStayLength() throws {
        let session = finishedSession(vehicleID: UUID(), daysAgo: 1, cost: nil, stayHours: 2)

        let estimate = try viewModel.estimate(for: session, rates: [.hourly(price: 5)])

        XCTAssertEqual(estimate.amount, 10)
    }

    func test_estimate_throwsInvalidDuration_whenSessionHasNoEndDate() {
        let active = ParkingSession(vehicleID: UUID(), startDate: .now, expiryDate: .now.addingTimeInterval(3600))

        XCTAssertThrowsError(try viewModel.estimate(for: active, rates: [.flat(price: 5)])) { error in
            XCTAssertEqual(error as? ParkingCostError, .invalidDuration)
        }
    }

    func test_saveEstimate_movesSessionFromUncostedToCosted() async throws {
        let session = finishedSession(vehicleID: UUID(), daysAgo: 1, cost: nil, stayHours: 2)
        sessions.sessions = [session]
        await viewModel.load()

        let estimate = try viewModel.estimate(for: session, rates: [.hourly(price: 5)])
        let saved = await viewModel.saveEstimate(estimate, for: session)

        XCTAssertTrue(saved)
        XCTAssertTrue(viewModel.uncostedSessions.isEmpty)
        XCTAssertEqual(viewModel.costedSessions.first?.cost, 10)
    }

    func test_saveActualCost_failsAndReportsError_whenAmountIsInvalid() async {
        let session = finishedSession(vehicleID: UUID(), daysAgo: 1, cost: 10)
        sessions.sessions = [session]

        let saved = await viewModel.saveActualCost(-1, for: session)

        XCTAssertFalse(saved)
        XCTAssertEqual(viewModel.errorMessage, ParkingCostError.invalidActualCost.errorDescription)
    }

    private func finishedSession(
        vehicleID: UUID,
        daysAgo: Double,
        cost: Decimal?,
        stayHours: Double = 1
    ) -> ParkingSession {
        let start = Date.now.addingTimeInterval(-daysAgo * 24 * 60 * 60)
        return ParkingSession(
            vehicleID: vehicleID,
            startDate: start,
            expiryDate: start.addingTimeInterval(stayHours * 60 * 60),
            endDate: start.addingTimeInterval(stayHours * 60 * 60),
            cost: cost
        )
    }
}
