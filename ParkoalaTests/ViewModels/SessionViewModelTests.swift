import XCTest
@testable import Parkoala

@MainActor
final class SessionViewModelTests: XCTestCase {

    private var sessions: MockSessionRepository!
    private var vehicles: MockVehicleRepository!
    private var viewModel: SessionViewModel!
    private var notificationService: MockNotificationService!

    override func setUp() {
        super.setUp()

        sessions = MockSessionRepository()
        vehicles = MockVehicleRepository()
        notificationService = MockNotificationService()

        let useCase = ManageParkingSessionUseCase(
            sessionRepository: sessions,
            vehicleRepository: vehicles
        )

        let alertsUseCase = ManageParkingAlertsUseCase(
            notificationService: notificationService
        )

        viewModel = SessionViewModel(
            useCase: useCase,
            alertsUseCase: alertsUseCase
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
            )
        )
        
        await relaunched.load()

        XCTAssertEqual(relaunched.activeSession, saved)
    }
}
