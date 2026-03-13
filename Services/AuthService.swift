import Foundation
import AuthenticationServices

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var provider: String = "Guest"
    @Published var isSignedIn: Bool = false
    @Published var authErrorMessage: String?

    private init() {}

    /// Handles native Sign in with Apple callback result.
    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard authorization.credential as? ASAuthorizationAppleIDCredential != nil else {
                authErrorMessage = "Apple Sign-In credential missing"
                provider = "Guest"
                isSignedIn = false
                return
            }
            provider = "Apple"
            isSignedIn = true
            authErrorMessage = nil
        case .failure(let error):
            provider = "Guest"
            isSignedIn = false
            authErrorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
        }
    }

    func signInWithGoogle() {
        #if canImport(GoogleSignIn)
        provider = "Google"
        isSignedIn = true
        authErrorMessage = nil
        #else
        provider = "Google (SDK pending)"
        isSignedIn = false
        authErrorMessage = "Google Sign-In SDK not integrated in this build"
        #endif
    }

    func continueAsGuest() {
        provider = "Guest"
        isSignedIn = false
        authErrorMessage = nil
    }

    func signOut() {
        provider = "Guest"
        isSignedIn = false
        authErrorMessage = nil
    }
}
