import SwiftUI
import Supabase

@MainActor
class EventRSVPViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var rsvps: [RSVPData] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Computed Properties
    var confirmedCount: Int {
        rsvps.filter { $0.status == .confirmed }.count
    }
    
    var pendingCount: Int {
        rsvps.filter { $0.status == .pending }.count
    }
    
    var declinedCount: Int {
        rsvps.filter { $0.status == .declined }.count
    }
    

    
    private let supabase = SupabaseManager.shared.client
    private let authService = SupabaseAuthService.shared
    
    // MARK: - Methods
    func loadRSVPs(for eventId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: [RSVPModel] = try await supabase
                .from("tickets")
                .select("""
                    *,
                    profiles:user_id (
                        id,
                        name,
                        avatar
                    )
                """)
                .eq("event_id", value: eventId.uuidString)
                .execute()
                .value
            
            rsvps = response.compactMap { rsvpModel in
                guard let profile = rsvpModel.profile else { return nil }
                
                return RSVPData(
                    id: rsvpModel.id,
                    eventId: rsvpModel.eventId,
                    userId: rsvpModel.userId,
                    userName: profile.name,
                    userHandle: profile.handle ?? "",
                    userAvatar: profile.avatar,
                    status: RSVPData.RSVPStatus(rawValue: rsvpModel.ticketType) ?? .confirmed,
                    createdAt: rsvpModel.createdAt
                )
            }
            
        } catch {
            errorMessage = "Failed to load RSVPs: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createRSVP(for eventId: UUID, ticketType: String = "general") async throws {
        guard let currentUser = authService.currentUser else {
            throw RSVPError.userNotAuthenticated
        }
        
        do {
            try await supabase
                .from("tickets")
                .insert([
                    "event_id": eventId.uuidString,
                    "user_id": currentUser.id,
                    "ticket_type": ticketType
                ])
                .execute()
            
            // Refresh RSVPs after creating new one
            await loadRSVPs(for: eventId)
            
        } catch {
            throw RSVPError.createFailed("Failed to create RSVP: \(error.localizedDescription)")
        }
    }
    
    func updateRSVPStatus(_ rsvpId: UUID, to newStatus: RSVPStatus) async throws {
        do {
            try await supabase
                .from("tickets")
                .update(["ticket_type": newStatus.rawValue])
                .eq("id", value: rsvpId.uuidString)
                .execute()
            
            // Update local data
        if let index = rsvps.firstIndex(where: { $0.id == rsvpId }) {
            rsvps[index] = RSVPData(
                id: rsvps[index].id,
                eventId: rsvps[index].eventId,
                userId: rsvps[index].userId,
                userName: rsvps[index].userName,
                userHandle: rsvps[index].userHandle,
                userAvatar: rsvps[index].userAvatar,
                status: RSVPData.RSVPStatus(rawValue: newStatus.rawValue) ?? .pending,
                createdAt: rsvps[index].createdAt
            )
            }
            
        } catch {
            throw RSVPError.updateFailed("Failed to update RSVP: \(error.localizedDescription)")
        }
    }
    
    func refreshRSVPs() async {
        // This would use the actual event ID from the current context
        await loadRSVPs(for: UUID())
    }
}

// MARK: - RSVP Model for Supabase
struct RSVPModel: Codable {
    let id: UUID
    let eventId: UUID
    let userId: UUID
    let ticketType: String
    let createdAt: Date
    let profile: ProfileModel?
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case userId = "user_id"
        case ticketType = "ticket_type"
        case createdAt = "created_at"
        case profile = "profiles"
    }
}

struct ProfileModel: Codable {
    let id: UUID
    let name: String
    let handle: String?
    let avatar: String?
}

// MARK: - RSVP Errors
enum RSVPError: LocalizedError {
    case userNotAuthenticated
    case createFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User must be authenticated to RSVP"
        case .createFailed(let message):
            return "Failed to create RSVP: \(message)"
        case .updateFailed(let message):
            return "Failed to update RSVP: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete RSVP: \(message)"
        }
    }
} 