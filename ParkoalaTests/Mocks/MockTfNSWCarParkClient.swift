import Foundation
@testable import Parkoala

final class MockTfNSWCarParkClient: TfNSWCarParkClient {
    var result: Result<[TfNSWCarParkDTO], Error> = .success([])
    private(set) var fetchCallCount = 0

    func fetchAllFacilities() async throws -> [TfNSWCarParkDTO] {
        fetchCallCount += 1
        return try result.get()
    }
}
