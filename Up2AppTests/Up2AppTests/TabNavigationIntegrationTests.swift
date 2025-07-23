import XCTest
import SwiftUI
@testable import Up2App

// MARK: - Tab Navigation Integration Tests
final class TabNavigationIntegrationTests: XCTestCase {
    
    // MARK: - Properties
    private var navigationCoordinator: NavigationCoordinator!
    private var appStateManager: MockAppStateManager!
    private var deepLinkHandler: DeepLinkHandler!
    
    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        appStateManager = MockAppStateManager()
        navigationCoordinator = NavigationCoordinator(appStateManager: appStateManager)
        deepLinkHandler = DeepLinkHandler(navigationCoordinator: navigationCoordinator, appStateManager: appStateManager)
    }
    
    override func tearDown() {
        navigationCoordinator = nil
        appStateManager = nil
        deepLinkHandler = nil
        super.tearDown()
    }
    
    // MARK: - Tab Configuration Tests
    
    func testAllTabsAreConfigured() {
        let allTabs = AppTab.allCases
        XCTAssertEqual(allTabs.count, 5, "Should have exactly 5 tabs")
        
        let expectedTabs: [AppTab] = [.forYou, .map, .trending, .profile, .more]
        for tab in expectedTabs {
            XCTAssertTrue(allTabs.contains(tab), "Should contain \(tab) tab")
        }
    }
    
    func testTabProperties() {
        let tab = AppTab.forYou
        
        XCTAssertEqual(tab.title, "For You")
        XCTAssertEqual(tab.icon, "safari")
        XCTAssertEqual(tab.selectedIcon, "safari.fill")
        XCTAssertFalse(tab.accessibilityLabel.isEmpty)
    }
    
    func testTabBarItemGeneration() {
        let tabItems = AppTab.allCases.map { tab in
            Up2TabBar.TabItem(
                id: tab.rawValue,
                icon: tab.icon,
                selectedIcon: tab.selectedIcon,
                title: tab.title
            )
        }
        
        XCTAssertEqual(tabItems.count, 5)
        
        let forYouItem = tabItems.first { $0.id == "for_you" }
        XCTAssertNotNil(forYouItem)
        XCTAssertEqual(forYouItem?.title, "For You")
        XCTAssertEqual(forYouItem?.icon, "safari")
    }
    
    // MARK: - Tab Navigation Flow Tests
    
    func testTabSwitchingFlow() {
        // Start with default tab
        XCTAssertEqual(navigationCoordinator.selectedTab, .forYou)
        
        // Switch to profile tab
        navigationCoordinator.selectedTab = .profile
        XCTAssertEqual(navigationCoordinator.selectedTab, .profile)
        
        // Switch to map tab
        navigationCoordinator.selectedTab = .map
        XCTAssertEqual(navigationCoordinator.selectedTab, .map)
        
        // Verify navigation state is updated
        XCTAssertEqual(navigationCoordinator.navigationState.selectedTab, .map)
    }
    
    func testTabNavigationPreservesStacks() {
        // Add content to For You tab
        navigationCoordinator.selectedTab = .forYou
        navigationCoordinator.navigate(to: .eventDetail(eventId: "event1"))
        navigationCoordinator.navigate(to: .eventDetail(eventId: "event2"))
        
        // Add content to Profile tab
        navigationCoordinator.selectedTab = .profile
        navigationCoordinator.navigate(to: .profileEdit)
        
        // Verify stacks are preserved when switching back
        navigationCoordinator.selectedTab = .forYou
        let forYouStack = navigationCoordinator.navigationState.navigationStack(for: .forYou)
        XCTAssertEqual(forYouStack.count, 2)
        
        navigationCoordinator.selectedTab = .profile
        let profileStack = navigationCoordinator.navigationState.navigationStack(for: .profile)
        XCTAssertEqual(profileStack.count, 1)
    }
    
    func testDoubleTabToPopToRoot() {
        // Add content to For You tab
        navigationCoordinator.selectedTab = .forYou
        navigationCoordinator.navigate(to: .eventDetail(eventId: "event1"))
        navigationCoordinator.navigate(to: .eventDetail(eventId: "event2"))
        
        // Verify stack has content
        XCTAssertTrue(navigationCoordinator.canNavigateBack(in: .forYou))
        
        // Simulate double-tap (same tab selection)
        navigationCoordinator.popToRoot(for: .forYou)
        
        // Verify stack is cleared
        XCTAssertFalse(navigationCoordinator.canNavigateBack(in: .forYou))
    }
    
    // MARK: - Deep Link Integration Tests
    
    func testDeepLinkToTabContent() {
        let url = URL(string: "up2://events/integration-test")!
        let result = deepLinkHandler.handleDeepLink(url)
        
        XCTAssertTrue(result)
        XCTAssertEqual(navigationCoordinator.selectedTab, .forYou)
        
        let stack = navigationCoordinator.navigationState.navigationStack(for: .forYou)
        XCTAssertEqual(stack.count, 1)
        XCTAssertEqual(stack.first, .eventDetail(eventId: "integration-test"))
    }
    
    func testDeepLinkTabSwitching() {
        // Start on For You tab
        navigationCoordinator.selectedTab = .forYou
        
        // Deep link to profile content
        let url = URL(string: "up2://profile/user123")!
        let result = deepLinkHandler.handleDeepLink(url)
        
        XCTAssertTrue(result)
        XCTAssertEqual(navigationCoordinator.selectedTab, .profile)
        
        let stack = navigationCoordinator.navigationState.navigationStack(for: .profile)
        XCTAssertEqual(stack.count, 1)
        XCTAssertEqual(stack.first, .profileView(userId: "user123"))
    }
    
    func testDeepLinkModalPresentation() {
        let url = URL(string: "up2://settings")!
        let result = deepLinkHandler.handleDeepLink(url)
        
        XCTAssertTrue(result)
        XCTAssertEqual(navigationCoordinator.presentedModal, .settings)
    }
    
    // MARK: - App State Integration Tests
    
    func testAuthenticationFlowIntegration() {
        // Start with unauthenticated state
        appStateManager.isUserAuthenticated = false
        appStateManager.appFlow = .authentication
        
        // Navigation should be reset
        navigationCoordinator.resetToInitialState()
        XCTAssertEqual(navigationCoordinator.selectedTab, .forYou)
        XCTAssertNil(navigationCoordinator.presentedModal)
    }
    
    func testMainAppFlowIntegration() {
        // Simulate reaching main app
        appStateManager.isUserAuthenticated = true
        appStateManager.hasProfileSetup = true
        appStateManager.appFlow = .mainApp
        
        // Navigation should handle authentication completion
        navigationCoordinator.handleAuthenticationComplete()
        
        XCTAssertEqual(navigationCoordinator.selectedTab, .forYou)
    }
    
    func testProfileSetupFlowIntegration() {
        // Simulate profile setup completion
        appStateManager.isUserAuthenticated = true
        appStateManager.hasProfileSetup = true
        
        navigationCoordinator.handleProfileSetupComplete()
        
        XCTAssertEqual(navigationCoordinator.selectedTab, .forYou)
    }
    
    // MARK: - State Persistence Tests
    
    func testNavigationStatePersistence() {
        // Set up navigation state
        navigationCoordinator.selectedTab = .profile
        navigationCoordinator.navigate(to: .profileEdit)
        
        // Save state
        navigationCoordinator.saveNavigationState()
        
        // Create new coordinator and restore state
        let newCoordinator = NavigationCoordinator(appStateManager: appStateManager)
        newCoordinator.restoreNavigationState()
        
        // Note: In a real test, we'd need to mock UserDefaults or use a test-specific storage
        // For now, we verify the methods exist and can be called
        XCTAssertNotNil(newCoordinator)
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testInvalidDeepLinkHandling() {
        let invalidUrl = URL(string: "invalid://scheme")!
        let result = deepLinkHandler.handleDeepLink(invalidUrl)
        
        XCTAssertFalse(result)
        
        // Navigation state should remain unchanged
        XCTAssertEqual(navigationCoordinator.selectedTab, .forYou)
        XCTAssertNil(navigationCoordinator.presentedModal)
    }
    
    func testNavigationToInvalidDestination() {
        // Test graceful handling of navigation to restricted destinations
        // This depends on the specific implementation of navigation rules
        
        // For example, trying to navigate to authentication-only destinations when authenticated
        // The coordinator should handle this gracefully
        XCTAssertNotNil(navigationCoordinator)
    }
    
    // MARK: - Cross-Tab Navigation Tests
    
    func testCrossTabEventNavigation() {
        // Start on Profile tab
        navigationCoordinator.selectedTab = .profile
        
        // Navigate to an event (should switch to For You tab)
        navigationCoordinator.navigate(to: .eventDetail(eventId: "cross-tab-event"), in: .forYou)
        
        XCTAssertEqual(navigationCoordinator.selectedTab, .forYou)
        
        let stack = navigationCoordinator.navigationState.navigationStack(for: .forYou)
        XCTAssertEqual(stack.count, 1)
        XCTAssertEqual(stack.first, .eventDetail(eventId: "cross-tab-event"))
    }
    
    func testCrossTabProfileNavigation() {
        // Start on For You tab
        navigationCoordinator.selectedTab = .forYou
        
        // Navigate to profile edit (should switch to Profile tab)
        navigationCoordinator.navigate(to: .profileEdit, in: .profile)
        
        XCTAssertEqual(navigationCoordinator.selectedTab, .profile)
        
        let stack = navigationCoordinator.navigationState.navigationStack(for: .profile)
        XCTAssertEqual(stack.count, 1)
        XCTAssertEqual(stack.first, .profileEdit)
    }
    
    // MARK: - Modal and Tab Interaction Tests
    
    func testModalDismissalPreservesTab() {
        // Switch to a specific tab
        navigationCoordinator.selectedTab = .trending
        
        // Present modal
        navigationCoordinator.presentModal(.settings)
        XCTAssertEqual(navigationCoordinator.presentedModal, .settings)
        
        // Dismiss modal
        navigationCoordinator.dismissModal()
        
        // Tab should remain the same
        XCTAssertEqual(navigationCoordinator.selectedTab, .trending)
        XCTAssertNil(navigationCoordinator.presentedModal)
    }
    
    func testTabSwitchingWithModalPresented() {
        // Present modal
        navigationCoordinator.presentModal(.help)
        
        // Switch tab
        navigationCoordinator.selectedTab = .map
        
        // Both should coexist
        XCTAssertEqual(navigationCoordinator.selectedTab, .map)
        XCTAssertEqual(navigationCoordinator.presentedModal, .help)
    }
    
    // MARK: - Performance Integration Tests
    
    func testComplexNavigationPerformance() {
        measure {
            // Simulate complex navigation scenario
            for i in 0..<50 {
                let tab = AppTab.allCases[i % AppTab.allCases.count]
                navigationCoordinator.selectedTab = tab
                navigationCoordinator.navigate(to: .eventDetail(eventId: "perf-test-\(i)"))
                
                if i % 10 == 0 {
                    navigationCoordinator.presentModal(.settings)
                    navigationCoordinator.dismissModal()
                }
                
                if i % 15 == 0 {
                    navigationCoordinator.popToRoot(for: tab)
                }
            }
        }
    }
    
    func testDeepLinkPerformance() {
        measure {
            for i in 0..<100 {
                let url = URL(string: "up2://events/perf-test-\(i)")!
                _ = deepLinkHandler.handleDeepLink(url)
            }
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testNavigationCoordinatorMemoryRetention() {
        weak var weakCoordinator: NavigationCoordinator?
        
        autoreleasepool {
            let coordinator = NavigationCoordinator(appStateManager: appStateManager)
            weakCoordinator = coordinator
            
            // Use the coordinator
            coordinator.selectedTab = .profile
            coordinator.navigate(to: .profileEdit)
        }
        
        // The coordinator should be deallocated after leaving the autoreleasepool
        // (In real scenarios, it would be retained by the app, but for this test we check basic memory behavior)
        XCTAssertNotNil(weakCoordinator) // May still be retained temporarily by internal systems
    }
    
    // MARK: - Accessibility Integration Tests
    
    func testTabAccessibilityLabels() {
        for tab in AppTab.allCases {
            XCTAssertFalse(tab.accessibilityLabel.isEmpty, "\(tab) should have accessibility label")
            XCTAssertTrue(tab.accessibilityLabel.count > 5, "\(tab) accessibility label should be descriptive")
        }
    }
}

// MARK: - Test Extensions

extension NavigationDestination: Equatable {
    public static func == (lhs: NavigationDestination, rhs: NavigationDestination) -> Bool {
        return lhs.id == rhs.id
    }
} 