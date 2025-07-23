import Foundation
import Supabase

@MainActor
class FeedCacheService: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseManager.shared.client
    
    func loadFeed() async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔄 Loading live feed from Supabase...")
            
            let response: [EventResponse] = try await supabase
                .from("events")
                .select("*")
                .eq("is_public", value: true)
                .eq("location", value: "Los Angeles")
                .gte("start_time", value: ISO8601DateFormatter().string(from: Date()))
                .order("start_time", ascending: true)
                .execute()
                .value
            
            print("📅 Fetched \(response.count) events from Supabase")
            
            // Convert EventResponse to Event models
            let convertedEvents = response.compactMap { eventResponse -> Event? in
                guard let event = convertToEvent(eventResponse) else {
                    print("⚠️ Failed to convert event: \(eventResponse.id)")
                    return nil
                }
                return event
            }
            
            events = convertedEvents
            print("✅ Feed loaded successfully with \(events.count) events")
            
        } catch {
            print("❌ Failed to load feed: \(error)")
            errorMessage = "Failed to load events: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshFeed() async {
        await loadFeed()
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