#if canImport(AuthenticationServices)
import SwiftUI
import AuthenticationServices
import CryptoKit
import Security

public struct SignInWithAppleButtonView: View {
    let onSuccess: (String, String?, PersonNameComponents?, String?, String?) -> Void
    let onError: (Error) -> Void
    @State private var currentNonce: String?

    public init(
        onSuccess: @escaping (String, String?, PersonNameComponents?, String?, String?) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        self.onSuccess = onSuccess
        self.onError = onError
    }

    public var body: some View {
        SignInWithAppleButton(.signIn) { request in
            let nonce = Self.randomNonceString()
            currentNonce = nonce
            request.requestedScopes = [.email, .fullName]
            request.nonce = Self.sha256(nonce)
        } onCompletion: { result in
            switch result {
            case .success(let auth):
                if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                    let identityToken = credential.identityToken.flatMap {
                        String(data: $0, encoding: .utf8)
                    }
                    onSuccess(
                        credential.user,
                        credential.email,
                        credential.fullName,
                        identityToken,
                        currentNonce
                    )
                }
            case .failure(let error):
                onError(error)
            }
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 54)
        .cornerRadius(ChildlockRadius.pill)
    }

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var random: UInt8 = 0
            let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            guard status == errSecSuccess else {
                fatalError("Unable to generate nonce.")
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
}
#endif
