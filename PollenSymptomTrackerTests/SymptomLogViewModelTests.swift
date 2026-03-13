import XCTest
@testable import PollenSymptomTracker

@MainActor
final class SymptomLogViewModelTests: XCTestCase {
    override func setUp() {
        super.setUp()
        StorageService.shared.clearAllData()
    }

    func testAddAndDeleteLog() {
        let vm = SymptomLogViewModel()
        vm.addLog(symptoms: [SymptomEntry(symptom: .sneezing, severity: .mild)], notes: "test", severity: 3)

        XCTAssertEqual(vm.symptomLogs.count, 1)
        let id = vm.symptomLogs[0].id

        vm.deleteLog(id: id)
        XCTAssertEqual(vm.symptomLogs.count, 0)
    }

    func testNearLimitWarning() {
        let vm = SymptomLogViewModel()

        for _ in 0..<9 {
            vm.addLog(symptoms: [SymptomEntry(symptom: .itchyEyes, severity: .moderate)], notes: "", severity: 2)
        }

        XCTAssertTrue(vm.nearLimitWarning)
        XCTAssertTrue(vm.canLogMore)
        XCTAssertEqual(vm.monthlyLogCount, 9)
    }
}
