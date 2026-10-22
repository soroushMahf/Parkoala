import Foundation

// Fetches facility data from the TfNSW Car Park API. A protocol so tests can
// substitute a mock instead of hitting the network.
protocol TfNSWCarParkClient {
    func fetchAllFacilities() async throws -> [TfNSWCarParkDTO]
}

// `/v1/carpark` facility list entry: just enough to drive the per-facility
// fallback. 
private enum TfNSWFacilityIndex: Decodable {
    case keyedByFacilityID([String: String])
    case list([TfNSWFacilityListEntry])

    init(from decoder: Decoder) throws {
        if let keyed = try? [String: String](from: decoder) {
            self = .keyedByFacilityID(keyed)
            return
        }
        if let list = try? [TfNSWFacilityListEntry](from: decoder) {
            self = .list(list)
            return
        }
        throw DecodingError.dataCorrupted(
            .init(codingPath: decoder.codingPath, debugDescription: "Unrecognized facility list response shape")
        )
    }

    var facilityIDs: [String] {
        switch self {
        case .keyedByFacilityID(let facilities): Array(facilities.keys)
        case .list(let facilities): facilities.map(\.facilityID)
        }
    }
}

private struct TfNSWFacilityListEntry: Decodable {
    let facilityID: String

    enum CodingKeys: String, CodingKey {
        case facilityID = "facility_id"
    }
}

final class URLSessionTfNSWCarParkClient: TfNSWCarParkClient {
    private static let baseURL = URL(string: "https://api.transport.nsw.gov.au")!

    private let apiKey: String
    private let urlSession: URLSession

    // Returns nil when there's no usable key, so callers can skip the API
    // entirely rather than making requests that will only ever 401.
    init?(apiKey: String?, urlSession: URLSession = .shared) {
        guard let apiKey, !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        self.apiKey = apiKey
        self.urlSession = urlSession
    }

    func fetchAllFacilities() async throws -> [TfNSWCarParkDTO] {
        do {
            let listResponse: TfNSWCarParkListResponse = try await get(path: "/v1/carpark/full-list")
            return listResponse.facilities
        } catch is DecodingError {
            return try await fetchPerFacility()
        }
    }

    private func fetchPerFacility() async throws -> [TfNSWCarParkDTO] {
        let index: TfNSWFacilityIndex = try await get(path: "/v1/carpark")

        var facilities: [TfNSWCarParkDTO] = []
        for facilityID in index.facilityIDs {
            if let facility: TfNSWCarParkDTO = try? await get(path: "/v1/carpark", query: [URLQueryItem(name: "facility", value: facilityID)]) {
                facilities.append(facility)
            }
        }
        return facilities
    }

    private func get<T: Decodable>(path: String, query: [URLQueryItem] = []) async throws -> T {
        var components = URLComponents(url: Self.baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        if !query.isEmpty {
            components?.queryItems = query
        }
        guard let url = components?.url else {
            throw NetworkError.badResponse
        }

        var request = URLRequest(url: url)
        request.setValue("apikey \(apiKey)", forHTTPHeaderField: "Authorization")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await urlSession.data(for: request)
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw NetworkError.offline
            default:
                throw NetworkError.badResponse
            }
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.badResponse
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401, 403:
            throw NetworkError.unauthorized
        case 429:
            throw NetworkError.rateLimited
        default:
            throw NetworkError.badResponse
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw error is DecodingError ? error : NetworkError.badResponse
        }
    }
}
