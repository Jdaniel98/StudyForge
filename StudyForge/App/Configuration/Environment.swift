import Foundation

enum AppEnvironment {
    case debug
    case release

    static var current: AppEnvironment {
        #if DEBUG
        .debug
        #else
        .release
        #endif
    }

    var isDebug: Bool { self == .debug }
}

// MARK: - Supabase Configuration (Phase 3)
// Placeholder — not used in Phase 1. Will read from Supabase.plist.

enum SupabaseConfig {
    static var url: String {
        guard let url = configValue(for: "SUPABASE_URL") else {
            #if DEBUG
            return "http://127.0.0.1:54321"
            #else
            fatalError("SUPABASE_URL not found in Supabase.plist")
            #endif
        }
        return url
    }

    static var anonKey: String {
        guard let key = configValue(for: "SUPABASE_ANON_KEY") else {
            #if DEBUG
            return ""
            #else
            fatalError("SUPABASE_ANON_KEY not found in Supabase.plist")
            #endif
        }
        return key
    }

    private static func configValue(for key: String) -> String? {
        guard let path = Bundle.main.path(forResource: "Supabase", ofType: "plist"),
              let dict = NSDictionary(contentsOfFile: path) else {
            return nil
        }
        return dict[key] as? String
    }
}
