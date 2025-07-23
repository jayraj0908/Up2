import XCTest
import Foundation
@testable import Up2App

// MARK: - Deep Link Handler Tests
final class DeepLinkHandlerTests: XCTestCase {
    
    // MARK: - Properties
    private var handler: DeepLinkHandler!
    private var mockNavigationCoordinator: MockNavigationCoordinator!
    private var mockAppStateManager: MockAppStateManager!
    
    // MARK: - Setup & Teardown
    override func setUp() {
        super.setUp()
        mockAppStateManager = MockAppStateManager()
        mockNavigationCoordinator = MockNavigationCoordinator()
        handler = DeepLinkHandler(
            navigationCoordinator: mockNavigationCoordinator,
            appStateManager: mockAppStateManager
        )
    }
    
    override func tearDown() {
        handler = nil
        mockNavigationCoordinator = nil
        mockAppStateManager = nil
        super.tearDown()
    }
    
    // MARK: - URL Scheme Validation Tests
    
    func testValidURLSchemes() {
        let validURLs = [
            URL(string: "up2://events/123")!,
            URL(string: "up2app://profile/user123")!,
            URL(string: "UP2://settings")! // Should handle case insensitive
        ]
        
        for url in validURLs {
            let result = handler.handleDeepLink(url)
            XCTAssertTrue(result, "Should handle valid URL: \(url)")
        }
    }
    
    func testInvalidURLSchemes() {
        let invalidURLs = [
            URL(string: "http://example.com")!,
            URL(string: "mailto:test@example.com")!,
            URL(string: "invalid://test")!,
            URL(string: "up3://events/123")! // Wrong scheme
        ]
        
        for url in invalidURLs {
            let result = handler.handleDeepLink(url)
            XCTAssertFalse(result, "Should reject invalid URL: \(url)")
        }
    }
    
    // MARK: - Deep Link Parsing Tests
    
    func testEventDeepLinks() {
        let url = URL(string: "up2://events/test-event-123")!
        let result = handler.handleDeepLink(url)
        
        XCTAssertTrue(result)
        XCTAssertEqual(mockNavigationCoordinator.lastNavigatedDestination, .eventDetail(eventId: "test-event-123"))
        XCTAssertEqual(mockNavigationCoordinator.lastNavigatedTab, .forYou)
    }
    
    func testProfileDeepLinks() {
        let url = URL(string: "up2://profile/user-456")!
        let result = handler.handleDeepLink(url)
        
        XCTAssertTrue(result)
        XCTAssertEqual(mockNavigationCoordinator.lastNavigatedDestination, .profileView(userId: "user-456"))
        XCTAssertEqual(mockNavigationCoordinator.lastNavigatedTab, .profile)
    }
    
    func testMapDeepLinks() {
        let url = URL(string: "up2://map?location=37.7749,-122.4194")!
        let result = handler.handleDeepLink(url)
        
        XCTAssertTrue(result)
        XCTAssertEqual(mockNavigationCoordinator.lastNavigatedDestination, .eventMap(location: "37.7749,-122.4194"))
    }
    
    func testSearchDeepLinks() {
        let url = URL(string: "up2://search?q=music%20festival")!
        let result = handler.handleDeepLink(url)
        
        XCTAssertTrue(result)
        XCTAssertEqual(mockNavigationCoordinator.lastNavigatedDestination, .eventSearch(query: "music festival"))
    }
    
    func testSettingsDeepLink() {
        let url = URL(string: "up2://settings")!
        let result = handler.handleDeepLink(url)
        
        XCTAssertTrue(result)
        XCTAssertEqual(mockNavigationCoordinator.lastPresentedModal, .settings)
    }
    
    func testHelpDeepLink() {
        let url = URL(string: "up2://help")!
        let result = handler.handleDeepLink(url)
        
        XCTAssertTrue(result)
        XCTAssertEqual(mockNavigationCoordinator.lastPresentedModal, .help)
    }
    
    // MARK: - Authentication Handling Tests
    
