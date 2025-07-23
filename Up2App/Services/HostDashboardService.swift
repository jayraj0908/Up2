import Foundation
import Supabase

@MainActor
class HostDashboardService: ObservableObject {
    @Published var upcomingEvents: [Event] = []
    @Published var pastEvents: [Event] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase = SupabaseManager.shared.client
    
    func loadHostEvents() async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("🔄 Loading host events from Supabase...")
            
            let session = try await supabase.auth.session
            let userId = session.user.id.uuidString
            
            let response: [EventResponse] = try await supabase
                .from("events")
                .select("*")
                .eq("host_id", value: userId)
                .order("start_time", ascending: false)
                .execute()
                .value
            
            print("📅 Fetched \(response.count) host events")
            
            // Convert to Event models
            let events = response.compactMap { convertToEvent($0) }
            
            // Separate upcoming and past events
            let now = Date()
            upcomingEvents = events.filter { $0.startTime > now }
            pastEvents = events.filter { $0.startTime <= now }
            
            print("✅ Host dashboard loaded: \(upcomingEvents.count) upcoming, \(pastEvents.count) past events")
            
        } catch {
            print("❌ Failed to load host events: \(error)")
            errorMessage = "Failed to load events: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshHostEvents() async {
        await loadHostEvents()
    }
    
    // MARK: - Analytics Methods
    
    func getTotalEvents() -> Int {
        return upcomingEvents.count + pastEvents.count
    }
    
    func getUpcomingEventsCount() -> Int {
        return upcomingEvents.count
    }
    
    func getPastEventsCount() -> Int {
        return pastEvents.count
    }
    
    func getTotalRevenue() -> Double {
        return pastEvents.compactMap { $0.price }.reduce(0, +)
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

// MARK: - Error Types
enum HostDashboardError: LocalizedError {
    case userNotAuthenticated
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        }
    }
} 