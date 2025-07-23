import SwiftUI

struct EmailInputField: View {
    @Binding var email: String
    @Binding var isValid: Bool
    let errorMessage: String?
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Up2Spacing.xs) {
            Text("Email Address")
                .font(Up2Typography.label)
                .foregroundColor(Up2Colors.textPrimary)
            
            TextField("Enter your email", text: $email)
                .font(Up2Typography.bodyMedium)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .focused($isFocused)
                .padding(.horizontal, Up2Spacing.lg)
                .padding(.vertical, Up2Spacing.lg)
                .background(Up2Colors.surface)
                .cornerRadius(Up2Spacing.sm)
                .overlay(
                    RoundedRectangle(cornerRadius: Up2Spacing.sm)
                        .stroke(borderColor, lineWidth: 1)
                )
                .onChange(of: email) { _, newValue in
                    // Validate email as user types
                    validateEmail()
                }
            
            // Error message
            if let errorMessage = errorMessage, !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(Up2Typography.caption)
                    .foregroundColor(Up2Colors.error)
            }
        }
    }
    
    private var borderColor: Color {
        if let errorMessage = errorMessage, !errorMessage.isEmpty {
            return Up2Colors.error
        } else if isFocused {
            return Up2Colors.primary
        } else {
            return Up2Colors.primary.opacity(0.3)
        }
    }
    
    private func validateEmail() {
        isValid = isValidEmail(email)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}

#Preview {
    EmailInputField(
        email: .constant(""),
        isValid: .constant(false),
        errorMessage: nil
    )
    .padding()
} 