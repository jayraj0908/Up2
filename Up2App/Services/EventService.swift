import Foundation
import Supabase

@MainActor
class EventService: ObservableObject {
    static let shared = EventService()
    
    private let authService = SupabaseAuthService.shared
    private var supabase: SupabaseClient { authService.supabase }
    
    @Published var isLoading = false
    @Published var events: [Event] = []
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Event Creation
    
    func createEvent(_ request: EventCreationRequest) async throws -> Event {
        guard let currentUser = authService.currentUser else {
            throw EventError.userNotAuthenticated
        }
        
        let event = Event(
            hostId: UUID(uuidString: currentUser.id) ?? UUID(),
            title: request.title,
            description: request.description,
            imageUrl: request.imageUrl,
            tags: request.tags,
            location: request.location,
            startTime: request.startTime,
            endTime: request.endTime,
            isPublic: request.isPublic,
            capacity: request.capacity,
            price: request.price
        )
        
        let eventRecord = EventRecord(
            id: event.id.uuidString,
            hostId: event.hostId.uuidString,
            title: event.title,
            description: event.description,
            imageUrl: event.imageUrl,
            tags: event.tags,
            location: event.location,
            startTime: ISO8601DateFormatter().string(from: event.startTime),
            endTime: ISO8601DateFormatter().string(from: event.endTime),
            isPublic: event.isPublic,
            capacity: event.capacity,
            price: event.price,
            createdAt: ISO8601DateFormatter().string(from: event.createdAt),
            updatedAt: ISO8601DateFormatter().string(from: event.updatedAt)
        )
        
        try await supabase
            .from("events")
            .insert(eventRecord)
            .execute()
        
        return event
    }
    
    // MARK: - Sample Event Creation (for testing)
    
    func createSampleEvents() async throws {
        guard let currentUser = authService.currentUser else {
            throw EventError.userNotAuthenticated
        }
        
        let now = Date()
        let userId = UUID(uuidString: currentUser.id) ?? UUID()
        
        let sampleEvents = [
            EventCreationRequest(
                hostId: userId,
                title: "Weekend Beach Party",
                description: "Join us for an amazing beach party with live music, food, and drinks!",
                imageUrl: nil,
                tags: ["Beach", "Music", "Party"],
                location: "Santa Monica Beach",
                startTime: now.addingTimeInterval(86400), // Tomorrow
                endTime: now.addingTimeInterval(90000),
                isPublic: true,
                capacity: 100,
                price: 25.0
            ),
            EventCreationRequest(
                hostId: userId,
                title: "Tech Meetup LA",
                description: "Network with fellow developers and tech enthusiasts in Los Angeles!",
                imageUrl: nil,
                tags: ["Tech", "Networking", "Professional"],
                location: "Downtown LA",
                startTime: now.addingTimeInterval(172800), // Day after tomorrow
                endTime: now.addingTimeInterval(176400),
                isPublic: true,
                capacity: 50,
                price: 15.0
            ),
            EventCreationRequest(
                hostId: userId,
                title: "Sunset Yoga Session",
                description: "Relaxing yoga session with beautiful sunset views",
                imageUrl: nil,
                tags: ["Yoga", "Wellness", "Sunset"],
                location: "Griffith Observatory",
                startTime: now.addingTimeInterval(259200), // 3 days from now
                endTime: now.addingTimeInterval(262800),
                isPublic: true,
                capacity: 30,
                price: 20.0
            )
        ]
        
        for eventRequest in sampleEvents {
            do {
                let event = try await createEvent(eventRequest)
                print("✅ Created sample event: \(event.title)")
            } catch {
                print("❌ Failed to create sample event: \(error)")
            }
        }
    }
    
    // MARK: - Event Fetching
    
    func fetchEventsForHost() async throws -> [Event] {
        guard let currentUser = authService.currentUser else {
            throw EventError.userNotAuthenticated
        }
        
        let hostId = currentUser.id
        
            let response: [EventResponse] = try await supabase
            .from("events")
                .select("*")
            .eq("host_id", value: hostId)
            .order("start_time", ascending: true)
                .execute()
                .value
            
        return response.compactMap { convertToEvent($0) }
    }
    
    func fetchPublicEvents(location: String? = nil) async throws -> [Event] {
        do {
            print("🔄 Fetching public events from Supabase...")
            
            let response: [EventResponse]
            
            if let location = location {
                response = try await supabase
                    .from("events")
                    .select("*")
                    .eq("is_public", value: true)
                    .eq("location", value: location)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            } else {
                response = try await supabase
                    .from("events")
                    .select("*")
                    .eq("is_public", value: true)
                    .order("created_at", ascending: false)
                    .execute()
                    .value
            }
            
            print("📅 Raw response count: \(response.count)")
            
            let events = response.compactMap { eventResponse -> Event? in
                let event = convertToEvent(eventResponse)
                if event == nil {
                    print("⚠️ Failed to convert event: \(eventResponse.title)")
                }
                return event
            }
            
            print("✅ Successfully converted \(events.count) events")
            return events
            
        } catch {
            print("❌ Error fetching events: \(error)")
            print("🔍 Error details: \(error.localizedDescription)")
            
            // Check if it's a decoding error
            if error.localizedDescription.contains("data couldn't be read") {
                print("🔍 This appears to be a decoding error. Checking response structure...")
                throw EventError.databaseError
            }
            
            throw error
        }
    }
    
