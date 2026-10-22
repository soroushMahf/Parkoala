import XCTest
import SwiftData
@testable import Parkoala

// Uses an in-memory store so tests never touch the real database on the device
@MainActor
final class SwiftDataSessionRepositoryTests: XCTestCase {

    private var container: ModelContainer!
    private var repository: SwiftDataSessionRepository!
    private let vehicleID = UUID()

    override func setUpWithError() throws {
        try super.setUpWithError()
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: ParkingSessionEntity.self, VehicleEntity.self, configurations: configuration)
        repository = SwiftDataSessionRepository(context: container.mainContext)
    }

    func test_activeSession_returnsSavedSession_whenItHasNotEnded() async throws {
        let session = makeSession()
        try await repository.save(session)

        let active = try await repository.activeSession(for: vehicleID)

        XCTAssertEqual(active, session)
    }

    func test_activeSession_returnsNil_afterSessionIsEnded() async throws {
        var session = makeSession()
        try await repository.save(session)

        session.endDate = session.startDate.addingTimeInterval(30 * 60)
        try await repository.save(session)

        let active = try await repository.activeSession(for: vehicleID)
        XCTAssertNil(active)
    }

    func test_save_updatesExistingSession_insteadOfAddingAnother() async throws {
        var session = makeSession()
        try await repository.save(session)
        session.endDate = session.startDate.addingTimeInterval(60)
        try await repository.save(session)

        let stored = try await repository.sessions(inMonthOf: session.startDate)

        XCTAssertEqual(stored.count, 1)
    }

    func test_delete_throwsNotFound_whenSessionDoesNotExist() async {
        do {
            try await repository.delete(id: UUID())
            XCTFail("Expected notFound")
        } catch {
            XCTAssertEqual(error as? RepositoryError, .notFound)
        }
    }

    private func makeSession() -> ParkingSession {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        return ParkingSession(vehicleID: vehicleID, startDate: start, expiryDate: start.addingTimeInterval(2 * 60 * 60))
    }
}
