import XCTest
@testable import PollenSymptomTracker

@MainActor
final class AuthServiceTests: XCTestCase {
    func testGuestAndSignOut() {
        let auth = AuthService.shared
        auth.continueAsGuest()
        XCTAssertEqual(auth.provider, "Guest")
        XCTAssertFalse(auth.isSignedIn)

        auth.signOut()
        XCTAssertEqual(auth.provider, "Guest")
        XCTAssertFalse(auth.isSignedIn)
    }

    func testGoogleFallbackStateWhenSDKMissing() {
        let auth = AuthService.shared
        auth.signInWithGoogle()
        #if canImport(GoogleSignIn)
        XCTAssertEqual(auth.provider, "Google")
        #else
        XCTAssertTrue(auth.provider.contains("Google"))
        XCTAssertFalse(auth.isSignedIn)
        #endif
    }
}
