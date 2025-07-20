import SwiftUI

@MainActor
class EventRSVPViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var rsvps: [RSVPData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Methods
    func loadRSVPs(for eventId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Simulate API call
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            // Load mock RSVP data
            await loadMockRSVPs(for: eventId)
            
        } catch {
            errorMessage = "Failed to load RSVPs: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private func loadMockRSVPs(for eventId: UUID) async {
        // Generate mock RSVP data
        let mockNames = [
            "Sarah Johnson", "Mike Chen", "Emma Davis", "Alex Rodriguez",
            "Jessica Lee", "David Kim", "Maria Garcia", "James Wilson",
            "Lisa Thompson", "Robert Brown", "Amanda White", "Christopher Taylor",
            "Nicole Anderson", "Kevin Martinez", "Rachel Green", "Daniel Clark"
        ]
        
        let mockAvatars = [
            "https://example.com/avatar1.jpg",
            "https://example.com/avatar2.jpg",
            "https://example.com/avatar3.jpg",
            "https://example.com/avatar4.jpg"
        ]
        
        rsvps = mockNames.enumerated().map { index, name in
            RSVPData(
                id: UUID(),
                userName: name,
                userAvatar: mockAvatars[index % mockAvatars.count],
                eventTitle: "Event Title", // This would be the actual event title
                status: RSVPStatus.allCases.randomElement() ?? .confirmed,
                date: Date().addingTimeInterval(-Double.random(in: 0...86400 * 7)) // Random time in last 7 days
            )
        }
    }
    
    func updateRSVPStatus(_ rsvpId: UUID, to newStatus: RSVPStatus) {
        if let index = rsvps.firstIndex(where: { $0.id == rsvpId }) {
            rsvps[index] = RSVPData(
                id: rsvps[index].id,
                userName: rsvps[index].userName,
                userAvatar: rsvps[index].userAvatar,
                eventTitle: rsvps[index].eventTitle,
                status: newStatus,
                date: rsvps[index].date
            )
        }
    }
    
    func refreshRSVPs() async {
        await loadRSVPs(for: UUID()) // This would use the actual event ID
    }
} 