import XCTest
import CoreLocation
@testable import Up2App

final class EventFeedModelsTests: XCTestCase {
    
    // MARK: - Event Model Tests
    
    func testEventCreation() {
        let eventId = UUID()
        let hostId = UUID()
        let eventDate = Date()
        let location = EventLocation(
            name: "Test Venue",
            address: "123 Test St",
            city: "San Francisco",
            state: "CA",
            country: "USA",
            zipCode: "94102",
            latitude: 37.7749,
            longitude: -122.4194
        )
        
        let event = Event(
            id: eventId,
            hostId: hostId,
            title: "Test Event",
            description: "A test event",
            vibe: "energetic",
            date: eventDate,
            location: location,
            capacity: 50,
            price: 25.0
        )
        
        XCTAssertEqual(event.id, eventId)
        XCTAssertEqual(event.hostId, hostId)
        XCTAssertEqual(event.title, "Test Event")
        XCTAssertEqual(event.vibe, "energetic")
        XCTAssertEqual(event.capacity, 50)
        XCTAssertEqual(event.price, 25.0)
        XCTAssertFalse(event.isFree)
        XCTAssertEqual(event.formattedPrice, "$25.00")
    }
    
    func testEventFreePrice() {
        let location = createTestLocation()
        let freeEvent = Event(
            hostId: UUID(),
            title: "Free Event",
            description: "A free event",
            vibe: "chill",
            date: Date(),
            location: location,
            price: nil
        )
        
        XCTAssertTrue(freeEvent.isFree)
        XCTAssertEqual(freeEvent.formattedPrice, "Free")
    }
    
    func testEventDateProperties() {
        let location = createTestLocation()
        let futureDate = Date().addingTimeInterval(3600) // 1 hour from now
        let pastDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let today = Date()
        
        let futureEvent = Event(
            hostId: UUID(),
            title: "Future Event",
            description: "Future event",
            vibe: "energetic",
            date: futureDate,
            location: location
        )
        
        let pastEvent = Event(
            hostId: UUID(),
            title: "Past Event",
            description: "Past event",
            vibe: "chill",
            date: pastDate,
            location: location
        )
        
        XCTAssertTrue(futureEvent.isUpcoming)
        XCTAssertFalse(futureEvent.isPast)
        
        XCTAssertFalse(pastEvent.isUpcoming)
        XCTAssertTrue(pastEvent.isPast)
    }
    
    // MARK: - EventLocation Tests
    
    func testEventLocationCreation() {
        let location = EventLocation(
            name: "Test Venue",
            address: "123 Main St",
            city: "San Francisco",
            state: "CA",
            country: "USA",
            zipCode: "94102",
            latitude: 37.7749,
            longitude: -122.4194
        )
        
        XCTAssertEqual(location.name, "Test Venue")
        XCTAssertEqual(location.shortAddress, "San Francisco, CA")
        XCTAssertTrue(location.fullAddress.contains("123 Main St"))
        XCTAssertTrue(location.fullAddress.contains("San Francisco"))
        XCTAssertEqual(location.coordinate.latitude, 37.7749, accuracy: 0.0001)
        XCTAssertEqual(location.coordinate.longitude, -122.4194, accuracy: 0.0001)
    }
    
    func testEventLocationDistance() {
        let location = createTestLocation()
        let userLocation = CLLocation(latitude: 37.7849, longitude: -122.4094) // Slightly different location
        
        let distance = location.distance(from: userLocation)
        XCTAssertGreaterThan(distance, 0)
        XCTAssertLessThan(distance, 2000) // Should be less than 2km apart
    }
    
    // MARK: - EventHost Tests
    
    func testEventHostCreation() {
        let hostId = UUID()
        let host = EventHost(
            id: hostId,
            name: "John Doe",
            handle: "johndoe",
            avatarUrl: "https://example.com/avatar.jpg",
            vibeTags: ["energetic", "social"],
            isVerified: true
        )
        
        XCTAssertEqual(host.id, hostId)
        XCTAssertEqual(host.displayName, "John Doe")
        XCTAssertTrue(host.isVerified)
        XCTAssertEqual(host.vibeTags.count, 2)
    }
    
