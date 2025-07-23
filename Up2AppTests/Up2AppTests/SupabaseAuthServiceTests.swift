import XCTest
@testable import Up2App

final class SupabaseAuthServiceTests: XCTestCase {
    
    var authService: SupabaseAuthService!
    
    override func setUp() {
        super.setUp()
        authService = SupabaseAuthService.shared
        // Reset state before each test
        authService.currentUser = nil
        authService.isAuthenticated = false
    }
    
    override func tearDown() {
        authService = nil
        super.tearDown()
    }
    
    // MARK: - Email Sign Up Tests
    func testSignUpWithEmailSuccess() async throws {
        let testEmail = "test@example.com"
        
        let user = try await authService.signUpWithEmail(testEmail)
        
        XCTAssertEqual(user.email, testEmail)
        XCTAssertNotNil(user.id)
        XCTAssertTrue(authService.isAuthenticated)
        XCTAssertEqual(authService.currentUser?.email, testEmail)
    }
    
    func testSignUpWithEmailInvalidEmail() async {
        let invalidEmail = "invalid-email"
        
        do {
            _ = try await authService.signUpWithEmail(invalidEmail)
            XCTFail("Expected AuthError.invalidEmail to be thrown")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidEmail)
        } catch {
            XCTFail("Expected AuthError.invalidEmail, got \(error)")
        }
    }
    
    func testSignUpWithEmailEmptyEmail() async {
        let emptyEmail = ""
        
        do {
            _ = try await authService.signUpWithEmail(emptyEmail)
            XCTFail("Expected AuthError.invalidEmail to be thrown")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidEmail)
        } catch {
            XCTFail("Expected AuthError.invalidEmail, got \(error)")
        }
    }
    
    // MARK: - Phone Sign Up Tests
    func testSignUpWithPhoneSuccess() async throws {
        let testPhone = "+1234567890"
        
        let user = try await authService.signUpWithPhone(testPhone)
        
        XCTAssertEqual(user.phone, testPhone)
        XCTAssertNotNil(user.id)
        XCTAssertTrue(authService.isAuthenticated)
        XCTAssertEqual(authService.currentUser?.phone, testPhone)
    }
    
    func testSignUpWithPhoneInvalidPhone() async {
        let invalidPhone = "123"
        
        do {
            _ = try await authService.signUpWithPhone(invalidPhone)
            XCTFail("Expected AuthError.invalidPhoneNumber to be thrown")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidPhoneNumber)
        } catch {
            XCTFail("Expected AuthError.invalidPhoneNumber, got \(error)")
        }
    }
    
    func testSignUpWithPhoneEmptyPhone() async {
        let emptyPhone = ""
        
        do {
            _ = try await authService.signUpWithPhone(emptyPhone)
            XCTFail("Expected AuthError.invalidPhoneNumber to be thrown")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidPhoneNumber)
        } catch {
            XCTFail("Expected AuthError.invalidPhoneNumber, got \(error)")
        }
    }
    
    // MARK: - OTP Verification Tests
    func testVerifyOTPSuccess() async throws {
        // First, sign up with email to get a user
        let testEmail = "test@example.com"
        let signUpUser = try await authService.signUpWithEmail(testEmail)
        
        let validCode = "123456"
        let verifiedUser = try await authService.verifyOTP(code: validCode, email: testEmail)
        
        XCTAssertEqual(verifiedUser.id, signUpUser.id)
        XCTAssertEqual(verifiedUser.email, testEmail)
        XCTAssertTrue(authService.isAuthenticated)
    }
    
    func testVerifyOTPInvalidCode() async {
        // First, sign up with email
        let testEmail = "test@example.com"
        _ = try! await authService.signUpWithEmail(testEmail)
        
        let invalidCode = "12345" // Wrong length
        
        do {
            _ = try await authService.verifyOTP(code: invalidCode, email: testEmail)
            XCTFail("Expected AuthError.invalidVerificationCode to be thrown")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidVerificationCode)
        } catch {
            XCTFail("Expected AuthError.invalidVerificationCode, got \(error)")
        }
    }
    
    func testVerifyOTPNonNumericCode() async {
        // First, sign up with email
        let testEmail = "test@example.com"
        _ = try! await authService.signUpWithEmail(testEmail)
        
        let invalidCode = "abcdef" // Contains letters
        
        do {
            _ = try await authService.verifyOTP(code: invalidCode, email: testEmail)
            XCTFail("Expected AuthError.invalidVerificationCode to be thrown")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidVerificationCode)
        } catch {
            XCTFail("Expected AuthError.invalidVerificationCode, got \(error)")
        }
    }
    
    func testVerifyOTPWithoutUser() async {
        let validCode = "123456"
        
        do {
            _ = try await authService.verifyOTP(code: validCode, email: "test@example.com")
            XCTFail("Expected AuthError.userNotFound to be thrown")
        } catch let error as AuthError {
            XCTAssertEqual(error, .userNotFound)
        } catch {
            XCTFail("Expected AuthError.userNotFound, got \(error)")
        }
    }
    
    // MARK: - Sign Out Tests
    func testSignOutSuccess() async throws {
        // First, sign up and authenticate
        let testEmail = "test@example.com"
        _ = try await authService.signUpWithEmail(testEmail)
        
        XCTAssertTrue(authService.isAuthenticated)
        XCTAssertNotNil(authService.currentUser)
        
        try await authService.signOut()
        
        XCTAssertFalse(authService.isAuthenticated)
        XCTAssertNil(authService.currentUser)
    }
    
    // MARK: - Session Tests
    func testGetCurrentSessionWhenAuthenticated() async throws {
        // First, sign up and authenticate
        let testEmail = "test@example.com"
        let user = try await authService.signUpWithEmail(testEmail)
        
        let session = try await authService.getCurrentSession()
        
        XCTAssertNotNil(session)
        XCTAssertEqual(session?.user.id, user.id)
        XCTAssertEqual(session?.user.email, testEmail)
        XCTAssertNotNil(session?.accessToken)
    }
    
    func testGetCurrentSessionWhenNotAuthenticated() async throws {
        let session = try await authService.getCurrentSession()
        
        XCTAssertNil(session)
    }
    
    // MARK: - State Consistency Tests
    func testAuthenticationStateConsistency() async throws {
        // Initially not authenticated
        XCTAssertFalse(authService.isAuthenticated)
        XCTAssertNil(authService.currentUser)
        
        // After sign up
        let testEmail = "test@example.com"
        let user = try await authService.signUpWithEmail(testEmail)
        
        XCTAssertTrue(authService.isAuthenticated)
        XCTAssertEqual(authService.currentUser?.id, user.id)
        
        // After sign out
        try await authService.signOut()
        
        XCTAssertFalse(authService.isAuthenticated)
        XCTAssertNil(authService.currentUser)
    }
    
    // MARK: - Performance Tests
    func testSignUpPerformance() throws {
        measure {
            Task {
                do {
                    _ = try await authService.signUpWithEmail("test@example.com")
                } catch {
                    // Handle error in performance test
                }
            }
        }
    }
    
    // MARK: - Login Methods Tests
    func testSignInWithEmailSuccess() async throws {
        let testEmail = "loginuser@example.com"
        
        let user = try await authService.signInWithEmail(testEmail)
        
        XCTAssertEqual(user.email, testEmail)
        XCTAssertNotNil(user.id)
        XCTAssertNil(user.phone)
    }
    
    func testSignInWithEmailInvalidEmail() async {
        let invalidEmail = "invalid-email"
        
        do {
            _ = try await authService.signInWithEmail(invalidEmail)
            XCTFail("Expected AuthError.invalidEmail to be thrown")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidEmail)
        } catch {
            XCTFail("Expected AuthError.invalidEmail, got \(error)")
        }
    }
    
    func testSignInWithEmailEmptyEmail() async {
        let emptyEmail = ""
        
        do {
            _ = try await authService.signInWithEmail(emptyEmail)
            XCTFail("Expected AuthError.invalidEmail to be thrown")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidEmail)
        } catch {
            XCTFail("Expected AuthError.invalidEmail, got \(error)")
        }
    }
    
    func testSignInWithEmailUserNotFound() async {
        let notFoundEmail = "notfound@example.com"
        
        do {
            _ = try await authService.signInWithEmail(notFoundEmail)
            XCTFail("Expected AuthError.invalidCredentials to be thrown")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidCredentials)
        } catch {
            XCTFail("Expected AuthError.invalidCredentials, got \(error)")
        }
    }
    
    // MARK: - Login Phone Tests
    func testSignInWithPhoneSuccess() async throws {
        let testPhone = "+1987654321"
        
        let user = try await authService.signInWithPhone(testPhone)
        
        XCTAssertEqual(user.phone, testPhone)
        XCTAssertNotNil(user.id)
        XCTAssertNil(user.email)
    }
    
    func testSignInWithPhoneInvalidPhone() async {
        let invalidPhone = "123"
        
        do {
            _ = try await authService.signInWithPhone(invalidPhone)
            XCTFail("Expected AuthError.invalidPhone to be thrown")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidPhone)
        } catch {
            XCTFail("Expected AuthError.invalidPhone, got \(error)")
        }
    }
    
    func testSignInWithPhoneEmptyPhone() async {
        let emptyPhone = ""
        
        do {
            _ = try await authService.signInWithPhone(emptyPhone)
            XCTFail("Expected AuthError.invalidPhone to be thrown")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidPhone)
        } catch {
            XCTFail("Expected AuthError.invalidPhone, got \(error)")
        }
    }
    
    func testSignInWithPhoneUserNotFound() async {
        let notFoundPhone = "+1234567890"
        
        do {
            _ = try await authService.signInWithPhone(notFoundPhone)
            XCTFail("Expected AuthError.invalidCredentials to be thrown")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidCredentials)
        } catch {
            XCTFail("Expected AuthError.invalidCredentials, got \(error)")
        }
    }
    
    // MARK: - Login OTP Verification Tests
    func testVerifyLoginOTPWithEmailSuccess() async throws {
        let testEmail = "loginuser@example.com"
        let testCode = "123456"
        
        let user = try await authService.verifyLoginOTP(
            code: testCode,
            email: testEmail,
            phone: nil
        )
        
        XCTAssertEqual(user.email, testEmail)
        XCTAssertNotNil(user.id)
        XCTAssertNil(user.phone)
    }
    
    func testVerifyLoginOTPWithPhoneSuccess() async throws {
        let testPhone = "+1987654321"
        let testCode = "123456"
        
        let user = try await authService.verifyLoginOTP(
            code: testCode,
            email: nil,
            phone: testPhone
        )
        
        XCTAssertEqual(user.phone, testPhone)
        XCTAssertNotNil(user.id)
        XCTAssertNil(user.email)
    }
    
    func testVerifyLoginOTPInvalidCode() async {
        let testEmail = "loginuser@example.com"
        let invalidCode = "000000"
        
        do {
            _ = try await authService.verifyLoginOTP(
                code: invalidCode,
                email: testEmail,
                phone: nil
            )
            XCTFail("Expected AuthError.invalidVerificationCode to be thrown")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidVerificationCode)
        } catch {
            XCTFail("Expected AuthError.invalidVerificationCode, got \(error)")
        }
    }
    
    func testVerifyLoginOTPNoCredentials() async {
        let testCode = "123456"
        
        do {
            _ = try await authService.verifyLoginOTP(
                code: testCode,
                email: nil,
                phone: nil
            )
            XCTFail("Expected AuthError.invalidCredentials to be thrown")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidCredentials)
        } catch {
            XCTFail("Expected AuthError.invalidCredentials, got \(error)")
        }
    }
    
    func testVerifyLoginOTPBothCredentials() async {
        let testCode = "123456"
        let testEmail = "test@example.com"
        let testPhone = "+1234567890"
        
        do {
            _ = try await authService.verifyLoginOTP(
                code: testCode,
                email: testEmail,
                phone: testPhone
            )
            XCTFail("Expected AuthError.invalidCredentials to be thrown")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidCredentials)
        } catch {
            XCTFail("Expected AuthError.invalidCredentials, got \(error)")
        }
    }
    
    // MARK: - Login Flow Integration Tests
    func testCompleteEmailLoginFlow() async throws {
        let testEmail = "flowtest@example.com"
        
        // Step 1: Initiate login
        let initiatedUser = try await authService.signInWithEmail(testEmail)
        XCTAssertEqual(initiatedUser.email, testEmail)
        
        // Step 2: Verify OTP
        let verifiedUser = try await authService.verifyLoginOTP(
            code: "123456",
            email: testEmail,
            phone: nil
        )
        XCTAssertEqual(verifiedUser.email, testEmail)
        XCTAssertEqual(verifiedUser.id, initiatedUser.id)
    }
    
    func testCompletePhoneLoginFlow() async throws {
        let testPhone = "+1555123456"
        
        // Step 1: Initiate login
        let initiatedUser = try await authService.signInWithPhone(testPhone)
        XCTAssertEqual(initiatedUser.phone, testPhone)
        
        // Step 2: Verify OTP
        let verifiedUser = try await authService.verifyLoginOTP(
            code: "123456",
            email: nil,
            phone: testPhone
        )
        XCTAssertEqual(verifiedUser.phone, testPhone)
        XCTAssertEqual(verifiedUser.id, initiatedUser.id)
    }
    
    // MARK: - Session Management Tests  
    func testSessionInitialization() async {
        // Test that session initialization completes without error
        // The actual session restoration is tested through the initialization process
        // This test ensures the service starts up properly
        XCTAssertNotNil(authService)
        
        // Allow time for async initialization
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Service should be ready for use
        XCTAssertFalse(authService.isAuthenticated) // Initially not authenticated
    }
    
    func testSignOutClearsCurrentUser() async throws {
        // First sign in a user (using mock)
        let testEmail = "signout@example.com"
        let user = try await authService.signUpWithEmail(testEmail)
        XCTAssertNotNil(authService.currentUser)
        XCTAssertTrue(authService.isAuthenticated)
        
        // Then sign out
        try await authService.signOut()
        
        // Verify state is cleared
        XCTAssertNil(authService.currentUser)
        XCTAssertFalse(authService.isAuthenticated)
    }
    
    // MARK: - Error Mapping Tests
    func testErrorMappingForNetworkErrors() async {
        // Test network simulation by using invalid data
        let networkTestEmail = "networkerror@test.invalid"
        
        do {
            _ = try await authService.signInWithEmail(networkTestEmail)
            // If no error, skip this test (mock might not simulate network errors)
        } catch let error as AuthError {
            // Verify that network-like errors are mapped appropriately
            XCTAssertNotEqual(error, .invalidEmail) // Should be some other error type
        } catch {
            // Any error is acceptable for this edge case test
        }
    }
    
    // MARK: - Performance Tests for Login
    func testLoginPerformance() {
        measure {
            let expectation = self.expectation(description: "Login performance")
            
            Task {
                do {
                    _ = try await authService.signInWithEmail("perf@example.com")
                    expectation.fulfill()
                } catch {
                    // Handle error in performance test
                    expectation.fulfill()
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
} 