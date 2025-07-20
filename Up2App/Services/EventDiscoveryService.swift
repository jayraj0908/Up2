import Foundation
import Supabase
import CoreLocation

@MainActor
class EventDiscoveryService: ObservableObject {
    static let shared = EventDiscoveryService()
    
    private let authService = SupabaseAuthService.shared
    private let profileService = ProfileService.shared
    
    private var supabase: SupabaseClient { authService.supabaseClient }
    
    @Published var isLoading = false
    @Published var currentFeed: [EventFeedItem] = []
    @Published var errorMessage: String?
    
    // Cache management
    private var feedCache: [String: EventFeedResponse] = [:]
    private var cacheTimestamps: [String: Date] = [:]
    private let cacheExpirationTime: TimeInterval = 300 // 5 minutes
    
    // AI Scoring Configuration
    private let vibeMatchWeight: Double = 0.4
    private let locationWeight: Double = 0.3
    private let friendNetworkWeight: Double = 0.3
    private let baseScore: Double = 0.1
    
    // Mock mode for Epic C development
    private let useMockData = true // Set to false when ready for real data
    
    private init() {}
    
    // MARK: - Main Feed Generation
    
    func generatePersonalizedFeed(request: EventFeedRequest) async throws -> EventFeedResponse {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            // Check cache first
            let cacheKey = generateCacheKey(for: request)
            if let cachedResponse = getCachedResponse(for: cacheKey) {
                return cachedResponse
            }
            
            // Use mock data for Epic C development
            if useMockData {
                return try await generateMockFeedResponse(request: request)
            }
            
            // Fetch events from database
            let events = try await fetchEvents(for: request)
            
            // Fetch user profile for scoring
            guard let userProfile = try await profileService.getProfile(for: request.userId) else {
                throw EventFeedError.invalidUserId
            }
            
            // Generate AI scores for each event
            let scoredItems = await generateScoredFeedItems(
                events: events,
                userProfile: userProfile,
                request: request
            )
            
            // Apply filtering and sorting
            let filteredItems = applyFiltersAndSorting(scoredItems, request: request)
            
            // Paginate results
            let paginatedItems = paginateResults(filteredItems, request: request)
            
            let response = EventFeedResponse(
                items: paginatedItems,
                totalCount: filteredItems.count,
                hasMore: hasMorePages(filteredItems.count, request: request),
                nextPage: getNextPage(filteredItems.count, request: request),
                requestId: UUID().uuidString,
                generatedAt: Date()
            )
            
            // Cache the response
            cacheResponse(response, for: cacheKey)
            
            return response
            
        } catch {
            errorMessage = "Failed to generate feed: \(error.localizedDescription)"
            throw EventFeedError.networkError(error.localizedDescription)
        }
    }
    
    // MARK: - Mock Data Generation for Epic C
    
    private func generateMockFeedResponse(request: EventFeedRequest) async throws -> EventFeedResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Generate mock feed items
        var mockItems = MockEventData.generateMockFeedItems()
        
        // Apply filters based on request
        mockItems = applyMockFilters(mockItems, request: request)
        
        // Apply sorting
        mockItems = applyMockSorting(mockItems, sortOption: request.sortOption)
        
        // Paginate results
        let paginatedItems = paginateResults(mockItems, request: request)
        
        return EventFeedResponse(
            items: paginatedItems,
            totalCount: mockItems.count,
            hasMore: hasMorePages(mockItems.count, request: request),
            nextPage: getNextPage(mockItems.count, request: request),
            requestId: UUID().uuidString,
            generatedAt: Date()
        )
    }
    
    private func applyMockFilters(_ items: [EventFeedItem], request: EventFeedRequest) -> [EventFeedItem] {
        var filteredItems = items
        
        // Apply vibe filtering
        if !request.filter.vibeFilters.isEmpty {
            filteredItems = filteredItems.filter { item in
                request.filter.vibeFilters.contains(item.event.vibe)
            }
        }
        
        // Apply price filtering
        let priceRange = request.filter.priceRange.range
        if let maxPrice = priceRange.max {
            if request.filter.freeOnly {
                filteredItems = filteredItems.filter { $0.event.price == 0 || $0.event.price == nil }
            } else {
                filteredItems = filteredItems.filter { ($0.event.price ?? 0) <= maxPrice }
            }
        }
        
        // Apply time filtering
        let timeRange = request.filter.timeRange.dateRange
        if let startDate = timeRange.start {
            filteredItems = filteredItems.filter { $0.event.date >= startDate }
        }
        if let endDate = timeRange.end {
            filteredItems = filteredItems.filter { $0.event.date <= endDate }
        }
        
        // Apply attendee range filtering
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
        
        return filteredItems
    }
    
    private func applyMockSorting(_ items: [EventFeedItem], sortOption: EventFeedSortOption) -> [EventFeedItem] {
        switch sortOption {
        case .relevance:
            return items.sorted { $0.score > $1.score }
        case .date:
            return items.sorted { $0.event.date < $1.event.date }
        case .distance:
            return items.sorted { ($0.distanceFromUser ?? Double.infinity) < ($1.distanceFromUser ?? Double.infinity) }
        case .price:
            return items.sorted { ($0.event.price ?? 0) < ($1.event.price ?? 0) }
        case .popularity:
            return items.sorted { $0.attendeeCount > $1.attendeeCount }
        }
    }
    
    // MARK: - Trending Events (Mock)
    
    func getTrendingEvents() async throws -> EventFeedResponse {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        let trendingItems = MockEventData.generateMockTrendingEvents()
        
        return EventFeedResponse(
            items: trendingItems,
            totalCount: trendingItems.count,
            hasMore: false,
            nextPage: nil,
            requestId: UUID().uuidString,
            generatedAt: Date()
        )
    }
    
    // MARK: - Private Events (Mock)
    
    func getPrivateEvents(for userId: UUID) async throws -> EventFeedResponse {
        isLoading = true
        defer { isLoading = false }
        
        // Simulate network delay
        try await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
        
        let privateItems = MockEventData.generateMockPrivateEvents()
        
        return EventFeedResponse(
            items: privateItems,
            totalCount: privateItems.count,
            hasMore: false,
            nextPage: nil,
            requestId: UUID().uuidString,
            generatedAt: Date()
        )
    }
    
    // MARK: - Event Fetching
    
    private func fetchEvents(for request: EventFeedRequest) async throws -> [(Event, EventHost)] {
        var query = supabase
            .from("events")
            .select("""
                *,
                hosts:host_id (
                    id,
                    name,
                    handle,
                    avatar,
                    vibe_tags,
                    is_verified
                )
            """)
            .eq("is_private", value: false) // Only public events for discovery
        
        // Apply time filtering
        let timeRange = request.filter.timeRange.dateRange
        if let startDate = timeRange.start {
            query = query.gte("date", value: startDate.ISO8601Format())
        }
        if let endDate = timeRange.end {
            query = query.lte("date", value: endDate.ISO8601Format())
        }
        
        // Apply price filtering
        let priceRange = request.filter.priceRange.range
        if let maxPrice = priceRange.max {
            if request.filter.freeOnly {
                query = query.or("price.is.null,price.eq.0")
            } else {
                query = query.lte("price", value: maxPrice)
            }
        }
        
        // Location filtering will be done in-memory for MVP
        // TODO: Implement PostGIS function for efficient location filtering
        
        // Apply vibe filtering
        if !request.filter.vibeFilters.isEmpty {
            let vibeArray = Array(request.filter.vibeFilters)
            query = query.in("vibe", values: vibeArray)
        }
        
        let response: [EventWithHost] = try await query.execute().value
        
        return response.compactMap { eventWithHost in
            guard let host = eventWithHost.host else { return nil }
            
            let event = Event(
                id: eventWithHost.id,
                hostId: eventWithHost.hostId,
                title: eventWithHost.title,
                description: eventWithHost.description,
                vibe: eventWithHost.vibe,
                date: eventWithHost.date,
                endDate: eventWithHost.endDate,
                location: eventWithHost.location,
                capacity: eventWithHost.capacity,
                price: eventWithHost.price,
                isPrivate: eventWithHost.isPrivate,
                mediaRefs: eventWithHost.mediaRefs,
                createdAt: eventWithHost.createdAt,
                updatedAt: eventWithHost.updatedAt
            )
            
            let eventHost = EventHost(
                id: host.id,
                name: host.name,
                handle: host.handle,
                avatarUrl: host.avatar,
                vibeTags: host.vibeTags,
                isVerified: host.isVerified
            )
            
            return (event, eventHost)
        }
    }
    
    // MARK: - AI Scoring System
    
    private func generateScoredFeedItems(
        events: [(Event, EventHost)],
        userProfile: ProfileData,
        request: EventFeedRequest
    ) async -> [EventFeedItem] {
        var feedItems: [EventFeedItem] = []
        
        for (event, host) in events {
            // Calculate AI score
            let score = await calculateAIScore(
                event: event,
                host: host,
                userProfile: userProfile,
                request: request
            )
            
            // Get attendee information
            let attendeeInfo = await getAttendeeInfo(eventId: event.id, userId: request.userId)
            
            // Calculate distance if user location is available
            let distance = request.userLocation?.distance(from: CLLocation(
                latitude: event.location.latitude,
                longitude: event.location.longitude
            ))
            
            let feedItem = EventFeedItem(
                id: event.id,
                event: event,
                host: host,
                score: score,
                attendeeCount: attendeeInfo.totalCount,
                friendsAttending: attendeeInfo.friendsAttending,
                isBookmarked: attendeeInfo.isBookmarked,
                distanceFromUser: distance
            )
            
            feedItems.append(feedItem)
        }
        
        return feedItems
    }
    
    private func calculateAIScore(
        event: Event,
        host: EventHost,
        userProfile: ProfileData,
        request: EventFeedRequest
    ) async -> Double {
        var totalScore = baseScore
        
        // 1. Vibe Tag Matching (40% weight)
        let vibeScore = calculateVibeMatchScore(
            eventVibe: event.vibe,
            hostVibeTags: host.vibeTags,
            userVibeTags: userProfile.vibeTags.map { $0.rawValue }
        )
        totalScore += vibeScore * vibeMatchWeight
        
        // 2. Location Relevance (30% weight)
        if let userLocation = request.userLocation {
            let locationScore = calculateLocationScore(
                eventLocation: event.location,
                userLocation: userLocation
            )
            totalScore += locationScore * locationWeight
        }
        
        // 3. Friend Network Influence (30% weight)
        let friendScore = await calculateFriendNetworkScore(
            eventId: event.id,
            friendIds: request.friendIds
        )
        totalScore += friendScore * friendNetworkWeight
        
        // Additional scoring factors
        totalScore += calculateTimeRelevanceScore(event: event) * 0.1
        totalScore += calculatePopularityScore(event: event) * 0.05
        totalScore += calculateHostReputationScore(host: host) * 0.05
        
        // Ensure score is between 0 and 1
        return min(max(totalScore, 0.0), 1.0)
    }
    
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
    
    private func calculateFriendNetworkScore(
        eventId: UUID,
        friendIds: [UUID]
    ) async -> Double {
        guard !friendIds.isEmpty else { return 0.0 }
        
        do {
            let attendeeResponse: [EventAttendeeResponse] = try await supabase
                .from("event_attendees")
                .select("user_id, status")
                .eq("event_id", value: eventId)
                .in("user_id", values: friendIds)
                .in("status", values: ["going", "maybe"])
                .execute()
                .value
            
            let friendsGoing = attendeeResponse.count
            
            // Each friend adds significant boost, with diminishing returns
            let baseBoost = 0.2 // 20% boost for first friend
            let additionalBoost = 0.1 // 10% boost for each additional friend
            
            if friendsGoing == 0 {
                return 0.0
            } else if friendsGoing == 1 {
                return baseBoost
            } else {
                return baseBoost + (Double(friendsGoing - 1) * additionalBoost)
            }
            
        } catch {
            print("Error calculating friend network score: \(error)")
            return 0.0
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
        // This would typically be based on attendee count, engagement, etc.
        // For MVP, we'll use a simple heuristic
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
        // This would typically be based on host history, ratings, etc.
        // For MVP, we'll use verification status and vibe tag count
        var score = 0.0
        
        if host.isVerified {
            score += 0.5
        }
        
        // More diverse vibe tags indicate experienced host
        score += min(Double(host.vibeTags.count) * 0.1, 0.5)
        
        return min(score, 1.0)
    }
    
    // MARK: - Attendee Information
    
    private func getAttendeeInfo(eventId: UUID, userId: UUID) async -> (totalCount: Int, friendsAttending: [EventAttendee], isBookmarked: Bool) {
        do {
            // Get total attendee count
            let attendeeResponse: [EventAttendeeResponse] = try await supabase
                .from("event_attendees")
                .select("*")
                .eq("event_id", value: eventId)
                .in("status", values: ["going", "maybe"])
                .execute()
                .value
            
            // Get bookmarked status
            let bookmarkResponse: [BookmarkResponse] = try await supabase
                .from("event_bookmarks")
                .select("id")
                .eq("event_id", value: eventId)
                .eq("user_id", value: userId)
                .execute()
                .value
            
            let isBookmarked = !bookmarkResponse.isEmpty
            
            // Convert to EventAttendee objects
            let attendees = attendeeResponse.compactMap { response in
                EventAttendee(
                    id: UUID(),
                    userId: response.userId,
                    name: response.userName ?? "Unknown",
                    handle: response.userHandle ?? "unknown",
                    avatarUrl: response.userAvatar,
                    status: EventAttendee.AttendanceStatus(rawValue: response.status) ?? .invited,
                    joinedAt: response.joinedAt
                )
            }
            
            return (attendees.count, attendees, isBookmarked)
            
        } catch {
            print("Error getting attendee info: \(error)")
            return (0, [], false)
        }
    }
    
    // MARK: - Filtering and Sorting
    
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
    
    // MARK: - Pagination
    
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
    
    private func getNextPage(_ totalCount: Int, request: EventFeedRequest) -> Int? {
        return hasMorePages(totalCount, request: request) ? request.page + 1 : nil
    }
    
    // MARK: - Cache Management
    
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
        guard let response = feedCache[key],
              let timestamp = cacheTimestamps[key],
              Date().timeIntervalSince(timestamp) < cacheExpirationTime else {
            return nil
        }
        return response
    }
    
    private func cacheResponse(_ response: EventFeedResponse, for key: String) {
        feedCache[key] = response
        cacheTimestamps[key] = Date()
        
        // Clean up old cache entries
        cleanupCache()
    }
    
    private func cleanupCache() {
        let now = Date()
        let expiredKeys = cacheTimestamps.compactMap { key, timestamp in
            now.timeIntervalSince(timestamp) > cacheExpirationTime ? key : nil
        }
        
        for key in expiredKeys {
            feedCache.removeValue(forKey: key)
            cacheTimestamps.removeValue(forKey: key)
        }
    }
    
    // MARK: - Public Interface Methods
    
    func refreshFeed(for request: EventFeedRequest) async throws -> EventFeedResponse {
        // Clear cache for this request
        let cacheKey = generateCacheKey(for: request)
        feedCache.removeValue(forKey: cacheKey)
        cacheTimestamps.removeValue(forKey: cacheKey)
        
        return try await generatePersonalizedFeed(request: request)
    }
    
    func loadMoreEvents(for request: EventFeedRequest) async throws -> EventFeedResponse {
        let nextPageRequest = EventFeedRequest(
            userId: request.userId,
            userLocation: request.userLocation,
            userVibeTags: request.userVibeTags,
            friendIds: request.friendIds,
            filter: request.filter,
            sortOption: request.sortOption,
            page: request.page + 1,
            pageSize: request.pageSize
        )
        
        return try await generatePersonalizedFeed(request: nextPageRequest)
    }
}

