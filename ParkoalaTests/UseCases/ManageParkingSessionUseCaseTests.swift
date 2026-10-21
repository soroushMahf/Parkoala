import XCTest
@testable import Parkoala

@MainActor
final class ManageParkingSessionUseCaseTests: XCTestCase {

    private var sessions: MockSessionRepository!
    private var vehicles: MockVehicleRepository!
    private var useCase: ManageParkingSessionUseCase!
    private let fixedNow = Date(timeIntervalSince1970: 1_800_000_000)

    override func setUp() {
        super.setUp()
        sessions = MockSessionRepository()
        vehicles = MockVehicleRepository()
        let now = fixedNow
        useCase = ManageParkingSessionUseCase(
            sessionRepository: sessions,
            vehicleRepository: vehicles,
            now: { now }
        )
    }

    func test_startSession_savesSessionWithExpiry_whenNothingIsRunning() async throws {
        let session = try await useCase.startSession(duration: 2 * 60 * 60)

        XCTAssertEqual(session.startDate, fixedNow)
        XCTAssertEqual(session.expiryDate, fixedNow.addingTimeInterval(2 * 60 * 60))
        XCTAssertTrue(session.isActive)
        XCTAssertEqual(sessions.sessions, [session])
    }

    func test_startSession_createsDefaultVehicle_whenNoneExists() async throws {
        let session = try await useCase.startSession(duration: 60 * 60)

        XCTAssertEqual(vehicles.vehicles.count, 1)
        XCTAssertEqual(session.vehicleID, vehicles.vehicles.first?.id)
    }

    func test_startSession_throwsSessionAlreadyActive_whenSessionIsRunning() async throws {
        _ = try await useCase.startSession(duration: 60 * 60)

        await assertThrows(ParkingSessionError.sessionAlreadyActive) {
            _ = try await self.useCase.startSession(duration: 60 * 60)
        }
        XCTAssertEqual(sessions.sessions.count, 1)
    }

    func test_startSession_throwsInvalidDuration_whenDurationIsZero() async {
        await assertThrows(ParkingSessionError.invalidDuration) {
            _ = try await self.useCase.startSession(duration: 0)
        }
    }

    func test_startSession_throwsInvalidDuration_whenLongerThanOneDay() async {
        await assertThrows(ParkingSessionError.invalidDuration) {
            _ = try await self.useCase.startSession(duration: 25 * 60 * 60)
        }
    }

    func test_startSession_throwsExceedsTimeLimit_whenLongerThanSignAllows() async {
        let twoHourSign = ParkingRestriction(kind: .timeLimited, maxStay: 2 * 60 * 60)

        await assertThrows(ParkingSessionError.exceedsTimeLimit) {
            _ = try await self.useCase.startSession(duration: 3 * 60 * 60, restriction: twoHourSign)
        }
    }

    func test_endSession_setsEndDate_whenSessionIsRunning() async throws {
        _ = try await useCase.startSession(duration: 60 * 60)

        let ended = try await useCase.endSession()

        XCTAssertEqual(ended.endDate, fixedNow)
        XCTAssertFalse(ended.isActive)
        let active = try await useCase.activeSession()
        XCTAssertNil(active)
    }

    func test_endSession_throwsNoActiveSession_whenNothingIsRunning() async {
        await assertThrows(ParkingSessionError.noActiveSession) {
            _ = try await self.useCase.endSession()
        }
    }

    func test_startSession_passesRepositoryError_whenRepositoryFails() async {
        sessions.shouldThrow = true

        await assertThrows(RepositoryError.fetchFailed) {
            _ = try await self.useCase.startSession(duration: 60 * 60)
        }
    }

    func test_recentSessions_returnsOnlyFinishedSessions_newestFirst() async throws {
        let vehicleID = UUID()
        let older = finishedSession(vehicleID: vehicleID, daysAgo: 5)
        let newer = finishedSession(vehicleID: vehicleID, daysAgo: 1)
        let running = ParkingSession(vehicleID: vehicleID, startDate: fixedNow, expiryDate: fixedNow.addingTimeInterval(3600))
        sessions.sessions = [older, running, newer]

        let recent = try await useCase.recentSessions()

        XCTAssertEqual(recent, [newer, older])
    }

    func test_recentSessions_leavesOutSessionsOlderThanThreeMonths() async throws {
        let recentOne = finishedSession(vehicleID: UUID(), daysAgo: 10)
        let oldOne = finishedSession(vehicleID: UUID(), daysAgo: 150)
        sessions.sessions = [recentOne, oldOne]

        let recent = try await useCase.recentSessions()

        XCTAssertEqual(recent, [recentOne])
    }

    private func finishedSession(vehicleID: UUID, daysAgo: Double) -> ParkingSession {
        let start = fixedNow.addingTimeInterval(-daysAgo * 24 * 60 * 60)
        return ParkingSession(
            vehicleID: vehicleID,
            startDate: start,
            expiryDate: start.addingTimeInterval(2 * 60 * 60),
            endDate: start.addingTimeInterval(60 * 60)
        )
    }

    // Checks that the work throws exactly the expected error
    private func assertThrows<E: Error & Equatable>(
        _ expected: E,
        _ work: () async throws -> Void,
        file: StaticString = #filePath,
        line: UInt = #line
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
