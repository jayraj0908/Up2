import SwiftUI

struct VerificationCodeView: View {
    @ObservedObject var viewModel: RegistrationViewModel
    @FocusState private var isCodeFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: Up2Spacing.xl) {
            headerView
            codeInputSection
            actionButtons
        }
        .onAppear {
            isCodeFieldFocused = true
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: Up2Spacing.lg) {
            Image(systemName: "envelope.badge")
                .font(.system(size: 64))
                .foregroundColor(Up2Colors.primary)
            
            Text("Verification Code")
                .font(Up2Typography.heading2)
                .foregroundColor(Up2Colors.textPrimary)
            
            Text("We've sent a 6-digit code to \(maskedContactInfo)")
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Code Input Section
    private var codeInputSection: some View {
        VStack(spacing: Up2Spacing.lg) {
            codeInputField
            
            if let errorMessage = viewModel.verificationCodeValidation.errorMessage {
                Text(errorMessage)
                    .font(Up2Typography.caption)
                    .foregroundColor(Up2Colors.error)
            }
        }
    }
    
    private var codeInputField: some View {
        HStack(spacing: Up2Spacing.sm) {
            ForEach(0..<6, id: \.self) { index in
                SingleDigitField(
                    digit: getDigit(at: index),
                    isFocused: isCodeFieldFocused && index == viewModel.registrationData.verificationCode.count
                )
            }
        }
        .background(
            // Hidden text field for input handling
            TextField("", text: Binding(
                get: { viewModel.registrationData.verificationCode },
                set: { newValue in
                    let filtered = String(newValue.prefix(6).filter { $0.isNumber })
                    viewModel.updateVerificationCode(filtered)
                }
            ))
            .keyboardType(.numberPad)
            .focused($isCodeFieldFocused)
            .opacity(0)
        )
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: Up2Spacing.lg) {
            verifyButton
            resendButton
            changeMethodButton
        }
    }
    
    private var verifyButton: some View {
        Up2Button(
            viewModel.registrationState == .verifying ? "Verifying..." : "Verify Code",
            style: .primary,
            size: .large,
            isEnabled: viewModel.verificationCodeValidation.isValid && 
                      viewModel.registrationData.verificationCode.count == 6 &&
                      viewModel.registrationState != .verifying,
            isLoading: viewModel.registrationState == .verifying
        ) {
            viewModel.verifyCode()
        }
    }
    
    private var resendButton: some View {
        Up2Button(
            viewModel.isLoading && viewModel.registrationState != .verifying ? "Resending..." : "Resend Code",
            style: .secondary,
            size: .medium,
            isEnabled: !viewModel.isLoading,
            isLoading: viewModel.isLoading && viewModel.registrationState != .verifying
        ) {
            viewModel.resendVerificationCode()
        }
    }
    
    private var changeMethodButton: some View {
        Button("Change \(viewModel.registrationData.inputMethod == .email ? "Email" : "Phone Number")") {
            viewModel.resetRegistration()
        }
        .font(Up2Typography.buttonMedium)
        .foregroundColor(Up2Colors.textSecondary)
    }
    
    // MARK: - Helper Methods
    private func getDigit(at index: Int) -> String {
        let code = viewModel.registrationData.verificationCode
        return index < code.count ? String(code[code.index(code.startIndex, offsetBy: index)]) : ""
    }
    
    private var maskedContactInfo: String {
        switch viewModel.registrationData.inputMethod {
        case .email:
            return maskEmail(viewModel.registrationData.emailAddress)
        case .phone:
            return maskPhoneNumber(viewModel.registrationData.phoneNumber)
        }
    }
    
    private func maskEmail(_ email: String) -> String {
        let components = email.components(separatedBy: "@")
        guard components.count == 2 else { return email }
        
        let username = components[0]
        let domain = components[1]
        
        let maskedUsername = username.count > 2 ? 
            String(username.prefix(2)) + String(repeating: "*", count: max(1, username.count - 2)) :
            username
        
        return "\(maskedUsername)@\(domain)"
    }
    
    private func maskPhoneNumber(_ phone: String) -> String {
        let digitsOnly = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        guard digitsOnly.count >= 10 else { return phone }
        
        let visibleDigits = 4
        let masked = String(repeating: "*", count: digitsOnly.count - visibleDigits)
        let lastFour = String(digitsOnly.suffix(visibleDigits))
        
        return "\(masked)\(lastFour)"
    }
}

// MARK: - Single Digit Field Component
struct SingleDigitField: View {
    let digit: String
    let isFocused: Bool
    
    var body: some View {
        Text(digit)
            .font(Up2Typography.heading3)
            .foregroundColor(Up2Colors.textPrimary)
            .frame(width: 44, height: 56)
            .background(Up2Colors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: Up2Spacing.sm)
                    .stroke(
                        isFocused ? Up2Colors.primary : Up2Colors.primary.opacity(0.3),
                        lineWidth: isFocused ? 2 : 1
                    )
            )
            .cornerRadius(Up2Spacing.sm)
    }
}

#Preview {
    VerificationCodeView(viewModel: RegistrationViewModel())
} 