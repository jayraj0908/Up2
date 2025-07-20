import Foundation

// MARK: - Registration Data Models
struct RegistrationData {
    var inputMethod: RegistrationInputMethod = .email
    var emailAddress: String = ""
    var phoneNumber: String = ""
    var verificationCode: String = ""
    var isValid: Bool = false
}

enum RegistrationInputMethod: CaseIterable {
    case email
    case phone
    
    var title: String {
        switch self {
        case .email:
            return "Email"
        case .phone:
            return "Phone"
        }
    }
}

// MARK: - Validation Results
struct ValidationResult {
    let isValid: Bool
    let errorMessage: String?
    
    static let valid = ValidationResult(isValid: true, errorMessage: nil)
    static func invalid(_ message: String) -> ValidationResult {
        return ValidationResult(isValid: false, errorMessage: message)
    }
}

// MARK: - Registration States
enum RegistrationState: Equatable {
    case inputCredentials
    case awaitingVerification
    case verifying
    case completed
    case error(String)
}

// MARK: - Login Data Models
struct LoginData {
    var inputMethod: LoginInputMethod = .email
    var emailAddress: String = ""
    var phoneNumber: String = ""
    var verificationCode: String = ""
    var isValid: Bool = false
}

enum LoginInputMethod: CaseIterable {
    case email
    case phone
    
    var title: String {
        switch self {
        case .email:
            return "Email"
        case .phone:
            return "Phone"
        }
    }
}

// MARK: - Login States
enum LoginState: Equatable {
    case inputCredentials
    case awaitingVerification
    case verifying
    case completed
    case error(String)
} 