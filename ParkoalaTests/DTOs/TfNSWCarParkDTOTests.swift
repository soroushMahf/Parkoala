import Foundation
import Testing
@testable import Parkoala

@MainActor
struct TfNSWCarParkDTOTests {

    private func decode(_ json: String) throws -> TfNSWCarParkDTO {
        try JSONDecoder().decode(TfNSWCarParkDTO.self, from: Data(json.utf8))
    }

    @Test("The documented sample response decodes correctly")
    func decodesSampleResponse() throws {
        let json = """
        {
          "tsn": "2155384", "time": "785808515", "spots": "123",
          "zones": [{ "spots": "123", "zone_id": "1",
                      "occupancy": { "loop": "4786", "total": "123", "monthlies": null, "open_gate": null, "transients": null },
                      "zone_name": "SYD396A Tallawong P1 Car Park", "parent_zone_id": "0" }],
          "ParkID": "1",
          "location": { "suburb": "Tallawong", "address": "Conferta Avenue", "latitude": "-33.69304704", "longitude": "150.9052577" },
          "occupancy": { "loop": "4786", "total": "123", "monthlies": null, "open_gate": null, "transients": null },
          "MessageDate": "2024-11-25T11:08:35",
          "facility_id": "26", "facility_name": "Park&Ride - Tallawong P1", "tfnsw_facility_id": "2155384TPR001"
        }
        """

        let dto = try decode(json)

        #expect(dto.parkID == "1")
        #expect(dto.facilityID == "26")
        #expect(dto.facilityName == "Park&Ride - Tallawong P1")
        #expect(dto.spots == 123)
        #expect(dto.occupancy?.total == 123)
        #expect(dto.location?.latitude == -33.69304704)
        #expect(dto.location?.longitude == 150.9052577)

        let components = Calendar(identifier: .gregorian).dateComponents(
            in: TimeZone(identifier: "Australia/Sydney")!,
            from: try #require(dto.messageDate)
        )
        #expect(components.year == 2024)
        #expect(components.month == 11)
        #expect(components.day == 25)
        #expect(components.hour == 11)
        #expect(components.minute == 8)
    }

    @Test("Null occupancy fields and non-numeric strings decode without crashing")
    func toleratesNullsAndGarbageValues() throws {
        let json = """
        {
          "ParkID": "1",
          "spots": "not a number",
          "occupancy": { "total": null },
          "location": { "latitude": "not a number", "longitude": null },
          "MessageDate": "not a date",
          "facility_id": "99"
        }
        """

        let dto = try decode(json)

        #expect(dto.spots == nil)
        #expect(dto.occupancy?.total == nil)
        #expect(dto.location?.latitude == nil)
        #expect(dto.location?.longitude == nil)
        #expect(dto.messageDate == nil)
        #expect(dto.facilityID == "99")
    }

    @Test("Missing keys entirely decode without crashing")
    func toleratesMissingKeys() throws {
        let dto = try decode("{ \"facility_id\": \"7\" }")

        #expect(dto.facilityID == "7")
        #expect(dto.spots == nil)
        #expect(dto.occupancy == nil)
        #expect(dto.location == nil)
        #expect(dto.messageDate == nil)
    }

    @Test("A full-list response as a bare array decodes")
    func decodesListShape() throws {
        let json = "[{ \"facility_id\": \"26\" }, { \"facility_id\": \"27\" }]"
        let response = try JSONDecoder().decode(TfNSWCarParkListResponse.self, from: Data(json.utf8))

        #expect(response.facilities.map(\.facilityID) == ["26", "27"])
    }

    @Test("A full-list response keyed by facility ID decodes")
    func decodesKeyedShape() throws {
        let json = "{ \"26\": { \"facility_id\": \"26\" }, \"27\": { \"facility_id\": \"27\" } }"
        let response = try JSONDecoder().decode(TfNSWCarParkListResponse.self, from: Data(json.utf8))

        #expect(Set(response.facilities.compactMap(\.facilityID)) == ["26", "27"])
    }

    @Test("An unrecognized full-list shape throws instead of silently returning nothing")
    func rejectsUnrecognizedShape() {
        let json = "\"just a string\""

        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(TfNSWCarParkListResponse.self, from: Data(json.utf8))
        }
    }
}
