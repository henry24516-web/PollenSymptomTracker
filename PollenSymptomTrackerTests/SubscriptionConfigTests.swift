import XCTest
@testable import PollenSymptomTracker

final class SubscriptionConfigTests: XCTestCase {
    func testProductIDFormat() {
        let p = SubscriptionProduct(id: "monthly")
        XCTAssertEqual(p.productID, "com.pollenhealth.symptomtracker.premium.monthly")
    }

    func testDefaultConfigHasProducts() {
        let cfg = SubscriptionConfig.default
        XCTAssertFalse(cfg.products.isEmpty)
    }

    func testSubscriptionStateActiveFlag() {
        let active = SubscriptionState(status: .premium, expirationDate: Date().addingTimeInterval(3600), productID: "x")
        XCTAssertTrue(active.isActive)

        let expired = SubscriptionState(status: .premium, expirationDate: Date().addingTimeInterval(-3600), productID: "x")
        XCTAssertFalse(expired.isActive)
    }
}
