import XCTest
import Foundation
@testable import Up2App

// MARK: - Navigation Models Tests
final class NavigationModelsTests: XCTestCase {
    
    // MARK: - AppTab Tests
    
    func testAppTabProperties() {
        let forYouTab = AppTab.forYou
        
        XCTAssertEqual(forYouTab.rawValue, "for_you")
        XCTAssertEqual(forYouTab.title, "For You")
        XCTAssertEqual(forYouTab.icon, "safari")
        XCTAssertEqual(forYouTab.selectedIcon, "safari.fill")
        XCTAssertEqual(forYouTab.accessibilityLabel, "For You events feed")
    }
    
    func testAllAppTabs() {
        let allTabs = AppTab.allCases
        XCTAssertEqual(allTabs.count, 5)
        
        let expectedRawValues = ["for_you", "map", "trending", "profile", "more"]
        for (index, tab) in allTabs.enumerated() {
            XCTAssertEqual(tab.rawValue, expectedRawValues[index])
        }
    }
    
    func testAppTabIdentifiable() {
        let tab = AppTab.profile
        XCTAssertEqual(tab.id, tab.rawValue)
    }
    
    // MARK: - NavigationDestination Tests
    
    func testNavigationDestinationIds() {
        let destinations: [NavigationDestination] = [
            .login,
            .tab(.forYou),
            .eventDetail(eventId: "test123"),
            .profileView(userId: "user456"),
            .settings
        ]
        
        let expectedIds = [
            "login",
            "tab_for_you",
            "event_detail_test123",
            "profile_view_user456",
            "settings"
        ]
        
        for (index, destination) in destinations.enumerated() {
            XCTAssertEqual(destination.id, expectedIds[index])
        }
    }
    
    func testNavigationDestinationEquality() {
        let destination1 = NavigationDestination.eventDetail(eventId: "test")
        let destination2 = NavigationDestination.eventDetail(eventId: "test")
        let destination3 = NavigationDestination.eventDetail(eventId: "different")
        
        XCTAssertEqual(destination1.id, destination2.id)
        XCTAssertNotEqual(destination1.id, destination3.id)
    }
    
    func testNavigationDestinationSuggestedTab() {
        XCTAssertEqual(NavigationDestination.eventDetail(eventId: "test").suggestedTab, .forYou)
        XCTAssertEqual(NavigationDestination.eventMap(location: nil).suggestedTab, .forYou)
        XCTAssertEqual(NavigationDestination.profileEdit.suggestedTab, .profile)
        XCTAssertEqual(NavigationDestination.tab(.trending).suggestedTab, .trending)
    }
    
    // MARK: - NavigationState Tests
    
    func testNavigationStateInitialization() {
        let state = NavigationState()
        
        XCTAssertEqual(state.selectedTab, .forYou)
        XCTAssertTrue(state.presentedModals.isEmpty)
        
        // All tabs should have empty navigation stacks
        for tab in AppTab.allCases {
            XCTAssertTrue(state.navigationStack(for: tab).isEmpty)
        }
    }
    
    func testNavigationStateStackManagement() {
        var state = NavigationState()
        
        // Test push
        state.push(.eventDetail(eventId: "event1"), to: .forYou)
        XCTAssertEqual(state.navigationStack(for: .forYou).count, 1)
        
        state.push(.eventDetail(eventId: "event2"), to: .forYou)
        XCTAssertEqual(state.navigationStack(for: .forYou).count, 2)
        
        // Test pop
        state.pop(from: .forYou)
        XCTAssertEqual(state.navigationStack(for: .forYou).count, 1)
        
        // Test pop to root
        state.push(.eventDetail(eventId: "event3"), to: .forYou)
        state.popToRoot(for: .forYou)
        XCTAssertTrue(state.navigationStack(for: .forYou).isEmpty)
    }
    
    func testNavigationStateTabSelection() {
        var state = NavigationState()
        
        state.selectTab(.profile)
        XCTAssertEqual(state.selectedTab, .profile)
    }
    
    func testNavigationStateModalManagement() {
        var state = NavigationState()
        
        // Test present modal
        state.presentModal(.settings)
        XCTAssertEqual(state.presentedModals.count, 1)
        XCTAssertEqual(state.currentModal, .settings)
        
        // Test multiple modals
        state.presentModal(.help)
        XCTAssertEqual(state.presentedModals.count, 2)
        XCTAssertEqual(state.currentModal, .help)
        
        // Test dismiss modal
        state.dismissModal()
        XCTAssertEqual(state.presentedModals.count, 1)
        XCTAssertEqual(state.currentModal, .settings)
        
        // Test dismiss all modals
        state.presentModal(.notifications)
        state.dismissAllModals()
        XCTAssertTrue(state.presentedModals.isEmpty)
        XCTAssertNil(state.currentModal)
    }
    
