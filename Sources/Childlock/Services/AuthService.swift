import Foundation
import Observation
import CryptoKit
#if canImport(AuthenticationServices)
import AuthenticationServices
#endif
#if canImport(GoogleSignIn)
import GoogleSignIn
#endif
#if canImport(Supabase)
import Supabase
#endif
#if canImport(UIKit)
import UIKit
#endif
import Security

@MainActor
@Observable
public final class AuthService {
    public static let shared = AuthService()
    public static let oauthRedirectURL = URL(string: "childlock://login-callback")!

    public enum AuthState: Equatable {
        case unknown
        case signedOut
        case signedIn(userID: String)
    }

    public private(set) var state: AuthState = .unknown
    public private(set) var lastErrorMessage: String?

    private let secureStore: SecureStore
    private static let authUserIDKey = "auth_user_id"
    private static let appleUserIDKey = "apple_user_id"
    private static let authProviderKey = "auth_provider"

    private enum AuthProvider: String {
        case apple
        case google
        case external
        case debug
    }

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

    public static func isOAuthRedirectURL(_ url: URL) -> Bool {
        guard
            let expectedScheme = oauthRedirectURL.scheme,
            url.scheme?.caseInsensitiveCompare(expectedScheme) == .orderedSame
        else {
            return false
        }

        return url.host == oauthRedirectURL.host && url.path == oauthRedirectURL.path
    }

    // MARK: - Credential Check

    private func checkExistingCredential() {
        let storedAuthUserID = secureStore.loadString(key: Self.authUserIDKey)
        let storedAppleUserID = secureStore.loadString(key: Self.appleUserIDKey)
        let storedProvider = secureStore.loadString(key: Self.authProviderKey).flatMap(AuthProvider.init(rawValue:))

        guard storedProvider == .apple || storedAppleUserID != nil else {
            if let storedAuthUserID {
                state = .signedIn(userID: storedAuthUserID)
            } else {
                state = .signedOut
            }
            return
        }

        guard let storedAppleUserID else {
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
                    self?.secureStore.delete(key: Self.authProviderKey)
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
    ) async -> Bool {
        #if canImport(Supabase)
        if BackendConfig.current.isSupabaseConfigured {
            guard
                let client = SupabaseClientProvider.shared,
                let identityToken,
                let rawNonce
            else {
                failSignIn("Account setup could not be completed. Please try again.")
                return false
            }

            do {
                let session = try await client.auth.signInWithIdToken(
                    credentials: OpenIDConnectCredentials(
                        provider: .apple,
                        idToken: identityToken,
                        nonce: rawNonce
                    )
                )
                completeSupabaseSignIn(session: session, provider: .apple, appleUserID: appleUserID)
                if email != nil || fullName != nil {
                    try? await DataSyncService.shared.syncParentProfile(
                        appleUserID: appleUserID,
                        email: email,
                        fullName: fullName
                    )
                }
                return true
            } catch {
                failSignIn("Account setup could not be completed. Please try again.")
                return false
            }
        }
        #endif

        #if DEBUG
        lastErrorMessage = nil
        secureStore.saveString(appleUserID, key: Self.appleUserIDKey)
        secureStore.saveString(appleUserID, key: Self.authUserIDKey)
        secureStore.saveString(AuthProvider.debug.rawValue, key: Self.authProviderKey)
        state = .signedIn(userID: appleUserID)
        return true
        #else
        failSignIn("Account setup is unavailable right now. Please try again later.")
        return false
        #endif
    }

    public func handleGoogleSignIn() async -> Bool {
        #if canImport(Supabase) && canImport(GoogleSignIn) && canImport(UIKit)
        if BackendConfig.current.isSupabaseConfigured {
            guard let client = SupabaseClientProvider.shared else {
                failSignIn("Google sign in could not be started. Please try again.")
                return false
            }

            guard BackendConfig.current.isGoogleSignInConfigured else {
                failSignIn("Google sign in is not available in this build. Please use Sign in with Apple for now.")
                return false
            }

            configureGoogleSignIn()

            guard let presentingViewController = Self.presentingViewController() else {
                failSignIn("Google sign in could not find an active app window. Please try again.")
                return false
            }

            do {
                let rawNonce = try Self.randomNonceString()
                let result = try await Self.signInWithGoogle(
                    presentingViewController: presentingViewController,
                    nonce: Self.sha256(rawNonce)
                )
                guard let idToken = result.user.idToken?.tokenString else {
                    failSignIn("Google sign in could not be completed. Please try again.")
                    return false
                }

                let session = try await client.auth.signInWithIdToken(
                    credentials: OpenIDConnectCredentials(
                        provider: .google,
                        idToken: idToken,
                        accessToken: result.user.accessToken.tokenString,
                        nonce: rawNonce
                    )
                )
                completeSupabaseSignIn(session: session, provider: .google, appleUserID: nil)
                return true
            } catch {
                failSignIn("Google sign in could not be completed. Please try again.")
                return false
            }
        }
        #endif

        failSignIn("Google sign in is unavailable right now. Please try again later.")
        return false
    }

    public func handleGoogleRedirectURL(_ url: URL) -> Bool {
        #if canImport(GoogleSignIn)
        return GIDSignIn.sharedInstance.handle(url)
        #else
        return false
        #endif
    }

    @discardableResult
    public func handleOAuthCallback(_ url: URL) async -> Bool {
        guard Self.isOAuthRedirectURL(url) else { return false }

        #if canImport(Supabase)
        guard let client = SupabaseClientProvider.shared else {
            failSignIn("Account setup could not be completed. Please try again.")
            return false
        }

        do {
            let session = try await client.auth.session(from: url)
            completeSupabaseSignIn(session: session, provider: .external, appleUserID: nil)
            return true
        } catch {
            failSignIn("Account setup could not be completed. Please try again.")
            return false
        }
        #else
        failSignIn("Account setup is unavailable right now. Please try again later.")
        return false
        #endif
    }

    public func signOut() {
        secureStore.delete(key: Self.authUserIDKey)
        secureStore.delete(key: Self.appleUserIDKey)
        secureStore.delete(key: Self.authProviderKey)
        lastErrorMessage = nil
        state = .signedOut

        #if canImport(Supabase)
        if let client = SupabaseClientProvider.shared {
            Task {
                try? await client.auth.signOut()
            }
        }
        #endif

        #if canImport(GoogleSignIn)
        GIDSignIn.sharedInstance.signOut()
        #endif
    }

    #if DEBUG
    public func debugSignIn(userID: String = "childlock-qa-parent") {
        lastErrorMessage = nil
        secureStore.saveString(userID, key: Self.authUserIDKey)
        secureStore.saveString(AuthProvider.debug.rawValue, key: Self.authProviderKey)
        secureStore.delete(key: Self.appleUserIDKey)
        state = .signedIn(userID: userID)
    }
    #endif

    private func failSignIn(_ message: String) {
        secureStore.delete(key: Self.authUserIDKey)
        secureStore.delete(key: Self.appleUserIDKey)
        secureStore.delete(key: Self.authProviderKey)
        lastErrorMessage = message
        state = .signedOut
    }

    #if canImport(Supabase)
    private func completeSupabaseSignIn(session: Session, provider: AuthProvider, appleUserID: String?) {
        let authUserID = session.user.id.uuidString
        secureStore.saveString(authUserID, key: Self.authUserIDKey)
        secureStore.saveString(provider.rawValue, key: Self.authProviderKey)

        if let appleUserID {
            secureStore.saveString(appleUserID, key: Self.appleUserIDKey)
        } else {
            secureStore.delete(key: Self.appleUserIDKey)
        }

        lastErrorMessage = nil
        state = .signedIn(userID: authUserID)

        Task {
            try? await DataSyncService.shared.syncParentProfile(
                appleUserID: appleUserID,
                email: session.user.email,
                fullName: Self.displayName(from: session.user.userMetadata)
            )
        }
    }

    private static func displayName(from metadata: [String: AnyJSON]) -> String? {
        let candidates = [
            metadata["full_name"]?.stringValue,
            metadata["name"]?.stringValue,
            joinedName(
                givenName: metadata["given_name"]?.stringValue,
                familyName: metadata["family_name"]?.stringValue
            )
        ]

        return candidates
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }
    }
    #endif