// MARK: - Response Models

private struct EventWithHost: Codable {
    let id: UUID
    let hostId: UUID
    let title: String
    let description: String
    let vibe: String
    let date: Date
    let endDate: Date?
    let location: EventLocation
    let capacity: Int?
    let price: Double?
    let isPrivate: Bool
    let mediaRefs: [String]
    let createdAt: Date
    let updatedAt: Date
    let host: HostResponse?
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, vibe, date, location, capacity, price, host
        case hostId = "host_id"
        case endDate = "end_date"
        case isPrivate = "is_private"
        case mediaRefs = "media_refs"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

private struct HostResponse: Codable {
    let id: UUID
    let name: String
    let handle: String
    let avatar: String?
    let vibeTags: [String]
    let isVerified: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, handle, avatar
        case vibeTags = "vibe_tags"
        case isVerified = "is_verified"
    }
}

private struct EventAttendeeResponse: Codable {
    let userId: UUID
    let status: String
    let joinedAt: Date
    let userName: String?
    let userHandle: String?
    let userAvatar: String?
    
    enum CodingKeys: String, CodingKey {
        case status
        case userId = "user_id"
        case joinedAt = "joined_at"
        case userName = "user_name"
        case userHandle = "user_handle"
        case userAvatar = "user_avatar"
    }
}

private struct BookmarkResponse: Codable {
    let id: UUID
} 