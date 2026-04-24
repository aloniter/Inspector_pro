import Foundation
import Supabase

// MARK: - Result

enum ExportPermissionResult {
    case allowed
    case deniedTrialExpired
    case deniedSuspended
    case deniedExportDisabled
    case cannotVerifyOffline
    case notLoggedIn
    case backendError(String)

    var isAllowed: Bool { self == .allowed }

    /// Hebrew message to display when export is blocked.
    var hebrewDenialMessage: String? {
        switch self {
        case .allowed:
            return nil
        case .deniedTrialExpired:
            return "תקופת הניסיון הסתיימה. צור קשר עם הנהלת המערכת להפעלת החשבון."
        case .deniedSuspended, .deniedExportDisabled:
            return "אפשרות הייצוא אינה פעילה בחשבון זה. יש לפנות לתמיכה להפעלה מחדש."
        case .cannotVerifyOffline:
            return "לא ניתן לאמת הרשאות ייצוא. נסה שוב כשיש חיבור לאינטרנט."
        case .notLoggedIn:
            return "יש להתחבר לחשבון כדי לייצא דוחות."
        case .backendError:
            return "שגיאה באימות הרשאות ייצוא. נסה שוב מאוחר יותר."
        }
    }
}

extension ExportPermissionResult: Equatable {
    static func == (lhs: ExportPermissionResult, rhs: ExportPermissionResult) -> Bool {
        switch (lhs, rhs) {
        case (.allowed, .allowed),
             (.deniedTrialExpired, .deniedTrialExpired),
             (.deniedSuspended, .deniedSuspended),
             (.deniedExportDisabled, .deniedExportDisabled),
             (.cannotVerifyOffline, .cannotVerifyOffline),
             (.notLoggedIn, .notLoggedIn):
            return true
        case (.backendError(let a), .backendError(let b)):
            return a == b
        default:
            return false
        }
    }
}

// MARK: - Service

