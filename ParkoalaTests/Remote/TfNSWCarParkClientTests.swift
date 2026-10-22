import Foundation
import Testing
@testable import Parkoala

// Serialized because every test mutates the same static MockURLProtocol.requestHandler —
// running them in parallel would let one test's handler leak into another's request.
@Suite(.serialized)
struct TfNSWCarParkClientTests {

    private func makeClient() -> URLSessionTfNSWCarParkClient {
        URLSessionTfNSWCarParkClient(apiKey: "test-key", urlSession: MockURLProtocol.makeSession())!
    }

    private func jsonResponse(for url: URL, statusCode: Int, body: String) -> (HTTPURLResponse, Data) {
        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        return (response, Data(body.utf8))
    }

    @Test("A nil or blank API key means no client can be created")
    func rejectsMissingKey() {
        #expect(URLSessionTfNSWCarParkClient(apiKey: nil) == nil)
        #expect(URLSessionTfNSWCarParkClient(apiKey: "") == nil)
        #expect(URLSessionTfNSWCarParkClient(apiKey: "   ") == nil)
    }

    @Test("A real API key creates a usable client")
    func acceptsRealKey() {
        #expect(URLSessionTfNSWCarParkClient(apiKey: "real-key") != nil)
    }

    @Test("A 401 response maps to unauthorized")
    func mapsUnauthorized() async {
        MockURLProtocol.requestHandler = { request in
            self.jsonResponse(for: request.url!, statusCode: 401, body: "")
        }
        let client = makeClient()

        await #expect(throws: NetworkError.unauthorized) {
            try await client.fetchAllFacilities()
        }
    }

    @Test("A 429 response maps to rateLimited")
    func mapsRateLimited() async {
        MockURLProtocol.requestHandler = { request in
            self.jsonResponse(for: request.url!, statusCode: 429, body: "")
        }
        let client = makeClient()

        await #expect(throws: NetworkError.rateLimited) {
            try await client.fetchAllFacilities()
        }
    }

    @Test("No internet connection maps to offline")
    func mapsOffline() async {
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        let client = makeClient()

        await #expect(throws: NetworkError.offline) {
            try await client.fetchAllFacilities()
        }
    }

    @Test("A malformed full-list response falls back to per-facility requests")
    func fallsBackToPerFacility() async throws {
        MockURLProtocol.requestHandler = { request in
            let url = request.url!
            if url.path == "/v1/carpark/full-list" {
                return self.jsonResponse(for: url, statusCode: 200, body: "{ not valid json")
            }
            if url.path == "/v1/carpark", url.query == nil {
                return self.jsonResponse(for: url, statusCode: 200, body: "[{ \"facility_id\": \"26\" }]")
            }
            if url.query == "facility=26" {
                return self.jsonResponse(for: url, statusCode: 200, body: "{ \"facility_id\": \"26\" }")
            }
            Issue.record("Unexpected request to \(url)")
            return self.jsonResponse(for: url, statusCode: 404, body: "")
        }
        let client = makeClient()

        let facilities = try await client.fetchAllFacilities()

        #expect(facilities.map(\.facilityID) == ["26"])
    }
}
