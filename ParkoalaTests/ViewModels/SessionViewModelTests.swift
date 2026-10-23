import XCTest
@testable import Parkoala

@MainActor
final class SessionViewModelTests: XCTestCase {

    private var sessions: MockSessionRepository!
    private var vehicles: MockVehicleRepository!
    private var viewModel: SessionViewModel!
    private var notificationService: MockNotificationService!
    private var liveActivityService: MockLiveActivityService!

    override func setUp() {
        super.setUp()

        sessions = MockSessionRepository()
        vehicles = MockVehicleRepository()
        notificationService = MockNotificationService()
        liveActivityService = MockLiveActivityService()

        let useCase = ManageParkingSessionUseCase(
            sessionRepository: sessions,
            vehicleRepository: vehicles
        )

        let alertsUseCase = ManageParkingAlertsUseCase(
            notificationService: notificationService
        )

        viewModel = SessionViewModel(
            useCase: useCase,
            alertsUseCase: alertsUseCase,
            liveActivityService: liveActivityService,
            costUseCase: CalculateParkingCostsUseCase(sessionRepository: sessions)
        )
    }

    func test_startSession_setsActiveSession_whenItSucceeds() async {
        let started = await viewModel.startSession(duration: 60 * 60)

        XCTAssertTrue(started)
        XCTAssertNotNil(viewModel.activeSession)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_startSession_showsMessage_whenDurationIsInvalid() async {
        let started = await viewModel.startSession(duration: 0)

        XCTAssertFalse(started)
        XCTAssertNil(viewModel.activeSession)
        XCTAssertEqual(viewModel.errorMessage, ParkingSessionError.invalidDuration.errorDescription)
    }

    func test_endSession_clearsActiveSession() async {
        await viewModel.startSession(duration: 60 * 60)

        await viewModel.endSession()

        XCTAssertNil(viewModel.activeSession)
        XCTAssertNil(viewModel.errorMessage)
    }

    func test_load_showsActiveSession_afterRelaunch() async {
        await viewModel.startSession(duration: 60 * 60)
        let saved = viewModel.activeSession

        let relaunched = SessionViewModel(
            useCase: ManageParkingSessionUseCase(
                sessionRepository: sessions,
                vehicleRepository: vehicles
            ),
            alertsUseCase: ManageParkingAlertsUseCase(
                notificationService: notificationService
            ),
            liveActivityService: liveActivityService,
            costUseCase: CalculateParkingCostsUseCase(sessionRepository: sessions)
        )
        
        await relaunched.load()

        XCTAssertEqual(relaunched.activeSession, saved)
    }
    
    func test_startSession_startsLiveActivity() async {
        let duration: TimeInterval = 30 * 60

        let success = await viewModel.startSession(
            duration: duration
        )

        XCTAssertTrue(success)
        XCTAssertEqual(liveActivityService.startCallCount, 1)

        XCTAssertEqual(
            liveActivityService.startedSessionID,
            viewModel.activeSession?.id
        )

        XCTAssertEqual(
            liveActivityService.startedExpiryDate,
            viewModel.activeSession?.expiryDate
        )
    }
    
    func test_endSession_endsLiveActivity() async {
        _ = await viewModel.startSession(
            duration: 30 * 60
        )

        await viewModel.endSession()

        XCTAssertEqual(
            liveActivityService.endCallCount,
            1
        )
    }

    func test_startSession_storesThePlannedRate_whenProvided() async {
        _ = await viewModel.startSession(duration: 60 * 60, plannedRate: .hourly(price: 5))

        XCTAssertEqual(viewModel.activeSession?.plannedRate, .hourly(price: 5))
    }

    func test_endSession_calculatesCost_whenPlannedRateWasSet() async throws {
        _ = await viewModel.startSession(duration: 2 * 60 * 60, plannedRate: .hourly(price: 4))

        await viewModel.endSession()

        let saved = try XCTUnwrap(sessions.sessions.first)
        XCTAssertNotNil(saved.cost)
    }
}
