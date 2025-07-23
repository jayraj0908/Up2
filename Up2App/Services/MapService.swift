import Foundation
import Supabase
import CoreLocation

@MainActor
class MapService: ObservableObject {
    static let shared = MapService()
    
    private let authService = SupabaseAuthService.shared
    private var supabase: SupabaseClient { authService.supabase }
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Map Events
    
    func fetchMapEvents(location: CLLocation? = nil, radius: Double = 50000) async throws -> [MapEvent] {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch real map events from Supabase
            let response: [MapEventResponse] = try await supabase
                .from("events")
                .select("*")
                .eq("is_public", value: true)
                .gte("start_time", value: ISO8601DateFormatter().string(from: Date()))
                .order("start_time", ascending: true)
                .limit(50)
                .execute()
                .value
            
            let mapEvents = response.compactMap { convertToMapEvent($0) }
            
            isLoading = false
            return mapEvents
        } catch {
            isLoading = false
            errorMessage = "Failed to fetch map events: \(error.localizedDescription)"
            throw error
        }
    }
    
    func fetchEventsNearLocation(location: CLLocation, radius: Double = 50000) async throws -> [MapEvent] {
        isLoading = true
        errorMessage = nil
        
        do {
            // Calculate bounding box for location-based query
            let latDelta = radius / 111000 // Approximate meters per degree latitude
            let lonDelta = radius / (111000 * cos(location.coordinate.latitude * .pi / 180))
            
            let minLat = location.coordinate.latitude - latDelta
            let maxLat = location.coordinate.latitude + latDelta
            let minLon = location.coordinate.longitude - lonDelta
            let maxLon = location.coordinate.longitude + lonDelta
            
            // Fetch events within the bounding box
            let response: [MapEventResponse] = try await supabase
                .from("events")
                .select("*")
                .eq("is_public", value: true)
                .gte("start_time", value: ISO8601DateFormatter().string(from: Date()))
                .gte("location_latitude", value: minLat)
                .lte("location_latitude", value: maxLat)
                .gte("location_longitude", value: minLon)
                .lte("location_longitude", value: maxLon)
                .order("start_time", ascending: true)
                .limit(50)
                .execute()
                .value
            
            let mapEvents = response.compactMap { convertToMapEvent($0) }
            
            isLoading = false
            return mapEvents
        } catch {
            isLoading = false
            errorMessage = "Failed to fetch nearby events: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    private func convertToMapEvent(_ response: MapEventResponse) -> MapEvent? {
        guard let id = UUID(uuidString: response.id) else { return nil }
        
        // Use event coordinates if available, otherwise use default location
        let coordinate: CLLocationCoordinate2D
        if let lat = response.locationLatitude, let lon = response.locationLongitude {
            coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        } else {
            // Default to San Francisco if no coordinates
            coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        }
        
        return MapEvent(
            id: id.uuidString,
            title: response.title,
            coordinate: coordinate
        )
    }
}

// MARK: - Database Models

private struct MapEventResponse: Codable {
    let id: String
    let title: String
    let description: String
    let startTime: String
    let endTime: String
    let locationName: String?
    let locationAddress: String?
    let locationLatitude: Double?
    let locationLongitude: Double?
    let isPublic: Bool
    let price: Double?
    let capacity: Int?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case startTime = "start_time"
        case endTime = "end_time"
        case locationName = "location_name"
        case locationAddress = "location_address"
        case locationLatitude = "location_latitude"
        case locationLongitude = "location_longitude"
        case isPublic = "is_public"
        case price
        case capacity
    }
}

// MARK: - Supporting Types

struct MapEvent: Identifiable, Hashable, Equatable {
    let id: String
    let title: String
    let coordinate: CLLocationCoordinate2D
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MapEvent, rhs: MapEvent) -> Bool {
        return lhs.id == rhs.id
    }
} 