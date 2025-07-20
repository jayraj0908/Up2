import Foundation
import SwiftUI

// MARK: - Login View Model
class LoginViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var loginData = LoginData()
    @Published var loginState: LoginState = .inputCredentials
    @Published var emailValidation: ValidationResult = .valid
    @Published var phoneValidation: ValidationResult = .valid
    @Published var verificationCodeValidation: ValidationResult = .valid
    @Published var isLoading = false
    
    // MARK: - Computed Properties
    var currentInputValue: String {
        switch loginData.inputMethod {
        case .email:
            return loginData.emailAddress
        case .phone:
            return loginData.phoneNumber
        }
    }
    
    var isCurrentInputValid: Bool {
        switch loginData.inputMethod {
        case .email:
            return emailValidation.isValid && !loginData.emailAddress.isEmpty
        case .phone:
            return phoneValidation.isValid && !loginData.phoneNumber.isEmpty
        }
    }
    
    // MARK: - Input Method Toggle
    func selectInputMethod(_ method: LoginInputMethod) {
        loginData.inputMethod = method
        clearValidationErrors()
    }
    
    // MARK: - Input Updates
    func updateEmailAddress(_ email: String) {
        loginData.emailAddress = email
        emailValidation = ValidationService.validateEmail(email)
    }
    
    func updatePhoneNumber(_ phone: String) {
        loginData.phoneNumber = phone
        phoneValidation = ValidationService.validatePhoneNumber(phone)
    }
    
    func updateVerificationCode(_ code: String) {
        loginData.verificationCode = code
        verificationCodeValidation = ValidationService.validateVerificationCode(code)
    }
    
    // MARK: - Login Flow
    func sendVerificationCode() {
        guard isCurrentInputValid else { return }
        
        isLoading = true
        clearValidationErrors()
        
        Task {
            do {
                switch loginData.inputMethod {
                case .email:
                    _ = try await SupabaseAuthService.shared.signInWithEmail(loginData.emailAddress)
                case .phone:
                    _ = try await SupabaseAuthService.shared.signInWithPhone(loginData.phoneNumber)
                }
                
                await MainActor.run {
                    self.isLoading = false
                    self.loginState = .awaitingVerification
                }
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.loginState = .error(error.localizedDescription)
                }
            }
        }
    }
    
    func verifyCodeAndLogin() {
        guard verificationCodeValidation.isValid else { return }
        
        isLoading = true
        loginState = .verifying
        
        Task {
            do {
                let verifiedUser = try await SupabaseAuthService.shared.verifyLoginOTP(
                    code: loginData.verificationCode,
                    email: loginData.inputMethod == .email ? loginData.emailAddress : nil,
                    phone: loginData.inputMethod == .phone ? loginData.phoneNumber : nil
                )
                
                // Set the current user in app state and handle login completion
                await MainActor.run {
                    AppStateManager.shared.setCurrentUser(verifiedUser)
                    AppStateManager.shared.handleLoginComplete()
                    self.isLoading = false
                    self.loginState = .completed
                }
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.loginState = .error(error.localizedDescription)
                }
            }
        }
    }
    
    func resendVerificationCode() {
        sendVerificationCode()
    }
    
    func goBackToCredentials() {
        loginState = .inputCredentials
        clearVerificationCode()
        clearValidationErrors()
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
        phoneValidation = .valid
        verificationCodeValidation = .valid
    }
    
    private func clearVerificationCode() {
        loginData.verificationCode = ""
        verificationCodeValidation = .valid
    }
} 