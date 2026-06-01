import Foundation
import Observation
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
#if canImport(Supabase)
import Supabase
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
    private static let authUserIDKey = "auth_user_id"
    private static let appleUserIDKey = "apple_user_id"

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
        let storedAuthUserID = secureStore.loadString(key: Self.authUserIDKey)
        guard let storedAppleUserID = secureStore.loadString(key: Self.appleUserIDKey) else {
            if let storedAuthUserID {
                state = .signedIn(userID: storedAuthUserID)
                return
            }

            state = .signedOut
            return
        }

        #if canImport(AuthenticationServices)
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: storedAppleUserID) { [weak self] credentialState, _ in
            Task { @MainActor in
                switch credentialState {
                case .authorized:
                    self?.state = .signedIn(userID: storedAuthUserID ?? storedAppleUserID)
                case .revoked, .notFound:
                    self?.secureStore.delete(key: Self.authUserIDKey)
                    self?.secureStore.delete(key: Self.appleUserIDKey)
                    self?.state = .signedOut
                default:
                    self?.state = .signedIn(userID: storedAuthUserID ?? storedAppleUserID)
                }
            }
        }
        #else
        state = .signedIn(userID: storedAuthUserID ?? storedAppleUserID)
        #endif
    }

    // MARK: - Sign In / Out

    public func handleSignIn(
        userID appleUserID: String,
        email: String?,
        fullName: PersonNameComponents?,
        identityToken: String? = nil,
        rawNonce: String? = nil
    ) async {
        secureStore.saveString(appleUserID, key: Self.appleUserIDKey)

        #if canImport(Supabase)
        if
            let client = SupabaseClientProvider.shared,
            let identityToken,
            let rawNonce
        {
            do {
                let session = try await client.auth.signInWithIdToken(
                    credentials: OpenIDConnectCredentials(
                        provider: .apple,
                        idToken: identityToken,
                        nonce: rawNonce
                    )
                )
                let authUserID = session.user.id.uuidString
                secureStore.saveString(authUserID, key: Self.authUserIDKey)
                state = .signedIn(userID: authUserID)

                try? await DataSyncService.shared.syncParentProfile(
                    appleUserID: appleUserID,
                    email: email,
                    fullName: fullName
                )
                return
            } catch {
                // Keep the app usable offline/local if the backend is temporarily unavailable.
            }
        }
        #endif

        secureStore.saveString(appleUserID, key: Self.authUserIDKey)
        state = .signedIn(userID: appleUserID)
    }

    public func signOut() {
        secureStore.delete(key: Self.authUserIDKey)
        secureStore.delete(key: Self.appleUserIDKey)
        state = .signedOut

        #if canImport(Supabase)
        if let client = SupabaseClientProvider.shared {
            Task {
                try? await client.auth.signOut()
            }
        }
        #endif
    }
}

private extension SecureStore {
    func loadString(key: String) -> String? {
        guard let data = load(key: key) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func saveString(_ value: String, key: String) {
        guard let data = value.data(using: .utf8) else { return }
        save(key: key, data: data)
    }
}
