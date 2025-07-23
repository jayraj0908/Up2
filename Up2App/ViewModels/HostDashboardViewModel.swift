import SwiftUI

@MainActor
class HostDashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isLoading = false
    @Published var myEvents: [Event] = []
    @Published var recentRSVPs: [RSVPData] = []
    @Published var analyticsData: [AnalyticsDataPoint] = []
    @Published var topEvents: [TopEvent] = []
    @Published var errorMessage: String?
    
    private let eventService = EventService.shared
    private let authService = SupabaseAuthService.shared
    
    // MARK: - Computed Properties
    var totalEvents: Int {
        myEvents.count
    }
    
    var activeEvents: Int {
        myEvents.filter { $0.isActive || $0.isUpcoming }.count
    }
    
    var completedEvents: Int {
        myEvents.filter { $0.isCompleted }.count
    }
    
    var totalRSVPs: Int {
        // This would be calculated from RSVP data when implemented
        return 0
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
            // Load real events from Supabase
            myEvents = try await eventService.fetchEventsForHost()
            
            // Load real RSVPs from Supabase
            await loadRealRSVPs()
            
            // Load real analytics from Supabase
            await loadRealAnalytics()
            
        } catch {
            errorMessage = "Failed to load dashboard data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func loadRealRSVPs() async {
        // Load real RSVP data from Supabase
        do {
            var allRSVPs: [RSVPData] = []
            
            // Fetch RSVPs for each event
            for event in myEvents {
                let eventRSVPs = try await fetchEventRSVPs(eventId: event.id)
                allRSVPs.append(contentsOf: eventRSVPs)
            }
            
            // Sort by date and take recent ones
            recentRSVPs = allRSVPs
                .sorted(by: { $0.createdAt > $1.createdAt })
                .prefix(10)
                .map { $0 }
        } catch {
            print("Failed to load RSVPs: \(error)")
            recentRSVPs = []
        }
    }
    
    private func loadRealAnalytics() async {
        // Load real analytics data from Supabase
        var analyticsData: [AnalyticsDataPoint] = []
        var topEvents: [TopEvent] = []
        
        // Calculate analytics from real event data
        if !myEvents.isEmpty {
            // Create analytics data points from events
            let calendar = Calendar.current
            let now = Date()
            
            // Generate last 7 days of data
            for i in 0..<7 {
                if let date = calendar.date(byAdding: .day, value: -i, to: now) {
                    let eventsOnDay = myEvents.filter { event in
                        calendar.isDate(event.startTime, inSameDayAs: date)
                    }
                    
                    let dataPoint = AnalyticsDataPoint(
                        id: UUID(),
                        date: date,
                        value: Double(eventsOnDay.count),
                        label: formatDateLabel(date)
                    )
                    analyticsData.append(dataPoint)
                }
            }
            
            // Create top events from real data
            let sortedEvents = myEvents.sorted { $0.startTime > $1.startTime } // Sort by date instead
            topEvents = sortedEvents.prefix(5).map { event in
                TopEvent(
                    id: event.id,
                    title: event.title,
                    rsvpCount: 0, // Will be updated when RSVP service is implemented
                    revenue: (event.price ?? 0) * 0, // Will be updated when RSVP service is implemented
                    date: event.startTime
                )
            }
        }
        
        self.analyticsData = analyticsData
        self.topEvents = topEvents
    }
    
    private func fetchEventRSVPs(eventId: UUID) async throws -> [RSVPData] {
        // This would fetch RSVPs from Supabase
        // For now, return empty array as RSVP service needs to be implemented
        return []
    }
    
    private func formatDateLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
    
    // MARK: - Event Management
    
    func deleteEvent(_ event: Event) async {
        do {
            try await eventService.deleteEvent(event.id)
            // Remove from local array
            myEvents.removeAll { $0.id == event.id }
        } catch {
            errorMessage = "Failed to delete event: \(error.localizedDescription)"
        }
    }
    
    func refreshEvents() async {
        await loadDashboardData()
    }
}

// MARK: - Supporting Types (keeping existing mock types for now)

struct RSVPData: Identifiable {
    let id: UUID
    let eventId: UUID
    let userId: UUID
    let userName: String
    let userHandle: String
    let userAvatar: String?
    let status: RSVPStatus
    let createdAt: Date
    
    enum RSVPStatus: String, CaseIterable {
        case confirmed = "confirmed"
        case pending = "pending"
        case declined = "declined"
        
        var displayName: String {
            switch self {
            case .confirmed: return "Confirmed"
            case .pending: return "Pending"
            case .declined: return "Declined"
    }
}

        var color: Color {
            switch self {
            case .confirmed: return .green
            case .pending: return .orange
            case .declined: return .red
            }
        }
    }
}

struct AnalyticsDataPoint: Identifiable, Codable {
    let id: UUID
    let date: Date
    let value: Double
    let label: String
}

struct TopEvent: Identifiable, Codable {
    let id: UUID
    let title: String
    let rsvpCount: Int
    let revenue: Double
    let date: Date
} 