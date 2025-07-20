import Foundation
import Supabase

// MARK: - Authentication Service
@MainActor
class SupabaseAuthService: ObservableObject {
    static let shared = SupabaseAuthService()
    
    // MARK: - Supabase Client
    private let supabase: SupabaseClient
    
    // Public access to Supabase client for other services
    var supabaseClient: SupabaseClient { supabase }
    
    // MARK: - Session State
    @Published var currentSession: Session?
    @Published var currentUser: AuthUser?
    
    private init() {
        // Print configuration warning if credentials not set
        SupabaseConfig.printConfigurationWarning()
        
        // Initialize Supabase client with configuration
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.supabaseURL)!,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )
        
        // Initialize authentication state and set up session listener
        Task {
            await initializeAuthenticationState()
            await setupSessionListener()
        }
    }
    
    // MARK: - Session Initialization
    private func initializeAuthenticationState() async {
        do {
            // Try to get existing session from Supabase
            let session = try await supabase.auth.session
            
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
        init(from user: User) {
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
        for await state in supabase.auth.authStateChanges {
            switch state.event {
            case .signedIn:
                if let session = state.session {
                    self.currentSession = session
                    self.currentUser = AuthUser(from: session.user)
                }
            case .signedOut:
                self.currentSession = nil
                self.currentUser = nil
            case .tokenRefreshed:
                if let session = state.session {
                    self.currentSession = session
                    self.currentUser = AuthUser(from: session.user)
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
    
    func signOut() async throws {
        try await supabase.auth.signOut()
    }
    
    func refreshSession() async throws {
        try await supabase.auth.refreshSession()
    }
    
    // MARK: - Registration Methods
    func signUpWithEmail(_ email: String) async throws -> AuthUser {
        do {
            // For OTP-based signup, we use signInWithOTP which sends a verification code
            try await supabase.auth.signInWithOTP(email: email)
            
            // Return user info for verification step (OTP-based flow)
            return AuthUser(id: UUID().uuidString, email: email, phone: nil, isHost: false)
        } catch {
            throw mapSupabaseError(error)
        }
    }
    
    func signUpWithPhone(_ phone: String) async throws -> AuthUser {
        do {
            // For OTP-based signup, we use signInWithOTP which sends a verification code
            try await supabase.auth.signInWithOTP(phone: phone)
            
            // Return user info for verification step (OTP-based flow)
            return AuthUser(id: UUID().uuidString, email: nil, phone: phone, isHost: false)
        } catch {
            throw mapSupabaseError(error)
        }
    }
    
    func verifyOTP(code: String, email: String?, phone: String?) async throws -> AuthUser {
        do {
            let response: AuthResponse
            
            if let email = email {
                response = try await supabase.auth.verifyOTP(
                    email: email,
                    token: code,
                    type: .signup
                )
            } else if let phone = phone {
                response = try await supabase.auth.verifyOTP(
                    phone: phone,
                    token: code,
                    type: .sms
                )
            } else {
                throw AuthError.invalidCredentials
            }
            
            let user = response.user
            return AuthUser(from: user)
        } catch {
            throw mapSupabaseError(error)
        }
    }
    
    // MARK: - Login Methods
    func signInWithEmail(_ email: String) async throws -> AuthUser {
        do {
            try await supabase.auth.signInWithOTP(email: email)
            
            // For OTP-based email login, user will need to verify
            // Return user info for verification step
            return AuthUser(id: UUID().uuidString, email: email, phone: nil, isHost: false)
        } catch {
            throw mapSupabaseError(error)
        }
    }
    
    func signInWithPhone(_ phone: String) async throws -> AuthUser {
        do {
            try await supabase.auth.signInWithOTP(phone: phone)
            
            // For OTP-based phone login, user will need to verify
            // Return user info for verification step
            return AuthUser(id: UUID().uuidString, email: nil, phone: phone, isHost: false)
        } catch {
            throw mapSupabaseError(error)
        }
    }
    
    func verifyLoginOTP(code: String, email: String?, phone: String?) async throws -> AuthUser {
        do {
            let response: AuthResponse
            
            if let email = email {
                response = try await supabase.auth.verifyOTP(
                    email: email,
                    token: code,
                    type: .email
                )
            } else if let phone = phone {
                response = try await supabase.auth.verifyOTP(
                    phone: phone,
                    token: code,
                    type: .sms
                )
            } else {
                throw AuthError.invalidCredentials
            }
            
            let user = response.user
            return AuthUser(from: user)
        } catch {
            throw mapSupabaseError(error)
        }
    }
    
    // MARK: - Error Mapping
    private func mapSupabaseError(_ error: Error) -> AuthError {
        // Map Supabase errors to our custom AuthError enum
        let errorString = error.localizedDescription.lowercased()
        
        if errorString.contains("invalid_credentials") || errorString.contains("invalid credentials") {
            return .invalidCredentials
        } else if errorString.contains("user_already_registered") || errorString.contains("already registered") {
            return .userAlreadyExists
        } else if errorString.contains("invalid_otp") || errorString.contains("invalid otp") || errorString.contains("otp") {
            return .invalidVerificationCode
        } else if errorString.contains("network") || errorString.contains("connection") {
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
    case invalidVerificationCode
    case networkError
    case userAlreadyExists
    case invalidCredentials
    case rateLimitExceeded
    case sessionExpired
    case userNotFound
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidVerificationCode:
            return "Invalid verification code. Please try again."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .userAlreadyExists:
            return "An account with this email/phone already exists."
        case .invalidCredentials:
            return "Invalid credentials provided."
        case .rateLimitExceeded:
            return "Too many attempts. Please wait before trying again."
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        case .userNotFound:
            return "No account found with these credentials."
        case .unknownError(let message):
            return "An error occurred: \(message)"
        }
    }
} 