    func testEventHostDisplayNameFallback() {
        let host = EventHost(
            id: UUID(),
            name: "",
            handle: "testuser",
            avatarUrl: nil,
            vibeTags: [],
            isVerified: false
        )
        
        XCTAssertEqual(host.displayName, "@testuser")
    }
    
    // MARK: - EventFeedItem Tests
    
    func testEventFeedItemCreation() {
        let feedItem = createTestEventFeedItem()
        
        XCTAssertNotNil(feedItem.id)
        XCTAssertEqual(feedItem.score, 0.85)
        XCTAssertEqual(feedItem.attendeeCount, 15)
        XCTAssertEqual(feedItem.friendsAttending.count, 2)
        XCTAssertFalse(feedItem.isBookmarked)
        XCTAssertEqual(feedItem.distanceFromUser, 1500.0)
    }
    
    func testEventRelevanceScoreCalculation() {
        let feedItem = createTestEventFeedItem()
        let relevanceScore = feedItem.relevanceScore
        
        XCTAssertEqual(relevanceScore.overallScore, 0.85)
        XCTAssertGreaterThan(relevanceScore.vibeMatch, 0)
        XCTAssertGreaterThan(relevanceScore.locationRelevance, 0)
        XCTAssertGreaterThan(relevanceScore.friendNetworkBoost, 0)
        XCTAssertEqual(relevanceScore.percentageScore, 85)
    }
    
    func testEventRelevanceScoreDescription() {
        let highScore = EventRelevanceScore(vibeMatch: 0.4, locationRelevance: 0.3, friendNetworkBoost: 0.2, overallScore: 0.9)
        let lowScore = EventRelevanceScore(vibeMatch: 0.1, locationRelevance: 0.05, friendNetworkBoost: 0.0, overallScore: 0.15)
        
        XCTAssertEqual(highScore.scoreDescription, "Perfect Match")
        XCTAssertEqual(lowScore.scoreDescription, "Low Match")
    }
    
    // MARK: - EventAttendee Tests
    
    func testEventAttendeeCreation() {
        let attendeeId = UUID()
        let userId = UUID()
        let attendee = EventAttendee(
            id: attendeeId,
            userId: userId,
            name: "Jane Smith",
            handle: "janesmith",
            avatarUrl: nil,
            status: .going,
            joinedAt: Date()
        )
        
        XCTAssertEqual(attendee.id, attendeeId)
        XCTAssertEqual(attendee.status, .going)
        XCTAssertEqual(attendee.status.displayName, "Going")
    }
    
    func testAttendanceStatusProperties() {
        XCTAssertEqual(EventAttendee.AttendanceStatus.going.displayName, "Going")
        XCTAssertEqual(EventAttendee.AttendanceStatus.maybe.displayName, "Maybe")
        XCTAssertEqual(EventAttendee.AttendanceStatus.notGoing.displayName, "Not Going")
        XCTAssertEqual(EventAttendee.AttendanceStatus.invited.displayName, "Invited")
    }
    
    // MARK: - EventFeedFilter Tests
    
    func testEventFeedFilterDefault() {
        let defaultFilter = EventFeedFilter.default
        
        XCTAssertEqual(defaultFilter.timeRange, .upcoming)
        XCTAssertEqual(defaultFilter.priceRange, .any)
        XCTAssertTrue(defaultFilter.vibeFilters.isEmpty)
        XCTAssertEqual(defaultFilter.locationRadius, 25000) // 25km
        XCTAssertEqual(defaultFilter.attendeeRange, .any)
        XCTAssertFalse(defaultFilter.friendsOnly)
        XCTAssertFalse(defaultFilter.freeOnly)
    }
    
