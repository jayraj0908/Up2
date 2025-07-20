import Foundation
import Supabase

@MainActor
class EventService: ObservableObject {
    static let shared = EventService()
    
    private let authService = SupabaseAuthService.shared
    private var supabase: SupabaseClient { authService.supabaseClient }
    
    @Published var isLoading = false
    @Published var events: [UserEvent] = []
    @Published var analytics: EventAnalytics?
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Event Tracking
    
    func trackEvent(_ event: UserEvent) async {
        do {
            try event.validate()
            
            // Store event in Supabase
            try await storeEvent(event)
            
            // Update local events array
            events.append(event)
            
            // Update analytics
            updateAnalytics()
            
        } catch {
            print("Failed to track event: \(error)")
            errorMessage = "Failed to track event: \(error.localizedDescription)"
        }
    }
    
    func trackEvent(
        userId: UUID,
        eventType: EventType,
        eventData: [String: String]? = nil,
        metadata: EventMetadata? = nil
    ) async {
        let event = UserEvent(
            userId: userId,
            eventType: eventType,
            eventData: eventData,
            metadata: metadata ?? EventMetadata()
        )
        
        await trackEvent(event)
    }
    
    // MARK: - Event Storage
    
    private func storeEvent(_ event: UserEvent) async throws {
        let eventRecord = EventRecord(
            id: event.id.uuidString,
            userId: event.userId.uuidString,
            eventType: event.eventType.rawValue,
            eventData: event.eventData,
            createdAt: ISO8601DateFormatter().string(from: event.createdAt),
            metadata: encodeEventMetadata(event.metadata)
        )
        
        try await supabase
            .from("user_events")
            .insert(eventRecord)
            .execute()
    }
    
    private func encodeEventMetadata(_ metadata: EventMetadata?) -> [String: String] {
        guard let metadata = metadata else { return [:] }
        
        return [
            "source": metadata.source ?? "unknown",
            "version": metadata.version ?? "unknown",
            "platform": metadata.platform ?? "unknown",
            "device_model": metadata.deviceModel ?? "unknown"
        ]
    }
    
    // MARK: - Event Retrieval
    
