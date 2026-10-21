import XCTest
@testable import Parkoala

@MainActor
final class SessionHistoryViewModelTests: XCTestCase {

    private var sessions: MockSessionRepository!
    private var viewModel: SessionHistoryViewModel!

    override func setUp() {
        super.setUp()
        sessions = MockSessionRepository()
        let useCase = ManageParkingSessionUseCase(
            sessionRepository: sessions,
            vehicleRepository: MockVehicleRepository()
        )
        viewModel = SessionHistoryViewModel(useCase: useCase)
    }

    func test_load_isEmpty_whenThereAreNoFinishedSessions() async {
        await viewModel.load()

        XCTAssertTrue(viewModel.isEmpty)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_load_groupsSessionsByMonth() async throws {
        let calendar = Calendar.current
        let thisMonth = Date.now
        let lastMonth = try XCTUnwrap(calendar.date(byAdding: .month, value: -1, to: thisMonth))
        sessions.sessions = [finished(at: thisMonth), finished(at: lastMonth), finished(at: lastMonth)]

        await viewModel.load()

        XCTAssertEqual(viewModel.months.count, 2)
        XCTAssertEqual(viewModel.months.first?.sessions.count, 1)
        XCTAssertEqual(viewModel.months.last?.sessions.count, 2)
    }

    func test_load_showsMessage_whenRepositoryFails() async {
        sessions.shouldThrow = true

        await viewModel.load()

        XCTAssertEqual(viewModel.errorMessage, RepositoryError.fetchFailed.errorDescription)
    }

    private func finished(at date: Date) -> ParkingSession {
        let start = date.addingTimeInterval(-2 * 60 * 60)
        return ParkingSession(
            vehicleID: UUID(),
            startDate: start,
            expiryDate: start.addingTimeInterval(60 * 60),
            endDate: start.addingTimeInterval(30 * 60)
        )
    }
}
