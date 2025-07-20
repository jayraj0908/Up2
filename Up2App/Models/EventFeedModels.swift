import Foundation
import SwiftUI
import CoreLocation

// MARK: - Core Event Models

struct Event: Identifiable, Codable, Equatable {
    let id: UUID
    let hostId: UUID
    let title: String
    let description: String
    let vibe: String // Event mood/theme
    let date: Date
    let endDate: Date?
    let location: EventLocation
    let capacity: Int?
    let price: Double? // nil for free events
    let isPrivate: Bool
    let mediaRefs: [String] // URLs or storage references
    let createdAt: Date
    let updatedAt: Date
    
    // Computed properties
    var isUpcoming: Bool {
        date > Date()
    }
    
    var isPast: Bool {
        date <= Date()
    }
    
    var isToday: Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }
    
    var isFree: Bool {
        price == nil || price == 0
    }
    
    var ticketPrice: Double {
        return price ?? 0.0
    }
    
    var formattedPrice: String {
        if isFree {
            return "Free"
        } else if let price = price {
            return String(format: "$%.2f", price)
        }
        return "Price TBD"
    }
    
    init(
        id: UUID = UUID(),
        hostId: UUID,
        title: String,
        description: String,
        vibe: String,
        date: Date,
        endDate: Date? = nil,
        location: EventLocation,
        capacity: Int? = nil,
        price: Double? = nil,
        isPrivate: Bool = false,
        mediaRefs: [String] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.hostId = hostId
        self.title = title
        self.description = description
        self.vibe = vibe
        self.date = date
        self.endDate = endDate
        self.location = location
        self.capacity = capacity
        self.price = price
        self.isPrivate = isPrivate
        self.mediaRefs = mediaRefs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Event Location

struct EventLocation: Codable, Equatable {
    let name: String
    let address: String
    let city: String
    let state: String?
    let country: String
    let zipCode: String?
    let latitude: Double
    let longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var shortAddress: String {
        "\(city), \(state ?? country)"
    }
    
    var fullAddress: String {
        var components = [address, city]
        if let state = state { components.append(state) }
        if let zipCode = zipCode { components.append(zipCode) }
        components.append(country)
        return components.joined(separator: ", ")
    }
    
    func distance(from location: CLLocation) -> CLLocationDistance {
        let eventLocation = CLLocation(latitude: latitude, longitude: longitude)
        return location.distance(from: eventLocation)
    }
}

// MARK: - Host Information

struct EventHost: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String
    let handle: String
    let avatarUrl: String?
    let vibeTags: [String]
    let isVerified: Bool
    
    var displayName: String {
        name.isEmpty ? "@\(handle)" : name
    }
}

// MARK: - Event Feed Item

struct EventFeedItem: Identifiable, Equatable {
    let id: UUID
    let event: Event
    let host: EventHost
    let score: Double // AI recommendation score
    let attendeeCount: Int
    let friendsAttending: [EventAttendee]
    let isBookmarked: Bool
    let distanceFromUser: Double? // in meters
    
    var relevanceScore: EventRelevanceScore {
        EventRelevanceScore(
            vibeMatch: min(score * 0.4, 0.4),
            locationRelevance: calculateLocationScore(),
            friendNetworkBoost: calculateFriendScore(),
            overallScore: score
        )
    }
    
    private func calculateLocationScore() -> Double {
        guard let distance = distanceFromUser else { return 0.0 }
        
        // Score decreases with distance
        // 100% for events within 5km, decreasing to 0% at 50km
        let maxDistance: Double = 50000 // 50km
        let optimalDistance: Double = 5000 // 5km
        
        if distance <= optimalDistance {
            return 0.3 // Max location score contribution
        } else if distance >= maxDistance {
            return 0.0
        } else {
            let normalizedDistance = (distance - optimalDistance) / (maxDistance - optimalDistance)
            return 0.3 * (1.0 - normalizedDistance)
        }
    }
    
    private func calculateFriendScore() -> Double {
        let friendCount = Double(friendsAttending.count)
        // Each friend adds 0.05 to score, max 0.3
        return min(friendCount * 0.05, 0.3)
    }
    
    static func == (lhs: EventFeedItem, rhs: EventFeedItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Event Attendee

struct EventAttendee: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let name: String
    let handle: String
    let avatarUrl: String?
    let status: AttendanceStatus
    let joinedAt: Date
    
    enum AttendanceStatus: String, CaseIterable, Codable {
        case going = "going"
        case maybe = "maybe"
        case notGoing = "not_going"
        case invited = "invited"
        
        var displayName: String {
            switch self {
            case .going: return "Going"
            case .maybe: return "Maybe"
            case .notGoing: return "Not Going"
            case .invited: return "Invited"
            }
        }
        
        var color: Color {
            switch self {
            case .going: return .green
            case .maybe: return .orange
            case .notGoing: return .red
            case .invited: return .blue
            }
        }
    }
}

// MARK: - Event Relevance Scoring

struct EventRelevanceScore {
    let vibeMatch: Double // 0.0 - 0.4
    let locationRelevance: Double // 0.0 - 0.3
    let friendNetworkBoost: Double // 0.0 - 0.3
    let overallScore: Double // 0.0 - 1.0
    
    var percentageScore: Int {
        Int(overallScore * 100)
    }
    
    var scoreDescription: String {
        switch overallScore {
        case 0.8...1.0: return "Perfect Match"
        case 0.6..<0.8: return "Great Match"
        case 0.4..<0.6: return "Good Match"
        case 0.2..<0.4: return "Fair Match"
        default: return "Low Match"
        }
    }
}

// MARK: - Feed Filter and Sorting

struct EventFeedFilter: Equatable {
    var timeRange: TimeRange
    var priceRange: PriceRange
    var vibeFilters: Set<String>
    var locationRadius: Double // in meters
    var attendeeRange: AttendeeRange
    var friendsOnly: Bool
    var freeOnly: Bool
    