    #if canImport(GoogleSignIn)
    private func configureGoogleSignIn() {
        guard
            let iosClientID = BackendConfig.current.googleIOSClientID,
            let webClientID = BackendConfig.current.googleWebClientID
        else {
            return
        }

        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: iosClientID,
            serverClientID: webClientID
        )
    }

    #if canImport(UIKit)
    private enum GoogleSignInRuntimeError: Error {
        case missingResult
    }

    private static func signInWithGoogle(
        presentingViewController: UIViewController,
        nonce: String
    ) async throws -> GIDSignInResult {
        try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.signIn(
                withPresenting: presentingViewController,
                hint: nil,
                additionalScopes: nil,
                nonce: nonce
            ) { result, error in
                if let result {
                    continuation.resume(returning: result)
                } else {
                    continuation.resume(throwing: error ?? GoogleSignInRuntimeError.missingResult)
                }
            }
        }
    }
    #endif
    #endif

    private static func joinedName(givenName: String?, familyName: String?) -> String? {
        let components = [givenName, familyName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !components.isEmpty else { return nil }
        return components.joined(separator: " ")
    }

    private enum NonceGenerationError: Error {
        case failed
    }

    private static func randomNonceString(length: Int = 32) throws -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var random: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            guard status == errSecSuccess else {
                throw NonceGenerationError.failed
            }

            if Int(random) < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }

        return result
    }

    private static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.map { String(format: "%02x", $0) }.joined()
    }

    #if canImport(UIKit)
    private static func presentingViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let keyWindow = scenes
            .flatMap(\.windows)
            .first { $0.isKeyWindow }

        var presenter = keyWindow?.rootViewController
        while let presented = presenter?.presentedViewController {
            presenter = presented
        }

        return presenter
    }
    #endif
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
