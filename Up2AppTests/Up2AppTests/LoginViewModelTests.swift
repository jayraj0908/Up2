import XCTest
@testable import Up2App

final class LoginViewModelTests: XCTestCase {
    
    var viewModel: LoginViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = LoginViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    func testInitialState() {
        XCTAssertEqual(viewModel.loginState, .inputCredentials)
        XCTAssertEqual(viewModel.loginData.inputMethod, .email)
        XCTAssertTrue(viewModel.loginData.emailAddress.isEmpty)
        XCTAssertTrue(viewModel.loginData.phoneNumber.isEmpty)
        XCTAssertTrue(viewModel.loginData.verificationCode.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.emailValidation, .valid)
        XCTAssertEqual(viewModel.phoneValidation, .valid)
        XCTAssertEqual(viewModel.verificationCodeValidation, .valid)
    }
    
    // MARK: - Input Method Toggle Tests
    func testSelectInputMethod() {
        // Start with email (default)
        XCTAssertEqual(viewModel.loginData.inputMethod, .email)
        
        // Switch to phone
        viewModel.selectInputMethod(.phone)
        XCTAssertEqual(viewModel.loginData.inputMethod, .phone)
        
        // Switch back to email
        viewModel.selectInputMethod(.email)
        XCTAssertEqual(viewModel.loginData.inputMethod, .email)
    }
    
    // MARK: - Email Input Tests
    func testUpdateEmailAddress() {
        let validEmail = "user@example.com"
        viewModel.updateEmailAddress(validEmail)
        
        XCTAssertEqual(viewModel.loginData.emailAddress, validEmail)
        XCTAssertTrue(viewModel.emailValidation.isValid)
        XCTAssertNil(viewModel.emailValidation.errorMessage)
    }
    
    func testUpdateEmailAddressInvalid() {
        let invalidEmail = "invalid-email"
        viewModel.updateEmailAddress(invalidEmail)
        
        XCTAssertEqual(viewModel.loginData.emailAddress, invalidEmail)
        XCTAssertFalse(viewModel.emailValidation.isValid)
        XCTAssertNotNil(viewModel.emailValidation.errorMessage)
    }
    
    func testUpdateEmailAddressEmpty() {
        viewModel.updateEmailAddress("")
        
        XCTAssertTrue(viewModel.loginData.emailAddress.isEmpty)
        XCTAssertFalse(viewModel.emailValidation.isValid)
        XCTAssertNotNil(viewModel.emailValidation.errorMessage)
    }
    
    // MARK: - Phone Input Tests
    func testUpdatePhoneNumber() {
        let validPhone = "+1234567890"
        viewModel.updatePhoneNumber(validPhone)
        
        XCTAssertEqual(viewModel.loginData.phoneNumber, validPhone)
        XCTAssertTrue(viewModel.phoneValidation.isValid)
        XCTAssertNil(viewModel.phoneValidation.errorMessage)
    }
    
    func testUpdatePhoneNumberInvalid() {
        let invalidPhone = "123"
        viewModel.updatePhoneNumber(invalidPhone)
        
        XCTAssertEqual(viewModel.loginData.phoneNumber, invalidPhone)
        XCTAssertFalse(viewModel.phoneValidation.isValid)
        XCTAssertNotNil(viewModel.phoneValidation.errorMessage)
    }
    
    func testUpdatePhoneNumberEmpty() {
        viewModel.updatePhoneNumber("")
        
        XCTAssertTrue(viewModel.loginData.phoneNumber.isEmpty)
        XCTAssertFalse(viewModel.phoneValidation.isValid)
        XCTAssertNotNil(viewModel.phoneValidation.errorMessage)
    }
    
    // MARK: - Verification Code Input Tests
    func testUpdateVerificationCode() {
        let validCode = "123456"
        viewModel.updateVerificationCode(validCode)
        
        XCTAssertEqual(viewModel.loginData.verificationCode, validCode)
        XCTAssertTrue(viewModel.verificationCodeValidation.isValid)
        XCTAssertNil(viewModel.verificationCodeValidation.errorMessage)
    }
    