    func fetchEvent(by id: UUID) async throws -> Event? {
            let response: [EventResponse] = try await supabase
            .from("events")
                .select("*")
            .eq("id", value: id.uuidString)
            .limit(1)
                .execute()
                .value
            
        return response.first.flatMap { convertToEvent($0) }
    }
    
    // MARK: - Event Updates
    
    func updateEvent(_ id: UUID, with request: EventUpdateRequest) async throws -> Event {
        var updateData = EventUpdateData()
        
        if let title = request.title { updateData.title = title }
        if let description = request.description { updateData.description = description }
        if let imageUrl = request.imageUrl { updateData.imageUrl = imageUrl }
        if let tags = request.tags { updateData.tags = tags }
        if let location = request.location { updateData.location = location }
        if let startTime = request.startTime { updateData.startTime = ISO8601DateFormatter().string(from: startTime) }
        if let endTime = request.endTime { updateData.endTime = ISO8601DateFormatter().string(from: endTime) }
        if let isPublic = request.isPublic { updateData.isPublic = isPublic }
        if let capacity = request.capacity { updateData.capacity = capacity }
        if let price = request.price { updateData.price = price }
        
        updateData.updatedAt = ISO8601DateFormatter().string(from: Date())
        
        try await supabase
            .from("events")
            .update(updateData)
            .eq("id", value: id.uuidString)
            .execute()
        
        return try await fetchEvent(by: id) ?? Event(
            hostId: UUID(),
            title: "",
            description: "",
            location: "",
            startTime: Date(),
            endTime: Date()
        )
    }
    
    func deleteEvent(_ id: UUID) async throws {
        try await supabase
            .from("events")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    // MARK: - Helper Methods
    
    private func convertToEvent(_ response: EventResponse) -> Event? {
        guard let id = UUID(uuidString: response.id),
              let hostId = UUID(uuidString: response.hostId),
              let startTime = ISO8601DateFormatter().date(from: response.startTime),
              let endTime = ISO8601DateFormatter().date(from: response.endTime),
              let createdAt = ISO8601DateFormatter().date(from: response.createdAt),
              let updatedAt = ISO8601DateFormatter().date(from: response.updatedAt) else {
            return nil
        }
        
        return Event(
            id: id,
            hostId: hostId,
            title: response.title,
            description: response.description,
            imageUrl: response.imageUrl,
            tags: response.tags ?? [], // Handle null tags
            location: response.location,
            startTime: startTime,
            endTime: endTime,
            isPublic: response.isPublic,
            capacity: response.capacity,
            price: response.price,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Database Models

private struct EventUpdateData: Codable {
    var title: String?
    var description: String?
    var imageUrl: String?
    var tags: [String]?
    var location: String?
    var startTime: String?
    var endTime: String?
    var isPublic: Bool?
    var capacity: Int?
    var price: Double?
    var updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case title, description, tags, location, capacity, price
        case imageUrl = "image_url"
        case startTime = "start_time"
        case endTime = "end_time"
        case isPublic = "is_public"
        case updatedAt = "updated_at"
    }
}

private struct EventRecord: Codable {
    let id: String
    let hostId: String
    let title: String
    let description: String
    let imageUrl: String?
    let tags: [String]
    let location: String
    let startTime: String
    let endTime: String
    let isPublic: Bool
    let capacity: Int?
    let price: Double?
    let createdAt: String
    let updatedAt: String
}

private struct EventResponse: Codable {
    let id: String
    let hostId: String
    let title: String
    let description: String
    let imageUrl: String?
    let tags: [String]?
    let location: String
    let startTime: String
    let endTime: String
    let isPublic: Bool
    let capacity: Int?
    let price: Double?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case hostId = "host_id"
        case title
        case description
        case imageUrl = "image_url"
        case tags
        case location
        case startTime = "start_time"
        case endTime = "end_time"
        case isPublic = "is_public"
        case capacity
        case price
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Event Errors

enum EventError: LocalizedError {
    case userNotAuthenticated
    case eventNotFound
    case invalidEventData
    case networkError
    case databaseError
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User must be authenticated to perform this action"
        case .eventNotFound:
            return "Event not found"
        case .invalidEventData:
            return "Invalid event data provided"
        case .networkError:
            return "Network error occurred"
        case .databaseError:
            return "Database error occurred"
        }
    }
} 