    func testTimeRangeDateCalculation() {
        let today = EventFeedFilter.TimeRange.today
        let thisWeek = EventFeedFilter.TimeRange.thisWeek
        let upcoming = EventFeedFilter.TimeRange.upcoming
        let all = EventFeedFilter.TimeRange.all
        
        let todayRange = today.dateRange
        XCTAssertNotNil(todayRange.start)
        XCTAssertNotNil(todayRange.end)
        
        let weekRange = thisWeek.dateRange
        XCTAssertNotNil(weekRange.start)
        XCTAssertNotNil(weekRange.end)
        
        let upcomingRange = upcoming.dateRange
        XCTAssertNotNil(upcomingRange.start)
        XCTAssertNil(upcomingRange.end)
        
        let allRange = all.dateRange
        XCTAssertNil(allRange.start)
        XCTAssertNil(allRange.end)
    }
    
    func testPriceRangeCalculation() {
        let free = EventFeedFilter.PriceRange.free
        let under25 = EventFeedFilter.PriceRange.under25
        let under50 = EventFeedFilter.PriceRange.under50
        let any = EventFeedFilter.PriceRange.any
        
        XCTAssertEqual(free.range.min, 0)
        XCTAssertEqual(free.range.max, 0)
        
        XCTAssertEqual(under25.range.min, 0)
        XCTAssertEqual(under25.range.max, 25)
        
        XCTAssertEqual(under50.range.min, 0)
        XCTAssertEqual(under50.range.max, 50)
        
        XCTAssertNil(any.range.min)
        XCTAssertNil(any.range.max)
    }
    
    func testAttendeeRangeCalculation() {
        let intimate = EventFeedFilter.AttendeeRange.intimate
        let small = EventFeedFilter.AttendeeRange.small
        let large = EventFeedFilter.AttendeeRange.large
        let any = EventFeedFilter.AttendeeRange.any
        
        XCTAssertEqual(intimate.range.min, 1)
        XCTAssertEqual(intimate.range.max, 20)
        
        XCTAssertEqual(small.range.min, 21)
        XCTAssertEqual(small.range.max, 50)
        
        XCTAssertEqual(large.range.min, 201)
        XCTAssertNil(large.range.max)
        
        XCTAssertNil(any.range.min)
        XCTAssertNil(any.range.max)
    }
    
    // MARK: - EventFeedSortOption Tests
    
    func testEventFeedSortOptions() {
        let relevance = EventFeedSortOption.relevance
        let date = EventFeedSortOption.date
        let distance = EventFeedSortOption.distance
        let price = EventFeedSortOption.price
        let popularity = EventFeedSortOption.popularity
        
        XCTAssertEqual(relevance.displayName, "Relevance")
        XCTAssertEqual(date.displayName, "Date")
        XCTAssertEqual(distance.displayName, "Distance")
        XCTAssertEqual(price.displayName, "Price")
        XCTAssertEqual(popularity.displayName, "Popularity")
        
        XCTAssertEqual(relevance.systemImage, "heart.fill")
        XCTAssertEqual(date.systemImage, "calendar")
        XCTAssertEqual(distance.systemImage, "location")
    }
    
    // MARK: - EventFeedState Tests
    
    func testEventFeedStateProperties() {
        let idle = EventFeedState.idle
        let loading = EventFeedState.loading
        let loaded = EventFeedState.loaded([createTestEventFeedItem()])
        let error = EventFeedState.error("Test error")
        let empty = EventFeedState.empty
        
        XCTAssertFalse(idle.isLoading)
        XCTAssertTrue(loading.isLoading)
        XCTAssertFalse(loaded.isLoading)
        XCTAssertFalse(error.isLoading)
        XCTAssertFalse(empty.isLoading)
        
        XCTAssertTrue(idle.items.isEmpty)
        XCTAssertTrue(loading.items.isEmpty)
        XCTAssertEqual(loaded.items.count, 1)
        XCTAssertTrue(error.items.isEmpty)
        XCTAssertTrue(empty.items.isEmpty)
        
        XCTAssertNil(idle.errorMessage)
        XCTAssertNil(loading.errorMessage)
        XCTAssertNil(loaded.errorMessage)
        XCTAssertEqual(error.errorMessage, "Test error")
        XCTAssertNil(empty.errorMessage)
    }
    
    // MARK: - EventFeedRequest Tests
    
