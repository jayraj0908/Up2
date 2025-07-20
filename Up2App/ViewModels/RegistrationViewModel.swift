import Foundation
import SwiftUI

// MARK: - Registration View Model
class RegistrationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var registrationData = RegistrationData()
    @Published var registrationState: RegistrationState = .inputCredentials
    @Published var emailValidation: ValidationResult = .valid
    @Published var phoneValidation: ValidationResult = .valid
    @Published var verificationCodeValidation: ValidationResult = .valid
    @Published var isLoading = false
    
    // MARK: - Computed Properties
    var currentInputValue: String {
        switch registrationData.inputMethod {
        case .email:
            return registrationData.emailAddress
        case .phone:
            return registrationData.phoneNumber
        }
    }
    
    var isCurrentInputValid: Bool {
        switch registrationData.inputMethod {
        case .email:
            return emailValidation.isValid && !registrationData.emailAddress.isEmpty
        case .phone:
            return phoneValidation.isValid && !registrationData.phoneNumber.isEmpty
        }
    }
    
    // MARK: - Input Method Toggle
    func selectInputMethod(_ method: RegistrationInputMethod) {
        registrationData.inputMethod = method
        clearValidationErrors()
    }
    
    // MARK: - Input Updates
    func updateEmailAddress(_ email: String) {
        registrationData.emailAddress = email
        emailValidation = ValidationService.validateEmail(email)
    }
    
    func updatePhoneNumber(_ phone: String) {
        registrationData.phoneNumber = phone
        phoneValidation = ValidationService.validatePhoneNumber(phone)
    }
    
    func updateVerificationCode(_ code: String) {
        registrationData.verificationCode = code
        verificationCodeValidation = ValidationService.validateVerificationCode(code)
    }
    
    // MARK: - Registration Flow
    func sendVerificationCode() {
        guard isCurrentInputValid else { return }
        
        isLoading = true
        clearValidationErrors()
        
        Task {
            do {
                switch registrationData.inputMethod {
                case .email:
                    _ = try await SupabaseAuthService.shared.signUpWithEmail(registrationData.emailAddress)
                case .phone:
                    _ = try await SupabaseAuthService.shared.signUpWithPhone(registrationData.phoneNumber)
                }
                
                await MainActor.run {
                    self.isLoading = false
                    self.registrationState = .awaitingVerification
                }
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.registrationState = .error(error.localizedDescription)
                }
            }
        }
    }
    
    func verifyCode() {
        guard verificationCodeValidation.isValid else { return }
        
        isLoading = true
        registrationState = .verifying
        
        Task {
            do {
                let email = registrationData.inputMethod == .email ? registrationData.emailAddress : nil
                let phone = registrationData.inputMethod == .phone ? registrationData.phoneNumber : nil
                
                let verifiedUser = try await SupabaseAuthService.shared.verifyOTP(
                    code: registrationData.verificationCode,
                    email: email,
                    phone: phone
                )
                
                // Set the current user in app state
                await AppStateManager.shared.setCurrentUser(verifiedUser)
                
                // Create user profile in database after successful verification
                _ = try await UserProfileService.shared.createUserProfile(for: verifiedUser)
                
                await MainActor.run {
                    self.isLoading = false
                    self.registrationState = .completed
                    
                    // Trigger navigation after successful registration
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        AppStateManager.shared.handleRegistrationComplete()
                    }
                }
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.registrationState = .error(error.localizedDescription)
                    // Reset to allow retry
                    self.registrationData.verificationCode = ""
                    self.verificationCodeValidation = .valid
                }
            }
        }
    }
    
    func resendVerificationCode() {
        isLoading = true
        
        Task {
            do {
                // Re-trigger the signup process to resend verification
                switch registrationData.inputMethod {
                case .email:
                    _ = try await SupabaseAuthService.shared.signUpWithEmail(registrationData.emailAddress)
                case .phone:
                    _ = try await SupabaseAuthService.shared.signUpWithPhone(registrationData.phoneNumber)
                }
                
                await MainActor.run {
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.registrationState = .error(error.localizedDescription)
                }
            }
        }
    }
    
    func resetRegistration() {
        registrationData = RegistrationData()
        registrationState = .inputCredentials
        clearValidationErrors()
    }
    
    // MARK: - Helper Methods
    private func clearValidationErrors() {
        emailValidation = .valid
        phoneValidation = .valid
        verificationCodeValidation = .valid
    }
} 