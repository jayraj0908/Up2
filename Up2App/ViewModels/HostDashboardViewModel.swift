import SwiftUI

@MainActor
class HostDashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var myEvents: [HostEvent] = []
    @Published var recentRSVPs: [RSVPData] = []
    @Published var analyticsData: [AnalyticsDataPoint] = []
    @Published var topEvents: [TopEvent] = []
    @Published var errorMessage: String?
    
    // MARK: - Computed Properties
    var totalEvents: Int {
        myEvents.count
    }
    
    var activeEvents: Int {
        myEvents.filter { $0.status == .active || $0.status == .upcoming }.count
    }
    
    var totalRSVPs: Int {
        myEvents.reduce(0) { $0 + $1.rsvpCount }
    }
    
    var averageRSVPs: Int {
        guard !myEvents.isEmpty else { return 0 }
        return totalRSVPs / myEvents.count
    }
    
    // MARK: - Methods
    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate API calls
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            // Load mock data
            await loadMockData()
            
        } catch {
            errorMessage = "Failed to load dashboard data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func loadMockData() async {
        // Check if there are any real created events first
        if let realEvents = await loadRealCreatedEvents() {
            myEvents = realEvents
        } else {
            // Fallback to mock events if no real events exist
            myEvents = [
                HostEvent(
                    id: UUID(),
                    title: "Summer Beach Party",
                    venueName: "Santa Monica Beach",
                    date: Date().addingTimeInterval(86400 * 7), // 7 days from now
                    rsvpCount: 45,
                    price: 25.0,
                    status: .upcoming,
                    imageURL: "https://example.com/beach-party.jpg"
                ),
                HostEvent(
                    id: UUID(),
                    title: "Electronic Music Night",
                    venueName: "Club XYZ",
                    date: Date().addingTimeInterval(86400 * 2), // 2 days from now
                    rsvpCount: 78,
                    price: 35.0,
                    status: .active,
                    imageURL: "https://example.com/electronic-night.jpg"
                ),
                HostEvent(
                    id: UUID(),
                    title: "Wine Tasting Evening",
                    venueName: "Vineyard Estate",
                    date: Date().addingTimeInterval(-86400 * 3), // 3 days ago
                    rsvpCount: 32,
                    price: 50.0,
                    status: .completed,
                    imageURL: "https://example.com/wine-tasting.jpg"
                ),
                HostEvent(
                    id: UUID(),
                    title: "Tech Meetup",
                    venueName: "Innovation Center",
                    date: Date().addingTimeInterval(-86400 * 10), // 10 days ago
                    rsvpCount: 0,
                    price: 0.0,
                    status: .cancelled,
                    imageURL: "https://example.com/tech-meetup.jpg"
                )
            ]
        }
        
        // Mock RSVPs
        recentRSVPs = [
            RSVPData(
                id: UUID(),
                userName: "Sarah Johnson",
                userAvatar: "https://example.com/sarah.jpg",
                eventTitle: "Summer Beach Party",
                status: .confirmed,
                date: Date().addingTimeInterval(-3600 * 2) // 2 hours ago
            ),
            RSVPData(
                id: UUID(),
                userName: "Mike Chen",
                userAvatar: "https://example.com/mike.jpg",
                eventTitle: "Electronic Music Night",
                status: .confirmed,
                date: Date().addingTimeInterval(-3600 * 4) // 4 hours ago
            ),
            RSVPData(
                id: UUID(),
                userName: "Emma Davis",
                userAvatar: "https://example.com/emma.jpg",
                eventTitle: "Summer Beach Party",
                status: .pending,
                date: Date().addingTimeInterval(-3600 * 6) // 6 hours ago
            ),
            RSVPData(
                id: UUID(),
                userName: "Alex Rodriguez",
                userAvatar: "https://example.com/alex.jpg",
                eventTitle: "Electronic Music Night",
                status: .confirmed,
                date: Date().addingTimeInterval(-3600 * 8) // 8 hours ago
            )
        ]
        
        // Mock Analytics Data
        analyticsData = [
            AnalyticsDataPoint(label: "Jan", value: 12),
            AnalyticsDataPoint(label: "Feb", value: 18),
            AnalyticsDataPoint(label: "Mar", value: 15),
            AnalyticsDataPoint(label: "Apr", value: 22),
            AnalyticsDataPoint(label: "May", value: 28),
            AnalyticsDataPoint(label: "Jun", value: 35)
        ]
        
        // Mock Top Events
        topEvents = [
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
            ),
            TopEvent(
                id: UUID(),
                title: "Wine Tasting Evening",
                imageURL: "https://example.com/wine-tasting.jpg",
                rsvpCount: 32,
                rating: 4.9,
                revenue: 1600.0
            )
        ]
    }
    
    // MARK: - Real Event Loading
    private func loadRealCreatedEvents() async -> [HostEvent]? {
        // This would integrate with the actual event creation service
        // For now, we'll check if there are any events created through the app
        do {
            // Simulate checking for real events
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // In a real implementation, this would query the database
            // let events = try await EventHostService.shared.getHostEvents(userId: currentUserId)
            
            // For now, return nil to use mock data
            return nil
        } catch {
            print("Error loading real events: \(error)")
            return nil
        }
    }
    
    // MARK: - Event Management
    func editEvent(_ event: HostEvent) {
        print("Edit event: \(event.title)")
        // This would navigate to event editing
    }
    
    func deleteEvent(_ event: HostEvent) {
        print("Delete event: \(event.title)")
        // This would show confirmation dialog and delete the event
        withAnimation {
            myEvents.removeAll { $0.id == event.id }
        }
    }
    
    func viewRSVPs(for event: HostEvent) {
        print("View RSVPs for event: \(event.title)")
        // This would navigate to detailed RSVP view
        // In a real app, this would trigger navigation to EventRSVPView
    }
    
    func refreshData() async {
        await loadDashboardData()
    }
}

// MARK: - Data Models

struct HostEvent: Identifiable {
    let id: UUID
    let title: String
    let venueName: String
    let date: Date
    let rsvpCount: Int
    let price: Double
    let status: EventStatus
    let imageURL: String?
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var formattedPrice: String {
        if price == 0 {
            return "Free"
        } else {
            return "$\(String(format: "%.0f", price))"
        }
    }
}

enum EventStatus: String, CaseIterable {
    case upcoming = "Upcoming"
    case active = "Active"
    case completed = "Completed"
    case cancelled = "Cancelled"
}

struct RSVPData: Identifiable {
    let id: UUID
    let userName: String
    let userAvatar: String?
    let eventTitle: String
    let status: RSVPStatus
    let date: Date
    
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

enum RSVPStatus: String, CaseIterable {
    case confirmed = "Confirmed"
    case pending = "Pending"
    case cancelled = "Cancelled"
}

struct AnalyticsDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Int
}

struct TopEvent: Identifiable {
    let id: UUID
    let title: String
    let imageURL: String?
    let rsvpCount: Int
    let rating: Double
    let revenue: Double
    
    var formattedRevenue: String {
        return "$\(String(format: "%.0f", revenue))"
    }
} 