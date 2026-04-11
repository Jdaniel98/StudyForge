import SwiftUI
import AuthenticationServices
import CryptoKit

struct AuthView: View {
    @EnvironmentObject private var authService: AuthService
    @Environment(\.colorScheme) private var colorScheme

    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var displayName = ""
    @State private var nonce: String?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Header
            VStack(spacing: Spacing.md) {
                Image(systemName: "book.and.wrench.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(Theme.accentFocus)

                Text("StudyForge")
                    .font(Typography.largeTitle)
                    .foregroundStyle(Theme.textPrimaryFallback(for: colorScheme))

                Text(isSignUp ? "Create an account to sync your data" : "Sign in to sync across devices")
                    .font(Typography.body)
                    .foregroundStyle(Theme.textSecondaryFallback(for: colorScheme))
            }

            Spacer()

            // Form
            VStack(spacing: Spacing.lg) {
                if isSignUp {
                    textField("Display Name", text: $displayName, icon: "person")
                }

                textField("Email", text: $email, icon: "envelope")
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    #endif

                secureField("Password", text: $password, icon: "lock")

                SFButton(
                    isSignUp ? "Create Account" : "Sign In",
                    icon: isSignUp ? "person.badge.plus" : "arrow.right",
                    variant: .primary
                ) {
                    Task {
                        if isSignUp {
                            await authService.signUp(email: email, password: password, displayName: displayName)
                        } else {
                            await authService.signIn(email: email, password: password)
                        }
                    }
                }
                .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
                .opacity(authService.isLoading ? 0.6 : 1)

                // Divider
                HStack {
                    Rectangle()
                        .fill(Theme.borderSubtleFallback(for: colorScheme))
                        .frame(height: 1)
                    Text("or")
                        .font(Typography.caption)
                        .foregroundStyle(Theme.textMutedFallback(for: colorScheme))
                    Rectangle()
                        .fill(Theme.borderSubtleFallback(for: colorScheme))
                        .frame(height: 1)
                }

                // Apple Sign-In
                SignInWithAppleButton(.signIn) { request in
                    let rawNonce = randomNonceString()
                    nonce = rawNonce
                    request.requestedScopes = [.fullName, .email]
                    request.nonce = sha256(rawNonce)
                } onCompletion: { result in
                    handleAppleSignIn(result)
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(height: 48)
                .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
            }
            .padding(.horizontal, Spacing.lg)

            Spacer()

            // Toggle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { isSignUp.toggle() }
            } label: {
                Text(isSignUp ? "Already have an account? **Sign In**" : "Don't have an account? **Sign Up**")
                    .font(Typography.body)
                    .foregroundStyle(Theme.textSecondaryFallback(for: colorScheme))
            }
            .buttonStyle(.plain)
            .padding(.bottom, Spacing.xxl)
        }
        .background(Theme.surfacePrimaryFallback(for: colorScheme).ignoresSafeArea())
        .alert(
            "Error",
            isPresented: Binding(
                get: { authService.error != nil },
                set: { if !$0 { authService.error = nil } }
            ),
            presenting: authService.error
        ) { _ in
            Button("OK") { authService.error = nil }
        } message: { error in
            Text(error.localizedDescription)
        }
        .overlay {
            if authService.isLoading {
                ProgressView()
                    .controlSize(.large)
            }
        }
    }

    // MARK: - Form Fields

    private func textField(_ placeholder: String, text: Binding<String>, icon: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Theme.textMutedFallback(for: colorScheme))
                .frame(width: 20)
            TextField(placeholder, text: text)
                .font(Typography.body)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Theme.surfaceSecondaryFallback(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
    }

    private func secureField(_ placeholder: String, text: Binding<String>, icon: String) -> some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(Theme.textMutedFallback(for: colorScheme))
                .frame(width: 20)
            SecureField(placeholder, text: text)
                .font(Typography.body)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Theme.surfaceSecondaryFallback(for: colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: Theme.radiusMedium))
    }

    // MARK: - Apple Sign-In Helpers

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                  let tokenData = credential.identityToken,
                  let idToken = String(data: tokenData, encoding: .utf8),
                  let nonce else { return }

            Task {
                await authService.signInWithApple(idToken: idToken, nonce: nonce)
            }

        case .failure(let error):
            // User cancelled — don't show an error
            if (error as NSError).code != ASAuthorizationError.canceled.rawValue {
                authService.error = .authFailed(error.localizedDescription)
            }
        }
    }

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthService())
        .preferredColorScheme(.dark)
}
