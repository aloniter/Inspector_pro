import Foundation
import SwiftUI

enum AppConstants {
    static let appDirectoryName = "InspectorPro"
    static let imagesDirectoryName = "Images"
    static let exportCacheDirectoryName = "ExportCache"
    static let exportsDirectoryName = "Exports"
    static let thumbnailMaxSize: CGFloat = 200
    static let thumbnailJPEGQuality: CGFloat = 0.6
    static let importMaxWidth: CGFloat = 2000
    static let gallerySelectionLimit = 100
    static let importSaveCheckpoint = 20

    static var documentsURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var appBaseURL: URL {
        documentsURL.appendingPathComponent(appDirectoryName)
    }

    static var imagesBaseURL: URL {
        appBaseURL.appendingPathComponent(imagesDirectoryName)
    }

    static var exportCacheURL: URL {
        appBaseURL.appendingPathComponent(exportCacheDirectoryName)
    }

    static var exportsURL: URL {
        appBaseURL.appendingPathComponent(exportsDirectoryName)
    }
}

enum AppPreferenceKeys {
    static let darkModeEnabled = "app.preference.dark_mode_enabled"
    static let languageCode = "app.preference.language_code"
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case hebrew = "he"
    case english = "en"

    var id: String { rawValue }

    var locale: Locale {
        Locale(identifier: rawValue)
    }

    var layoutDirection: LayoutDirection {
        switch self {
        case .hebrew:
            return .rightToLeft
        case .english:
            return .leftToRight
        }
    }

    var displayTitle: String {
        switch self {
        case .hebrew:
            return AppStrings.text("עברית")
        case .english:
            return "English"
        }
    }

    static var current: AppLanguage {
        let rawValue = UserDefaults.standard.string(forKey: AppPreferenceKeys.languageCode) ?? AppLanguage.hebrew.rawValue
        return AppLanguage(rawValue: rawValue) ?? .hebrew
    }
}

enum AppStrings {
    static func text(_ key: String) -> String {
        localizedBundle.localizedString(forKey: key, value: key, table: nil)
    }

    static func format(_ key: String, _ args: CVarArg...) -> String {
        let format = text(key)
        return String(format: format, locale: AppLanguage.current.locale, arguments: args)
    }

    private static var localizedBundle: Bundle {
        guard let bundlePath = Bundle.main.path(forResource: AppLanguage.current.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: bundlePath) else {
            return .main
        }
        return bundle
    }
}

enum AppTextDirection {
    static func horizontalAlignment(for direction: LayoutDirection) -> HorizontalAlignment {
        direction == .rightToLeft ? .trailing : .leading
    }

    static func textAlignment(for direction: LayoutDirection) -> TextAlignment {
        direction == .rightToLeft ? .trailing : .leading
    }

    static func frameAlignment(for direction: LayoutDirection) -> Alignment {
        direction == .rightToLeft ? .trailing : .leading
    }
}
