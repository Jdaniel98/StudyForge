import Foundation
import Combine
import Supabase
import AuthenticationServices

@MainActor
final class AuthService: ObservableObject {
    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated = false
    @Published private(set) var isLoading = false
    @Published var error: AppError?

    private var authStateTask: Task<Void, Never>?

    init() {
        // Check for existing session
        Task {
            await restoreSession()
            listenToAuthChanges()
        }
    }

    deinit {
        authStateTask?.cancel()
    }

    // MARK: - Auth State

    private func restoreSession() async {
        do {
            let session = try await supabaseClient.auth.session
            currentUser = session.user
            isAuthenticated = true
        } catch {
            currentUser = nil
            isAuthenticated = false
        }
    }

    private func listenToAuthChanges() {
        authStateTask = Task { [weak self] in
            for await (event, session) in supabaseClient.auth.authStateChanges {
                guard let self else { return }
                switch event {
                case .signedIn:
                    self.currentUser = session?.user
                    self.isAuthenticated = true
                case .signedOut:
                    self.currentUser = nil
                    self.isAuthenticated = false
                default:
                    break
                }
            }
        }
    }

    // MARK: - Email/Password

    func signUp(email: String, password: String, displayName: String) async {
        isLoading = true
        error = nil
        do {
            let response = try await supabaseClient.auth.signUp(
                email: email,
                password: password,
                data: ["display_name": .string(displayName)]
            )
            currentUser = response.user
            isAuthenticated = true
        } catch {
            self.error = .authFailed(error.localizedDescription)
        }
        isLoading = false
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        error = nil
        do {
            let session = try await supabaseClient.auth.signIn(
                email: email,
                password: password
            )
            currentUser = session.user
            isAuthenticated = true
        } catch {
            self.error = .authFailed(error.localizedDescription)
        }
        isLoading = false
    }

    // MARK: - Apple Sign-In

    func signInWithApple(idToken: String, nonce: String) async {
        isLoading = true
        error = nil
        do {
            let session = try await supabaseClient.auth.signInWithIdToken(
                credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
            )
            currentUser = session.user
            isAuthenticated = true
        } catch {
            self.error = .authFailed(error.localizedDescription)
        }
        isLoading = false
    }

    // MARK: - Sign Out

    func signOut() async {
        do {
            try await supabaseClient.auth.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            self.error = .authFailed(error.localizedDescription)
        }
    }

    // MARK: - Account Deletion (App Store requirement)

    func deleteAccount() async {
        isLoading = true
        error = nil
        do {
            // Delete via RPC (triggers ON DELETE CASCADE for sessions, groups, etc.)
            try await supabaseClient.rpc("delete_own_account").execute()
            try await supabaseClient.auth.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            self.error = .authFailed(error.localizedDescription)
        }
        isLoading = false
    }

    // MARK: - Profile

    func updateDisplayName(_ name: String) async {
        do {
            try await supabaseClient.from("profiles")
                .update(["display_name": name])
                .eq("id", value: currentUser?.id.uuidString ?? "")
                .execute()
        } catch {
            self.error = .authFailed(error.localizedDescription)
        }
    }
}