    func testNavigationStateHasContent() {
        var state = NavigationState()
        
        XCTAssertFalse(state.hasContent(in: .forYou))
        
        state.push(.eventDetail(eventId: "test"), to: .forYou)
        XCTAssertTrue(state.hasContent(in: .forYou))
        
        state.popToRoot(for: .forYou)
        XCTAssertFalse(state.hasContent(in: .forYou))
    }
    
    // MARK: - DeepLink Tests
    
    func testDeepLinkValidURL() {
        let url = URL(string: "up2://events/test-event")!
        let deepLink = DeepLink(url: url)
        
        XCTAssertNotNil(deepLink)
        XCTAssertEqual(deepLink?.url, url)
        XCTAssertEqual(deepLink?.destination, .eventDetail(eventId: "test-event"))
    }
    
    func testDeepLinkInvalidURL() {
        let url = URL(string: "invalid-url")!
        let deepLink = DeepLink(url: url)
        
        // Should still create the DeepLink object but destination might be nil
        XCTAssertNotNil(deepLink)
    }
    
    func testDeepLinkEventParsing() {
        let testCases: [(String, NavigationDestination?)] = [
            ("up2://events/123", .eventDetail(eventId: "123")),
            ("up2://events", .tab(.forYou)),
            ("up2://map", .eventMap(location: nil)),
            ("up2://map?location=37.7749,-122.4194", .eventMap(location: "37.7749,-122.4194")),
            ("up2://profile/user123", .profileView(userId: "user123")),
            ("up2://profile", .tab(.profile)),
            ("up2://trending", .tab(.trending)),
            ("up2://search?q=music", .eventSearch(query: "music")),
            ("up2://search", .eventSearch(query: nil)),
            ("up2://settings", .settings),
            ("up2://help", .help)
        ]
        
        for (urlString, expectedDestination) in testCases {
            let url = URL(string: urlString)!
            let deepLink = DeepLink(url: url)
            
            XCTAssertNotNil(deepLink, "Should create DeepLink for: \(urlString)")
            XCTAssertEqual(deepLink?.destination?.id, expectedDestination?.id, "Wrong destination for: \(urlString)")
        }
    }
    
    func testDeepLinkUnsupportedScheme() {
        let url = URL(string: "http://example.com")!
        let deepLink = DeepLink(url: url)
        
        XCTAssertNotNil(deepLink)
        XCTAssertNil(deepLink?.destination)
    }
    
    // MARK: - NavigationEvent Tests
    
    func testNavigationEventCreation() {
        let source = NavigationDestination.tab(.forYou)
        let destination = NavigationDestination.eventDetail(eventId: "test")
        let event = NavigationEvent(
            from: source,
            to: destination,
            method: .tap
        )
        
        XCTAssertEqual(event.source?.id, source.id)
        XCTAssertEqual(event.destination.id, destination.id)
        XCTAssertEqual(event.method, .tap)
        XCTAssertTrue(event.metadata.isEmpty)
    }
    
    func testNavigationEventWithMetadata() {
        let destination = NavigationDestination.eventDetail(eventId: "test")
        let metadata = ["url": "up2://events/test", "timestamp": "12345"]
        let event = NavigationEvent(
            from: nil,
            to: destination,
            method: .deepLink,
            metadata: metadata
        )
        
        XCTAssertEqual(event.metadata["url"] as? String, "up2://events/test")
        XCTAssertEqual(event.metadata["timestamp"] as? String, "12345")
    }
    
    // MARK: - NavigationConfiguration Tests
    
    func testDefaultNavigationConfiguration() {
        let config = NavigationConfiguration.default
        
        XCTAssertTrue(config.persistNavigationState)
        XCTAssertTrue(config.enableDeepLinking)
        XCTAssertTrue(config.enableAnalytics)
        XCTAssertEqual(config.modalPresentationStyle, .sheet)
    }
    
