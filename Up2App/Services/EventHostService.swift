import Foundation
import Supabase
import SwiftUI

@MainActor
class EventHostService: ObservableObject {
    static let shared = EventHostService()
    
    private let authService = SupabaseAuthService.shared
    private var supabase: SupabaseClient { authService.supabase }
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Event Management
    
    func createEvent(_ event: HostEvent) async throws -> HostEvent {
        guard let currentUser = authService.currentUser else {
            throw EventHostError.userNotAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let eventRecord = HostEventRecord(
                id: event.id.uuidString,
                hostId: currentUser.id,
                title: event.title,
                venueName: event.venueName,
                date: ISO8601DateFormatter().string(from: event.date),
                rsvpCount: event.rsvpCount,
                price: event.price,
                status: event.status.rawValue,
                imageURL: event.imageURL,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            try await supabase
                .from("host_events")
                .insert(eventRecord)
                .execute()
            
            isLoading = false
            return event
        } catch {
            isLoading = false
            errorMessage = "Failed to create event: \(error.localizedDescription)"
            throw error
        }
    }
    
    func updateEvent(_ event: HostEvent) async throws -> HostEvent {
        guard let currentUser = authService.currentUser else {
            throw EventHostError.userNotAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let updateData = HostEventUpdateData(
                title: event.title,
                venueName: event.venueName,
                date: ISO8601DateFormatter().string(from: event.date),
                rsvpCount: event.rsvpCount,
                price: event.price,
                status: event.status.rawValue,
                imageUrl: event.imageURL ?? "",
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            try await supabase
                .from("host_events")
                .update(updateData)
                .eq("id", value: event.id.uuidString)
                .eq("host_id", value: currentUser.id)
                .execute()
            
            isLoading = false
            return event
        } catch {
            isLoading = false
            errorMessage = "Failed to update event: \(error.localizedDescription)"
            throw error
        }
    }
    
    func deleteEvent(_ eventId: UUID) async throws {
        guard let currentUser = authService.currentUser else {
            throw EventHostError.userNotAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabase
                .from("host_events")
                .delete()
                .eq("id", value: eventId.uuidString)
                .eq("host_id", value: currentUser.id)
                .execute()
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to delete event: \(error.localizedDescription)"
            throw error
        }
    }
    
    func getHostEvents(userId: String) async throws -> [HostEvent] {
        guard let currentUser = authService.currentUser else {
            throw EventHostError.userNotAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response: [HostEventResponse] = try await supabase
                .from("host_events")
                .select("*")
                .eq("host_id", value: currentUser.id)
                .order("date", ascending: true)
                .execute()
                .value
            
            let events = response.compactMap { convertToHostEvent($0) }
            
            isLoading = false
            return events
        } catch {
            isLoading = false
            errorMessage = "Failed to fetch events: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Analytics
    
    func getEventAnalytics(eventId: UUID) async throws -> HostEventAnalytics {
        guard let currentUser = authService.currentUser else {
            throw EventHostError.userNotAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch real analytics data from Supabase
            let response: [AnalyticsResponse] = try await supabase
                .from("event_analytics")
                .select("*")
                .eq("event_id", value: eventId.uuidString)
                .eq("host_id", value: currentUser.id)
                .execute()
                .value
            
            guard let analyticsData = response.first else {
                // Return default analytics if no data exists
                let defaultAnalytics = HostEventAnalytics(
                    eventId: eventId,
                    totalViews: 0,
                    uniqueViews: 0,
                    rsvpRate: 0.0,
                    conversionRate: 0.0,
                    revenue: 0.0,
                    topReferrers: [:],
                    dailyStats: []
                )
                isLoading = false
                return defaultAnalytics
            }
            
            let analytics = HostEventAnalytics(
                eventId: eventId,
                totalViews: analyticsData.totalViews,
                uniqueViews: analyticsData.uniqueViews,
                rsvpRate: analyticsData.rsvpRate,
                conversionRate: analyticsData.conversionRate,
                revenue: analyticsData.revenue,
                topReferrers: analyticsData.topReferrers,
                dailyStats: analyticsData.dailyStats
            )
            
            isLoading = false
            return analytics
        } catch {
            isLoading = false
            errorMessage = "Failed to fetch analytics: \(error.localizedDescription)"
            throw error
        }
    }
    
    func getHostAnalytics(userId: String) async throws -> HostAnalytics {
        guard let currentUser = authService.currentUser else {
            throw EventHostError.userNotAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch real host analytics from Supabase
            let response: [HostAnalyticsResponse] = try await supabase
                .from("host_analytics")
                .select("*")
                .eq("host_id", value: currentUser.id)
                .execute()
                .value
            
            guard let analyticsData = response.first else {
                // Return default analytics if no data exists
                let defaultAnalytics = HostAnalytics(
                    totalEvents: 0,
                    totalRevenue: 0.0,
                    averageRSVPs: 0,
                    totalAttendees: 0,
                    monthlyGrowth: 0.0,
                    topEvents: []
                )
                isLoading = false
                return defaultAnalytics
            }
            
            let analytics = HostAnalytics(
                totalEvents: analyticsData.totalEvents,
                totalRevenue: analyticsData.totalRevenue,
                averageRSVPs: analyticsData.averageRSVPs,
                totalAttendees: analyticsData.totalAttendees,
                monthlyGrowth: analyticsData.monthlyGrowth,
                topEvents: analyticsData.topEvents
            )
            
            isLoading = false
            return analytics
        } catch {
            isLoading = false
            errorMessage = "Failed to fetch host analytics: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Guest Management
    
    func getEventGuests(eventId: UUID) async throws -> [RSVPData] {
        guard authService.currentUser != nil else {
            throw EventHostError.userNotAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response: [RSVPResponse] = try await supabase
                .from("rsvps")
                .select("*, profiles(name, avatar)")
                .eq("event_id", value: eventId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            let guests = response.compactMap { convertToRSVPData($0) }
            
            isLoading = false
            return guests
        } catch {
            isLoading = false
            errorMessage = "Failed to fetch guests: \(error.localizedDescription)"
            throw error
        }
    }
    
    func updateGuestStatus(eventId: UUID, guestId: UUID, status: RSVPStatus) async throws {
        guard authService.currentUser != nil else {
            throw EventHostError.userNotAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabase
                .from("rsvps")
                .update(["status": status.rawValue, "updated_at": ISO8601DateFormatter().string(from: Date())])
                .eq("event_id", value: eventId.uuidString)
                .eq("user_id", value: guestId.uuidString)
                .execute()
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to update guest status: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Event Promotion
    
    func createPromoCode(eventId: UUID, code: String, discount: Double, maxUses: Int) async throws {
        guard let currentUser = authService.currentUser else {
            throw EventHostError.userNotAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let promoCodeRecord = PromoCodeRecord(
                id: UUID().uuidString,
                eventId: eventId.uuidString,
                hostId: currentUser.id,
                code: code,
                discount: discount,
                maxUses: maxUses,
                usedCount: 0,
                isActive: true,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            try await supabase
                .from("promo_codes")
                .insert(promoCodeRecord)
                .execute()
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to create promo code: \(error.localizedDescription)"
            throw error
        }
    }
    
    func getEventPromoCodes(eventId: UUID) async throws -> [PromoCode] {
        guard let currentUser = authService.currentUser else {
            throw EventHostError.userNotAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response: [PromoCodeResponse] = try await supabase
                .from("promo_codes")
                .select("*")
                .eq("event_id", value: eventId.uuidString)
                .eq("host_id", value: currentUser.id)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            let promoCodes = response.compactMap { convertToPromoCode($0) }
            
            isLoading = false
            return promoCodes
        } catch {
            isLoading = false
            errorMessage = "Failed to fetch promo codes: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    private func convertToHostEvent(_ response: HostEventResponse) -> HostEvent? {
        guard let id = UUID(uuidString: response.id),
              let date = ISO8601DateFormatter().date(from: response.date) else {
            return nil
        }
        
        return HostEvent(
            id: id,
            title: response.title,
            venueName: response.venueName,
            date: date,
            rsvpCount: response.rsvpCount,
            price: response.price,
            status: HostEvent.HostEventStatus(rawValue: response.status) ?? .upcoming,
            imageURL: response.imageURL
        )
    }
    
    private func convertToRSVPData(_ response: RSVPResponse) -> RSVPData? {
        guard let id = UUID(uuidString: response.id),
              let eventId = UUID(uuidString: response.eventId),
              let userId = UUID(uuidString: response.userId),
              let date = ISO8601DateFormatter().date(from: response.createdAt) else {
            return nil
        }
        
        return RSVPData(
            id: id,
            eventId: eventId,
            userId: userId,
            userName: response.profileName,
            userHandle: response.profileName, // Using profileName as userHandle for now
            userAvatar: response.profileAvatar,
            status: RSVPData.RSVPStatus(rawValue: response.status) ?? .pending,
            createdAt: date
        )
    }
    
    private func convertToPromoCode(_ response: PromoCodeResponse) -> PromoCode? {
        guard let id = UUID(uuidString: response.id) else {
            return nil
        }
        
        return PromoCode(
            id: id,
            code: response.code,
            discount: response.discount,
            maxUses: response.maxUses,
            usedCount: response.usedCount,
            isActive: response.isActive
        )
    }
}

// MARK: - Database Models

private struct HostEventUpdateData: Codable {
    let title: String
    let venueName: String
    let date: String
    let rsvpCount: Int
    let price: Double
    let status: String
    let imageUrl: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case title
        case venueName = "venue_name"
        case date
        case rsvpCount = "rsvp_count"
        case price
        case status
        case imageUrl = "image_url"
        case updatedAt = "updated_at"
    }
}

private struct HostEventRecord: Codable {
    let id: String
    let hostId: String
    let title: String
    let venueName: String
    let date: String
    let rsvpCount: Int
    let price: Double
    let status: String
    let imageURL: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case hostId = "host_id"
        case title
        case venueName = "venue_name"
        case date
        case rsvpCount = "rsvp_count"
        case price
        case status
        case imageURL = "image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

private struct HostEventResponse: Codable {
    let id: String
    let hostId: String
    let title: String
    let venueName: String
    let date: String
    let rsvpCount: Int
    let price: Double
    let status: String
    let imageURL: String?
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case hostId = "host_id"
        case title
        case venueName = "venue_name"
        case date
        case rsvpCount = "rsvp_count"
        case price
        case status
        case imageURL = "image_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

private struct AnalyticsResponse: Codable {
    let eventId: String
    let hostId: String
    let totalViews: Int
    let uniqueViews: Int
    let rsvpRate: Double
    let conversionRate: Double
    let revenue: Double
    let topReferrers: [String: Int]
    let dailyStats: [AnalyticsDataPoint]
    
    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case hostId = "host_id"
        case totalViews = "total_views"
        case uniqueViews = "unique_views"
        case rsvpRate = "rsvp_rate"
        case conversionRate = "conversion_rate"
        case revenue
        case topReferrers = "top_referrers"
        case dailyStats = "daily_stats"
    }
}

private struct HostAnalyticsResponse: Codable {
    let hostId: String
    let totalEvents: Int
    let totalRevenue: Double
    let averageRSVPs: Int
    let totalAttendees: Int
    let monthlyGrowth: Double
    let topEvents: [TopEvent]
    
    enum CodingKeys: String, CodingKey {
        case hostId = "host_id"
        case totalEvents = "total_events"
        case totalRevenue = "total_revenue"
        case averageRSVPs = "average_rsvps"
        case totalAttendees = "total_attendees"
        case monthlyGrowth = "monthly_growth"
        case topEvents = "top_events"
    }
}

private struct RSVPResponse: Codable {
    let id: String
    let eventId: String
    let userId: String
    let eventTitle: String
    let status: String
    let createdAt: String
    let profileName: String
    let profileAvatar: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case userId = "user_id"
        case eventTitle = "event_title"
        case status
        case createdAt = "created_at"
        case profileName = "profiles.name"
        case profileAvatar = "profiles.avatar"
    }
}

private struct PromoCodeRecord: Codable {
    let id: String
    let eventId: String
    let hostId: String
    let code: String
    let discount: Double
    let maxUses: Int
    let usedCount: Int
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case hostId = "host_id"
        case code
        case discount
        case maxUses = "max_uses"
        case usedCount = "used_count"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

private struct PromoCodeResponse: Codable {
    let id: String
    let eventId: String
    let hostId: String
    let code: String
    let discount: Double
    let maxUses: Int
    let usedCount: Int
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case hostId = "host_id"
        case code
        case discount
        case maxUses = "max_uses"
        case usedCount = "used_count"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Data Models

struct HostEventAnalytics: Identifiable {
    let id = UUID()
    let eventId: UUID
    let totalViews: Int
    let uniqueViews: Int
    let rsvpRate: Double
    let conversionRate: Double
    let revenue: Double
    let topReferrers: [String: Int]
    let dailyStats: [AnalyticsDataPoint]
}

struct HostAnalytics: Identifiable {
    let id = UUID()
    let totalEvents: Int
    let totalRevenue: Double
    let averageRSVPs: Int
    let totalAttendees: Int
    let monthlyGrowth: Double
    let topEvents: [TopEvent]
}

struct PromoCode: Identifiable {
    let id: UUID
    let code: String
    let discount: Double
    let maxUses: Int
    let usedCount: Int
    let isActive: Bool
    
    var usagePercentage: Double {
        guard maxUses > 0 else { return 0 }
        return Double(usedCount) / Double(maxUses)
    }
    
    var remainingUses: Int {
        return max(0, maxUses - usedCount)
    }
}

// MARK: - Supporting Types

struct HostEvent: Identifiable, Codable {
    let id: UUID
    let title: String
    let venueName: String
    let date: Date
    let rsvpCount: Int
    let price: Double
    let status: HostEventStatus
    let imageURL: String?
    
    enum HostEventStatus: String, Codable, CaseIterable {
        case upcoming = "upcoming"
        case active = "active"
        case completed = "completed"
        case cancelled = "cancelled"
        
        var displayName: String {
            switch self {
            case .upcoming: return "Upcoming"
            case .active: return "Active"
            case .completed: return "Completed"
            case .cancelled: return "Cancelled"
            }
        }
        
        var color: Color {
            switch self {
            case .upcoming: return .blue
            case .active: return .green
            case .completed: return .gray
            case .cancelled: return .red
            }
        }
    }
}



enum EventHostError: LocalizedError {
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

