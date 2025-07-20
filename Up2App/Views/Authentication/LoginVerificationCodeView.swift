import SwiftUI

struct LoginVerificationCodeView: View {
    @ObservedObject var viewModel: LoginViewModel
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
                    isFocused: isCodeFieldFocused && index == viewModel.loginData.verificationCode.count
                )
            }
        }
        .background(
            // Hidden text field for input handling
            TextField("", text: Binding(
                get: { viewModel.loginData.verificationCode },
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
            changeCredentialsButton
        }
    }
    
    private var verifyButton: some View {
        Up2Button(
            viewModel.loginState == .verifying ? "Verifying..." : "Verify & Sign In",
            style: .primary,
            size: .large,
            isEnabled: viewModel.verificationCodeValidation.isValid && 
                      viewModel.loginData.verificationCode.count == 6 &&
                      viewModel.loginState != .verifying,
            isLoading: viewModel.loginState == .verifying
        ) {
            viewModel.verifyCodeAndLogin()
        }
    }
    
    private var resendButton: some View {
        Up2Button(
            viewModel.isLoading && viewModel.loginState == .awaitingVerification ? "Sending..." : "Resend Code",
            style: .secondary,
            size: .medium,
            isEnabled: !viewModel.isLoading,
            isLoading: viewModel.isLoading && viewModel.loginState == .awaitingVerification
        ) {
            viewModel.resendVerificationCode()
            }
        }
    
    private var changeCredentialsButton: some View {
        Button("Change \(viewModel.loginData.inputMethod == .email ? "Email" : "Phone Number")") {
            viewModel.goBackToCredentials()
        }
        .font(Up2Typography.buttonMedium)
        .foregroundColor(Up2Colors.textSecondary)
    }
    
    // MARK: - Helper Methods
    private func getDigit(at index: Int) -> String {
        guard index < viewModel.loginData.verificationCode.count else {
            return ""
        }
        return String(viewModel.loginData.verificationCode[viewModel.loginData.verificationCode.index(viewModel.loginData.verificationCode.startIndex, offsetBy: index)])
    }
    
    private var maskedContactInfo: String {
        switch viewModel.loginData.inputMethod {
        case .email:
            return maskEmail(viewModel.loginData.emailAddress)
        case .phone:
            return maskPhoneNumber(viewModel.loginData.phoneNumber)
        }
    }
    
    private func maskEmail(_ email: String) -> String {
        let components = email.components(separatedBy: "@")
        guard components.count == 2 else { return email }
        
        let username = components[0]
        let domain = components[1]
        
        if username.count <= 2 {
            return "\(username)***@\(domain)"
        } else {
            return "\(username.prefix(2))***@\(domain)"
        }
    }
    
    private func maskPhoneNumber(_ phone: String) -> String {
        guard phone.count >= 4 else { return phone }
        
        let visibleDigits = 2
        let maskedPortion = String(repeating: "*", count: max(0, phone.count - visibleDigits * 2))
        let prefix = String(phone.prefix(visibleDigits))
        let suffix = String(phone.suffix(visibleDigits))
        
        return "\(prefix)\(maskedPortion)\(suffix)"
    }
}

// Note: SingleDigitField is already defined in VerificationCodeView.swift 