    func testUpdateVerificationCodeShort() {
        let shortCode = "123"
        viewModel.updateVerificationCode(shortCode)
        
        XCTAssertEqual(viewModel.loginData.verificationCode, shortCode)
        XCTAssertFalse(viewModel.verificationCodeValidation.isValid)
        XCTAssertNotNil(viewModel.verificationCodeValidation.errorMessage)
    }
    
    func testUpdateVerificationCodeLong() {
        let longCode = "1234567"
        viewModel.updateVerificationCode(longCode)
        
        // Should be truncated to 6 digits
        XCTAssertEqual(viewModel.loginData.verificationCode, "123456")
        XCTAssertTrue(viewModel.verificationCodeValidation.isValid)
    }
    
    func testUpdateVerificationCodeNonNumeric() {
        let nonNumericCode = "abc123"
        viewModel.updateVerificationCode(nonNumericCode)
        
        // Should filter out non-numeric characters
        XCTAssertEqual(viewModel.loginData.verificationCode, "123")
        XCTAssertFalse(viewModel.verificationCodeValidation.isValid)
    }
    
    // MARK: - Computed Properties Tests
    func testCurrentInputValueEmail() {
        let email = "test@example.com"
        viewModel.selectInputMethod(.email)
        viewModel.updateEmailAddress(email)
        
        XCTAssertEqual(viewModel.currentInputValue, email)
    }
    
    func testCurrentInputValuePhone() {
        let phone = "+1234567890"
        viewModel.selectInputMethod(.phone)
        viewModel.updatePhoneNumber(phone)
        
        XCTAssertEqual(viewModel.currentInputValue, phone)
    }
    
    func testIsCurrentInputValidEmail() {
        viewModel.selectInputMethod(.email)
        viewModel.updateEmailAddress("valid@example.com")
        
        XCTAssertTrue(viewModel.isCurrentInputValid)
        
        viewModel.updateEmailAddress("invalid-email")
        XCTAssertFalse(viewModel.isCurrentInputValid)
    }
    
    func testIsCurrentInputValidPhone() {
        viewModel.selectInputMethod(.phone)
        viewModel.updatePhoneNumber("+1234567890")
        
        XCTAssertTrue(viewModel.isCurrentInputValid)
        
        viewModel.updatePhoneNumber("123")
        XCTAssertFalse(viewModel.isCurrentInputValid)
    }
    
    func testVerificationCodeValidation() {
        viewModel.updateVerificationCode("123456")
        XCTAssertTrue(viewModel.verificationCodeValidation.isValid)
        
        viewModel.updateVerificationCode("123")
        XCTAssertFalse(viewModel.verificationCodeValidation.isValid)
    }
    