    func testDeepLinkWithoutAuthentication() {
        mockAppStateManager.isUserAuthenticated = false
        
        let url = URL(string: "up2://events/test-event")!
        let result = handler.handleDeepLink(url)
        
        // Should accept the link but store it as pending
        XCTAssertTrue(result)
        XCTAssertNotNil(handler.pendingDeepLink)
        XCTAssertEqual(handler.pendingDeepLink?.url, url)
    }
    
    func testPendingDeepLinkProcessing() {
        // Set up a pending deep link
        mockAppStateManager.isUserAuthenticated = false
        let url = URL(string: "up2://events/test-event")!
        _ = handler.handleDeepLink(url)
        
        XCTAssertNotNil(handler.pendingDeepLink)
        
        // Simulate authentication completion
        mockAppStateManager.isUserAuthenticated = true
        mockAppStateManager.hasProfileSetup = true
        mockAppStateManager.appFlow = .mainApp
        
        // Process pending deep link
        handler.processPendingDeepLink()
        
        XCTAssertNil(handler.pendingDeepLink)
        XCTAssertEqual(mockNavigationCoordinator.lastNavigatedDestination, .eventDetail(eventId: "test-event"))
    }
    
    func testPublicDeepLinksWithoutAuth() {
        // Test that login/registration links work without authentication
        mockAppStateManager.isUserAuthenticated = false
        
        let loginURL = URL(string: "up2://login")!
        let result = handler.handleDeepLink(loginURL)
        
        XCTAssertTrue(result)
        XCTAssertNil(handler.pendingDeepLink) // Should not be pending
    }
    
    // MARK: - Deep Link Generation Tests
    
    func testGenerateEventDeepLink() {
        let destination = NavigationDestination.eventDetail(eventId: "test-event")
        let url = handler.generateDeepLink(for: destination)
        
        XCTAssertEqual(url?.absoluteString, "up2://events/test-event")
    }
    
    func testGenerateProfileDeepLink() {
        let destination = NavigationDestination.profileView(userId: "user123")
        let url = handler.generateDeepLink(for: destination)
        
        XCTAssertEqual(url?.absoluteString, "up2://profile/user123")
    }
    
    func testGenerateSearchDeepLink() {
        let destination = NavigationDestination.eventSearch(query: "music festival")
        let url = handler.generateDeepLink(for: destination)
        
        XCTAssertEqual(url?.absoluteString, "up2://search?q=music%20festival")
    }
    
    func testGenerateTabDeepLink() {
        let destination = NavigationDestination.tab(.profile)
        let url = handler.generateDeepLink(for: destination)
        
        XCTAssertEqual(url?.absoluteString, "up2://profile")
    }
    
    // MARK: - Error Handling Tests
    
    func testMalformedURL() {
        let url = URL(string: "up2://")!
        let result = handler.handleDeepLink(url)
        
        XCTAssertFalse(result)
        
        // Check that error was recorded
        let history = handler.getRecentActivity(limit: 1)
        XCTAssertEqual(history.count, 1)
        if case .failed = history.first?.status {
            // Expected
        } else {
            XCTFail("Should have recorded a failure")
        }
    }
    
    func testUnsupportedDestination() {
        let url = URL(string: "up2://unsupported/path")!
        let result = handler.handleDeepLink(url)
        
        XCTAssertFalse(result)
    }
    
    // MARK: - History and Analytics Tests
    
    func testSuccessfulLinkHistory() {
        let url = URL(string: "up2://events/test")!
        _ = handler.handleDeepLink(url)
        
        let history = handler.getRecentActivity(limit: 1)
        XCTAssertEqual(history.count, 1)
        
        let record = history.first!
        XCTAssertEqual(record.url, url)
        if case .success = record.status {
            // Expected
        } else {
            XCTFail("Should have recorded success")
        }
    }
    