    enum TimeRange: CaseIterable, Equatable {
        case today
        case thisWeek
        case thisMonth
        case upcoming
        case all
        
        var displayName: String {
            switch self {
            case .today: return "Today"
            case .thisWeek: return "This Week"
            case .thisMonth: return "This Month"
            case .upcoming: return "Upcoming"
            case .all: return "All Events"
            }
        }
        
        var dateRange: (start: Date?, end: Date?) {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .today:
                let startOfDay = calendar.startOfDay(for: now)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)
                return (startOfDay, endOfDay)
            case .thisWeek:
                let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start
                let endOfWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: startOfWeek ?? now)
                return (startOfWeek, endOfWeek)
            case .thisMonth:
                let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start
                let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth ?? now)
                return (startOfMonth, endOfMonth)
            case .upcoming:
                return (now, nil)
            case .all:
                return (nil, nil)
            }
        }
    }
    
    enum PriceRange: CaseIterable, Equatable {
        case free
        case under25
        case under50
        case under100
        case any
        
        var displayName: String {
            switch self {
            case .free: return "Free"
            case .under25: return "Under $25"
            case .under50: return "Under $50"
            case .under100: return "Under $100"
            case .any: return "Any Price"
            }
        }
        
        var range: (min: Double?, max: Double?) {
            switch self {
            case .free: return (0, 0)
            case .under25: return (0, 25)
            case .under50: return (0, 50)
            case .under100: return (0, 100)
            case .any: return (nil, nil)
            }
        }
    }
    
    enum AttendeeRange: CaseIterable, Equatable {
        case intimate // 1-20
        case small // 21-50
        case medium // 51-200
        case large // 201+
        case any
        
        var displayName: String {
            switch self {
            case .intimate: return "Intimate (1-20)"
            case .small: return "Small (21-50)"
            case .medium: return "Medium (51-200)"
            case .large: return "Large (201+)"
            case .any: return "Any Size"
            }
        }
        
        var range: (min: Int?, max: Int?) {
            switch self {
            case .intimate: return (1, 20)
            case .small: return (21, 50)
            case .medium: return (51, 200)
            case .large: return (201, nil)
            case .any: return (nil, nil)
            }
        }
    }
    
    static let `default` = EventFeedFilter(
        timeRange: .upcoming,
        priceRange: .any,
        vibeFilters: Set<String>(),
        locationRadius: 25000, // 25km default
        attendeeRange: .any,
        friendsOnly: false,
        freeOnly: false
    )
}

// MARK: - Feed Sort Options

enum EventFeedSortOption: CaseIterable {
    case relevance
    case date
    case distance
    case price
    case popularity
    
    var displayName: String {
        switch self {
        case .relevance: return "Relevance"
        case .date: return "Date"
        case .distance: return "Distance"
        case .price: return "Price"
        case .popularity: return "Popularity"
        }
    }
    
    var systemImage: String {
        switch self {
        case .relevance: return "heart.fill"
        case .date: return "calendar"
        case .distance: return "location"
        case .price: return "dollarsign.circle"
        case .popularity: return "person.3.fill"
        }
    }
}

// MARK: - Feed State

enum EventFeedState: Equatable {
    case idle
    case loading
    case loaded([EventFeedItem])
    case refreshing([EventFeedItem])
    case loadingMore([EventFeedItem])
    case error(String)
    case empty
    
    var isLoading: Bool {
        switch self {
        case .loading, .refreshing, .loadingMore:
            return true
        default:
            return false
        }
    }
    
    var items: [EventFeedItem] {
        switch self {
        case .loaded(let items), .refreshing(let items), .loadingMore(let items):
            return items
        default:
            return []
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .error(let message):
            return message
        default:
            return nil
        }
    }
}

// MARK: - Feed Request

struct EventFeedRequest {
    let userId: UUID
    let userLocation: CLLocation?
    let userVibeTags: [String]
    let friendIds: [UUID]
    let filter: EventFeedFilter
    let sortOption: EventFeedSortOption
    let page: Int
    let pageSize: Int
    
    init(
        userId: UUID,
        userLocation: CLLocation? = nil,
        userVibeTags: [String] = [],
        friendIds: [UUID] = [],
        filter: EventFeedFilter = .default,
        sortOption: EventFeedSortOption = .relevance,
        page: Int = 0,
        pageSize: Int = 20
    ) {
        self.userId = userId
        self.userLocation = userLocation
        self.userVibeTags = userVibeTags
        self.friendIds = friendIds
        self.filter = filter
        self.sortOption = sortOption
        self.page = page
        self.pageSize = pageSize
    }
}

// MARK: - Feed Response

struct EventFeedResponse {
    let items: [EventFeedItem]
    let totalCount: Int
    let hasMore: Bool
    let nextPage: Int?
    let requestId: String
    let generatedAt: Date
    
    var isEmpty: Bool {
        items.isEmpty
    }
}

// MARK: - Error Types

enum EventFeedError: LocalizedError {
    case invalidUserId
    case networkError(String)
    case noPermission
    case invalidFilter
    case locationNotAvailable
    case serviceUnavailable
    
    var errorDescription: String? {
        switch self {
        case .invalidUserId:
            return "Invalid user ID provided"
        case .networkError(let message):
            return "Network error: \(message)"
        case .noPermission:
            return "You don't have permission to access this feed"
        case .invalidFilter:
            return "Invalid filter parameters"
        case .locationNotAvailable:
            return "Location services not available"
        case .serviceUnavailable:
            return "Event discovery service is temporarily unavailable"
        }
    }
} 