actor ExportPermissionService {

    static let shared = ExportPermissionService()

    private let cacheTTL: TimeInterval = 6 * 60 * 60  // 6 hours

    // UserDefaults keys
    private let keyAllowed      = "exportPerm.allowed"
    private let keyStatus       = "exportPerm.paymentStatus"
    private let keyTrialEnd     = "exportPerm.trialEndDate"
    private let keyCheckedAt    = "exportPerm.checkedAt"
    private let keyUserID       = "exportPerm.userID"

    // MARK: - Public

    /// Returns the current export permission, fetching fresh if possible, using cache if offline.
    func checkExportAllowed() async -> ExportPermissionResult {
        guard let client = SupabaseManager.client else {
            return .notLoggedIn
        }

        // Get current user
        guard let userID = await currentUserID(client: client) else {
            clearCache()
            return .notLoggedIn
        }

        // Invalidate cache if the logged-in user changed
        if cachedUserID != userID.uuidString {
            clearCache()
        }

        // Try to fetch fresh from network
        if let fresh = await fetchFromNetwork(client: client, userID: userID) {
            cacheResult(fresh, userID: userID.uuidString)
            return evaluate(fresh)
        }

        // Network failed — use cache if still valid
        if let cached = loadCachedData(), isCacheValid() {
            return evaluate(cached)
        }

        // No valid cache and no network
        return .cannotVerifyOffline
    }

    /// Call this on logout to wipe the permission cache.
    func clearCache() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: keyAllowed)
        defaults.removeObject(forKey: keyStatus)
        defaults.removeObject(forKey: keyTrialEnd)
        defaults.removeObject(forKey: keyCheckedAt)
        defaults.removeObject(forKey: keyUserID)
    }

    // MARK: - Network fetch

    private struct ProfileRow: Decodable {
        let company_id: UUID
    }

    private struct CompanyRow: Decodable {
        let export_allowed: Bool
        let payment_status: String
        let trial_end_date: String?
    }

    private struct PermissionData {
        let exportAllowed: Bool
        let paymentStatus: String
        let trialEndDate: Date?
    }

    /// Returns a synchronous snapshot of the cached permission result, or nil if no cache exists.
    nonisolated func cachedResult() -> ExportPermissionResult? {
        guard let data = loadCachedDataSync() else { return nil }
        return evaluateSync(data)
    }

    /// Cached trial end date as a display string (yyyy-MM-dd), or nil.
    nonisolated func cachedTrialEndDateString() -> String? {
        let interval = UserDefaults.standard.double(forKey: keyTrialEnd)
        guard interval > 0 else { return nil }
        let date = Date(timeIntervalSince1970: interval)
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "he")
        return formatter.string(from: date)
    }

    private func fetchFromNetwork(client: SupabaseClient, userID: UUID) async -> PermissionData? {
        do {
            // 1. Fetch profile to get company_id
            let profiles: [ProfileRow] = try await client
                .from("profiles")
                .select("company_id")
                .eq("id", value: userID)
                .execute()
                .value

            guard let profile = profiles.first else { return nil }

            #if DEBUG
            print("[ExportPermission] user_id=\(userID.uuidString) company_id=\(profile.company_id.uuidString)")
            #endif

            // 2. Fetch company data
            let companies: [CompanyRow] = try await client
                .from("companies")
                .select("export_allowed,payment_status,trial_end_date")
                .eq("id", value: profile.company_id)
                .execute()
                .value

            guard let company = companies.first else { return nil }

            let trialEndDate = company.trial_end_date.flatMap { parseDateString($0) }
            let data = PermissionData(
                exportAllowed: company.export_allowed,
                paymentStatus: company.payment_status,
                trialEndDate: trialEndDate
            )

            #if DEBUG
            let result = evaluateSync(data)
            print("[ExportPermission] result=\(result) export_allowed=\(company.export_allowed) status=\(company.payment_status) trial_end=\(company.trial_end_date ?? "nil")")
            #endif

            return data
        } catch {
            #if DEBUG
            print("[ExportPermission] Network fetch failed: \(error)")
            #endif
            return nil
        }
    }

    // MARK: - Evaluate

    // nonisolated variant so cachedResult() can call it without crossing the actor boundary
    private nonisolated func evaluateSync(_ data: PermissionData) -> ExportPermissionResult {
        if data.paymentStatus == "suspended"  { return .deniedSuspended }
        if data.paymentStatus == "expired"    { return .deniedTrialExpired }
        if data.paymentStatus == "trial", let end = data.trialEndDate, end < Date() { return .deniedTrialExpired }
        if !data.exportAllowed                { return .deniedExportDisabled }
        return .allowed
    }

    private func evaluate(_ data: PermissionData) -> ExportPermissionResult {
        // Suspended always blocks
        if data.paymentStatus == "suspended" {
            return .deniedSuspended
        }

        // Expired status blocks
        if data.paymentStatus == "expired" {
            return .deniedTrialExpired
        }

        // Trial with past end date blocks
        if data.paymentStatus == "trial", let end = data.trialEndDate, end < Date() {
            return .deniedTrialExpired
        }

        // Master kill switch
        if !data.exportAllowed {
            return .deniedExportDisabled
        }

        return .allowed
    }

    // MARK: - Cache

    private func cacheResult(_ data: PermissionData, userID: String) {
        let defaults = UserDefaults.standard
        defaults.set(data.exportAllowed, forKey: keyAllowed)
        defaults.set(data.paymentStatus, forKey: keyStatus)
        defaults.set(data.trialEndDate?.timeIntervalSince1970, forKey: keyTrialEnd)
        defaults.set(Date().timeIntervalSince1970, forKey: keyCheckedAt)
        defaults.set(userID, forKey: keyUserID)
    }

    private nonisolated func loadCachedDataSync() -> PermissionData? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: keyAllowed) != nil,
              let status = defaults.string(forKey: keyStatus) else { return nil }
        let exportAllowed = defaults.bool(forKey: keyAllowed)
        let trialEndInterval = defaults.double(forKey: keyTrialEnd)
        let trialEndDate = trialEndInterval > 0 ? Date(timeIntervalSince1970: trialEndInterval) : nil
        return PermissionData(exportAllowed: exportAllowed, paymentStatus: status, trialEndDate: trialEndDate)
    }

    private func loadCachedData() -> PermissionData? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: keyAllowed) != nil,
              let status = defaults.string(forKey: keyStatus) else {
            return nil
        }
        let exportAllowed = defaults.bool(forKey: keyAllowed)
        let trialEndInterval = defaults.double(forKey: keyTrialEnd)
        let trialEndDate = trialEndInterval > 0 ? Date(timeIntervalSince1970: trialEndInterval) : nil
        return PermissionData(exportAllowed: exportAllowed, paymentStatus: status, trialEndDate: trialEndDate)
    }

    private func isCacheValid() -> Bool {
        let checkedAt = UserDefaults.standard.double(forKey: keyCheckedAt)
        guard checkedAt > 0 else { return false }
        return Date().timeIntervalSince1970 - checkedAt < cacheTTL
    }

    private var cachedUserID: String? {
        UserDefaults.standard.string(forKey: keyUserID)
    }

    // MARK: - Helpers

    private func currentUserID(client: SupabaseClient) async -> UUID? {
        guard let session = try? await client.auth.session else { return nil }
        return session.user.id
    }

    private func parseDateString(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.date(from: string)
    }
}
