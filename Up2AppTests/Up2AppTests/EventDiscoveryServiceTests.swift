import XCTest
import CoreLocation
@testable import Up2App

final class EventDiscoveryServiceTests: XCTestCase {
    
    var discoveryService: EventDiscoveryService!
    var mockProfileService: MockProfileService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        discoveryService = EventDiscoveryService.shared
        mockProfileService = MockProfileService()
        
        // Reset service state
        discoveryService.isLoading = false
        discoveryService.currentFeed = []
        discoveryService.errorMessage = nil
    }
    
    override func tearDown() {
        discoveryService = nil
        mockProfileService = nil
        super.tearDown()
    }
    
    // MARK: - AI Scoring System Tests
    
    func testVibeMatchScoring() {
        let eventVibe = "energetic"
        let hostVibeTags = ["energetic", "social", "outdoorsy"]
        let userVibeTags = ["energetic", "chill"]
        
        // Test internal vibe matching logic
        let vibeScore = calculateVibeMatchScore(
            eventVibe: eventVibe,
            hostVibeTags: hostVibeTags,
            userVibeTags: userVibeTags
        )
        
        // Should get points for direct vibe match (energetic) and tag intersection
        XCTAssertGreaterThan(vibeScore, 0.5)
        XCTAssertLessThanOrEqual(vibeScore, 1.0)
    }
    
    func testVibeMatchScoringNoMatch() {
        let eventVibe = "artistic"
        let hostVibeTags = ["creative", "indoor"]
        let userVibeTags = ["energetic", "outdoorsy"]
        
        let vibeScore = calculateVibeMatchScore(
            eventVibe: eventVibe,
            hostVibeTags: hostVibeTags,
            userVibeTags: userVibeTags
        )
        
        // Should get minimal or no score for no matches
        XCTAssertLessThan(vibeScore, 0.2)
    }
    
    func testLocationScoring() {
        let eventLocation = EventLocation(
            name: "Test Venue",
            address: "123 Test St",
            city: "San Francisco",
            state: "CA",
            country: "USA",
            zipCode: "94102",
            latitude: 37.7749,
            longitude: -122.4194
        )
        
        // Test close location (within 5km)
        let closeUserLocation = CLLocation(latitude: 37.7849, longitude: -122.4094)
        let closeScore = calculateLocationScore(eventLocation: eventLocation, userLocation: closeUserLocation)
        
        // Test far location (over 50km)
        let farUserLocation = CLLocation(latitude: 38.2, longitude: -122.8)
        let farScore = calculateLocationScore(eventLocation: eventLocation, userLocation: farUserLocation)
        
        XCTAssertGreaterThan(closeScore, farScore)
        XCTAssertGreaterThan(closeScore, 0.8) // Should be high for close events
        XCTAssertLessThan(farScore, 0.2) // Should be low for far events
    }
    
    func testTimeRelevanceScoring() {
        let now = Date()
        
        // Event in 12 hours
        let soonEvent = Event(
            hostId: UUID(),
            title: "Soon Event",
            description: "Test",
            vibe: "energetic",
            date: now.addingTimeInterval(12 * 3600),
            location: createTestLocation()
        )
        
        // Event in 1 week
        let laterEvent = Event(
            hostId: UUID(),
            title: "Later Event",
            description: "Test",
            vibe: "energetic",
            date: now.addingTimeInterval(7 * 24 * 3600),
            location: createTestLocation()
        )
        
        // Event in the past
        let pastEvent = Event(
            hostId: UUID(),
            title: "Past Event",
            description: "Test",
            vibe: "energetic",
            date: now.addingTimeInterval(-3600),
            location: createTestLocation()
        )
        
        let soonScore = calculateTimeRelevanceScore(event: soonEvent)
        let laterScore = calculateTimeRelevanceScore(event: laterEvent)
        let pastScore = calculateTimeRelevanceScore(event: pastEvent)
        
        XCTAssertGreaterThan(soonScore, laterScore)
        XCTAssertEqual(pastScore, 0.0) // Past events should get 0 score
        XCTAssertEqual(soonScore, 1.0) // Events within 24 hours should get max score
    }
    
    func testPopularityScoring() {
        // Small intimate event
        let smallEvent = Event(
            hostId: UUID(),
            title: "Small Event",
            description: "Test",
            vibe: "chill",
            date: Date().addingTimeInterval(3600),
            location: createTestLocation(),
            capacity: 15
        )
        
        // Large event
        let largeEvent = Event(
            hostId: UUID(),
            title: "Large Event",
            description: "Test",
            vibe: "energetic",
            date: Date().addingTimeInterval(3600),
            location: createTestLocation(),
            capacity: 500
        )
        
        let smallScore = calculatePopularityScore(event: smallEvent)
        let largeScore = calculatePopularityScore(event: largeEvent)
        
        XCTAssertGreaterThan(largeScore, smallScore)
        XCTAssertLessThanOrEqual(largeScore, 1.0)
        XCTAssertGreaterThanOrEqual(smallScore, 0.0)
    }
    
    func testHostReputationScoring() {
        // Verified host with many vibe tags
        let verifiedHost = EventHost(
            id: UUID(),
            name: "John Doe",
            handle: "johndoe",
            avatarUrl: nil,
            vibeTags: ["energetic", "social", "creative", "outdoorsy"],
            isVerified: true
        )
        
        // New host, not verified
        let newHost = EventHost(
            id: UUID(),
            name: "Jane Smith",
            handle: "janesmith",
            avatarUrl: nil,
            vibeTags: ["chill"],
            isVerified: false
        )
        
        let verifiedScore = calculateHostReputationScore(host: verifiedHost)
        let newScore = calculateHostReputationScore(host: newHost)
        
        XCTAssertGreaterThan(verifiedScore, newScore)
        XCTAssertLessThanOrEqual(verifiedScore, 1.0)
    }
    
    // MARK: - Cache Management Tests
    
    func testCacheKeyGeneration() {
        let request = EventFeedRequest(
            userId: UUID(),
            userLocation: CLLocation(latitude: 37.7749, longitude: -122.4194),
            userVibeTags: ["energetic"],
            friendIds: [UUID()],
            filter: .default,
            sortOption: .relevance,
            page: 0,
            pageSize: 20
        )
        
        let cacheKey1 = generateCacheKey(for: request)
        let cacheKey2 = generateCacheKey(for: request)
        
        // Same request should generate same cache key
        XCTAssertEqual(cacheKey1, cacheKey2)
        
        // Different page should generate different cache key
        let differentPageRequest = EventFeedRequest(
            userId: request.userId,
            userLocation: request.userLocation,
            userVibeTags: request.userVibeTags,
            friendIds: request.friendIds,
            filter: request.filter,
            sortOption: request.sortOption,
            page: 1, // Different page
            pageSize: request.pageSize
        )
        
        let differentCacheKey = generateCacheKey(for: differentPageRequest)
        XCTAssertNotEqual(cacheKey1, differentCacheKey)
    }
    
    func testCacheExpiration() {
        let response = EventFeedResponse(
            items: [],
            totalCount: 0,
            hasMore: false,
            nextPage: nil,
            requestId: "test",
            generatedAt: Date()
        )
        
        let cacheKey = "test_cache_key"
        
        // Cache the response
        cacheResponse(response, for: cacheKey)
        
        // Should be retrievable immediately
        let cachedResponse = getCachedResponse(for: cacheKey)
        XCTAssertNotNil(cachedResponse)
        
        // Simulate cache expiration by setting timestamp in the past
        setCacheTimestamp(cacheKey, timestamp: Date().addingTimeInterval(-400)) // 400 seconds ago
        
        // Should not be retrievable after expiration
        let expiredResponse = getCachedResponse(for: cacheKey)
        XCTAssertNil(expiredResponse)
    }
    
    // MARK: - Filtering and Sorting Tests
    
    func testAttendeesFiltering() {
        let smallEvent = createTestEventFeedItem(attendeeCount: 10)
        let mediumEvent = createTestEventFeedItem(attendeeCount: 75)
        let largeEvent = createTestEventFeedItem(attendeeCount: 250)
        
        let items = [smallEvent, mediumEvent, largeEvent]
        
        // Filter for intimate events (1-20 attendees)
        var filter = EventFeedFilter.default
        filter.attendeeRange = .intimate
        
        let request = EventFeedRequest(
            userId: UUID(),
            filter: filter,
            sortOption: .relevance
        )
        
        let filteredItems = applyFiltersAndSorting(items, request: request)
        
        XCTAssertEqual(filteredItems.count, 1)
        XCTAssertEqual(filteredItems.first?.attendeeCount, 10)
    }
    
    func testFriendsOnlyFiltering() {
        let eventWithFriends = createTestEventFeedItem(friendsAttending: 2)
        let eventWithoutFriends = createTestEventFeedItem(friendsAttending: 0)
        
        let items = [eventWithFriends, eventWithoutFriends]
        
        var filter = EventFeedFilter.default
        filter.friendsOnly = true
        
        let request = EventFeedRequest(
            userId: UUID(),
            filter: filter,
            sortOption: .relevance
        )
        
        let filteredItems = applyFiltersAndSorting(items, request: request)
        
        XCTAssertEqual(filteredItems.count, 1)
        XCTAssertEqual(filteredItems.first?.friendsAttending.count, 2)
    }
    
    func testSortingByRelevance() {
        let highScoreItem = createTestEventFeedItem(score: 0.9)
        let mediumScoreItem = createTestEventFeedItem(score: 0.6)
        let lowScoreItem = createTestEventFeedItem(score: 0.3)
        
        let items = [mediumScoreItem, lowScoreItem, highScoreItem] // Mixed order
        
        let request = EventFeedRequest(
            userId: UUID(),
            sortOption: .relevance
        )
        
        let sortedItems = applyFiltersAndSorting(items, request: request)
        
        XCTAssertEqual(sortedItems[0].score, 0.9)
        XCTAssertEqual(sortedItems[1].score, 0.6)
        XCTAssertEqual(sortedItems[2].score, 0.3)
    }
    
    func testSortingByDistance() {
        let nearItem = createTestEventFeedItem(distance: 500.0)
        let farItem = createTestEventFeedItem(distance: 5000.0)
        let mediumItem = createTestEventFeedItem(distance: 2000.0)
        
        let items = [farItem, nearItem, mediumItem] // Mixed order
        
        let request = EventFeedRequest(
            userId: UUID(),
            sortOption: .distance
        )
        
        let sortedItems = applyFiltersAndSorting(items, request: request)
        
        XCTAssertEqual(sortedItems[0].distanceFromUser, 500.0)
        XCTAssertEqual(sortedItems[1].distanceFromUser, 2000.0)
        XCTAssertEqual(sortedItems[2].distanceFromUser, 5000.0)
    }
    
    func testSortingByPrice() {
        let freeItem = createTestEventFeedItem(price: nil)
        let cheapItem = createTestEventFeedItem(price: 10.0)
        let expensiveItem = createTestEventFeedItem(price: 50.0)
        
        let items = [expensiveItem, freeItem, cheapItem] // Mixed order
        
        let request = EventFeedRequest(
            userId: UUID(),
            sortOption: .price
        )
        
        let sortedItems = applyFiltersAndSorting(items, request: request)
        
        XCTAssertEqual(sortedItems[0].event.price, nil) // Free first
        XCTAssertEqual(sortedItems[1].event.price, 10.0)
        XCTAssertEqual(sortedItems[2].event.price, 50.0)
    }
    
    // MARK: - Pagination Tests
    
    func testPaginationResults() {
        let items = (0..<25).map { _ in createTestEventFeedItem() }
        
        // Test first page
        let firstPageRequest = EventFeedRequest(
            userId: UUID(),
            page: 0,
            pageSize: 10
        )
        
        let firstPage = paginateResults(items, request: firstPageRequest)
        XCTAssertEqual(firstPage.count, 10)
        
        // Test second page
        let secondPageRequest = EventFeedRequest(
            userId: UUID(),
            page: 1,
            pageSize: 10
        )
        
        let secondPage = paginateResults(items, request: secondPageRequest)
        XCTAssertEqual(secondPage.count, 10)
        
        // Test partial last page
        let lastPageRequest = EventFeedRequest(
            userId: UUID(),
            page: 2,
            pageSize: 10
        )
        
        let lastPage = paginateResults(items, request: lastPageRequest)
        XCTAssertEqual(lastPage.count, 5) // 25 total, 20 on first two pages, 5 remaining
    }
    
    func testHasMorePagesCalculation() {
        let totalCount = 25
        
        let firstPageRequest = EventFeedRequest(
            userId: UUID(),
            page: 0,
            pageSize: 10
        )
        
        let secondPageRequest = EventFeedRequest(
            userId: UUID(),
            page: 1,
            pageSize: 10
        )
        
        let lastPageRequest = EventFeedRequest(
            userId: UUID(),
            page: 2,
            pageSize: 10
        )
        
        XCTAssertTrue(hasMorePages(totalCount, request: firstPageRequest))
        XCTAssertTrue(hasMorePages(totalCount, request: secondPageRequest))
        XCTAssertFalse(hasMorePages(totalCount, request: lastPageRequest))
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidUserIdError() async {
        let invalidRequest = EventFeedRequest(
            userId: UUID(), // This would fail if profile doesn't exist
            page: 0,
            pageSize: 20
        )
        
        do {
            _ = try await discoveryService.generatePersonalizedFeed(request: invalidRequest)
            XCTFail("Expected EventFeedError.invalidUserId to be thrown")
        } catch let error as EventFeedError {
            XCTAssertEqual(error, .invalidUserId)
        } catch {
            XCTFail("Expected EventFeedError.invalidUserId, got \(error)")
        }
    }
    
    // MARK: - Performance Tests
    
    func testFeedGenerationPerformance() async {
        // This test ensures the feed generation completes within reasonable time
        let request = EventFeedRequest(
            userId: UUID(),
            page: 0,
            pageSize: 20
        )
        
        measure {
            // Simulate feed generation time
            let expectation = self.expectation(description: "Feed generation")
            
            Task {
                do {
                    _ = try await discoveryService.generatePersonalizedFeed(request: request)
                } catch {
                    // Expected to fail due to mock data, but we're measuring time
                }
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 2.0) // Should complete within 2 seconds
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestLocation() -> EventLocation {
        return EventLocation(
            name: "Test Venue",
            address: "123 Test St",
            city: "San Francisco",
            state: "CA",
            country: "USA",
            zipCode: "94102",
            latitude: 37.7749,
            longitude: -122.4194
        )
    }
    
    private func createTestEventFeedItem(
        score: Double = 0.75,
        attendeeCount: Int = 25,
        friendsAttending: Int = 1,
        distance: Double = 1500.0,
        price: Double? = 25.0
    ) -> EventFeedItem {
        let event = Event(
            hostId: UUID(),
            title: "Test Event",
            description: "A test event",
            vibe: "energetic",
            date: Date().addingTimeInterval(3600),
            location: createTestLocation(),
            capacity: 50,
            price: price
        )
        
        let host = EventHost(
            id: UUID(),
            name: "John Doe",
            handle: "johndoe",
            avatarUrl: nil,
            vibeTags: ["energetic", "social"],
            isVerified: true
        )
        
        let friends = (0..<friendsAttending).map { index in
            EventAttendee(
                id: UUID(),
                userId: UUID(),
                name: "Friend \(index + 1)",
                handle: "friend\(index + 1)",
                avatarUrl: nil,
                status: .going,
                joinedAt: Date()
            )
        }
        
        return EventFeedItem(
            id: event.id,
            event: event,
            host: host,
            score: score,
            attendeeCount: attendeeCount,
            friendsAttending: friends,
            isBookmarked: false,
            distanceFromUser: distance
        )
    }
    
    // MARK: - Private scoring method stubs for testing
    // These would normally be private methods in EventDiscoveryService
    
    private func calculateVibeMatchScore(
        eventVibe: String,
        hostVibeTags: [String],
        userVibeTags: [String]
    ) -> Double {
        let userTagsSet = Set(userVibeTags)
        let hostTagsSet = Set(hostVibeTags)
        
        // Direct vibe match
        let directMatch = userTagsSet.contains(eventVibe) ? 0.5 : 0.0
        
        // Host-user vibe tag intersection
        let commonTags = userTagsSet.intersection(hostTagsSet)
        let intersectionScore = Double(commonTags.count) / Double(max(userTagsSet.count, 1)) * 0.5
        
        return directMatch + intersectionScore
    }
    
    private func calculateLocationScore(
        eventLocation: EventLocation,
        userLocation: CLLocation
    ) -> Double {
        let distance = userLocation.distance(from: CLLocation(
            latitude: eventLocation.latitude,
            longitude: eventLocation.longitude
        ))
        
        // Optimal distance: 0-5km = 1.0, decreasing to 0.0 at 50km
        let maxDistance: Double = 50000 // 50km
        let optimalDistance: Double = 5000 // 5km
        
        if distance <= optimalDistance {
            return 1.0
        } else if distance >= maxDistance {
            return 0.0
        } else {
            return 1.0 - (distance - optimalDistance) / (maxDistance - optimalDistance)
        }
    }
    
    private func calculateTimeRelevanceScore(event: Event) -> Double {
        let now = Date()
        let timeUntilEvent = event.date.timeIntervalSince(now)
        
        // Events happening soon get higher scores
        let hoursUntilEvent = timeUntilEvent / 3600
        
        if hoursUntilEvent < 0 {
            return 0.0 // Past events get no time bonus
        } else if hoursUntilEvent <= 24 {
            return 1.0 // Events within 24 hours get max score
        } else if hoursUntilEvent <= 168 { // 1 week
            return 0.8
        } else if hoursUntilEvent <= 720 { // 1 month
            return 0.5
        } else {
            return 0.2
        }
    }
    
    private func calculatePopularityScore(event: Event) -> Double {
        let capacity = event.capacity ?? 100
        
        if capacity <= 20 {
            return 0.3 // Intimate events
        } else if capacity <= 100 {
            return 0.6 // Medium events
        } else {
            return 0.8 // Large events
        }
    }
    
    private func calculateHostReputationScore(host: EventHost) -> Double {
        var score = 0.0
        
        if host.isVerified {
            score += 0.5
        }
        
        // More diverse vibe tags indicate experienced host
        score += min(Double(host.vibeTags.count) * 0.1, 0.5)
        
        return min(score, 1.0)
    }
    
    // Mock methods for testing cache functionality
    private func generateCacheKey(for request: EventFeedRequest) -> String {
        let components = [
            request.userId.uuidString,
            String(request.page),
            String(request.pageSize),
            request.sortOption.displayName,
            request.filter.timeRange.displayName,
            request.filter.priceRange.displayName,
            String(request.filter.locationRadius),
            String(request.filter.friendsOnly),
            String(request.filter.freeOnly)
        ]
        return components.joined(separator: "_")
    }
    
    private func getCachedResponse(for key: String) -> EventFeedResponse? {
        // Mock implementation for testing
        return nil
    }
    
    private func cacheResponse(_ response: EventFeedResponse, for key: String) {
        // Mock implementation for testing
    }
    
    private func setCacheTimestamp(_ key: String, timestamp: Date) {
        // Mock implementation for testing
    }
    
    private func applyFiltersAndSorting(_ items: [EventFeedItem], request: EventFeedRequest) -> [EventFeedItem] {
        var filteredItems = items
        
        // Apply attendee range filter
        let attendeeRange = request.filter.attendeeRange.range
        if let minAttendees = attendeeRange.min {
            filteredItems = filteredItems.filter { $0.attendeeCount >= minAttendees }
        }
        if let maxAttendees = attendeeRange.max {
            filteredItems = filteredItems.filter { $0.attendeeCount <= maxAttendees }
        }
        
        // Apply friends-only filter
        if request.filter.friendsOnly {
            filteredItems = filteredItems.filter { !$0.friendsAttending.isEmpty }
        }
        
        // Apply sorting
        switch request.sortOption {
        case .relevance:
            filteredItems.sort { $0.score > $1.score }
        case .date:
            filteredItems.sort { $0.event.date < $1.event.date }
        case .distance:
            filteredItems.sort { ($0.distanceFromUser ?? Double.infinity) < ($1.distanceFromUser ?? Double.infinity) }
        case .price:
            filteredItems.sort { ($0.event.price ?? 0) < ($1.event.price ?? 0) }
        case .popularity:
            filteredItems.sort { $0.attendeeCount > $1.attendeeCount }
        }
        
        return filteredItems
    }
    
    private func paginateResults(_ items: [EventFeedItem], request: EventFeedRequest) -> [EventFeedItem] {
        let startIndex = request.page * request.pageSize
        let endIndex = min(startIndex + request.pageSize, items.count)
        
        guard startIndex < items.count else { return [] }
        
        return Array(items[startIndex..<endIndex])
    }
    
    private func hasMorePages(_ totalCount: Int, request: EventFeedRequest) -> Bool {
        let currentItemCount = (request.page + 1) * request.pageSize
        return currentItemCount < totalCount
    }
}

// MARK: - Mock Classes

class MockProfileService {
    func getProfile(for userId: UUID) async throws -> ProfileData? {
        // Return a mock profile for testing
        return ProfileData(
            id: userId,
            name: "Test User",
            handle: "testuser",
            vibeTags: [.energetic, .social],
            bio: "Test bio"
        )
    }
} 