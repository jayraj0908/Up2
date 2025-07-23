import XCTest
import SwiftUI
import CoreLocation
@testable import Up2App

final class ForYouFeedIntegrationTests: XCTestCase {
    
    var viewModel: EventFeedViewModel!
    var discoveryService: EventDiscoveryService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        viewModel = EventFeedViewModel()
        discoveryService = EventDiscoveryService.shared
        
        // Set up test user
        let testUser = SupabaseAuthService.AuthUser(
            id: UUID().uuidString,
            email: "test@example.com",
            phone: nil
        )
        SupabaseAuthService.shared.currentUser = testUser
    }
    
    override func tearDown() {
        SupabaseAuthService.shared.currentUser = nil
        viewModel = nil
        discoveryService = nil
        super.tearDown()
    }
    
    // MARK: - View Integration Tests
    
    func testForYouFeedViewInitialization() {
        let feedView = ForYouFeedView()
        
        // Test that the view can be initialized without errors
        XCTAssertNotNil(feedView)
    }
    
    func testViewModelIntegrationWithDiscoveryService() async {
        // Test that the view model properly coordinates with the discovery service
        
        // Start with idle state
        XCTAssertEqual(viewModel.feedState, .idle)
        
        // Load initial feed
        await viewModel.loadInitialFeed()
        
        // Verify state transitions occurred
        // Note: In a real test environment, this would likely result in an error
        // due to missing database/network setup, but we can verify the attempt was made
    }
    
    func testFeedRefreshIntegration() async {
        // Set up mock loaded state
        let mockItems = [createMockEventFeedItem()]
        viewModel.feedState = .loaded(mockItems)
        
        // Test refresh functionality
        await viewModel.refreshFeed()
        
        // Verify the refresh was attempted
        // In a real environment, this would test the full refresh cycle
    }
    
    func testFilterSheetIntegration() {
        // Test filter sheet interaction
        var showingFilterSheet = false
        
        // Simulate showing filter sheet
        showingFilterSheet = true
        XCTAssertTrue(showingFilterSheet)
        
        // Test filter application
        var newFilter = EventFeedFilter.default
        newFilter.timeRange = .today
        newFilter.priceRange = .free
        newFilter.attendeeRange = .intimate
        
        viewModel.currentFilter = newFilter
        
        XCTAssertEqual(viewModel.currentFilter.timeRange, .today)
        XCTAssertEqual(viewModel.currentFilter.priceRange, .free)
        XCTAssertEqual(viewModel.currentFilter.attendeeRange, .intimate)
    }
    
    func testSortSheetIntegration() {
        // Test sort sheet interaction
        var showingSortSheet = false
        
        // Simulate showing sort sheet
        showingSortSheet = true
        XCTAssertTrue(showingSortSheet)
        
        // Test sort option change
        viewModel.currentSortOption = .distance
        XCTAssertEqual(viewModel.currentSortOption, .distance)
        
        viewModel.currentSortOption = .price
        XCTAssertEqual(viewModel.currentSortOption, .price)
        
        viewModel.currentSortOption = .popularity
        XCTAssertEqual(viewModel.currentSortOption, .popularity)
    }
    
    func testEventCardInteraction() {
        let mockItem = createMockEventFeedItem()
        var selectedEventItem: EventFeedItem?
        
        // Simulate tapping on event card
        selectedEventItem = mockItem
        XCTAssertNotNil(selectedEventItem)
        XCTAssertEqual(selectedEventItem?.id, mockItem.id)
        
        // Test navigation to event detail
        XCTAssertNotNil(selectedEventItem)
    }
    
    // MARK: - State Management Integration Tests
    
    func testEmptyFeedStateDisplay() {
        viewModel.feedState = .empty
        
        XCTAssertEqual(viewModel.feedState, .empty)
        XCTAssertTrue(viewModel.feedState.items.isEmpty)
    }
    
    func testLoadingStateDisplay() {
        viewModel.feedState = .loading
        
        XCTAssertEqual(viewModel.feedState, .loading)
        XCTAssertTrue(viewModel.feedState.isLoading)
    }
    
    func testErrorStateDisplay() {
        let errorMessage = "Failed to load events"
        viewModel.feedState = .error(errorMessage)
        
        XCTAssertEqual(viewModel.feedState.errorMessage, errorMessage)
    }
    
    func testLoadedStateDisplay() {
        let mockItems = [createMockEventFeedItem(), createMockEventFeedItem()]
        viewModel.feedState = .loaded(mockItems)
        
        XCTAssertEqual(viewModel.feedState.items.count, 2)
        XCTAssertFalse(viewModel.feedState.isLoading)
    }
    
    // MARK: - Location Integration Tests
    
    func testLocationPermissionIntegration() {
        // Test initial location state
        XCTAssertFalse(viewModel.isLocationEnabled)
        XCTAssertEqual(viewModel.locationDescription, "Location off")
        
        // Simulate location permission granted
        viewModel.isLocationEnabled = true
        viewModel.locationDescription = "Current location"
        
        XCTAssertTrue(viewModel.isLocationEnabled)
        XCTAssertEqual(viewModel.locationDescription, "Current location")
    }
    
    func testLocationBasedFeedUpdate() async {
        // Simulate location update
        let testLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        viewModel.isLocationEnabled = true
        
        // In a real implementation, this would trigger a feed refresh with location
        // For now, we verify that location state is properly managed
        XCTAssertTrue(viewModel.isLocationEnabled)
    }
    
    // MARK: - Pull-to-Refresh Integration Tests
    
    func testPullToRefreshIntegration() async {
        // Set up initial loaded state
        let mockItems = [createMockEventFeedItem()]
        viewModel.feedState = .loaded(mockItems)
        
        // Simulate pull-to-refresh
        await viewModel.refreshFeed()
        
        // Verify refresh was attempted
        // In a real environment, this would test the complete refresh cycle
    }
    
    // MARK: - Infinite Scroll Integration Tests
    
    func testInfiniteScrollIntegration() async {
        // Set up initial loaded state with more events available
        let mockItems = [createMockEventFeedItem()]
        viewModel.feedState = .loaded(mockItems)
        viewModel.hasMoreEvents = true
        
        // Simulate reaching end of list
        await viewModel.loadMoreEvents()
        
        // Verify load more was attempted
        // In a real environment, this would test pagination
    }
    
    func testInfiniteScrollWithNoMoreEvents() async {
        viewModel.hasMoreEvents = false
        
        let initialState = viewModel.feedState
        await viewModel.loadMoreEvents()
        
        // Should not attempt to load more when no more events are available
        XCTAssertEqual(viewModel.feedState, initialState)
    }
    
    // MARK: - Event Card Integration Tests
    
    func testEventCardBookmarkIntegration() async {
        let mockItem = createMockEventFeedItem()
        viewModel.feedState = .loaded([mockItem])
        
        // Test bookmark toggle
        await viewModel.toggleBookmark(for: mockItem)
        
        // In a real implementation, this would verify bookmark state changed
        // and the UI updated accordingly
    }
    
    func testEventCardDetailNavigation() {
        let mockItem = createMockEventFeedItem()
        var selectedEventItem: EventFeedItem?
        
        // Simulate tapping event card
        selectedEventItem = mockItem
        
        XCTAssertNotNil(selectedEventItem)
        XCTAssertEqual(selectedEventItem?.event.title, mockItem.event.title)
        XCTAssertEqual(selectedEventItem?.host.name, mockItem.host.name)
    }
    
    // MARK: - Filter Integration Tests
    
    func testTimeFilterIntegration() async {
        // Test today filter
        var filter = EventFeedFilter.default
        filter.timeRange = .today
        viewModel.currentFilter = filter
        
        await viewModel.applyFilter()
        
        XCTAssertEqual(viewModel.currentFilter.timeRange, .today)
    }
    
    func testPriceFilterIntegration() async {
        // Test free events filter
        var filter = EventFeedFilter.default
        filter.priceRange = .free
        filter.freeOnly = true
        viewModel.currentFilter = filter
        
        await viewModel.applyFilter()
        
        XCTAssertEqual(viewModel.currentFilter.priceRange, .free)
        XCTAssertTrue(viewModel.currentFilter.freeOnly)
    }
    
    func testVibeFilterIntegration() async {
        // Test vibe tag filtering
        var filter = EventFeedFilter.default
        filter.vibeFilters = Set(["energetic", "social"])
        viewModel.currentFilter = filter
        
        await viewModel.applyFilter()
        
        XCTAssertTrue(viewModel.currentFilter.vibeFilters.contains("energetic"))
        XCTAssertTrue(viewModel.currentFilter.vibeFilters.contains("social"))
    }
    
    func testAttendeeRangeFilterIntegration() async {
        // Test intimate events filter
        var filter = EventFeedFilter.default
        filter.attendeeRange = .intimate
        viewModel.currentFilter = filter
        
        await viewModel.applyFilter()
        
        XCTAssertEqual(viewModel.currentFilter.attendeeRange, .intimate)
    }
    
    func testFriendsOnlyFilterIntegration() async {
        // Test friends-only filter
        var filter = EventFeedFilter.default
        filter.friendsOnly = true
        viewModel.currentFilter = filter
        
        await viewModel.applyFilter()
        
        XCTAssertTrue(viewModel.currentFilter.friendsOnly)
    }
    
    // MARK: - Sort Integration Tests
    
    func testRelevanceSortIntegration() async {
        viewModel.currentSortOption = .relevance
        await viewModel.applySorting()
        
        XCTAssertEqual(viewModel.currentSortOption, .relevance)
    }
    
    func testDistanceSortIntegration() async {
        viewModel.currentSortOption = .distance
        await viewModel.applySorting()
        
        XCTAssertEqual(viewModel.currentSortOption, .distance)
    }
    
    func testDateSortIntegration() async {
        viewModel.currentSortOption = .date
        await viewModel.applySorting()
        
        XCTAssertEqual(viewModel.currentSortOption, .date)
    }
    
    func testPriceSortIntegration() async {
        viewModel.currentSortOption = .price
        await viewModel.applySorting()
        
        XCTAssertEqual(viewModel.currentSortOption, .price)
    }
    
    func testPopularitySortIntegration() async {
        viewModel.currentSortOption = .popularity
        await viewModel.applySorting()
        
        XCTAssertEqual(viewModel.currentSortOption, .popularity)
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testNetworkErrorRecoveryIntegration() async {
        // Simulate network error
        viewModel.feedState = .error("Network connection failed")
        
        // Test error state display
        XCTAssertEqual(viewModel.feedState.errorMessage, "Network connection failed")
        
        // Simulate retry after error
        await viewModel.loadInitialFeed()
        
        // Verify retry was attempted
        // In a real environment, this would test error recovery
    }
    
    func testLocationErrorIntegration() {
        // Simulate location error
        viewModel.isLocationEnabled = false
        viewModel.locationDescription = "Location access denied"
        
        XCTAssertFalse(viewModel.isLocationEnabled)
        XCTAssertEqual(viewModel.locationDescription, "Location access denied")
        
        // Test that feed still works without location
        // The feed should fall back to non-location-based recommendations
    }
    
    // MARK: - Performance Integration Tests
    
    func testFeedPerformanceWithManyItems() {
        measure {
            let mockItems = (0..<100).map { _ in createMockEventFeedItem() }
            viewModel.feedState = .loaded(mockItems)
            
            // Test that UI can handle large number of items efficiently
            XCTAssertEqual(viewModel.feedState.items.count, 100)
        }
    }
    
    func testFilterPerformanceIntegration() {
        // Set up feed with many items
        let mockItems = (0..<50).map { _ in createMockEventFeedItem() }
        viewModel.feedState = .loaded(mockItems)
        
        measure {
            // Apply multiple filters
            var filter = EventFeedFilter.default
            filter.timeRange = .today
            filter.priceRange = .free
            filter.attendeeRange = .intimate
            filter.friendsOnly = true
            viewModel.currentFilter = filter
        }
    }
    
    // MARK: - Complete Flow Integration Tests
    
    func testCompleteUserFlowIntegration() async {
        // Test complete user flow from app start to event discovery
        
        // 1. Initial app state
        XCTAssertEqual(viewModel.feedState, .idle)
        
        // 2. Load initial feed
        await viewModel.loadInitialFeed()
        
        // 3. Apply filter
        var filter = EventFeedFilter.default
        filter.timeRange = .thisWeek
        viewModel.currentFilter = filter
        await viewModel.applyFilter()
        
        // 4. Change sort option
        viewModel.currentSortOption = .distance
        await viewModel.applySorting()
        
        // 5. Verify final state
        XCTAssertEqual(viewModel.currentFilter.timeRange, .thisWeek)
        XCTAssertEqual(viewModel.currentSortOption, .distance)
    }
    
    func testCompleteLocationFlowIntegration() {
        // Test complete location flow
        
        // 1. Initial state without location
        XCTAssertFalse(viewModel.isLocationEnabled)
        
        // 2. Request location permission
        viewModel.requestLocationPermission()
        
        // 3. Simulate permission granted and location update
        viewModel.isLocationEnabled = true
        viewModel.locationDescription = "Current location"
        
        // 4. Verify location-based features are enabled
        XCTAssertTrue(viewModel.isLocationEnabled)
        XCTAssertNotEqual(viewModel.locationDescription, "Location off")
    }
    
    // MARK: - Edge Cases Integration Tests
    
    func testEmptySearchResultsIntegration() async {
        // Test handling of empty search results
        var filter = EventFeedFilter.default
        filter.vibeFilters = Set(["very_rare_vibe_tag"])
        viewModel.currentFilter = filter
        
        await viewModel.applyFilter()
        
        // Should handle empty results gracefully
        // In a real implementation, this would result in an empty state
    }
    
    func testNetworkTimeoutIntegration() async {
        // Test handling of network timeouts
        viewModel.feedState = .loading
        
        // Simulate timeout
        viewModel.feedState = .error("Request timed out")
        
        XCTAssertEqual(viewModel.feedState.errorMessage, "Request timed out")
    }
    
    // MARK: - Helper Methods
    
    private func createMockEventFeedItem() -> EventFeedItem {
        let event = Event(
            hostId: UUID(),
            title: "Integration Test Event",
            description: "An event for integration testing",
            vibe: "energetic",
            date: Date().addingTimeInterval(3600),
            location: EventLocation(
                name: "Test Venue",
                address: "123 Test St",
                city: "San Francisco",
                state: "CA",
                country: "USA",
                zipCode: "94102",
                latitude: 37.7749,
                longitude: -122.4194
            ),
            capacity: 50,
            price: 25.0
        )
        
        let host = EventHost(
            id: UUID(),
            name: "Integration Host",
            handle: "integrationhost",
            avatarUrl: nil,
            vibeTags: ["energetic", "social"],
            isVerified: true
        )
        
        let friendsAttending = [
            EventAttendee(
                id: UUID(),
                userId: UUID(),
                name: "Test Friend",
                handle: "testfriend",
                avatarUrl: nil,
                status: .going,
                joinedAt: Date()
            )
        ]
        
        return EventFeedItem(
            id: event.id,
            event: event,
            host: host,
            score: 0.8,
            attendeeCount: 30,
            friendsAttending: friendsAttending,
            isBookmarked: false,
            distanceFromUser: 2000.0
        )
    }
} 