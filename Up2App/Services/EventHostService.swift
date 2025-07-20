import Foundation
import Supabase
import SwiftUI

@MainActor
class EventHostService: ObservableObject {
    static let shared = EventHostService()
    
    private let supabase = SupabaseClient(
        supabaseURL: URL(string: "https://your-project.supabase.co")!,
        supabaseKey: "your-anon-key"
    )
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Event Management
    
    func createEvent(_ event: HostEvent) async throws -> HostEvent {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate API call for now
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            
            // In real implementation, this would save to Supabase
            // let response = try await supabase
            //     .from("events")
            //     .insert(event.toDictionary())
            //     .execute()
            
            isLoading = false
            return event
        } catch {
            isLoading = false
            errorMessage = "Failed to create event: \(error.localizedDescription)"
            throw error
        }
    }
    
    func updateEvent(_ event: HostEvent) async throws -> HostEvent {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // In real implementation:
            // let response = try await supabase
            //     .from("events")
            //     .update(event.toDictionary())
            //     .eq("id", value: event.id.uuidString)
            //     .execute()
            
            isLoading = false
            return event
        } catch {
            isLoading = false
            errorMessage = "Failed to update event: \(error.localizedDescription)"
            throw error
        }
    }
    
    func deleteEvent(_ eventId: UUID) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // In real implementation:
            // try await supabase
            //     .from("events")
            //     .delete()
            //     .eq("id", value: eventId.uuidString)
            //     .execute()
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to delete event: \(error.localizedDescription)"
            throw error
        }
    }
    
    func getHostEvents(userId: String) async throws -> [HostEvent] {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // In real implementation:
            // let response = try await supabase
            //     .from("events")
            //     .select()
            //     .eq("host_id", value: userId)
            //     .execute()
            
            // Return mock data for now
            let mockEvents = [
                HostEvent(
                    id: UUID(),
                    title: "Summer Beach Party",
                    venueName: "Santa Monica Beach",
                    date: Date().addingTimeInterval(86400 * 7),
                    rsvpCount: 45,
                    price: 25.0,
                    status: .upcoming,
                    imageURL: "https://example.com/beach-party.jpg"
                ),
                HostEvent(
                    id: UUID(),
                    title: "Electronic Music Night",
                    venueName: "Club XYZ",
                    date: Date().addingTimeInterval(86400 * 2),
                    rsvpCount: 78,
                    price: 35.0,
                    status: .active,
                    imageURL: "https://example.com/electronic-night.jpg"
                )
            ]
            
            isLoading = false
            return mockEvents
        } catch {
            isLoading = false
            errorMessage = "Failed to fetch events: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Analytics
    
    func getEventAnalytics(eventId: UUID) async throws -> HostEventAnalytics {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Mock analytics data
            let analytics = HostEventAnalytics(
                eventId: eventId,
                totalViews: 1250,
                uniqueViews: 890,
                rsvpRate: 0.68,
                conversionRate: 0.45,
                revenue: 2750.0,
                topReferrers: [
                    "Instagram": 45,
                    "Friends": 32,
                    "Search": 18,
                    "Direct": 5
                ],
                dailyStats: [
                    AnalyticsDataPoint(label: "Mon", value: 12),
                    AnalyticsDataPoint(label: "Tue", value: 18),
                    AnalyticsDataPoint(label: "Wed", value: 15),
                    AnalyticsDataPoint(label: "Thu", value: 22),
                    AnalyticsDataPoint(label: "Fri", value: 28),
                    AnalyticsDataPoint(label: "Sat", value: 35),
                    AnalyticsDataPoint(label: "Sun", value: 20)
                ]
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
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // Mock host analytics
            let analytics = HostAnalytics(
                totalEvents: 12,
                totalRevenue: 15420.0,
                averageRSVPs: 45,
                totalAttendees: 540,
                monthlyGrowth: 0.23,
                topEvents: [
                    TopEvent(
                        id: UUID(),
                        title: "Electronic Music Night",
                        imageURL: "https://example.com/electronic-night.jpg",
                        rsvpCount: 78,
                        rating: 4.8,
                        revenue: 2730.0
                    ),
                    TopEvent(
                        id: UUID(),
                        title: "Summer Beach Party",
                        imageURL: "https://example.com/beach-party.jpg",
                        rsvpCount: 45,
                        rating: 4.6,
                        revenue: 1125.0
                    )
                ]
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
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Mock guest data
            let guests = [
                RSVPData(
                    id: UUID(),
                    userName: "Sarah Johnson",
                    userAvatar: "https://example.com/sarah.jpg",
                    eventTitle: "Event Title",
                    status: .confirmed,
                    date: Date().addingTimeInterval(-3600 * 2)
                ),
                RSVPData(
                    id: UUID(),
                    userName: "Mike Chen",
                    userAvatar: "https://example.com/mike.jpg",
                    eventTitle: "Event Title",
                    status: .confirmed,
                    date: Date().addingTimeInterval(-3600 * 4)
                ),
                RSVPData(
                    id: UUID(),
                    userName: "Emma Davis",
                    userAvatar: "https://example.com/emma.jpg",
                    eventTitle: "Event Title",
                    status: .pending,
                    date: Date().addingTimeInterval(-3600 * 6)
                )
            ]
            
            isLoading = false
            return guests
        } catch {
            isLoading = false
            errorMessage = "Failed to fetch guests: \(error.localizedDescription)"
            throw error
        }
    }
    
    func updateGuestStatus(eventId: UUID, guestId: UUID, status: RSVPStatus) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // In real implementation:
            // try await supabase
            //     .from("rsvps")
            //     .update(["status": status.rawValue])
            //     .eq("event_id", value: eventId.uuidString)
            //     .eq("user_id", value: guestId.uuidString)
            //     .execute()
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to update guest status: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Event Promotion
    
    func createPromoCode(eventId: UUID, code: String, discount: Double, maxUses: Int) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // In real implementation:
            // try await supabase
            //     .from("promo_codes")
            //     .insert([
            //         "event_id": eventId.uuidString,
            //         "code": code,
            //         "discount": discount,
            //         "max_uses": maxUses,
            //         "used_count": 0
            //     ])
            //     .execute()
            
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = "Failed to create promo code: \(error.localizedDescription)"
            throw error
        }
    }
    
    func getEventPromoCodes(eventId: UUID) async throws -> [PromoCode] {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
            
            // Mock promo codes
            let promoCodes = [
                PromoCode(
                    id: UUID(),
                    code: "SUMMER20",
                    discount: 20.0,
                    maxUses: 50,
                    usedCount: 23,
                    isActive: true
                ),
                PromoCode(
                    id: UUID(),
                    code: "EARLYBIRD",
                    discount: 15.0,
                    maxUses: 30,
                    usedCount: 30,
                    isActive: false
                )
            ]
            
            isLoading = false
            return promoCodes
        } catch {
            isLoading = false
            errorMessage = "Failed to fetch promo codes: \(error.localizedDescription)"
            throw error
        }
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