    func testFailedLinkHistory() {
        let url = URL(string: "invalid://test")!
        _ = handler.handleDeepLink(url)
        
        let history = handler.getRecentActivity(limit: 1)
        XCTAssertEqual(history.count, 1)
        
        let record = history.first!
        XCTAssertEqual(record.url, url)
        if case .failed = record.status {
            // Expected
        } else {
            XCTFail("Should have recorded failure")
        }
    }
    
    func testPendingLinkHistory() {
        mockAppStateManager.isUserAuthenticated = false
        
        let url = URL(string: "up2://events/test")!
        _ = handler.handleDeepLink(url)
        
        let history = handler.getRecentActivity(limit: 1)
        XCTAssertEqual(history.count, 1)
        
        let record = history.first!
        if case .pending = record.status {
            // Expected
        } else {
            XCTFail("Should have recorded pending status")
        }
    }
    
    func testHistoryLimit() {
        // Generate more than the max history size
        for i in 0..<60 {
            let url = URL(string: "up2://events/test-\(i)")!
            _ = handler.handleDeepLink(url)
        }
        
        let allHistory = handler.linkHandlingHistory
        XCTAssertLessThanOrEqual(allHistory.count, 50, "History should be limited to max size")
    }
    
    func testClearHistory() {
        let url = URL(string: "up2://events/test")!
        _ = handler.handleDeepLink(url)
        
        XCTAssertFalse(handler.linkHandlingHistory.isEmpty)
        
        handler.clearHistory()
        XCTAssertTrue(handler.linkHandlingHistory.isEmpty)
    }
    
    // MARK: - App State Integration Tests
    
    func testAppStateChangeTriggersPendingProcessing() {
        // Set up pending deep link
        mockAppStateManager.isUserAuthenticated = false
        let url = URL(string: "up2://events/test")!
        _ = handler.handleDeepLink(url)
        
        XCTAssertNotNil(handler.pendingDeepLink)
        
        // Simulate app flow change to main app
        mockAppStateManager.appFlow = .mainApp
        mockAppStateManager.isUserAuthenticated = true
        
        // This would trigger the handler in real scenario
        // For testing, we call it manually
        handler.processPendingDeepLink()
        
        XCTAssertNil(handler.pendingDeepLink)
    }
    
    // MARK: - Edge Cases Tests
    
    func testSpecialCharactersInURL() {
        let url = URL(string: "up2://search?q=caf%C3%A9%20%26%20music")! // "café & music"
        let result = handler.handleDeepLink(url)
        
        XCTAssertTrue(result)
        // URL decoding should handle special characters properly
    }
    
    func testEmptyParameters() {
        let url = URL(string: "up2://search?q=")!
        let result = handler.handleDeepLink(url)
        
        XCTAssertTrue(result)
        XCTAssertEqual(mockNavigationCoordinator.lastNavigatedDestination, .eventSearch(query: ""))
    }
    
    func testConcurrentDeepLinks() {
        let expectation = self.expectation(description: "Concurrent deep links")
        expectation.expectedFulfillmentCount = 10
        
        // Simulate multiple concurrent deep links
        for i in 0..<10 {
            DispatchQueue.global(qos: .userInitiated).async {
                let url = URL(string: "up2://events/concurrent-\(i)")!
                _ = self.handler.handleDeepLink(url)
                expectation.fulfill()
            }
        }
        
        waitForExpectations(timeout: 5.0, handler: nil)
        
        // All should be recorded in history
        XCTAssertGreaterThanOrEqual(handler.linkHandlingHistory.count, 10)
    }
}

// MARK: - Mock Navigation Coordinator

class MockNavigationCoordinator: NavigationCoordinator {
    var lastNavigatedDestination: NavigationDestination?
    var lastNavigatedTab: AppTab?
    var lastPresentedModal: NavigationDestination?
    
    override func navigate(to destination: NavigationDestination, in tab: AppTab) {
        lastNavigatedDestination = destination
        lastNavigatedTab = tab
        super.navigate(to: destination, in: tab)
    }
    
    override func presentModal(_ destination: NavigationDestination) {
        lastPresentedModal = destination
        super.presentModal(destination)
    }
} 