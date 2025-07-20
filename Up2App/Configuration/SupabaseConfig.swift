import Foundation

// MARK: - Supabase Configuration
struct SupabaseConfig {
    
    // MARK: - Configuration Constants
    static let supabaseURL: String = {
        // TODO: Replace with your actual Supabase project URL
        // Format: https://your-project-id.supabase.co
        return "https://demo.supabase.co"
    }()
    
    static let supabaseAnonKey: String = {
        // TODO: Replace with your actual Supabase anon key
        // This is safe to use in client-side code
        return "demoAnonKey1234567890abcdef"
    }()
    
    // MARK: - Validation
    static var isConfigured: Bool {
        return !supabaseURL.contains("YOUR_SUPABASE") && 
               !supabaseAnonKey.contains("YOUR_SUPABASE")
    }
    
    // MARK: - Development Mode Check
    static func printConfigurationWarning() {
        if !isConfigured {
            print("⚠️ SUPABASE NOT CONFIGURED ⚠️")
            print("Please update SupabaseConfig.swift with your actual Supabase credentials.")
            print("The app will use mock authentication until configured.")
            print("Visit: https://app.supabase.com to get your project credentials.")
        }
    }
    
    // MARK: - Configuration Validation
    static func validateConfiguration() throws {
        guard isConfigured else {
            throw ConfigurationError.missingSupabaseCredentials
        }
        
        guard let url = URL(string: supabaseURL) else {
            throw ConfigurationError.invalidSupabaseURL
        }
        
        guard supabaseAnonKey.count > 20 else {
            throw ConfigurationError.invalidSupabaseKey
        }
    }
}

// MARK: - Configuration Errors
enum ConfigurationError: LocalizedError {
    case missingSupabaseCredentials
    case invalidSupabaseURL
    case invalidSupabaseKey
    
    var errorDescription: String? {
        switch self {
        case .missingSupabaseCredentials:
            return "Supabase credentials not configured. Please update SupabaseConfig.swift with your project credentials."
        case .invalidSupabaseURL:
            return "Invalid Supabase URL format. Please check your configuration."
        case .invalidSupabaseKey:
            return "Invalid Supabase key format. Please check your configuration."
        }
    }
} 