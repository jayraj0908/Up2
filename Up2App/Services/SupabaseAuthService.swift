import Foundation
import Supabase

// MARK: - Authentication Service
@MainActor
class SupabaseAuthService: ObservableObject {
    static let shared = SupabaseAuthService()
    
    // MARK: - Supabase Client
    private let supabaseClient: SupabaseClient
    
    // Public access to Supabase client for other services
    internal var supabase: SupabaseClient { supabaseClient }
    
    // MARK: - Session State
    @Published var currentSession: Session?
    @Published var currentUser: AuthUser?
    @Published var isLoading: Bool = false
    
    private init() {
        // Use SupabaseManager for client initialization
        self.supabaseClient = SupabaseManager.shared.client
        
        // Initialize authentication state and set up session listener
        Task {
            await initializeAuthenticationState()
            await setupSessionListener()
        }
    }
    
    // MARK: - Session Reset (FIXED)
    func resetSession() async {
        print("🔄 Resetting session state...")
        
        // Clear local state immediately without making network calls
        await MainActor.run {
            self.currentSession = nil
            self.currentUser = nil
            self.isLoading = false
        }
        
        print("✅ Session reset completed (local state only)")
    }
    
    // MARK: - Session Initialization
    private func initializeAuthenticationState() async {
        do {
            // Try to get existing session from Supabase
            let session = try await supabaseClient.auth.session
            
            // Update current session and user
            await MainActor.run {
                self.currentSession = session
                self.currentUser = AuthUser(from: session.user)
            }
            print("✅ Session restored successfully")
        } catch {
            print("⚠️ Error restoring session: \(error)")
            // Clear any invalid session data
            await MainActor.run {
                self.currentSession = nil
                self.currentUser = nil
            }
        }
    }
    
    // MARK: - User Model
    struct AuthUser {
        let id: String
        let email: String?
        let phone: String?
        var isHost: Bool
        
        // Initialize from Supabase User
        init(from user: Auth.User) {
            self.id = user.id.uuidString
            self.email = user.email
            self.phone = user.phone
            self.isHost = false // Default to false, will be updated from profile
        }
        
        // For testing and mock purposes
        init(id: String, email: String?, phone: String?, isHost: Bool = false) {
            self.id = id
            self.email = email
            self.phone = phone
            self.isHost = isHost
        }
    }
    
    // MARK: - Session Management
    private func setupSessionListener() async {
        // Listen for auth state changes
        for await state in supabaseClient.auth.authStateChanges {
            switch state.event {
            case .signedIn:
                if let session = state.session {
                    self.currentSession = session
                    self.currentUser = AuthUser(from: session.user)
                    print("✅ User signed in successfully")
                }
            case .signedOut:
                self.currentSession = nil
                self.currentUser = nil
                print("✅ User signed out successfully")
            case .tokenRefreshed:
                if let session = state.session {
                    self.currentSession = session
                    self.currentUser = AuthUser(from: session.user)
                    print("✅ Session token refreshed")
                }
            default:
                break
            }
        }
    }
    
    // MARK: - Session State Methods
    var isAuthenticated: Bool {
        return currentSession != nil
    }
    
    func getCurrentUser() async -> AuthUser? {
        return currentUser
    }
    
    func signOut() async throws {
        do {
            // Sign out from Supabase
            try await supabaseClient.auth.signOut()
            
            // Clear local state immediately
            await MainActor.run {
                self.currentSession = nil
                self.currentUser = nil
            }
            
            print("✅ Sign out completed successfully")
        } catch {
            print("❌ Error during sign out: \(error)")
            // Even if Supabase sign out fails, clear local state
            await MainActor.run {
                self.currentSession = nil
                self.currentUser = nil
            }
            throw mapSupabaseError(error)
        }
    }
    
    func refreshSession() async throws {
        do {
            try await supabaseClient.auth.refreshSession()
        } catch {
            print("❌ Error refreshing session: \(error)")
            throw mapSupabaseError(error)
        }
    }
    
    // MARK: - Email/Password Authentication Methods
    func signUpWithEmail(_ email: String, password: String) async throws -> AuthUser {
        await MainActor.run { self.isLoading = true }
        
        do {
            print("🔄 Attempting to sign up user: \(email)")
            
            // Reset session before sign up to ensure clean state
            await resetSession()
            
            let response = try await supabaseClient.auth.signUp(
                    email: email,
                password: password
            )
            
            let user = response.user
            
            // Update current user
            await MainActor.run {
                self.currentUser = AuthUser(from: user)
                self.isLoading = false
            }
            
            print("✅ User signed up successfully: \(user.email ?? "unknown")")
            return AuthUser(from: user)
        } catch {
            await MainActor.run { self.isLoading = false }
            print("❌ Sign up error: \(error)")
            throw mapSupabaseError(error)
        }
    }
    
    func signInWithEmail(_ email: String, password: String) async throws -> AuthUser {
        await MainActor.run { self.isLoading = true }
        
        do {
            print("🔄 Attempting to sign in user: \(email)")
            
            // Reset session before sign in to ensure clean state
            await resetSession()
            
            let response = try await supabaseClient.auth.signIn(
                email: email,
                password: password
            )
            
            let user = response.user
            
            // Update current user
            await MainActor.run {
                self.currentUser = AuthUser(from: user)
                self.isLoading = false
            }
            
            print("✅ User signed in successfully: \(user.email ?? "unknown")")
            return AuthUser(from: user)
        } catch {
            await MainActor.run { self.isLoading = false }
            print("❌ Sign in error: \(error)")
            throw mapSupabaseError(error)
        }
    }
    
    // MARK: - Error Mapping
    private func mapSupabaseError(_ error: Error) -> AuthError {
        // Map Supabase errors to our custom AuthError enum
        let errorString = error.localizedDescription.lowercased()
        let nsError = error as NSError
        
        print("🔍 Mapping error: \(errorString)")
        print("🔍 Error code: \(nsError.code)")
        print("🔍 Error domain: \(nsError.domain)")
        
        // Check for network connectivity issues
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                return .networkError
            case NSURLErrorTimedOut:
                return .networkError
            case NSURLErrorCannotConnectToHost:
                return .networkError
            default:
                break
            }
        }
        
        if errorString.contains("invalid_credentials") || errorString.contains("invalid credentials") {
            return .invalidCredentials
        } else if errorString.contains("user_already_registered") || errorString.contains("already registered") {
            return .userAlreadyExists
        } else if errorString.contains("network") || errorString.contains("connection") || errorString.contains("lost") {
            return .networkError
        } else if errorString.contains("rate_limit") || errorString.contains("too many") {
            return .rateLimitExceeded
        } else if errorString.contains("session") || errorString.contains("token") {
            return .sessionExpired
        } else {
            return .unknownError(error.localizedDescription)
        }
    }
}

// MARK: - Authentication Errors
enum AuthError: LocalizedError {
    case networkError
    case userAlreadyExists
    case invalidCredentials
    case rateLimitExceeded
    case sessionExpired
    case userNotFound
    case signUpFailed(String)
    case signInFailed(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .userAlreadyExists:
            return "An account with this email already exists."
        case .invalidCredentials:
            return "Invalid email or password. Please try again."
        case .rateLimitExceeded:
            return "Too many attempts. Please wait before trying again."
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .userNotFound:
            return "No account found with these credentials."
        case .signUpFailed(let message):
            return "Failed to create account: \(message)"
        case .signInFailed(let message):
            return "Failed to sign in: \(message)"
        case .unknownError(let message):
            return "An error occurred: \(message)"
        }
    }
} 