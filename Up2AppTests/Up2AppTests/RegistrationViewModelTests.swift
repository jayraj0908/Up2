import XCTest
@testable import Up2App

final class RegistrationViewModelTests: XCTestCase {
    
    var viewModel: RegistrationViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = RegistrationViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    func testInitialState() {
        XCTAssertEqual(viewModel.registrationState, .inputCredentials)
        XCTAssertEqual(viewModel.registrationData.inputMethod, .email)
        XCTAssertTrue(viewModel.registrationData.emailAddress.isEmpty)
        XCTAssertTrue(viewModel.registrationData.phoneNumber.isEmpty)
        XCTAssertTrue(viewModel.registrationData.verificationCode.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Input Method Toggle Tests
    func testSelectInputMethod() {
        // Start with email (default)
        XCTAssertEqual(viewModel.registrationData.inputMethod, .email)
        
        // Switch to phone
        viewModel.selectInputMethod(.phone)
        XCTAssertEqual(viewModel.registrationData.inputMethod, .phone)
        
        // Switch back to email
        viewModel.selectInputMethod(.email)
        XCTAssertEqual(viewModel.registrationData.inputMethod, .email)
    }
    
    // MARK: - Email Input Tests
    func testUpdateEmailAddress() {
        let validEmail = "test@example.com"
        viewModel.updateEmailAddress(validEmail)
        
        XCTAssertEqual(viewModel.registrationData.emailAddress, validEmail)
        XCTAssertTrue(viewModel.emailValidation.isValid)
        XCTAssertNil(viewModel.emailValidation.errorMessage)
    }
    
    func testUpdateInvalidEmailAddress() {
        let invalidEmail = "invalid-email"
        viewModel.updateEmailAddress(invalidEmail)
        
        XCTAssertEqual(viewModel.registrationData.emailAddress, invalidEmail)
        XCTAssertFalse(viewModel.emailValidation.isValid)
        XCTAssertNotNil(viewModel.emailValidation.errorMessage)
    }
    
    // MARK: - Phone Input Tests
    func testUpdatePhoneNumber() {
        let validPhone = "1234567890"
        viewModel.updatePhoneNumber(validPhone)
        
        XCTAssertEqual(viewModel.registrationData.phoneNumber, validPhone)
        XCTAssertTrue(viewModel.phoneValidation.isValid)
        XCTAssertNil(viewModel.phoneValidation.errorMessage)
    }
    
    func testUpdateInvalidPhoneNumber() {
        let invalidPhone = "123"
        viewModel.updatePhoneNumber(invalidPhone)
        
        XCTAssertEqual(viewModel.registrationData.phoneNumber, invalidPhone)
        XCTAssertFalse(viewModel.phoneValidation.isValid)
        XCTAssertNotNil(viewModel.phoneValidation.errorMessage)
    }
    
    // MARK: - Verification Code Tests
    func testUpdateVerificationCode() {
        let validCode = "123456"
        viewModel.updateVerificationCode(validCode)
        
        XCTAssertEqual(viewModel.registrationData.verificationCode, validCode)
        XCTAssertTrue(viewModel.verificationCodeValidation.isValid)
        XCTAssertNil(viewModel.verificationCodeValidation.errorMessage)
    }
    
    func testUpdateInvalidVerificationCode() {
        let invalidCode = "123"
        viewModel.updateVerificationCode(invalidCode)
        
        XCTAssertEqual(viewModel.registrationData.verificationCode, invalidCode)
        XCTAssertFalse(viewModel.verificationCodeValidation.isValid)
        XCTAssertNotNil(viewModel.verificationCodeValidation.errorMessage)
    }
    
    // MARK: - Current Input Value Tests
    func testCurrentInputValueForEmail() {
        let email = "test@example.com"
        viewModel.selectInputMethod(.email)
        viewModel.updateEmailAddress(email)
        
        XCTAssertEqual(viewModel.currentInputValue, email)
    }
    
    func testCurrentInputValueForPhone() {
        let phone = "1234567890"
        viewModel.selectInputMethod(.phone)
        viewModel.updatePhoneNumber(phone)
        
        XCTAssertEqual(viewModel.currentInputValue, phone)
    }
    
    // MARK: - Input Validation Tests
    func testIsCurrentInputValidForEmail() {
        viewModel.selectInputMethod(.email)
        
        // Invalid initially
        XCTAssertFalse(viewModel.isCurrentInputValid)
        
        // Valid after entering valid email
        viewModel.updateEmailAddress("test@example.com")
        XCTAssertTrue(viewModel.isCurrentInputValid)
        
        // Invalid after entering invalid email
        viewModel.updateEmailAddress("invalid")
        XCTAssertFalse(viewModel.isCurrentInputValid)
    }
    
    func testIsCurrentInputValidForPhone() {
        viewModel.selectInputMethod(.phone)
        
        // Invalid initially
        XCTAssertFalse(viewModel.isCurrentInputValid)
        
        // Valid after entering valid phone
        viewModel.updatePhoneNumber("1234567890")
        XCTAssertTrue(viewModel.isCurrentInputValid)
        
        // Invalid after entering invalid phone
        viewModel.updatePhoneNumber("123")
        XCTAssertFalse(viewModel.isCurrentInputValid)
    }
    
    // MARK: - Registration Flow Tests
    func testSendVerificationCodeWithValidInput() {
        // Setup valid email
        viewModel.selectInputMethod(.email)
        viewModel.updateEmailAddress("test@example.com")
        
        XCTAssertTrue(viewModel.isCurrentInputValid)
        
        // Test sending verification code
        let expectation = self.expectation(description: "Verification code sent")
        
        viewModel.sendVerificationCode()
        XCTAssertTrue(viewModel.isLoading)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            XCTAssertFalse(self.viewModel.isLoading)
            XCTAssertEqual(self.viewModel.registrationState, .awaitingVerification)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testVerifyCodeWithValidCode() {
        // Setup verification state
        viewModel.registrationState = .awaitingVerification
        viewModel.updateVerificationCode("123456")
        
        XCTAssertTrue(viewModel.verificationCodeValidation.isValid)
        
        // Test code verification
        let expectation = self.expectation(description: "Code verified")
        
        viewModel.verifyCode()
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertEqual(viewModel.registrationState, .verifying)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            XCTAssertFalse(self.viewModel.isLoading)
            XCTAssertEqual(self.viewModel.registrationState, .completed)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testResendVerificationCode() {
        viewModel.registrationState = .awaitingVerification
        
        let expectation = self.expectation(description: "Code resent")
        
        viewModel.resendVerificationCode()
        XCTAssertTrue(viewModel.isLoading)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            XCTAssertFalse(self.viewModel.isLoading)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    // MARK: - Reset Tests
    func testResetRegistration() {
        // Setup some data
        viewModel.updateEmailAddress("test@example.com")
        viewModel.updatePhoneNumber("1234567890")
        viewModel.updateVerificationCode("123456")
        viewModel.registrationState = .awaitingVerification
        
        // Reset
        viewModel.resetRegistration()
        
        // Verify everything is reset
        XCTAssertEqual(viewModel.registrationState, .inputCredentials)
        XCTAssertEqual(viewModel.registrationData.inputMethod, .email)
        XCTAssertTrue(viewModel.registrationData.emailAddress.isEmpty)
        XCTAssertTrue(viewModel.registrationData.phoneNumber.isEmpty)
        XCTAssertTrue(viewModel.registrationData.verificationCode.isEmpty)
        XCTAssertTrue(viewModel.emailValidation.isValid)
        XCTAssertTrue(viewModel.phoneValidation.isValid)
        XCTAssertTrue(viewModel.verificationCodeValidation.isValid)
    }
    
    // MARK: - Error Handling Tests
    func testInputMethodSwitchClearsValidationErrors() {
        // Set invalid email and switch to phone
        viewModel.selectInputMethod(.email)
        viewModel.updateEmailAddress("invalid")
        XCTAssertFalse(viewModel.emailValidation.isValid)
        
        // Switch to phone should clear validation errors
        viewModel.selectInputMethod(.phone)
        XCTAssertTrue(viewModel.emailValidation.isValid)
        XCTAssertTrue(viewModel.phoneValidation.isValid)
        XCTAssertTrue(viewModel.verificationCodeValidation.isValid)
    }
} 