import Foundation
#if canImport(Supabase)
import Supabase
#endif

public enum SupabaseClientProvider {
    #if canImport(Supabase)
    @MainActor
    public static let shared: SupabaseClient? = {
        let config = BackendConfig.current
        guard
            let url = config.supabaseURL,
            let key = config.supabasePublishableKey
        else {
            return nil
        }

        return SupabaseClient(supabaseURL: url, supabaseKey: key)
    }()
    #endif
}
