import XCTest
@testable import Up2App

final class AppStateManagerTests: XCTestCase {
    
    var appStateManager: AppStateManager!
    
    override func setUp() {
        super.setUp()
        appStateManager = AppStateManager.shared
        // Reset to initial state
        appStateManager.appState = .loading
        appStateManager.isAuthenticated = false
        appStateManager.currentUser = nil
        appStateManager.currentUserProfile = nil
    }
    
    override func tearDown() {
        appStateManager = nil
        super.tearDown()
    }
    
    // MARK: - Initial State Tests
    func testInitialState() {
        XCTAssertEqual(appStateManager.appState, .loading)
        XCTAssertFalse(appStateManager.isAuthenticated)
        XCTAssertNil(appStateManager.currentUser)
        XCTAssertNil(appStateManager.currentUserProfile)
    }
    
    // MARK: - Navigation Tests
    func testNavigateToAuthentication() {
        // Start from a different state
        appStateManager.appState = .mainApp
        appStateManager.isAuthenticated = true
        
        appStateManager.navigateToAuthentication()
        
        XCTAssertEqual(appStateManager.appState, .authentication)
        XCTAssertFalse(appStateManager.isAuthenticated)
        XCTAssertNil(appStateManager.currentUser)
        XCTAssertNil(appStateManager.currentUserProfile)
    }
    
    func testNavigateToProfileSetup() {
        appStateManager.navigateToProfileSetup()
        
        XCTAssertEqual(appStateManager.appState, .profileSetup)
    }
    
    func testNavigateToMainApp() {
        appStateManager.navigateToMainApp()
        
        XCTAssertEqual(appStateManager.appState, .mainApp)
    }
    
