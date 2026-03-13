import XCTest
@testable import PollenSymptomTracker

final class TelemetryServiceTests: XCTestCase {
    func testTrackFallbackIncrementsCounters() {
        let telemetry = TelemetryService.shared
        telemetry.reset()
        telemetry.trackFallback(.primary)
        telemetry.trackFallback(.primary)
        telemetry.trackFallback(.backup)

        let stats = telemetry.fallbackStats()
        XCTAssertEqual(stats[.primary], 2)
        XCTAssertEqual(stats[.backup], 1)
        XCTAssertEqual(stats[.cache], 0)
    }
}
