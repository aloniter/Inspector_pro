import Foundation
import UIKit
import Supabase

// MARK: - Cached branding model

struct CompanyBranding: Codable {
    let name: String
    let footerAddressLine: String
    let primaryFooterLinePDF: String
    let primaryFooterLineDOCX: String
    let secondaryFooterLine: String
    let showLogoInReport: Bool
    let showFooterInReport: Bool
    /// Remote logo URL from Supabase. Used to detect URL changes and skip redundant downloads.
    let logoURL: String?
    let cachedAt: Date
}

// MARK: - Service

actor CompanyBrandingService {

    static let shared = CompanyBrandingService()

    private let cacheTTL: TimeInterval = 6 * 60 * 60   // 6 hours
    private let brandingKey = "companyBranding.data"
    private let logoFileName = "remote_logo.jpg"

    // MARK: - Public API

    /// Fetches fresh branding from Supabase and caches it.
    /// Skips the network call if the cache is still valid (< 6 hours old).
    func syncIfNeeded() async {
        guard !isCacheValid() else { return }
        await fetchAndCache()
    }

    /// Forces a fresh fetch regardless of cache age. Use on login.
    func syncForced() async {
        await fetchAndCache()
    }

    /// Clears cached branding and any downloaded logo. Call on logout.
    func clearCache() {
        UserDefaults.standard.removeObject(forKey: brandingKey)
        FileManagerService.shared.deleteItem(at: logoFileURL)
    }

    // MARK: - Synchronous cache reads (safe — UserDefaults and FileManager are thread-safe)

    /// Returns the cached CompanyBranding, or nil if not yet fetched.
    nonisolated func loadCached() -> CompanyBranding? {
        guard let data = UserDefaults.standard.data(forKey: brandingKey) else { return nil }
        return try? JSONDecoder().decode(CompanyBranding.self, from: data)
    }

    /// Returns the locally cached logo image data, or nil if no logo is available.
    nonisolated func cachedLogoImageData() -> Data? {
        let url = AppConstants.brandingAssetsURL.appendingPathComponent("remote_logo.jpg")
        return try? Data(contentsOf: url)
    }

    // MARK: - Private helpers

    private var logoFileURL: URL {
        AppConstants.brandingAssetsURL.appendingPathComponent(logoFileName)
    }

    private struct ProfileRow: Decodable {
        let company_id: UUID
    }

    private struct CompanyRow: Decodable {
        let name: String
        let logo_url: String?
        let footer_address_line: String
        let primary_footer_line_pdf: String
        let primary_footer_line_docx: String
        let secondary_footer_line: String
        let show_logo_in_report: Bool
        let show_footer_in_report: Bool
    }

    private func fetchAndCache() async {
        guard let client = SupabaseManager.client,
              let userID = await currentUserID(client: client) else { return }

        do {
            let profiles: [ProfileRow] = try await client
                .from("profiles")
                .select("company_id")
                .eq("id", value: userID)
                .execute()
                .value

            guard let profile = profiles.first else { return }

            #if DEBUG
            print("[CompanyBranding] user_id=\(userID.uuidString) company_id=\(profile.company_id.uuidString)")
            #endif

            let companies: [CompanyRow] = try await client
                .from("companies")
                .select("name,logo_url,footer_address_line,primary_footer_line_pdf,primary_footer_line_docx,secondary_footer_line,show_logo_in_report,show_footer_in_report")
                .eq("id", value: profile.company_id)
                .execute()
                .value

            guard let company = companies.first else { return }

            await downloadLogoIfNeeded(logoURL: company.logo_url)

            let branding = CompanyBranding(
                name: company.name,
                footerAddressLine: company.footer_address_line,
                primaryFooterLinePDF: company.primary_footer_line_pdf,
                primaryFooterLineDOCX: company.primary_footer_line_docx,
                secondaryFooterLine: company.secondary_footer_line,
                showLogoInReport: company.show_logo_in_report,
                showFooterInReport: company.show_footer_in_report,
                logoURL: company.logo_url,
                cachedAt: Date()
            )

            if let encoded = try? JSONEncoder().encode(branding) {
                UserDefaults.standard.set(encoded, forKey: brandingKey)
            }

            #if DEBUG
            print("[CompanyBrandingService] Synced: \(branding.name)")
            #endif
        } catch {
            #if DEBUG
            print("[CompanyBrandingService] Sync failed: \(error)")
            #endif
        }
    }

    private func downloadLogoIfNeeded(logoURL: String?) async {
        // No remote logo → remove any previously cached file
        guard let urlString = logoURL, !urlString.isEmpty, let url = URL(string: urlString) else {
            FileManagerService.shared.deleteItem(at: logoFileURL)
            return
        }

        // Already have this exact logo cached — skip download
        let existingBranding = loadCached()
        if FileManagerService.shared.fileExists(at: logoFileURL),
           existingBranding?.logoURL == urlString {
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { return }
            let compressed = image.thumbnail(maxSize: AppConstants.brandingLogoMaxSize)
            guard let jpegData = compressed.jpegDataStripped(quality: AppConstants.brandingLogoJPEGQuality) else { return }
            FileManagerService.shared.ensureDirectoryExists(at: AppConstants.brandingAssetsURL)
            try jpegData.write(to: logoFileURL, options: .atomic)
            #if DEBUG
            print("[CompanyBrandingService] Logo downloaded")
            #endif
        } catch {
            #if DEBUG
            print("[CompanyBrandingService] Logo download failed: \(error)")
            #endif
        }
    }

    private func isCacheValid() -> Bool {
        guard let branding = loadCached() else { return false }
        return Date().timeIntervalSince(branding.cachedAt) < cacheTTL
    }

    private func currentUserID(client: SupabaseClient) async -> UUID? {
        if let session = try? await client.auth.session {
            return session.user.id
        }
        return client.auth.currentUser?.id
    }
}
