import Foundation
import SwiftUI

// MARK: - Login View Model
class LoginViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var loginData = LoginData()
    @Published var loginState: LoginState = .inputCredentials
    @Published var emailValidation: ValidationResult = .valid
    @Published var passwordValidation: ValidationResult = .valid
    @Published var isLoading = false
    
    // MARK: - Computed Properties
    var isCurrentInputValid: Bool {
        return emailValidation.isValid && 
               !loginData.emailAddress.isEmpty && 
               passwordValidation.isValid && 
               !loginData.password.isEmpty
    }
    
    // MARK: - Input Updates
    func updateEmailAddress(_ email: String) {
        loginData.emailAddress = email
        emailValidation = ValidationService.validateEmail(email)
    }
    
    func updatePassword(_ password: String) {
        loginData.password = password
        passwordValidation = ValidationService.validatePassword(password)
    }
    
    // MARK: - Login Flow
    func signIn() {
        guard isCurrentInputValid else { return }
        
        // Check network connectivity first
        guard SupabaseManager.shared.checkNetworkConnectivity() else {
            loginState = .error("No internet connection. Please check your network and try again.")
            return
        }
        
        isLoading = true
        clearValidationErrors()
        
        Task {
            do {
                print("🔄 Starting sign in process...")
                
                // Reset session before attempting sign in to ensure clean state
                await SupabaseAuthService.shared.resetSession()
                
                let user = try await SupabaseAuthService.shared.signInWithEmail(
                    loginData.emailAddress,
                    password: loginData.password
                )
                
                print("✅ Sign in successful for user: \(user.email ?? "unknown")")
                
                await MainActor.run {
                    self.isLoading = false
                    self.loginState = .completed
                }
                
                // Let AppStateManager handle the navigation automatically
                // The session observer will update the app flow
                
            } catch {
                print("❌ Sign in failed: \(error)")
                
                await MainActor.run {
                    self.isLoading = false
                    
                    // Provide more specific error messages
                    let errorMessage = getErrorMessage(for: error)
                    self.loginState = .error(errorMessage)
                }
            }
        }
    }
    
    func resetLogin() {
        loginData = LoginData()
        loginState = .inputCredentials
        clearValidationErrors()
        isLoading = false
    }
    
    // MARK: - Helper Methods
    private func clearValidationErrors() {
        emailValidation = .valid
        passwordValidation = .valid
    }
    
    private func getErrorMessage(for error: Error) -> String {
        if let authError = error as? AuthError {
            return authError.localizedDescription
        }
        
        let errorString = error.localizedDescription.lowercased()
        let nsError = error as NSError
        
        // Check for network connectivity issues
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                return "Network connection lost. Please check your internet connection and try again."
            case NSURLErrorTimedOut:
                return "Request timed out. Please check your connection and try again."
            case NSURLErrorCannotConnectToHost:
                return "Cannot connect to server. Please try again later."
            default:
                break
            }
        }
        
        if errorString.contains("network") || errorString.contains("connection") || errorString.contains("lost") {
            return "Network error. Please check your connection and try again."
        } else if errorString.contains("invalid_credentials") || errorString.contains("invalid credentials") {
            return "Invalid email or password. Please check your credentials and try again."
        } else if errorString.contains("user_already_registered") || errorString.contains("already registered") {
            return "An account with this email already exists."
        } else if errorString.contains("rate_limit") || errorString.contains("too many") {
            return "Too many attempts. Please wait a moment before trying again."
        } else if errorString.contains("session") || errorString.contains("token") {
            return "Session expired. Please try signing in again."
        } else {
            return "An unexpected error occurred. Please try again."
        }
    }
} 