    func testEventFeedRequestCreation() {
        let userId = UUID()
        let userLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let friendIds = [UUID(), UUID()]
        
        let request = EventFeedRequest(
            userId: userId,
            userLocation: userLocation,
            userVibeTags: ["energetic", "social"],
            friendIds: friendIds,
            filter: .default,
            sortOption: .relevance,
            page: 1,
            pageSize: 20
        )
        
        XCTAssertEqual(request.userId, userId)
        XCTAssertEqual(request.userLocation, userLocation)
        XCTAssertEqual(request.userVibeTags, ["energetic", "social"])
        XCTAssertEqual(request.friendIds, friendIds)
        XCTAssertEqual(request.page, 1)
        XCTAssertEqual(request.pageSize, 20)
    }
    
    // MARK: - EventFeedResponse Tests
    
    func testEventFeedResponseCreation() {
        let items = [createTestEventFeedItem()]
        let response = EventFeedResponse(
            items: items,
            totalCount: 10,
            hasMore: true,
            nextPage: 2,
            requestId: "test-request-123",
            generatedAt: Date()
        )
        
        XCTAssertEqual(response.items.count, 1)
        XCTAssertEqual(response.totalCount, 10)
        XCTAssertTrue(response.hasMore)
        XCTAssertEqual(response.nextPage, 2)
        XCTAssertFalse(response.isEmpty)
    }
    
    func testEventFeedResponseEmpty() {
        let response = EventFeedResponse(
            items: [],
            totalCount: 0,
            hasMore: false,
            nextPage: nil,
            requestId: "empty-request",
            generatedAt: Date()
        )
        
        XCTAssertTrue(response.isEmpty)
        XCTAssertFalse(response.hasMore)
        XCTAssertNil(response.nextPage)
    }
    
    // MARK: - Error Types Tests
    
    func testEventFeedErrorDescriptions() {
        let invalidUserId = EventFeedError.invalidUserId
        let networkError = EventFeedError.networkError("Connection failed")
        let noPermission = EventFeedError.noPermission
        let invalidFilter = EventFeedError.invalidFilter
        let locationNotAvailable = EventFeedError.locationNotAvailable
        let serviceUnavailable = EventFeedError.serviceUnavailable
        
        XCTAssertEqual(invalidUserId.errorDescription, "Invalid user ID provided")
        XCTAssertEqual(networkError.errorDescription, "Network error: Connection failed")
        XCTAssertEqual(noPermission.errorDescription, "You don't have permission to access this feed")
        XCTAssertEqual(invalidFilter.errorDescription, "Invalid filter parameters")
        XCTAssertEqual(locationNotAvailable.errorDescription, "Location services not available")
        XCTAssertEqual(serviceUnavailable.errorDescription, "Event discovery service is temporarily unavailable")
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
    
    private func createTestEventFeedItem() -> EventFeedItem {
        let event = Event(
            hostId: UUID(),
            title: "Test Event",
            description: "A test event",
            vibe: "energetic",
            date: Date().addingTimeInterval(3600),
            location: createTestLocation(),
            capacity: 50,
            price: 25.0
        )
        
        let host = EventHost(
            id: UUID(),
            name: "John Doe",
            handle: "johndoe",
            avatarUrl: nil,
            vibeTags: ["energetic", "social"],
            isVerified: true
        )
        
        let friendsAttending = [
            EventAttendee(
                id: UUID(),
                userId: UUID(),
                name: "Friend 1",
                handle: "friend1",
                avatarUrl: nil,
                status: .going,
                joinedAt: Date()
            ),
            EventAttendee(
                id: UUID(),
                userId: UUID(),
                name: "Friend 2",
                handle: "friend2",
                avatarUrl: nil,
                status: .maybe,
                joinedAt: Date()
            )
        ]
        
        return EventFeedItem(
            id: event.id,
            event: event,
            host: host,
            score: 0.85,
            attendeeCount: 15,
            friendsAttending: friendsAttending,
            isBookmarked: false,
            distanceFromUser: 1500.0
        )
    }
} 