    // MARK: - Login Flow Tests
    func testSendVerificationCodeWithEmailSuccess() {
        viewModel.selectInputMethod(.email)
        viewModel.updateEmailAddress("test@example.com")
        
        XCTAssertTrue(viewModel.isCurrentInputValid)
        
        // Test sending verification code
        let expectation = self.expectation(description: "Verification code sent")
        
        viewModel.sendVerificationCode()
        XCTAssertTrue(viewModel.isLoading)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            XCTAssertFalse(self.viewModel.isLoading)
            XCTAssertEqual(self.viewModel.loginState, .awaitingVerification)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testSendVerificationCodeWithPhoneSuccess() {
        viewModel.selectInputMethod(.phone)
        viewModel.updatePhoneNumber("+1234567890")
        
        XCTAssertTrue(viewModel.isCurrentInputValid)
        
        // Test sending verification code
        let expectation = self.expectation(description: "Verification code sent")
        
        viewModel.sendVerificationCode()
        XCTAssertTrue(viewModel.isLoading)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            XCTAssertFalse(self.viewModel.isLoading)
            XCTAssertEqual(self.viewModel.loginState, .awaitingVerification)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testSendVerificationCodeWithInvalidInput() {
        viewModel.selectInputMethod(.email)
        viewModel.updateEmailAddress("invalid-email")
        
        XCTAssertFalse(viewModel.isCurrentInputValid)
        
        // Should not send code with invalid input
        viewModel.sendVerificationCode()
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.loginState, .inputCredentials)
    }
    
    func testVerifyCodeWithValidCode() {
        // Setup verification state
        viewModel.loginState = .awaitingVerification
        viewModel.updateVerificationCode("123456")
        
        XCTAssertTrue(viewModel.verificationCodeValidation.isValid)
        
        // Test code verification
        let expectation = self.expectation(description: "Code verified")
        
        viewModel.verifyCodeAndLogin()
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertEqual(viewModel.loginState, .verifying)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            XCTAssertFalse(self.viewModel.isLoading)
            XCTAssertEqual(self.viewModel.loginState, .completed)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testVerifyCodeWithInvalidCode() {
        // Setup verification state with demo failing code
        viewModel.loginState = .awaitingVerification
        viewModel.updateVerificationCode("000000") // This code simulates failure
        
        XCTAssertTrue(viewModel.verificationCodeValidation.isValid) // Format is valid
        
        // Test code verification failure
        let expectation = self.expectation(description: "Code verification failed")
        
        viewModel.verifyCodeAndLogin()
        XCTAssertTrue(viewModel.isLoading)
        XCTAssertEqual(viewModel.loginState, .verifying)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            XCTAssertFalse(self.viewModel.isLoading)
            // Should be in error state
            if case .error = self.viewModel.loginState {
                // Expected error state
            } else {
                XCTFail("Expected error state, got \(self.viewModel.loginState)")
            }
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testVerifyCodeWithShortCode() {
        viewModel.loginState = .awaitingVerification
        viewModel.updateVerificationCode("123")
        
        XCTAssertFalse(viewModel.verificationCodeValidation.isValid)
        
        // Should not verify with invalid code format
        viewModel.verifyCodeAndLogin()
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.loginState, .awaitingVerification)
    }
    
    func testResendVerificationCode() {
        viewModel.loginState = .awaitingVerification
        
        let expectation = self.expectation(description: "Code resent")
        
        viewModel.resendVerificationCode()
        XCTAssertTrue(viewModel.isLoading)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            XCTAssertFalse(self.viewModel.isLoading)
            XCTAssertEqual(self.viewModel.loginState, .awaitingVerification)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testGoBackToCredentials() {
        viewModel.loginState = .awaitingVerification
        
        viewModel.goBackToCredentials()
        
        XCTAssertEqual(viewModel.loginState, .inputCredentials)
        XCTAssertTrue(viewModel.loginData.verificationCode.isEmpty)
    }
    
    // MARK: - Error Handling Tests
    func testHandleErrorFromFailedLogin() {
        viewModel.selectInputMethod(.email)
        viewModel.updateEmailAddress("notfound@example.com") // This email simulates user not found
        
        let expectation = self.expectation(description: "Login failed")
        
        viewModel.sendVerificationCode()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            // Should handle error gracefully
            if case .error(let message) = self.viewModel.loginState {
                XCTAssertFalse(message.isEmpty)
            } else {
                XCTFail("Expected error state, got \(self.viewModel.loginState)")
            }
            XCTAssertFalse(self.viewModel.isLoading)
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    // MARK: - State Reset Tests
    func testResetToInitialState() {
        // Modify state
        viewModel.loginState = .awaitingVerification
        viewModel.updateEmailAddress("test@example.com")
        viewModel.updateVerificationCode("123456")
        
        // Reset using goBackToCredentials
        viewModel.goBackToCredentials()
        
        XCTAssertEqual(viewModel.loginState, .inputCredentials)
        XCTAssertTrue(viewModel.loginData.verificationCode.isEmpty)
        // Email should remain to allow user to correct if needed
        XCTAssertEqual(viewModel.loginData.emailAddress, "test@example.com")
    }
} 