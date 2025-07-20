import Foundation
import SwiftUI

// MARK: - Event Type Definitions

enum EventType: String, CaseIterable, Codable {
    case profileCreated = "profile_created"
    case profileUpdated = "profile_updated" 
    case avatarUploaded = "avatar_uploaded"
    case vibeTagsUpdated = "vibe_tags_updated"
    case bioUpdated = "bio_updated"
    case profileViewed = "profile_viewed"
    case userAuthenticated = "user_authenticated"
    case settingsChanged = "settings_changed"
    
    var displayName: String {
        switch self {
        case .profileCreated: return "Profile Created"
        case .profileUpdated: return "Profile Updated"
        case .avatarUploaded: return "Avatar Uploaded"
        case .vibeTagsUpdated: return "Vibe Tags Updated"
        case .bioUpdated: return "Bio Updated"
        case .profileViewed: return "Profile Viewed"
        case .userAuthenticated: return "User Authenticated"
        case .settingsChanged: return "Settings Changed"
        }
    }
    
    var icon: String {
        switch self {
        case .profileCreated: return "person.badge.plus"
        case .profileUpdated: return "person.badge.clock"
        case .avatarUploaded: return "photo.circle"
        case .vibeTagsUpdated: return "tag.circle"
        case .bioUpdated: return "text.quote"
        case .profileViewed: return "eye.circle"
        case .userAuthenticated: return "lock.shield"
        case .settingsChanged: return "gearshape"
        }
    }
    
    var category: EventCategory {
        switch self {
        case .profileCreated, .profileUpdated, .avatarUploaded, .vibeTagsUpdated, .bioUpdated:
            return .profile
        case .profileViewed:
            return .social
        case .userAuthenticated:
            return .authentication
        case .settingsChanged:
            return .system
        }
    }
}

enum EventCategory: String, CaseIterable, Codable {
    case profile = "profile"
    case social = "social"
    case authentication = "authentication"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .profile: return "Profile"
        case .social: return "Social"
        case .authentication: return "Authentication"
        case .system: return "System"
        }
    }
    
    var color: Color {
        switch self {
        case .profile: return .blue
        case .social: return .green
        case .authentication: return .orange
        case .system: return .purple
        }
    }
}

// MARK: - Event Data Models

struct UserEvent: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let eventType: EventType
    let eventData: [String: String]? // JSON-serializable additional data
    let createdAt: Date
    let metadata: EventMetadata?
    
    init(id: UUID = UUID(), userId: UUID, eventType: EventType, eventData: [String: String]? = nil, metadata: EventMetadata? = nil) {
        self.id = id
        self.userId = userId
        self.eventType = eventType
        self.eventData = eventData
        self.createdAt = Date()
        self.metadata = metadata
    }
    
    // Computed properties
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}

struct EventMetadata: Codable {
    let source: String? // "mobile_app", "web", etc.
    let version: String? // App version when event occurred
    let platform: String? // iOS, Android, etc.
    let deviceModel: String?
    let ipAddress: String? // For security events
    let userAgent: String?
    
    init(source: String? = "mobile_app", 
         version: String? = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
         platform: String? = "iOS",
         deviceModel: String? = nil) {
        self.source = source
        self.version = version
        self.platform = platform
        self.deviceModel = deviceModel
        self.ipAddress = nil
        self.userAgent = nil
    }
}

// MARK: - Event Analytics Models

struct EventAnalytics: Codable {
    let totalEvents: Int
    let eventsByType: [EventType: Int]
    let eventsByCategory: [EventCategory: Int]
    let recentActivity: [UserEvent]
    let dailyActivity: [Date: Int]
    let weeklyActivity: [Date: Int]
    let monthlyActivity: [Date: Int]
    
    init(events: [UserEvent]) {
        self.totalEvents = events.count
        
        // Group by type
        var typeCounter: [EventType: Int] = [:]
        for event in events {
            typeCounter[event.eventType, default: 0] += 1
        }
        self.eventsByType = typeCounter
        
        // Group by category
        var categoryCounter: [EventCategory: Int] = [:]
        for event in events {
            categoryCounter[event.eventType.category, default: 0] += 1
        }
        self.eventsByCategory = categoryCounter
        
        // Recent activity (last 10 events)
        self.recentActivity = Array(events.sorted { $0.createdAt > $1.createdAt }.prefix(10))
        
        // Daily activity (last 30 days)
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentEvents = events.filter { $0.createdAt >= thirtyDaysAgo }
        
        var dailyCounter: [Date: Int] = [:]
        for event in recentEvents {
            let day = calendar.startOfDay(for: event.createdAt)
            dailyCounter[day, default: 0] += 1
        }
        self.dailyActivity = dailyCounter
        
        // Weekly activity (last 12 weeks)
        let twelveWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -12, to: Date()) ?? Date()
        let weeklyEvents = events.filter { $0.createdAt >= twelveWeeksAgo }
        
