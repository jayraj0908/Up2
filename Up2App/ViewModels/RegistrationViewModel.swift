import Foundation
import Supabase

@MainActor
class RegistrationViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isRegistrationSuccessful = false
    @Published var registrationState: RegistrationState = .inputCredentials
    @Published var registrationData = RegistrationData()
    @Published var emailValidation = ValidationResult()
    @Published var passwordValidation = ValidationResult()
    @Published var confirmPasswordValidation = ValidationResult()
    
    private let authService = SupabaseAuthService.shared
    
    var isCurrentInputValid: Bool {
        !registrationData.emailAddress.isEmpty &&
        !registrationData.password.isEmpty &&
        !registrationData.confirmPassword.isEmpty &&
        registrationData.password == registrationData.confirmPassword &&
        emailValidation.errorMessage == nil &&
        passwordValidation.errorMessage == nil &&
        confirmPasswordValidation.errorMessage == nil
    }
    
    // MARK: - Registration Data Model
    struct RegistrationData {
        var emailAddress: String = ""
        var password: String = ""
        var confirmPassword: String = ""
    }
    
    // MARK: - Registration State
    enum RegistrationState {
        case inputCredentials
        case completed
        case error(String)
    }
    
    // MARK: - Validation Result
    struct ValidationResult {
        var errorMessage: String?
        var isValid: Bool { errorMessage == nil }
    }
    
    // MARK: - Data Binding Methods
    func updateEmailAddress(_ email: String) {
        registrationData.emailAddress = email
        validateEmail()
    }
    
    func updatePassword(_ password: String) {
        registrationData.password = password
        validatePassword()
        validateConfirmPassword()
    }
    
    func updateConfirmPassword(_ confirmPassword: String) {
        registrationData.confirmPassword = confirmPassword
        validateConfirmPassword()
    }
    
    // MARK: - Validation Methods
    private func validateEmail() {
        if registrationData.emailAddress.isEmpty {
            emailValidation.errorMessage = "Email is required"
        } else if !isValidEmail(registrationData.emailAddress) {
            emailValidation.errorMessage = "Please enter a valid email address"
        } else {
            emailValidation.errorMessage = nil
        }
    }
    
    private func validatePassword() {
        if registrationData.password.isEmpty {
            passwordValidation.errorMessage = "Password is required"
        } else if registrationData.password.count < 6 {
            passwordValidation.errorMessage = "Password must be at least 6 characters"
        } else {
            passwordValidation.errorMessage = nil
        }
    }
    
    private func validateConfirmPassword() {
        if registrationData.confirmPassword.isEmpty {
            confirmPasswordValidation.errorMessage = "Please confirm your password"
        } else if registrationData.password != registrationData.confirmPassword {
            confirmPasswordValidation.errorMessage = "Passwords do not match"
        } else {
            confirmPasswordValidation.errorMessage = nil
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    // MARK: - Reset Method
    func resetRegistration() {
        registrationData = RegistrationData()
        emailValidation = ValidationResult()
        passwordValidation = ValidationResult()
        confirmPasswordValidation = ValidationResult()
        registrationState = .inputCredentials
        errorMessage = nil
        isRegistrationSuccessful = false
    }
    
    // MARK: - Sign Up Method
    func signUp() async {
        guard isCurrentInputValid else { return }
        
        registrationState = .inputCredentials
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔄 Starting user registration for: \(registrationData.emailAddress)")
            
            // Sign up the user using Supabase Auth
            let session = try await SupabaseManager.shared.client.auth.signUp(
                email: registrationData.emailAddress, 
                password: registrationData.password
            )
            
            print("✅ User signed up successfully")
            
            // Insert a new row into users table
            try await SupabaseManager.shared.client
                .from("users")
                .insert([
                    "id": session.user.id.uuidString,
                    "email": registrationData.emailAddress,
                    "full_name": registrationData.emailAddress.components(separatedBy: "@").first ?? "User"
                ])
                .execute()
            
            print("✅ User record created in users table")
            
            // Insert into profiles with the same id, set is_curator = false
            try await SupabaseManager.shared.client
                .from("profiles")
                .insert([
                    "id": session.user.id.uuidString,
                    "name": registrationData.emailAddress.components(separatedBy: "@").first ?? "User",
                    "handle": "user_\(session.user.id.uuidString.prefix(8))",
                    "is_curator": "false",
                    "created_at": ISO8601DateFormatter().string(from: Date()),
                    "updated_at": ISO8601DateFormatter().string(from: Date())
                ])
                .execute()
            
            print("✅ Profile created in profiles table")
            
            isRegistrationSuccessful = true
            registrationState = .completed
            
        } catch {
            print("❌ Registration failed: \(error)")
            errorMessage = "Registration failed: \(error.localizedDescription)"
            registrationState = .error(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func login(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔄 Attempting login for: \(email)")
            
            // Sign in the user using Supabase Auth
            try await SupabaseManager.shared.client.auth.signIn(
                email: email, 
                password: password
            )
            
            print("✅ Login successful")
            
        } catch {
            print("❌ Login failed: \(error)")
            errorMessage = "Login failed: \(error.localizedDescription)"
            throw error
        }
        
        isLoading = false
    }
} 