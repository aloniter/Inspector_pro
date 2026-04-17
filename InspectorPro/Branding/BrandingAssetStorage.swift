import Foundation
import UIKit

enum BrandingAssetStorageError: LocalizedError {
    case compressionFailed

    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to compress branding logo"
        }
    }
}

enum BrandingAssetStorage {
    static let bundledLogoImageData: Data? = try? TemplateExtractor.extract().logoImageData

    static func customLogoURL(forProfileID profileID: UUID) -> URL {
        AppConstants.brandingAssetsURL.appendingPathComponent("\(profileID.uuidString).jpg")
    }

    static func displayLogoImageData(for brandingProfile: BrandingProfile) -> Data? {
        if !brandingProfile.usesBundledDefaultLogo,
           let customLogoData = try? Data(contentsOf: customLogoURL(forProfileID: brandingProfile.id)) {
            return customLogoData
        }

        return bundledLogoImageData
    }

    static func displayLogoImage(for brandingProfile: BrandingProfile?) -> UIImage? {
        let data: Data?

        if let brandingProfile {
            data = displayLogoImageData(for: brandingProfile)
        } else {
            data = bundledLogoImageData
        }

        return data.flatMap(UIImage.init(data:))
    }

    static func saveCustomLogo(_ image: UIImage, for brandingProfile: BrandingProfile) throws {
        let normalizedImage = image.thumbnail(maxSize: AppConstants.brandingLogoMaxSize)
        guard let imageData = normalizedImage.jpegDataStripped(quality: AppConstants.brandingLogoJPEGQuality) else {
            throw BrandingAssetStorageError.compressionFailed
        }

        FileManagerService.shared.ensureDirectoryExists(at: AppConstants.brandingAssetsURL)
        try imageData.write(to: customLogoURL(forProfileID: brandingProfile.id), options: .atomic)
    }

    static func deleteCustomLogo(for brandingProfile: BrandingProfile) {
        FileManagerService.shared.deleteItem(at: customLogoURL(forProfileID: brandingProfile.id))
    }
}
