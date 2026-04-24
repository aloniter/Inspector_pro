import Foundation
import Supabase

enum SupabaseManager {
    private(set) static var client: SupabaseClient? = {
        guard Configuration.isSupabaseConfigured,
              let url = URL(string: Configuration.supabaseURL) else {
            #if DEBUG
            print("❌ Supabase config missing or invalid")
            #endif
            return nil
        }

        let client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: Configuration.supabaseAnonKey
        )

        #if DEBUG
        print("✅ Supabase client initialized")
        #endif

        return client
    }()

    static var isAvailable: Bool {
        client != nil
    }
}