    func testCustomNavigationConfiguration() {
        let config = NavigationConfiguration(
            persistNavigationState: false,
            enableDeepLinking: true,
            enableAnalytics: false,
            tabSwitchAnimation: .linear(duration: 0.1),
            modalPresentationStyle: .fullScreen
        )
        
        XCTAssertFalse(config.persistNavigationState)
        XCTAssertTrue(config.enableDeepLinking)
        XCTAssertFalse(config.enableAnalytics)
        XCTAssertEqual(config.modalPresentationStyle, .fullScreen)
    }
    
    // MARK: - Codable Tests
    
    func testNavigationDestinationCodable() {
        let destinations: [NavigationDestination] = [
            .login,
            .tab(.profile),
            .eventDetail(eventId: "test123"),
            .eventMap(location: "coordinates"),
            .profileView(userId: "user456"),
            .settings,
            .maintenance(message: "Under maintenance")
        ]
        
        for destination in destinations {
            do {
                let encoded = try JSONEncoder().encode(destination)
                let decoded = try JSONDecoder().decode(NavigationDestination.self, from: encoded)
                XCTAssertEqual(destination.id, decoded.id, "Codable failed for: \(destination)")
            } catch {
                XCTFail("Codable failed for destination: \(destination) with error: \(error)")
            }
        }
    }
    
    func testNavigationStateCodable() {
        var state = NavigationState(selectedTab: .profile)
        state.push(.eventDetail(eventId: "test"), to: .forYou)
        state.presentModal(.settings)
        
        do {
            let encoded = try JSONEncoder().encode(state)
            let decoded = try JSONDecoder().decode(NavigationState.self, from: encoded)
            
            XCTAssertEqual(state.selectedTab, decoded.selectedTab)
            XCTAssertEqual(state.navigationStack(for: .forYou).count, decoded.navigationStack(for: .forYou).count)
            XCTAssertEqual(state.presentedModals.count, decoded.presentedModals.count)
        } catch {
            XCTFail("NavigationState codable failed: \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testNavigationStatePerformance() {
        var state = NavigationState()
        
        measure {
            for i in 0..<1000 {
                let tab = AppTab.allCases[i % AppTab.allCases.count]
                state.push(.eventDetail(eventId: "event-\(i)"), to: tab)
            }
        }
    }
    
    func testDeepLinkParsingPerformance() {
        let urls = (0..<1000).map { URL(string: "up2://events/test-\($0)")! }
        
        measure {
            for url in urls {
                _ = DeepLink(url: url)
            }
        }
    }
    
    // MARK: - Edge Cases Tests
    
    func testNavigationDestinationSpecialCharacters() {
        let destination = NavigationDestination.eventDetail(eventId: "test-with-special-chars-@#$%")
        let id = destination.id
        
        XCTAssertTrue(id.contains("test-with-special-chars-@#$%"))
    }
    
    func testNavigationStateEdgeCases() {
        var state = NavigationState()
        
        // Test popping from empty stack
        state.pop(from: .forYou)
        XCTAssertTrue(state.navigationStack(for: .forYou).isEmpty)
        
        // Test dismissing when no modals
        state.dismissModal()
        XCTAssertTrue(state.presentedModals.isEmpty)
        
        // Test selecting same tab
        let originalTab = state.selectedTab
        state.selectTab(originalTab)
        XCTAssertEqual(state.selectedTab, originalTab)
    }
    
    func testDeepLinkEdgeCases() {
        let edgeCaseURLs = [
            "up2://",
            "up2://unknown",
            "up2://events/",
            "up2://search?q=",
            "up2://map?location="
        ]
        
        for urlString in edgeCaseURLs {
            let url = URL(string: urlString)!
            let deepLink = DeepLink(url: url)
            
            // Should handle gracefully without crashing
            XCTAssertNotNil(deepLink)
        }
    }
    
    // MARK: - Memory Tests
    
    func testNavigationStateMemoryUsage() {
        var state = NavigationState()
        
        // Add a large number of navigation entries
        for i in 0..<10000 {
            let tab = AppTab.allCases[i % AppTab.allCases.count]
            state.push(.eventDetail(eventId: "event-\(i)"), to: tab)
        }
        
        // Verify state is still functional
        XCTAssertTrue(state.hasContent(in: .forYou))
        
        // Clear state
        for tab in AppTab.allCases {
            state.popToRoot(for: tab)
        }
        
        // Verify all stacks are empty
        for tab in AppTab.allCases {
            XCTAssertFalse(state.hasContent(in: tab))
        }
    }
} 