import Foundation
import Supabase

@Observable
final class AuthService {
    var isAuthenticated = false
    var isCheckingSession = true   // true until initial session check completes

    private var stateListenerTask: Task<Void, Never>?

    init() {
        stateListenerTask = Task { [weak self] in
            await self?.observeAuthState()
        }
    }

    deinit {
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
        await ExportPermissionService.shared.clearCache()
        await CompanyBrandingService.shared.clearCache()
        // Explicit state update — safety net in case authStateChanges stream
        // doesn't fire immediately (e.g. offline or stream lag on device).
        await MainActor.run {
            isAuthenticated = false
            isCheckingSession = false
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

        for await (event, _) in await client.auth.authStateChanges {
            let authenticated: Bool
            switch event {
            case .initialSession, .signedIn, .tokenRefreshed, .userUpdated:
                authenticated = true
            case .signedOut, .userDeleted:
                authenticated = false
            default:
                continue
            }

            await MainActor.run {
                isAuthenticated = authenticated
                isCheckingSession = false
            }
        }
    }
}

enum AuthServiceError: LocalizedError {
    case notConfigured

    var errorDescription: String? {
        "מערכת האימות אינה מוגדרת. יש לפנות לתמיכה."
    }
}