        var weeklyCounter: [Date: Int] = [:]
        for event in weeklyEvents {
            let week = calendar.dateInterval(of: .weekOfYear, for: event.createdAt)?.start ?? event.createdAt
            weeklyCounter[week, default: 0] += 1
        }
        self.weeklyActivity = weeklyCounter
        
        // Monthly activity (last 12 months)
        let twelveMonthsAgo = calendar.date(byAdding: .month, value: -12, to: Date()) ?? Date()
        let monthlyEvents = events.filter { $0.createdAt >= twelveMonthsAgo }
        
        var monthlyCounter: [Date: Int] = [:]
        for event in monthlyEvents {
            let month = calendar.dateInterval(of: .month, for: event.createdAt)?.start ?? event.createdAt
            monthlyCounter[month, default: 0] += 1
        }
        self.monthlyActivity = monthlyCounter
    }
}

// MARK: - Event Display Models

struct EventGroup {
    let date: Date
    let events: [UserEvent]
    let displayDate: String
    
    init(date: Date, events: [UserEvent]) {
        self.date = date
        self.events = events
        
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            self.displayDate = "Today"
        } else if calendar.isDateInYesterday(date) {
            self.displayDate = "Yesterday"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            self.displayDate = formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            self.displayDate = formatter.string(from: date)
        }
    }
}

// MARK: - Profile-Specific Event Helpers

extension UserEvent {
    static func profileCreated(userId: UUID, profileData: ProfileData) -> UserEvent {
        let eventData: [String: String] = [
            "profile_name": profileData.name,
            "profile_handle": profileData.handle,
            "vibe_tags_count": String(profileData.vibeTags.count),
            "has_avatar": String(profileData.avatar != nil),
            "has_bio": String(!profileData.bio.isEmpty)
        ]
        
        return UserEvent(
            userId: userId,
            eventType: .profileCreated,
            eventData: eventData,
            metadata: EventMetadata()
        )
    }
    
    static func profileUpdated(userId: UUID, changes: [String: Any]) -> UserEvent {
        let eventData = changes.compactMapValues { value -> String? in
            if let stringValue = value as? String {
                return stringValue
            } else if let boolValue = value as? Bool {
                return String(boolValue)
            } else if let intValue = value as? Int {
                return String(intValue)
            } else {
                return String(describing: value)
            }
        }
        
        return UserEvent(
            userId: userId,
            eventType: .profileUpdated,
            eventData: eventData,
            metadata: EventMetadata()
        )
    }
    
    static func avatarUploaded(userId: UUID, avatarURL: String) -> UserEvent {
        let eventData: [String: String] = [
            "avatar_url": avatarURL,
            "upload_timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        return UserEvent(
            userId: userId,
            eventType: .avatarUploaded,
            eventData: eventData,
            metadata: EventMetadata()
        )
    }
    
    static func vibeTagsUpdated(userId: UUID, oldTags: [VibeTag], newTags: [VibeTag]) -> UserEvent {
        let eventData: [String: String] = [
            "old_tags": oldTags.map(\.rawValue).joined(separator: ","),
            "new_tags": newTags.map(\.rawValue).joined(separator: ","),
            "tags_added": String(newTags.count - oldTags.count),
            "total_tags": String(newTags.count)
        ]
        
        return UserEvent(
            userId: userId,
            eventType: .vibeTagsUpdated,
            eventData: eventData,
            metadata: EventMetadata()
        )
    }
    
    static func bioUpdated(userId: UUID, oldBio: String, newBio: String) -> UserEvent {
        let eventData: [String: String] = [
            "old_bio_length": String(oldBio.count),
            "new_bio_length": String(newBio.count),
            "bio_changed": String(oldBio != newBio)
        ]
        
        return UserEvent(
            userId: userId,
            eventType: .bioUpdated,
            eventData: eventData,
            metadata: EventMetadata()
        )
    }
    
    static func userAuthenticated(userId: UUID, method: String) -> UserEvent {
        let eventData: [String: String] = [
            "auth_method": method,
            "login_timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        return UserEvent(
            userId: userId,
            eventType: .userAuthenticated,
            eventData: eventData,
            metadata: EventMetadata()
        )
    }
}

// MARK: - Event Validation

extension UserEvent {
    var isValid: Bool {
        return !userId.uuidString.isEmpty && createdAt <= Date()
    }
    
    func validate() throws {
        guard isValid else {
            throw EventValidationError.invalidEventData("Invalid event data")
        }
    }
}

enum EventValidationError: LocalizedError {
    case invalidEventData(String)
    case invalidUserId
    case invalidEventType
    case eventTooOld
    case eventInFuture
    
    var errorDescription: String? {
        switch self {
        case .invalidEventData(let message):
            return "Invalid event data: \(message)"
        case .invalidUserId:
            return "Invalid user ID provided"
        case .invalidEventType:
            return "Invalid event type"
        case .eventTooOld:
            return "Event is too old to process"
        case .eventInFuture:
            return "Event cannot be in the future"
        }
    }
} 