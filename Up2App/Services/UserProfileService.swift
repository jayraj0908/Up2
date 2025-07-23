import Foundation

// MARK: - User Profile Service
class UserProfileService {
    static let shared = UserProfileService()
    
    private init() {}
    
    // MARK: - User Profile Model
    struct UserProfile {
        let id: String
        let name: String?
        let handle: String?
        let avatar: String?
        let vibeTags: [String]
        let bio: String?
        let email: String?
        let phone: String?
    }
    
    // MARK: - Profile Management
    func createUserProfile(for user: SupabaseAuthService.AuthUser) async throws -> UserProfile {
        // TODO: Implement actual user profile creation in database in Task 2
        // For now, create a basic profile
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        return UserProfile(
            id: user.id,
            name: nil,
            handle: nil,
            avatar: nil,
            vibeTags: [],
            bio: nil,
            email: user.email,
            phone: user.phone
        )
    }
    
    func updateUserProfile(_ profile: UserProfile) async throws -> UserProfile {
        // TODO: Implement profile updates in Task 3
        try await Task.sleep(nanoseconds: 500_000_000)
        return profile
    }
    
    func getUserProfile(id: String) async throws -> UserProfile? {
        // TODO: Implement profile retrieval in Task 3
        try await Task.sleep(nanoseconds: 300_000_000)
        return nil
    }
}

// MARK: - Profile Service Errors
enum ProfileError: LocalizedError {
    case profileNotFound
    case profileCreationFailed
    case profileUpdateFailed
    case networkError
    case invalidUserId(String)
    
    var errorDescription: String? {
        switch self {
        case .profileNotFound:
            return "User profile not found."
        case .profileCreationFailed:
            return "Failed to create user profile."
        case .profileUpdateFailed:
            return "Failed to update user profile."
        case .networkError:
            return "Network error. Please try again."
        case .invalidUserId(let message):
            return "Invalid user ID: \(message)"
        }
    }
} 