    func loadEvents(for userId: UUID, limit: Int = 100) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: [EventResponse] = try await supabase
                .from("user_events")
                .select("*")
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            events = response.compactMap { convertToUserEvent($0) }
            updateAnalytics()
            
        } catch {
            errorMessage = "Failed to load events: \(error.localizedDescription)"
            throw EventError.loadFailed(error.localizedDescription)
        }
        
        isLoading = false
    }
    
    func loadEventsByType(_ eventType: EventType, for userId: UUID, limit: Int = 50) async throws -> [UserEvent] {
        do {
            let response: [EventResponse] = try await supabase
                .from("user_events")
                .select("*")
                .eq("user_id", value: userId.uuidString)
                .eq("event_type", value: eventType.rawValue)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            return response.compactMap { convertToUserEvent($0) }
            
        } catch {
            throw EventError.loadFailed("Failed to load events by type: \(error.localizedDescription)")
        }
    }
    
    func loadEventsByCategory(_ category: EventCategory, for userId: UUID, limit: Int = 50) async throws -> [UserEvent] {
        let categoryTypes = EventType.allCases.filter { $0.category == category }
        let typeValues = categoryTypes.map { $0.rawValue }
        
        do {
            let response: [EventResponse] = try await supabase
                .from("user_events")
                .select("*")
                .eq("user_id", value: userId.uuidString)
                .in("event_type", values: typeValues)
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            return response.compactMap { convertToUserEvent($0) }
            
        } catch {
            throw EventError.loadFailed("Failed to load events by category: \(error.localizedDescription)")
        }
    }
    
    func loadRecentEvents(for userId: UUID, days: Int = 7) async throws -> [UserEvent] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let startDateString = ISO8601DateFormatter().string(from: startDate)
        
        do {
            let response: [EventResponse] = try await supabase
                .from("user_events")
                .select("*")
                .eq("user_id", value: userId.uuidString)
                .gte("created_at", value: startDateString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response.compactMap { convertToUserEvent($0) }
            
        } catch {
            throw EventError.loadFailed("Failed to load recent events: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Analytics
    
    private func updateAnalytics() {
        analytics = EventAnalytics(events: events)
    }
    
    func generateAnalytics(for userId: UUID) async throws -> EventAnalytics {
        try await loadEvents(for: userId)
        return EventAnalytics(events: events)
    }
    
    func getEventStats(for userId: UUID) async throws -> EventStats {
        let totalEvents = events.count
        let profileEvents = events.filter { $0.eventType.category == .profile }.count
        let socialEvents = events.filter { $0.eventType.category == .social }.count
        let authEvents = events.filter { $0.eventType.category == .authentication }.count
        
        let lastEventDate = events.first?.createdAt
        let firstEventDate = events.last?.createdAt
        
        return EventStats(
            totalEvents: totalEvents,
            profileEvents: profileEvents,
            socialEvents: socialEvents,
            authenticationEvents: authEvents,
            lastEventDate: lastEventDate,
            firstEventDate: firstEventDate
        )
    }
    
    // MARK: - Event Groups for UI
    
    func groupEventsByDate(_ events: [UserEvent]) -> [EventGroup] {
        let calendar = Calendar.current
        let groupedEvents = Dictionary(grouping: events) { event in
            calendar.startOfDay(for: event.createdAt)
        }
        
        return groupedEvents.map { date, events in
            EventGroup(date: date, events: events.sorted { $0.createdAt > $1.createdAt })
        }.sorted { $0.date > $1.date }
    }
    
    // MARK: - Profile Event Tracking Helpers
    
    func trackProfileCreation(_ profileData: ProfileData, userId: UUID) async {
        let event = UserEvent.profileCreated(userId: userId, profileData: profileData)
        await trackEvent(event)
    }
    
    func trackProfileUpdate(userId: UUID, changes: [String: Any]) async {
        let event = UserEvent.profileUpdated(userId: userId, changes: changes)
        await trackEvent(event)
    }
    
    func trackAvatarUpload(userId: UUID, avatarURL: String) async {
        let event = UserEvent.avatarUploaded(userId: userId, avatarURL: avatarURL)
        await trackEvent(event)
    }
    
    func trackVibeTagsUpdate(userId: UUID, oldTags: [VibeTag], newTags: [VibeTag]) async {
        let event = UserEvent.vibeTagsUpdated(userId: userId, oldTags: oldTags, newTags: newTags)
        await trackEvent(event)
    }
    
    func trackBioUpdate(userId: UUID, oldBio: String, newBio: String) async {
        let event = UserEvent.bioUpdated(userId: userId, oldBio: oldBio, newBio: newBio)
        await trackEvent(event)
    }
    
    func trackUserAuthentication(userId: UUID, method: String) async {
        let event = UserEvent.userAuthenticated(userId: userId, method: method)
        await trackEvent(event)
    }
    
    // MARK: - Utility Methods
    
    private func convertToUserEvent(_ response: EventResponse) -> UserEvent? {
        guard let id = UUID(uuidString: response.id),
              let userId = UUID(uuidString: response.userId),
              let eventType = EventType(rawValue: response.eventType),
              let createdAt = ISO8601DateFormatter().date(from: response.createdAt) else {
            return nil
        }
        
        let metadata = convertToEventMetadata(response.metadata)
        
        return UserEvent(
            id: id,
            userId: userId,
            eventType: eventType,
            eventData: response.eventData,
            metadata: metadata
        )
    }
    
    private func convertToEventMetadata(_ metadataDict: [String: String]?) -> EventMetadata? {
        guard let dict = metadataDict else { return nil }
        
        return EventMetadata(
            source: dict["source"],
            version: dict["version"],
            platform: dict["platform"],
            deviceModel: dict["device_model"]
        )
    }
    
    func clearLocalCache() {
        events.removeAll()
        analytics = nil
        errorMessage = nil
    }
}

// MARK: - Response Models

struct EventRecord: Codable {
    let id: String
    let userId: String
    let eventType: String
    let eventData: [String: String]?
    let createdAt: String
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case eventType = "event_type"
        case eventData = "event_data"
        case createdAt = "created_at"
        case metadata
    }
}

struct EventResponse: Codable {
    let id: String
    let userId: String
    let eventType: String
    let eventData: [String: String]?
    let createdAt: String
    let metadata: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case eventType = "event_type"
        case eventData = "event_data"
        case createdAt = "created_at"
        case metadata
    }
}

// MARK: - Analytics Models

struct EventStats {
    let totalEvents: Int
    let profileEvents: Int
    let socialEvents: Int
    let authenticationEvents: Int
    let lastEventDate: Date?
    let firstEventDate: Date?
    
    var mostActiveCategory: EventCategory? {
        let categoryScores = [
            (EventCategory.profile, profileEvents),
            (EventCategory.social, socialEvents),
            (EventCategory.authentication, authenticationEvents)
        ]
        
        return categoryScores.max(by: { $0.1 < $1.1 })?.0
    }
    
    var averageEventsPerDay: Double {
        guard let firstDate = firstEventDate,
              let lastDate = lastEventDate else { return 0 }
        
        let daysBetween = Calendar.current.dateComponents([.day], from: firstDate, to: lastDate).day ?? 1
        return Double(totalEvents) / Double(max(daysBetween, 1))
    }
}

// MARK: - Error Types

enum EventError: LocalizedError {
    case trackingFailed(String)
    case loadFailed(String)
    case invalidEventData(String)
    case storageError(String)
    
    var errorDescription: String? {
        switch self {
        case .trackingFailed(let message):
            return "Event tracking failed: \(message)"
        case .loadFailed(let message):
            return "Failed to load events: \(message)"
        case .invalidEventData(let message):
            return "Invalid event data: \(message)"
        case .storageError(let message):
            return "Storage error: \(message)"
        }
    }
} 