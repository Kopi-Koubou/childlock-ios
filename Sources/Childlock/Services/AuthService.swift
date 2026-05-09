import Foundation
import Observation
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif

@MainActor
@Observable
public final class AuthService {
    public static let shared = AuthService()

    public enum AuthState: Equatable {
        case unknown
        case signedOut
        case signedIn(userID: String)
    }

    public private(set) var state: AuthState = .unknown

    private let secureStore: SecureStore
    private static let userIDKey = "apple_user_id"

    public init(secureStore: SecureStore = KeychainSecureStore()) {
        self.secureStore = secureStore
        checkExistingCredential()
    }

    public var isSignedIn: Bool {
        if case .signedIn = state { return true }
        return false
    }

    public var userID: String? {
        if case .signedIn(let id) = state { return id }
        return nil
    }

    // MARK: - Credential Check

    private func checkExistingCredential() {
        guard let storedData = secureStore.load(key: Self.userIDKey),
              let storedUserID = String(data: storedData, encoding: .utf8)
        else {
            state = .signedOut
            return
        }

        #if canImport(AuthenticationServices)
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: storedUserID) { [weak self] credentialState, _ in
            Task { @MainActor in
                switch credentialState {
                case .authorized:
                    self?.state = .signedIn(userID: storedUserID)
                case .revoked, .notFound:
                    self?.secureStore.delete(key: Self.userIDKey)
                    self?.state = .signedOut
                default:
                    self?.state = .signedIn(userID: storedUserID)
                }
            }
        }
        #else
        state = .signedIn(userID: storedUserID)
        #endif
    }

    // MARK: - Sign In / Out

    public func handleSignIn(userID: String, email: String?, fullName: PersonNameComponents?) {
        if let data = userID.data(using: .utf8) {
            secureStore.save(key: Self.userIDKey, data: data)
        }
        state = .signedIn(userID: userID)
    }

    public func signOut() {
        secureStore.delete(key: Self.userIDKey)
        state = .signedOut
    }
}
