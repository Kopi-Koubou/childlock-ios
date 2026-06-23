import Foundation
import Observation
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
                completeSupabaseSignIn(session: session, appleUserID: appleUserID)
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
                failSignIn("Google sign in is not configured yet. Add the Google iOS client ID and URL scheme, then try again.")
                return false
            }

            guard let presentingViewController = Self.presentingViewController() else {
                failSignIn("Google sign in could not find an active app window. Please try again.")
                return false
            }

            do {
                let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
                guard let idToken = result.user.idToken?.tokenString else {
                    failSignIn("Google did not return an identity token. Check the Google iOS client and Supabase provider settings.")
                    return false
                }

                let session = try await client.auth.signInWithIdToken(
                    credentials: OpenIDConnectCredentials(
                        provider: .google,
                        idToken: idToken,
                        accessToken: result.user.accessToken.tokenString
                    )
                )
                completeSupabaseSignIn(session: session, appleUserID: nil)
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
            completeSupabaseSignIn(session: session, appleUserID: nil)
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
        secureStore.delete(key: Self.appleUserIDKey)
        state = .signedIn(userID: userID)
    }
    #endif

    private func failSignIn(_ message: String) {
        secureStore.delete(key: Self.authUserIDKey)
        secureStore.delete(key: Self.appleUserIDKey)
        lastErrorMessage = message
        state = .signedOut
    }

    #if canImport(Supabase)
    private func completeSupabaseSignIn(session: Session, appleUserID: String?) {
        let authUserID = session.user.id.uuidString
        secureStore.saveString(authUserID, key: Self.authUserIDKey)

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

    private static func joinedName(givenName: String?, familyName: String?) -> String? {
        let components = [givenName, familyName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !components.isEmpty else { return nil }
        return components.joined(separator: " ")
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
