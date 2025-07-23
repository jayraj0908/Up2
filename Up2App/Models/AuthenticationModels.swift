import Foundation

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: String
    let email: String
    let fullName: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
    }
}

// MARK: - Authentication Models

// MARK: - Validation Results
struct ValidationResult {
    let isValid: Bool
    let errorMessage: String?
    
    static let valid = ValidationResult(isValid: true, errorMessage: nil)
    static func invalid(_ message: String) -> ValidationResult {
        return ValidationResult(isValid: false, errorMessage: message)
    }
}

// MARK: - Registration Data Models
struct RegistrationData {
    var emailAddress: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    var isValid: Bool = false
}

// MARK: - Login Data Models
struct LoginData {
    var emailAddress: String = ""
    var password: String = ""
    var isValid: Bool = false
}

// MARK: - Authentication States
enum LoginState {
    case inputCredentials
    case completed
    case error(String)
}

enum RegistrationState {
    case inputCredentials
    case completed
    case error(String)
}

// MARK: - Input Methods (Legacy - kept for compatibility)
enum LoginInputMethod {
    case email
    case phone
}

enum RegistrationInputMethod {
    case email
    case phone
} 