import Foundation
import Supabase
import Network

// MARK: - Supabase Configuration
struct SupabaseConfig {
    
    // MARK: - Configuration Constants
    static let supabaseURL: String = "https://lwyyvorwlqmxmssuwzim.supabase.co"
    
    static let supabaseAnonKey: String = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imx3eXl2b3J3bHFteG1zc3V3emltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI2NDQ1NzUsImV4cCI6MjA2ODIyMDU3NX0.lsqP0r4aaPYaOdsMB7N9GoHIGFm3oKdiCCRzSD0iJtk"
    
    // MARK: - Validation
    static var isConfigured: Bool {
        return true
    }
    
    // MARK: - Development Mode Check
    static func printConfigurationWarning() {
        print("✅ Supabase configured with real project credentials")
        print("📊 Project ID: lwyyvorwlqmxmssuwzim")
        print("🔗 URL: \(supabaseURL)")
    }
    
    // MARK: - Configuration Validation
    static func validateConfiguration() throws {
        guard isConfigured else {
            throw ConfigurationError.missingSupabaseCredentials
        }
        
        guard URL(string: supabaseURL) != nil else {
            throw ConfigurationError.invalidSupabaseURL
        }
        
        guard supabaseAnonKey.count > 20 else {
            throw ConfigurationError.invalidSupabaseKey
        }
    }
}

// MARK: - Supabase Manager
final class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isNetworkAvailable: Bool = true
    
    private init() {
        let supabaseUrl = URL(string: SupabaseConfig.supabaseURL)!
        let supabaseKey = SupabaseConfig.supabaseAnonKey
        
        // Create basic client without custom options
        client = SupabaseClient(
            supabaseURL: supabaseUrl,
            supabaseKey: supabaseKey
        )
        
        // Print configuration warning
        SupabaseConfig.printConfigurationWarning()
        
        // Start network monitoring
        startNetworkMonitoring()
        
        // Test connection
        Task {
            await testConnection()
        }
    }
    
    // MARK: - Network Monitoring
    private func startNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isNetworkAvailable = path.status == .satisfied
                print("🌐 Network status: \(path.status == .satisfied ? "Connected" : "Disconnected")")
            }
        }
        networkMonitor.start(queue: networkQueue)
    }
    
    // MARK: - Connection Testing
    private func testConnection() async {
        guard isNetworkAvailable else {
            print("⚠️ Network not available, skipping connection test")
            return
        }
        
        do {
            // Try a simple query to test connection
            let _: [String] = try await client
                .from("users")
                .select("id")
                .limit(1)
                .execute()
                .value
            print("✅ Supabase connection test successful")
        } catch {
            print("⚠️ Supabase connection test failed: \(error)")
        }
    }
    
    // MARK: - Public Methods
    func checkNetworkConnectivity() -> Bool {
        return isNetworkAvailable
    }
    
    deinit {
        networkMonitor.cancel()
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
            return "Supabase credentials not configured. Please set SUPABASE_URL and SUPABASE_ANON_KEY environment variables."
        case .invalidSupabaseURL:
            return "Invalid Supabase URL format. Please check your configuration."
        case .invalidSupabaseKey:
            return "Invalid Supabase key format. Please check your configuration."
        }
    }
} 