import XCTest
@testable import Up2App

final class ValidationServiceTests: XCTestCase {
    
    // MARK: - Email Validation Tests
    func testValidEmailAddresses() {
        let validEmails = [
            "user@example.com",
            "test.email@domain.org",
            "user+tag@company.co.uk",
            "firstname.lastname@university.edu",
            "123@test.com"
        ]
        
        for email in validEmails {
            let result = ValidationService.validateEmail(email)
            XCTAssertTrue(result.isValid, "Expected \(email) to be valid")
            XCTAssertNil(result.errorMessage, "Expected no error message for valid email: \(email)")
        }
    }
    
    func testInvalidEmailAddresses() {
        let invalidEmails = [
            "",
            "invalid-email",
            "@domain.com",
            "user@",
            "user..double.dot@example.com",
            "user@domain",
            "user@.com",
            "user name@example.com"
        ]
        
        for email in invalidEmails {
            let result = ValidationService.validateEmail(email)
            XCTAssertFalse(result.isValid, "Expected \(email) to be invalid")
            XCTAssertNotNil(result.errorMessage, "Expected error message for invalid email: \(email)")
        }
    }
    
    func testEmptyEmailValidation() {
        let result = ValidationService.validateEmail("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Email address is required")
    }
    
    // MARK: - Phone Number Validation Tests
    func testValidPhoneNumbers() {
        let validPhones = [
            "1234567890",
            "+11234567890",
            "12345678901",
            "123456789012345"
        ]
        
        for phone in validPhones {
            let result = ValidationService.validatePhoneNumber(phone)
            XCTAssertTrue(result.isValid, "Expected \(phone) to be valid")
            XCTAssertNil(result.errorMessage, "Expected no error message for valid phone: \(phone)")
        }
    }
    
    func testInvalidPhoneNumbers() {
        let invalidPhones = [
            "",
            "123",
            "12345678",
            "1234567890123456", // Too long
            "abc1234567"
        ]
        
        for phone in invalidPhones {
            let result = ValidationService.validatePhoneNumber(phone)
            XCTAssertFalse(result.isValid, "Expected \(phone) to be invalid")
            XCTAssertNotNil(result.errorMessage, "Expected error message for invalid phone: \(phone)")
        }
    }
    
    func testEmptyPhoneNumberValidation() {
        let result = ValidationService.validatePhoneNumber("")
        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errorMessage, "Phone number is required")
    }
    
    func testPhoneNumberWithFormatting() {
        let formattedPhones = [
            "(123) 456-7890",
            "123-456-7890",
            "123.456.7890",
            "+1 (123) 456-7890"
        ]
        
        for phone in formattedPhones {
            let result = ValidationService.validatePhoneNumber(phone)
            XCTAssertTrue(result.isValid, "Expected formatted phone \(phone) to be valid")
        }
    }
    
    // MARK: - Verification Code Validation Tests
    func testValidVerificationCodes() {
        let validCodes = [
            "123456",
            "000000",
            "999999"
        ]
        
        for code in validCodes {
            let result = ValidationService.validateVerificationCode(code)
            XCTAssertTrue(result.isValid, "Expected \(code) to be valid")
            XCTAssertNil(result.errorMessage)
        }
    }
    
    func testInvalidVerificationCodes() {
        let invalidCodes = [
            "",
            "12345",   // Too short
            "1234567", // Too long
            "12345a",  // Contains letter
            "12 34 56" // Contains spaces
        ]
        
        for code in invalidCodes {
            let result = ValidationService.validateVerificationCode(code)
            XCTAssertFalse(result.isValid, "Expected \(code) to be invalid")
            XCTAssertNotNil(result.errorMessage)
        }
    }
    
    // MARK: - Phone Number Formatting Tests
    func testPhoneNumberFormatting() {
        let phone = "1234567890"
        let formatted = ValidationService.formatPhoneNumber(phone)
        XCTAssertEqual(formatted, "(123) 456-7890")
    }
    
    func testPhoneNumberFormattingWithInvalidLength() {
        let phone = "123456789"
        let formatted = ValidationService.formatPhoneNumber(phone)
        XCTAssertEqual(formatted, phone) // Should return original if not 10 digits
    }
} 