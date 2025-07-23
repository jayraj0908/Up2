import Foundation

// MARK: - Input Validation Service
class ValidationService {
    
    // MARK: - Email Validation
    static func validateEmail(_ email: String) -> ValidationResult {
        guard !email.isEmpty else {
            return .invalid("Email address is required")
        }
        
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        guard emailPredicate.evaluate(with: email) else {
            return .invalid("Please enter a valid email address")
        }
        
        return .valid
    }
    
    // MARK: - Phone Number Validation
    static func validatePhoneNumber(_ phoneNumber: String) -> ValidationResult {
        guard !phoneNumber.isEmpty else {
            return .invalid("Phone number is required")
        }
        
        // Remove all non-digit characters for validation
        let digitsOnly = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        // Check if it's a valid length (10-15 digits for international numbers)
        guard digitsOnly.count >= 10 && digitsOnly.count <= 15 else {
            return .invalid("Phone number must be 10-15 digits")
        }
        
        // Basic US phone number format check
        _ = "^[+]?[1-9]\\d{1,14}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", digitsOnly)
        
        guard phonePredicate.evaluate(with: digitsOnly) else {
            return .invalid("Please enter a valid phone number")
        }
        
        return .valid
    }
    
    // MARK: - Password Validation
    static func validatePassword(_ password: String) -> ValidationResult {
        guard !password.isEmpty else {
            return .invalid("Password is required")
        }
        
        guard password.count >= 6 else {
            return .invalid("Password must be at least 6 characters")
        }
        
        return .valid
    }
    
    // MARK: - Verification Code Validation
    static func validateVerificationCode(_ code: String) -> ValidationResult {
        guard !code.isEmpty else {
            return .invalid("Verification code is required")
        }
        
        guard code.count == 6 else {
            return .invalid("Verification code must be 6 digits")
        }
        
        let digitsOnly = code.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        guard digitsOnly.count == 6 else {
            return .invalid("Verification code must contain only digits")
        }
        
        return .valid
    }
    
    // MARK: - Format Phone Number for Display
    static func formatPhoneNumber(_ phoneNumber: String) -> String {
        let digitsOnly = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        guard digitsOnly.count == 10 else {
            return phoneNumber
        }
        
        let area = String(digitsOnly.prefix(3))
        let exchange = String(digitsOnly.dropFirst(3).prefix(3))
        let number = String(digitsOnly.suffix(4))
        
        return "(\(area)) \(exchange)-\(number)"
    }
} 