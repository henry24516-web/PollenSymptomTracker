import XCTest
@testable import PollenSymptomTracker

final class RiskInsightServiceTests: XCTestCase {
    func testRiskWindowsForHigh() {
        let data = PollenData(treePollen: 60, grassPollen: 20, weedPollen: 10, location: "London")
        let windows = RiskInsightService.shared.riskWindows(current: data)
        XCTAssertFalse(windows.isEmpty)
        XCTAssertEqual(windows.first?.riskLevel, .high)
    }

    func testWeeklySummaryReturnsText() {
        let logs = [SymptomLog(symptoms: [.sneezing], overallSeverity: 4)]
        let pollen = [PollenData(treePollen: 60, grassPollen: 10, weedPollen: 5, location: "London")]
        let summary = RiskInsightService.shared.weeklySummary(logs: logs, pollen: pollen)
        XCTAssertTrue(summary.contains("7-day summary"))
    }
}
