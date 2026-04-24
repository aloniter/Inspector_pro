import Foundation

enum Configuration {
    private static let config: [String: Any] = {
        guard let url = Bundle.main.url(forResource: "SupabaseConfig", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            return [:]
        }
        return dict
    }()

    static var supabaseURL: String {
        guard let value = config["SUPABASE_URL"] as? String,
              !value.isEmpty,
              !value.contains("your-project") else {
            return ""
        }
        return value
    }

    static var supabaseAnonKey: String {
        guard let value = config["SUPABASE_ANON_KEY"] as? String,
              !value.isEmpty,
              value != "your-anon-key-here" else {
            return ""
        }
        return value
    }

    static var isSupabaseConfigured: Bool {
        !supabaseURL.isEmpty && !supabaseAnonKey.isEmpty
    }
}
