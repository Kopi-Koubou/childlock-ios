#if canImport(AuthenticationServices)
import SwiftUI
import AuthenticationServices

public struct SignInWithAppleButtonView: View {
    let onSuccess: (String, String?, PersonNameComponents?) -> Void
    let onError: (Error) -> Void

    public init(
        onSuccess: @escaping (String, String?, PersonNameComponents?) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        self.onSuccess = onSuccess
        self.onError = onError
    }

    public var body: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.email, .fullName]
        } onCompletion: { result in
            switch result {
            case .success(let auth):
                if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                    onSuccess(
                        credential.user,
                        credential.email,
                        credential.fullName
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
}
#endif
