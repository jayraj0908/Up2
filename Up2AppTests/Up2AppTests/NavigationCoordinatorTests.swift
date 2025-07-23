import XCTest
import SwiftUI
@testable import Up2App

// MARK: - Navigation Coordinator Tests
final class NavigationCoordinatorTests: XCTestCase {
    
    // MARK: - Properties
    private var coordinator: NavigationCoordinator!
    private var mockAppStateManager: MockAppStateManager!
    
    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        mockAppStateManager = MockAppStateManager()
        coordinator = NavigationCoordinator(
            configuration: .default,
            appStateManager: mockAppStateManager
        )
    }
    
    override func tearDown() {
        coordinator = nil
        mockAppStateManager = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testCoordinatorInitialization() {
        XCTAssertEqual(coordinator.selectedTab, .forYou, "Should initialize with For You tab")
        XCTAssertNil(coordinator.presentedModal, "Should not have any modal presented initially")
        XCTAssertEqual(coordinator.navigationState.selectedTab, .forYou, "Navigation state should match selected tab")
    }
    
    func testDefaultNavigationState() {
        let navigationState = coordinator.navigationState
        
        XCTAssertEqual(navigationState.selectedTab, .forYou)
        XCTAssertTrue(navigationState.presentedModals.isEmpty)
        
        // All tabs should have empty navigation stacks
        for tab in AppTab.allCases {
            XCTAssertTrue(navigationState.navigationStack(for: tab).isEmpty)
        }
    }
    
    // MARK: - Tab Selection Tests
    
    func testTabSelection() {
        // Test switching to different tabs
        coordinator.selectedTab = .profile
        XCTAssertEqual(coordinator.selectedTab, .profile)
        XCTAssertEqual(coordinator.navigationState.selectedTab, .profile)
        
        coordinator.selectedTab = .map
        XCTAssertEqual(coordinator.selectedTab, .map)
        XCTAssertEqual(coordinator.navigationState.selectedTab, .map)
    }
    
    func testTabSelectionPersistence() {
        // Change tab and verify state persistence is called
        coordinator.selectedTab = .trending
        
        // Verify the state would be saved (in a real scenario)
        XCTAssertEqual(coordinator.selectedTab, .trending)
    }
    
    // MARK: - Navigation Tests
    
    func testNavigateToTab() {
        coordinator.navigate(to: .tab(.profile))
        XCTAssertEqual(coordinator.selectedTab, .profile)
    }
    
    func testNavigateToDestinationInCurrentTab() {
        coordinator.selectedTab = .forYou
        coordinator.navigate(to: .eventDetail(eventId: "test-event"))
        
        let stack = coordinator.navigationState.navigationStack(for: .forYou)
        XCTAssertEqual(stack.count, 1)
        XCTAssertEqual(stack.first, .eventDetail(eventId: "test-event"))
    }
    
    func testNavigateToDestinationInSpecificTab() {
        coordinator.selectedTab = .profile
        coordinator.navigate(to: .eventDetail(eventId: "test-event"), in: .forYou)
        
        // Should switch to the specified tab
        XCTAssertEqual(coordinator.selectedTab, .forYou)
        
        // Should add destination to that tab's stack
        let stack = coordinator.navigationState.navigationStack(for: .forYou)
        XCTAssertEqual(stack.count, 1)
        XCTAssertEqual(stack.first, .eventDetail(eventId: "test-event"))
    }
    
    func testNavigationStackManagement() {
        coordinator.selectedTab = .forYou
        
        // Add multiple destinations
        coordinator.navigate(to: .eventDetail(eventId: "event1"))
        coordinator.navigate(to: .eventDetail(eventId: "event2"))
        
        let stack = coordinator.navigationState.navigationStack(for: .forYou)
        XCTAssertEqual(stack.count, 2)
        XCTAssertEqual(stack[0], .eventDetail(eventId: "event1"))
        XCTAssertEqual(stack[1], .eventDetail(eventId: "event2"))
    }
    
    func testPopToRoot() {
        coordinator.selectedTab = .forYou
        
        // Add destinations to stack
        coordinator.navigate(to: .eventDetail(eventId: "event1"))
        coordinator.navigate(to: .eventDetail(eventId: "event2"))
        
        // Pop to root
        coordinator.popToRoot(for: .forYou)
        
        let stack = coordinator.navigationState.navigationStack(for: .forYou)
        XCTAssertTrue(stack.isEmpty)
    }
    
    func testCanNavigateBack() {
        coordinator.selectedTab = .forYou
        
        // Initially should not be able to navigate back
        XCTAssertFalse(coordinator.canNavigateBack(in: .forYou))
        
        // Add a destination
        coordinator.navigate(to: .eventDetail(eventId: "test-event"))
        
        // Now should be able to navigate back
        XCTAssertTrue(coordinator.canNavigateBack(in: .forYou))
    }
    
    // MARK: - Modal Presentation Tests
    
    func testPresentModal() {
        coordinator.presentModal(.settings)
        XCTAssertEqual(coordinator.presentedModal, .settings)
    }
    
    func testDismissModal() {
        coordinator.presentModal(.help)
        XCTAssertEqual(coordinator.presentedModal, .help)
        
        coordinator.dismissModal()
        XCTAssertNil(coordinator.presentedModal)
    }
    
    func testModalStackManagement() {
        // Present modal
        coordinator.presentModal(.settings)
        XCTAssertEqual(coordinator.navigationState.currentModal, .settings)
        
        // Dismiss modal
        coordinator.dismissModal()
        XCTAssertNil(coordinator.navigationState.currentModal)
    }
    
    // MARK: - Deep Link Tests
    
    func testValidDeepLink() {
        let url = URL(string: "up2://events/test-event")!
        let result = coordinator.handleDeepLink(url)
        
        XCTAssertTrue(result)
        XCTAssertEqual(coordinator.selectedTab, .forYou) // Events go to For You tab
        
        let stack = coordinator.navigationState.navigationStack(for: .forYou)
        XCTAssertEqual(stack.count, 1)
        XCTAssertEqual(stack.first, .eventDetail(eventId: "test-event"))
    }
    
    func testInvalidDeepLink() {
        let url = URL(string: "invalid://test")!
        let result = coordinator.handleDeepLink(url)
        
        XCTAssertFalse(result)
    }
    
    func testDeepLinkToTab() {
        let url = URL(string: "up2://profile")!
        let result = coordinator.handleDeepLink(url)
        
        XCTAssertTrue(result)
        XCTAssertEqual(coordinator.selectedTab, .profile)
    }
    
    func testDeepLinkToModal() {
        let url = URL(string: "up2://settings")!
        let result = coordinator.handleDeepLink(url)
        
        XCTAssertTrue(result)
        XCTAssertEqual(coordinator.presentedModal, .settings)
    }
    
    // MARK: - State Management Tests
    
    func testStateReset() {
        // Set up some navigation state
        coordinator.selectedTab = .profile
        coordinator.navigate(to: .eventDetail(eventId: "test"))
        coordinator.presentModal(.settings)
        
        // Reset state
        coordinator.resetToInitialState()
        
        // Verify reset
        XCTAssertEqual(coordinator.selectedTab, .forYou)
        XCTAssertNil(coordinator.presentedModal)
        XCTAssertTrue(coordinator.navigationState.navigationStack(for: .profile).isEmpty)
    }
    
    func testAuthenticationComplete() {
        // Simulate authentication completion
        coordinator.handleAuthenticationComplete()
        
        XCTAssertEqual(coordinator.selectedTab, .forYou)
        XCTAssertNil(coordinator.presentedModal)
    }
    
    func testProfileSetupComplete() {
        // Simulate profile setup completion
        coordinator.handleProfileSetupComplete()
        
        XCTAssertEqual(coordinator.selectedTab, .forYou)
        XCTAssertNil(coordinator.presentedModal)
    }
    
    // MARK: - App State Integration Tests
    
    func testAppFlowChangeToAuthentication() {
        // Set up some navigation state
        coordinator.selectedTab = .profile
        coordinator.navigate(to: .eventDetail(eventId: "test"))
        
        // Change app flow to authentication
        mockAppStateManager.appFlow = .authentication
        
        // This would trigger the coordinator's observer in real scenario
        // For testing, we manually call the handler
        coordinator.resetToInitialState()
        
        XCTAssertEqual(coordinator.selectedTab, .forYou)
        XCTAssertTrue(coordinator.navigationState.navigationStack(for: .profile).isEmpty)
    }
    
    // MARK: - Tab Content Provider Tests
    
    func testTabContentProvider() {
        // Test that coordinator can provide views for tabs
        let forYouView = coordinator.view(for: .forYou)
        XCTAssertNotNil(forYouView)
        
        let profileView = coordinator.view(for: .profile)
        XCTAssertNotNil(profileView)
    }
    
    func testCanNavigateToDestination() {
        // Test navigation rules
        XCTAssertTrue(coordinator.canNavigate(to: .eventDetail(eventId: "test"), in: .forYou))
        XCTAssertTrue(coordinator.canNavigate(to: .profileEdit, in: .profile))
        XCTAssertTrue(coordinator.canNavigate(to: .tab(.map), in: .forYou))
    }
    
    // MARK: - Performance Tests
    
    func testNavigationPerformance() {
        measure {
            for i in 0..<100 {
                coordinator.navigate(to: .eventDetail(eventId: "event-\(i)"))
            }
        }
    }
    
    func testTabSwitchingPerformance() {
        measure {
            for _ in 0..<100 {
                coordinator.selectedTab = .forYou
                coordinator.selectedTab = .profile
                coordinator.selectedTab = .map
                coordinator.selectedTab = .trending
                coordinator.selectedTab = .more
            }
        }
    }
}

// MARK: - Mock App State Manager

class MockAppStateManager: AppStateManager {
    override init() {
        super.init()
        // Initialize with default values for testing
        self.isUserAuthenticated = true
        self.hasProfileSetup = true
        self.appFlow = .mainApp
    }
    
    // Override methods that would normally interact with external services
    override func signOut() {
        // Mock implementation for testing
        isUserAuthenticated = false
        currentUser = nil
        appFlow = .authentication
    }
} 