    // MARK: - Registration Complete Tests
    func testHandleRegistrationCompleteWithIncompleteProfile() {
        // Create incomplete profile
        let incompleteProfile = UserProfile(
            id: "test-id",
            email: "test@example.com",
            phone: nil,
            name: "", // Empty name
            handle: "", // Empty handle
            avatar: nil,
            vibeTags: [],
            bio: "",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        appStateManager.currentUserProfile = incompleteProfile
        
        appStateManager.handleRegistrationComplete()
        
        XCTAssertEqual(appStateManager.appState, .profileSetup)
    }
    
    func testHandleRegistrationCompleteWithCompleteProfile() {
        // Create complete profile
        let completeProfile = UserProfile(
            id: "test-id",
            email: "test@example.com",
            phone: nil,
            name: "John Doe", // Has name
            handle: "johndoe", // Has handle
            avatar: nil,
            vibeTags: [],
            bio: "",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        appStateManager.currentUserProfile = completeProfile
        
        appStateManager.handleRegistrationComplete()
        
        XCTAssertEqual(appStateManager.appState, .mainApp)
    }
    
    func testHandleRegistrationCompleteWithoutProfile() {
        appStateManager.currentUserProfile = nil
        
        appStateManager.handleRegistrationComplete()
        
        // Should go to profile setup when no profile exists
        XCTAssertEqual(appStateManager.appState, .profileSetup)
    }
    
    // MARK: - Login Complete Tests
    func testHandleLoginCompleteWithIncompleteProfile() {
        // Create incomplete profile
        let incompleteProfile = UserProfile(
            id: "test-id",
            email: "test@example.com",
            phone: nil,
            name: "", // Empty name
            handle: "", // Empty handle
            avatar: nil,
            vibeTags: [],
            bio: "",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        appStateManager.currentUserProfile = incompleteProfile
        
        appStateManager.handleLoginComplete()
        
        XCTAssertEqual(appStateManager.appState, .profileSetup)
    }
    
    func testHandleLoginCompleteWithCompleteProfile() {
        // Create complete profile
        let completeProfile = UserProfile(
            id: "test-id",
            email: "test@example.com",
            phone: nil,
            name: "John Doe", // Has name
            handle: "johndoe", // Has handle
            avatar: nil,
            vibeTags: [],
            bio: "",
            createdAt: Date(),
            updatedAt: Date()
        )
        
        appStateManager.currentUserProfile = completeProfile
        
        appStateManager.handleLoginComplete()
        
        XCTAssertEqual(appStateManager.appState, .mainApp)
    }
    
    // MARK: - Logout Tests
    func testHandleLogoutSuccess() async {
        // Set up authenticated state
        appStateManager.appState = .mainApp
        appStateManager.isAuthenticated = true
        appStateManager.currentUser = AuthUser(
            id: "test-id",
            email: "test@example.com",
            phone: nil,
            createdAt: Date()
        )
        
        // Note: This test will call the real SupabaseAuthService.signOut() 
        // In a real test environment, you would mock this service
        await appStateManager.handleLogout()
        
        // Wait a moment for async operations to complete
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        XCTAssertEqual(appStateManager.appState, .authentication)
        XCTAssertFalse(appStateManager.isAuthenticated)
        XCTAssertNil(appStateManager.currentUser)
        XCTAssertNil(appStateManager.currentUserProfile)
    }
    
    // MARK: - App State Description Tests
    func testAppStateDescriptions() {
        XCTAssertEqual(AppState.loading.description, "Loading")
        XCTAssertEqual(AppState.authentication.description, "Authentication")
        XCTAssertEqual(AppState.profileSetup.description, "Profile Setup")
        XCTAssertEqual(AppState.mainApp.description, "Main App")
    }
    
    // MARK: - State Transition Tests
    func testCompleteAuthenticationFlow() {
        // Start with loading
        appStateManager.appState = .loading
        
        // Navigate to authentication
        appStateManager.navigateToAuthentication()
        XCTAssertEqual(appStateManager.appState, .authentication)
        
        // Complete registration with incomplete profile
        let incompleteProfile = UserProfile(
            id: "test-id",
            email: "test@example.com",
            phone: nil,
            name: "",
            handle: "",
            avatar: nil,
            vibeTags: [],
            bio: "",
            createdAt: Date(),
            updatedAt: Date()
        )
        appStateManager.currentUserProfile = incompleteProfile
        appStateManager.handleRegistrationComplete()
        XCTAssertEqual(appStateManager.appState, .profileSetup)
        
        // Complete profile setup
        appStateManager.navigateToMainApp()
        XCTAssertEqual(appStateManager.appState, .mainApp)
    }
    
    // MARK: - User Profile Integration Tests
    func testUserProfileCompletenesDetection() {
        // Test incomplete profile (missing name)
        let incompleteProfile1 = UserProfile(
            id: "test-id",
            email: "test@example.com",
            phone: nil,
            name: "", // Missing name
            handle: "johndoe",
            avatar: nil,
            vibeTags: [],
            bio: "",
            createdAt: Date(),
            updatedAt: Date()
        )
        XCTAssertFalse(incompleteProfile1.isProfileComplete)
        
        // Test incomplete profile (missing handle)
        let incompleteProfile2 = UserProfile(
            id: "test-id",
            email: "test@example.com",
            phone: nil,
            name: "John Doe",
            handle: "", // Missing handle
            avatar: nil,
            vibeTags: [],
            bio: "",
            createdAt: Date(),
            updatedAt: Date()
        )
        XCTAssertFalse(incompleteProfile2.isProfileComplete)
        
        // Test complete profile
        let completeProfile = UserProfile(
            id: "test-id",
            email: "test@example.com",
            phone: nil,
            name: "John Doe", // Has name
            handle: "johndoe", // Has handle
            avatar: nil,
            vibeTags: [],
            bio: "",
            createdAt: Date(),
            updatedAt: Date()
        )
        XCTAssertTrue(completeProfile.isProfileComplete)
    }
    
    // MARK: - Display Name Tests
    func testUserProfileDisplayName() {
        // Test with name
        let profileWithName = UserProfile(
            id: "test-id",
            email: "test@example.com",
            phone: nil,
            name: "John Doe",
            handle: "",
            avatar: nil,
            vibeTags: [],
            bio: "",
            createdAt: Date(),
            updatedAt: Date()
        )
        XCTAssertEqual(profileWithName.displayName, "John Doe")
        
        // Test with handle only
        let profileWithHandle = UserProfile(
            id: "test-id",
            email: "test@example.com",
            phone: nil,
            name: "",
            handle: "johndoe",
            avatar: nil,
            vibeTags: [],
            bio: "",
            createdAt: Date(),
            updatedAt: Date()
        )
        XCTAssertEqual(profileWithHandle.displayName, "@johndoe")
        
        // Test with email only
        let profileWithEmail = UserProfile(
            id: "test-id",
            email: "test@example.com",
            phone: nil,
            name: "",
            handle: "",
            avatar: nil,
            vibeTags: [],
            bio: "",
            createdAt: Date(),
            updatedAt: Date()
        )
        XCTAssertEqual(profileWithEmail.displayName, "test@example.com")
        
        // Test with phone only
        let profileWithPhone = UserProfile(
            id: "test-id",
            email: nil,
            phone: "+1234567890",
            name: "",
            handle: "",
            avatar: nil,
            vibeTags: [],
            bio: "",
            createdAt: Date(),
            updatedAt: Date()
        )
        XCTAssertEqual(profileWithPhone.displayName, "+1234567890")
        
        // Test fallback
        let emptyProfile = UserProfile(
            id: "test-id",
            email: nil,
            phone: nil,
            name: "",
            handle: "",
            avatar: nil,
            vibeTags: [],
            bio: "",
            createdAt: Date(),
            updatedAt: Date()
        )
        XCTAssertEqual(emptyProfile.displayName, "User")
    }
    
    // MARK: - Login Navigation Flow Tests
    func testLoginNavigationFlow() {
        // Start in authentication flow
        XCTAssertEqual(appStateManager.appFlow, .authentication)
        XCTAssertFalse(appStateManager.isUserAuthenticated)
        
        // Simulate successful login
        let loginUser = SupabaseAuthService.AuthUser(
            id: "login123",
            email: "loginuser@example.com",
            phone: nil
        )
        
        appStateManager.setCurrentUser(loginUser)
        
        // Should navigate to profile setup
        XCTAssertTrue(appStateManager.isUserAuthenticated)
        XCTAssertEqual(appStateManager.appFlow, .profileSetup)
        XCTAssertEqual(appStateManager.currentUser?.email, "loginuser@example.com")
    }
    
    func testLoginWithExistingProfileNavigation() {
        // Simulate user with existing profile
        appStateManager.hasProfileSetup = true
        
        let loginUser = SupabaseAuthService.AuthUser(
            id: "existing123",
            email: "existing@example.com",
            phone: nil
        )
        
        appStateManager.setCurrentUser(loginUser)
        
        // Should navigate directly to main app
        XCTAssertTrue(appStateManager.isUserAuthenticated)
        XCTAssertEqual(appStateManager.appFlow, .mainApp)
    }
    
    func testLoginPhoneUserNavigation() {
        let phoneUser = SupabaseAuthService.AuthUser(
            id: "phone123",
            email: nil,
            phone: "+1234567890"
        )
        
        appStateManager.setCurrentUser(phoneUser)
        
        XCTAssertTrue(appStateManager.isUserAuthenticated)
        XCTAssertEqual(appStateManager.appFlow, .profileSetup)
        XCTAssertEqual(appStateManager.currentUser?.phone, "+1234567890")
        XCTAssertNil(appStateManager.currentUser?.email)
    }
    
    func testLoginSessionPersistence() {
        // Simulate login
        let user = SupabaseAuthService.AuthUser(
            id: "persist123",
            email: "persist@example.com",
            phone: nil
        )
        
        appStateManager.setCurrentUser(user)
        appStateManager.completeProfileSetup()
        
        XCTAssertEqual(appStateManager.appFlow, .mainApp)
        XCTAssertTrue(appStateManager.hasProfileSetup)
        
        // Verify profile setup state is persisted
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hasCompletedProfileSetup"))
    }
    
    func testLoginAfterSignOut() {
        // First establish a session
        let user = SupabaseAuthService.AuthUser(
            id: "signout123",
            email: "signout@example.com",
            phone: nil
        )
        
        appStateManager.setCurrentUser(user)
        appStateManager.completeProfileSetup()
        
        XCTAssertEqual(appStateManager.appFlow, .mainApp)
        
        // Sign out
        appStateManager.signOut()
        
        XCTAssertFalse(appStateManager.isUserAuthenticated)
        XCTAssertNil(appStateManager.currentUser)
        XCTAssertEqual(appStateManager.appFlow, .authentication)
        
        // Login again
        let newUser = SupabaseAuthService.AuthUser(
            id: "newlogin123",
            email: "newlogin@example.com",
            phone: nil
        )
        
        appStateManager.setCurrentUser(newUser)
        
        // Should go to main app since profile was already set up
        XCTAssertTrue(appStateManager.isUserAuthenticated)
        XCTAssertEqual(appStateManager.appFlow, .mainApp)
    }
    
    func testInitializationStateHandling() {
        // Test that app starts in initializing state
        let newAppState = AppStateManager.shared
        XCTAssertTrue(newAppState.isInitializing)
        
        // Simulate initialization completion
        newAppState.finishInitialization()
        XCTAssertFalse(newAppState.isInitializing)
    }
    
    // MARK: - Login Error Handling Tests
    func testLoginErrorHandling() {
        // Start with authenticated state
        let user = SupabaseAuthService.AuthUser(
            id: "error123",
            email: "error@example.com",
            phone: nil
        )
        
        appStateManager.setCurrentUser(user)
        XCTAssertTrue(appStateManager.isUserAuthenticated)
        
        // Simulate authentication error by clearing user
        appStateManager.setCurrentUser(nil)
        
        // Should reset to authentication flow
        XCTAssertFalse(appStateManager.isUserAuthenticated)
        XCTAssertEqual(appStateManager.appFlow, .authentication)
        XCTAssertNil(appStateManager.currentUser)
    }
    
    func testMultipleUserSwitching() {
        // Login first user
        let user1 = SupabaseAuthService.AuthUser(
            id: "user1",
            email: "user1@example.com",
            phone: nil
        )
        
        appStateManager.setCurrentUser(user1)
        XCTAssertEqual(appStateManager.currentUser?.id, "user1")
        
        // Switch to second user (simulating logout and new login)
        appStateManager.signOut()
        
        let user2 = SupabaseAuthService.AuthUser(
            id: "user2",
            email: "user2@example.com",
            phone: nil
        )
        
        appStateManager.setCurrentUser(user2)
        
        XCTAssertEqual(appStateManager.currentUser?.id, "user2")
        XCTAssertEqual(appStateManager.currentUser?.email, "user2@example.com")
        XCTAssertTrue(appStateManager.isUserAuthenticated)
    }
    
    // MARK: - App Flow State Validation Tests
    func testAppFlowStateConsistency() {
        // Test that app flow states are consistent with authentication state
        
        // Unauthenticated state
        XCTAssertFalse(appStateManager.isUserAuthenticated)
        XCTAssertEqual(appStateManager.appFlow, .authentication)
        
        // Authenticated without profile
        let user = SupabaseAuthService.AuthUser(
            id: "flow123",
            email: "flow@example.com",
            phone: nil
        )
        
        appStateManager.setCurrentUser(user)
        
        XCTAssertTrue(appStateManager.isUserAuthenticated)
        XCTAssertEqual(appStateManager.appFlow, .profileSetup)
        
        // Complete profile setup
        appStateManager.completeProfileSetup()
        
        XCTAssertEqual(appStateManager.appFlow, .mainApp)
        XCTAssertTrue(appStateManager.hasProfileSetup)
    }
    
    func testProfileSetupStateTransitions() {
        // Start with no profile setup
        XCTAssertFalse(appStateManager.hasProfileSetup)
        
        let user = SupabaseAuthService.AuthUser(
            id: "setup123",
            email: "setup@example.com",
            phone: nil
        )
        
        appStateManager.setCurrentUser(user)
        XCTAssertEqual(appStateManager.appFlow, .profileSetup)
        
        // Complete profile setup
        appStateManager.completeProfileSetup()
        
        XCTAssertTrue(appStateManager.hasProfileSetup)
        XCTAssertEqual(appStateManager.appFlow, .mainApp)
        
        // Verify persistence
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "hasCompletedProfileSetup"))
    }
    
    // MARK: - Performance Tests
    func testNavigationPerformance() {
        measure {
            for i in 0..<100 {
                let user = SupabaseAuthService.AuthUser(
                    id: "perf\(i)",
                    email: "perf\(i)@example.com",
                    phone: nil
                )
                
                appStateManager.setCurrentUser(user)
                appStateManager.signOut()
            }
        }
    }
} 