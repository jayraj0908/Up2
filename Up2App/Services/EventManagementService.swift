import Foundation
import Supabase

@MainActor
class EventManagementService: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseManager.shared.client
    
    func createEvent(event: EventInputModel) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔄 Creating new event: \(event.title)")
            
            let session = try await supabase.auth.session
            let userId = session.user.id.uuidString
            let now = ISO8601DateFormatter().string(from: Date())
            let eventInsert = EventInsertModel(
                host_id: userId,
                title: event.title,
                description: event.description,
                image_url: event.imageUrl ?? "",
                tags: event.tags,
                location: event.location,
                start_time: ISO8601DateFormatter().string(from: event.startTime),
                end_time: ISO8601DateFormatter().string(from: event.endTime),
                is_public: event.isPublic,
                capacity: event.capacity ?? 0,
                price: event.price ?? 0.0,
                created_at: now,
                updated_at: now
            )
            
            try await supabase
                .from("events")
                .insert([eventInsert])
                .execute()
            
            print("✅ Event created successfully")
            
        } catch {
            print("❌ Failed to create event: \(error)")
            errorMessage = "Failed to create event: \(error.localizedDescription)"
            throw error
        }
        
        isLoading = false
    }
    
    func updateEvent(eventId: UUID, event: EventInputModel) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔄 Updating event: \(event.title)")
            
            let session = try await supabase.auth.session
            let userId = session.user.id.uuidString
            let now = ISO8601DateFormatter().string(from: Date())
            let eventUpdate = EventInsertModel(
                host_id: userId,
                title: event.title,
                description: event.description,
                image_url: event.imageUrl ?? "",
                tags: event.tags,
                location: event.location,
                start_time: ISO8601DateFormatter().string(from: event.startTime),
                end_time: ISO8601DateFormatter().string(from: event.endTime),
                is_public: event.isPublic,
                capacity: event.capacity ?? 0,
                price: event.price ?? 0.0,
                created_at: nil,
                updated_at: now
            )
            
            try await supabase
                .from("events")
                .update(eventUpdate)
                .eq("id", value: eventId.uuidString)
                .execute()
            
            print("✅ Event updated successfully")
            
        } catch {
            print("❌ Failed to update event: \(error)")
            errorMessage = "Failed to update event: \(error.localizedDescription)"
            throw error
        }
        
        isLoading = false
    }
    
    func deleteEvent(eventId: UUID) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔄 Deleting event: \(eventId)")
            
            try await supabase
                .from("events")
                .delete()
                .eq("id", value: eventId.uuidString)
                .execute()
            
            print("✅ Event deleted successfully")
            
        } catch {
            print("❌ Failed to delete event: \(error)")
            errorMessage = "Failed to delete event: \(error.localizedDescription)"
            throw error
        }
        
        isLoading = false
    }
    
    func getEvent(eventId: UUID) async throws -> Event? {
        do {
            let response: [EventResponse] = try await supabase
                .from("events")
                .select("*")
                .eq("id", value: eventId.uuidString)
                .execute()
                .value
            
            guard let eventResponse = response.first else {
                return nil
            }
            
            return convertToEvent(eventResponse)
            
        } catch {
            print("❌ Failed to fetch event: \(error)")
            throw error
        }
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
            tags: response.tags ?? [],
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

// MARK: - Event Input Model
struct EventInputModel {
    let title: String
    let description: String
    let imageUrl: String?
    let tags: [String]
    let location: String
    let startTime: Date
    let endTime: Date
    let isPublic: Bool
    let capacity: Int?
    let price: Double?
}

// MARK: - Event Response Model
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
}

// MARK: - Event Management Error
enum EventManagementError: Error, LocalizedError {
    case userNotAuthenticated
    case eventNotFound
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .eventNotFound:
            return "Event not found"
        case .unauthorized:
            return "Unauthorized to perform this action"
        }
    }
} 

struct EventInsertModel: Encodable {
    let host_id: String
    let title: String
    let description: String
    let image_url: String
    let tags: [String]
    let location: String
    let start_time: String
    let end_time: String
    let is_public: Bool
    let capacity: Int
    let price: Double
    let created_at: String?
    let updated_at: String?
} 