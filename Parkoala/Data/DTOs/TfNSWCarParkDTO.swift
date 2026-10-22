import Foundation

// Decodes a single TfNSW Car Park API facility payload (v2.4, Sept 2026).
// Every number arrives as a string and occupancy fields can be null, so every
// value here is optional: a missing key, a null, or text that isn't a number
// all become nil rather than failing the whole decode. `zones` and `time` are
// intentionally not modelled — the docs say not to rely on `time`, and the
// facility-level `spots`/`occupancy` are all this feature needs.
struct TfNSWCarParkDTO: Decodable {
    struct Location: Decodable {
        let suburb: String?
        let address: String?
        let latitude: Double?
        let longitude: Double?

        enum CodingKeys: String, CodingKey {
            case suburb, address, latitude, longitude
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            suburb = try? container.decode(String.self, forKey: .suburb)
            address = try? container.decode(String.self, forKey: .address)
            latitude = container.decodeLenientDouble(forKey: .latitude)
            longitude = container.decodeLenientDouble(forKey: .longitude)
        }

        init(suburb: String? = nil, address: String? = nil, latitude: Double?, longitude: Double?) {
            self.suburb = suburb
            self.address = address
            self.latitude = latitude
            self.longitude = longitude
        }
    }

    struct Occupancy: Decodable {
        let total: Int?

        enum CodingKeys: String, CodingKey {
            case total
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            total = container.decodeLenientInt(forKey: .total)
        }

        init(total: Int?) {
            self.total = total
        }
    }


    let parkID: String?
    let facilityID: String?
    let facilityName: String?
    let spots: Int?
    let occupancy: Occupancy?
    let location: Location?
    let messageDate: Date?

    enum CodingKeys: String, CodingKey {
        case parkID = "ParkID"
        case facilityID = "facility_id"
        case facilityName = "facility_name"
        case spots
        case occupancy
        case location
        case messageDate = "MessageDate"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        parkID = try? container.decode(String.self, forKey: .parkID)
        facilityID = try? container.decode(String.self, forKey: .facilityID)
        facilityName = try? container.decode(String.self, forKey: .facilityName)
        spots = container.decodeLenientInt(forKey: .spots)
        occupancy = try? container.decode(Occupancy.self, forKey: .occupancy)
        location = try? container.decode(Location.self, forKey: .location)

        if let dateString = try? container.decode(String.self, forKey: .messageDate) {
            messageDate = Self.sydneyDateFormatter.date(from: dateString)
        } else {
            messageDate = nil
        }
    }

    // Test-only convenience — production code only ever builds these via decoding.
    init(
        parkID: String? = nil,
        facilityID: String?,
        facilityName: String? = nil,
        spots: Int?,
        occupancy: Occupancy?,
        location: Location?,
        messageDate: Date?
    ) {
        self.parkID = parkID
        self.facilityID = facilityID
        self.facilityName = facilityName
        self.spots = spots
        self.occupancy = occupancy
        self.location = location
        self.messageDate = messageDate
    }

    static let sydneyDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Australia/Sydney")
        return formatter
    }()
}


enum TfNSWCarParkListResponse: Decodable {
    case list([TfNSWCarParkDTO])
    case keyedByFacilityID([String: TfNSWCarParkDTO])

    init(from decoder: Decoder) throws {
        if let list = try? [TfNSWCarParkDTO](from: decoder) {
            self = .list(list)
            return
        }

        if let keyed = try? [String: TfNSWCarParkDTO](from: decoder) {
            self = .keyedByFacilityID(keyed)
            return
        }

        throw DecodingError.dataCorrupted(
            .init(codingPath: decoder.codingPath, debugDescription: "Unrecognized full-list response shape")
        )
    }

    var facilities: [TfNSWCarParkDTO] {
        switch self {
        case .list(let facilities): facilities
        case .keyedByFacilityID(let facilities): Array(facilities.values)
        }
    }
}

private extension KeyedDecodingContainer where K: CodingKey {
    func decodeLenientInt(forKey key: K) -> Int? {
        if let value = try? decode(Int.self, forKey: key) {
            return value
        }
        if let string = try? decode(String.self, forKey: key) {
            return Int(string)
        }
        return nil
    }

    func decodeLenientDouble(forKey key: K) -> Double? {
        if let value = try? decode(Double.self, forKey: key) {
            return value
        }
        if let string = try? decode(String.self, forKey: key) {
            return Double(string)
        }
        return nil
    }
}
