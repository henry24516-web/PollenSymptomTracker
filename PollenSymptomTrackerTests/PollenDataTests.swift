import XCTest
@testable import PollenSymptomTracker

final class PollenDataTests: XCTestCase {
    func testOverallLevelLow() {
        let data = PollenData(treePollen: 5, grassPollen: 10, weedPollen: 3, location: "Test")
        XCTAssertEqual(data.overallLevel, .low)
    }

    func testOverallLevelVeryHigh() {
        let data = PollenData(treePollen: 120, grassPollen: 0, weedPollen: 0, location: "Test")
        XCTAssertEqual(data.overallLevel, .veryHigh)
    }

    func testBackwardCompatibleDecoding() throws {
        let json = """
        {"id":"00000000-0000-0000-0000-000000000000","date":"2026-03-11T00:00:00Z","treePollen":20,"grassPollen":10,"weedPollen":5,"location":"London"}
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(PollenData.self, from: json)
        XCTAssertEqual(decoded.location, "London")
        XCTAssertEqual(decoded.dataSource, "Unknown")
        XCTAssertEqual(decoded.confidence, .medium)
    }
}
