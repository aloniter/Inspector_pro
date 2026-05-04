import Foundation
import Supabase

@Observable
final class AuthService {
    var isAuthenticated = false
    var isCheckingSession = true   // true until initial session check completes
    var currentUserID: String?
    var currentUserEmail: String?

    private var stateListenerTask: Task<Void, Never>?
    private var sessionTimeoutTask: Task<Void, Never>?

    init() {
        sessionTimeoutTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(8))
            await MainActor.run { [weak self] in
                guard let self, self.isCheckingSession else { return }
                self.isAuthenticated = false
                self.isCheckingSession = false
            }
        }
        stateListenerTask = Task { [weak self] in
            await self?.observeAuthState()
        }
    }

    deinit {
        sessionTimeoutTask?.cancel()
        stateListenerTask?.cancel()
    }

    // MARK: - Public API

    func signIn(email: String, password: String) async throws {
        guard let client = SupabaseManager.client else {
            throw AuthServiceError.notConfigured
        }
        try await client.auth.signIn(email: email, password: password)
    }

    func signOut() async {
        await clearLocalSessionState()

        guard let client = SupabaseManager.client else { return }
        do {
            try await client.auth.signOut()
            #if DEBUG
            print("✅ User signed out")
            #endif
        } catch {
            #if DEBUG
            print("❌ signOut failed: \(error)")
            #endif
        }
    }

    private func clearLocalSessionState() async {
        await ExportPermissionService.shared.clearCache()
        await CompanyBrandingService.shared.clearCache()
        await MainActor.run {
            isAuthenticated = false
            isCheckingSession = false
            currentUserID = nil
            currentUserEmail = nil
        }
    }

    // MARK: - Private

    private func observeAuthState() async {
        guard let client = SupabaseManager.client else {
            await MainActor.run {
                isCheckingSession = false
                isAuthenticated = false
            }
            return
        }

        for await (event, session) in client.auth.authStateChanges {
            let authenticatedSession: Session?
            switch event {
            case .initialSession, .signedIn, .tokenRefreshed, .userUpdated:
                authenticatedSession = Self.sessionUsableForAuthentication(session)
            case .signedOut, .userDeleted:
                authenticatedSession = nil
            default:
                continue
            }

            await MainActor.run {
                sessionTimeoutTask?.cancel()
                let authenticated = authenticatedSession != nil
                isAuthenticated = authenticated
                isCheckingSession = false
                currentUserID = authenticatedSession?.user.id.uuidString
                currentUserEmail = authenticatedSession?.user.email
            }
        }
    }

    static func sessionUsableForAuthentication(_ session: Session?) -> Session? {
        guard let session, !session.isExpired else { return nil }
        return session
    }
}

enum AuthServiceError: LocalizedError {
    case notConfigured

    var errorDescription: String? {
        AppStrings.text("מערכת האימות אינה מוגדרת. יש לפנות לתמיכה.")
    }
}
