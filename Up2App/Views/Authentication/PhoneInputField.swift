import SwiftUI

struct PhoneInputField: View {
    @Binding var phoneNumber: String
    @Binding var isValid: Bool
    let errorMessage: String?
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: Up2Spacing.xs) {
            Text("Phone Number")
                .font(Up2Typography.label)
                .foregroundColor(Up2Colors.textPrimary)
            
            HStack {
                // Country code (US +1 for now)
                Text("+1")
                    .font(Up2Typography.bodyMedium)
                    .foregroundColor(Up2Colors.textSecondary)
                    .padding(.horizontal, Up2Spacing.md)
                    .padding(.vertical, Up2Spacing.lg)
                    .background(Up2Colors.surfaceVariant)
                    .cornerRadius(Up2Spacing.sm)
                
                TextField("(555) 123-4567", text: $phoneNumber)
                    .font(Up2Typography.bodyMedium)
                    .keyboardType(.phonePad)
                    .focused($isFocused)
                    .padding(.horizontal, Up2Spacing.lg)
                    .padding(.vertical, Up2Spacing.lg)
                    .background(Up2Colors.surface)
                    .cornerRadius(Up2Spacing.sm)
                    .overlay(
                        RoundedRectangle(cornerRadius: Up2Spacing.sm)
                            .stroke(borderColor, lineWidth: 1)
                    )
                    .onChange(of: phoneNumber) { newValue in
                        // Format phone number as user types
                        phoneNumber = formatPhoneNumber(newValue)
                        // Validate phone number
                        validatePhoneNumber()
                    }
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
    
    private func formatPhoneNumber(_ input: String) -> String {
        // Remove all non-numeric characters
        let cleaned = input.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        
        // Limit to 10 digits
        let limited = String(cleaned.prefix(10))
        
        // Format as (XXX) XXX-XXXX
        if limited.count >= 6 {
            let areaCode = String(limited.prefix(3))
            let exchange = String(limited.dropFirst(3).prefix(3))
            let number = String(limited.dropFirst(6))
            return "(\(areaCode)) \(exchange)-\(number)"
        } else if limited.count >= 3 {
            let areaCode = String(limited.prefix(3))
            let exchange = String(limited.dropFirst(3))
            return "(\(areaCode)) \(exchange)"
        } else if !limited.isEmpty {
            return "(\(limited)"
        }
        
        return limited
    }
    
    private func validatePhoneNumber() {
        let cleaned = phoneNumber.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        isValid = cleaned.count == 10
    }
}

#Preview {
    PhoneInputField(
        phoneNumber: .constant(""),
        isValid: .constant(false),
        errorMessage: nil
    )
    .padding()
} 