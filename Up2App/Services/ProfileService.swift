import Foundation
import Supabase
import UIKit

@MainActor
class ProfileService: ObservableObject {
    static let shared = ProfileService()
    
    private let authService = SupabaseAuthService.shared
    private var supabase: SupabaseClient { authService.supabase }
    private var storage: SupabaseStorageClient { supabase.storage }
    
    private init() {}
    
    // MARK: - Profile CRUD Operations
    
    func createProfile(_ profileData: ProfileData, for userId: UUID) async throws -> ProfileData {
        var profile = profileData
        profile.id = userId // Ensure profile ID matches user ID
        
        // Validate profile data
        guard profile.isValid else {
            throw ProfileError.invalidProfileData("Profile data is not valid")
        }
        
        // Check handle uniqueness
        try await validateHandleUniqueness(profile.handle, excludingUserId: nil)
        
        do {
            let profileRecord = ProfileRecord(
                id: profile.id.uuidString,
                name: profile.name,
                handle: profile.handle,
                avatar: profile.avatar,
                vibeTags: profile.vibeTags.map { $0.rawValue },
                bio: profile.bio,
                isCurator: profile.isCurator,
                createdAt: ISO8601DateFormatter().string(from: profile.createdAt),
                updatedAt: ISO8601DateFormatter().string(from: profile.updatedAt)
            )
            
            try await supabase
                .from("profiles")
                .insert(profileRecord)
                .execute()
            
            return profile
        } catch {
            throw ProfileError.createFailed("Failed to create profile: \(error.localizedDescription)")
        }
    }
    
    func getProfile(for userId: UUID) async throws -> ProfileData? {
        do {
            let response: [ProfileResponse] = try await supabase
                .from("profiles")
                .select("*")
                .eq("id", value: userId.uuidString)
                .execute()
                .value
            
            guard let profileResponse = response.first else {
                return nil
            }
            
            return try profileResponse.toProfileData()
        } catch {
            throw ProfileError.fetchFailed("Failed to fetch profile: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Profile Fetch (as requested in prompt)
    
    func getProfile(for userId: String) async throws -> ProfileData? {
        guard let uuid = UUID(uuidString: userId) else {
            throw ProfileError.invalidUserId("Invalid user ID format")
        }
        return try await getProfile(for: uuid)
    }
    
    func updateProfile(_ profileData: ProfileData) async throws -> ProfileData {
        // Validate profile data
        guard profileData.isValid else {
            throw ProfileError.invalidProfileData("Profile data is not valid")
        }
        
        // Check handle uniqueness (excluding current user)
        try await validateHandleUniqueness(profileData.handle, excludingUserId: profileData.id)
        
        var updatedProfile = profileData
        updatedProfile.updatedAt = Date()
        
        do {
            let profileRecord = ProfileRecord(
                id: updatedProfile.id.uuidString,
                name: updatedProfile.name,
                handle: updatedProfile.handle,
                avatar: updatedProfile.avatar,
                vibeTags: updatedProfile.vibeTags.map { $0.rawValue },
                bio: updatedProfile.bio,
                isCurator: updatedProfile.isCurator,
                createdAt: ISO8601DateFormatter().string(from: updatedProfile.createdAt),
                updatedAt: ISO8601DateFormatter().string(from: updatedProfile.updatedAt)
            )
            
            try await supabase
                .from("profiles")
                .update(profileRecord)
                .eq("id", value: updatedProfile.id.uuidString)
                .execute()
            
            return updatedProfile
        } catch {
            throw ProfileError.updateFailed("Failed to update profile: \(error.localizedDescription)")
        }
    }
    
    func updateProfileToHost(userId: UUID) async throws -> ProfileData {
        guard let currentUser = authService.currentUser else {
            throw ProfileError.userNotAuthenticated()
        }
        
        // Verify the user is updating their own profile
        guard currentUser.id == userId.uuidString else {
            throw ProfileError.unauthorized()
        }
        
        // Get current profile or create one if it doesn't exist
        let currentProfile = try await getProfile(for: userId)
        
        if currentProfile == nil {
            print("📝 Profile not found, creating new profile for host onboarding")
            
            // Create a basic profile directly in the database
            let profileRecord = ProfileRecord(
                id: userId.uuidString,
                name: "User",
                handle: "user_\(userId.uuidString.prefix(8))",
                avatar: nil,
                vibeTags: [],
                bio: "",
                isCurator: true, // Set as host immediately
                createdAt: ISO8601DateFormatter().string(from: Date()),
                updatedAt: ISO8601DateFormatter().string(from: Date())
            )
            
            do {
                try await supabase
                    .from("profiles")
                    .insert(profileRecord)
                    .execute()
                
                print("✅ Profile created successfully as host")
                
                // Return the created profile
                return ProfileData(
                    id: userId,
                    name: profileRecord.name,
                    handle: profileRecord.handle,
                    avatar: profileRecord.avatar,
                    vibeTags: [],
                    bio: profileRecord.bio,
                    isCurator: profileRecord.isCurator,
                    createdAt: Date(),
                    updatedAt: Date()
                )
            } catch {
                print("❌ Failed to create profile: \(error)")
                throw ProfileError.createFailed("Failed to create profile: \(error.localizedDescription)")
            }
        }
        
        guard var profile = currentProfile else {
            throw ProfileError.profileNotFound
        }
        
        // Update existing profile to become a host/curator
        profile.isCurator = true
        profile.updatedAt = Date()
        
        do {
            let profileRecord = ProfileRecord(
                id: profile.id.uuidString,
                name: profile.name,
                handle: profile.handle,
                avatar: profile.avatar,
                vibeTags: profile.vibeTags.map { $0.rawValue },
                bio: profile.bio,
                isCurator: profile.isCurator,
                createdAt: ISO8601DateFormatter().string(from: profile.createdAt),
                updatedAt: ISO8601DateFormatter().string(from: profile.updatedAt)
            )
            
            try await supabase
                .from("profiles")
                .update(profileRecord)
                .eq("id", value: profile.id.uuidString)
                .execute()
            
            print("✅ Profile updated to host successfully")
            return profile
        } catch {
            print("❌ Failed to update profile: \(error)")
            throw ProfileError.updateFailed("Failed to update profile: \(error.localizedDescription)")
        }
    }
    
    func createBasicProfile(userId: UUID) async throws -> ProfileData {
        guard let currentUser = authService.currentUser else {
            throw ProfileError.userNotAuthenticated()
        }
        
        // Verify the user is creating their own profile
        guard currentUser.id == userId.uuidString else {
            throw ProfileError.unauthorized()
        }
        
        // Check if profile already exists
        let existingProfile = try await getProfile(for: userId)
        if existingProfile != nil {
            return existingProfile!
        }
        
        print("📝 Creating basic profile for user onboarding")
        
        // Create a basic profile for regular users
        let profileRecord = ProfileRecord(
            id: userId.uuidString,
            name: currentUser.email ?? "User",
            handle: "user_\(userId.uuidString.prefix(8))",
            avatar: nil,
            vibeTags: [],
            bio: "",
            isCurator: false,
            createdAt: ISO8601DateFormatter().string(from: Date()),
            updatedAt: ISO8601DateFormatter().string(from: Date())
        )
        
        try await supabase
            .from("profiles")
            .insert(profileRecord)
            .execute()
        
        // Fetch and return the created profile
        guard let createdProfile = try await getProfile(for: userId) else {
            throw ProfileError.createFailed("Failed to create basic profile")
        }
        
        return createdProfile
    }
    
    func deleteProfile(for userId: UUID) async throws {
        do {
            // Delete avatar from storage if exists
            if let profile = try await getProfile(for: userId),
               let avatarPath = profile.avatar {
                try? await deleteAvatar(path: avatarPath)
            }
            
            // Delete profile from database
            try await supabase
                .from("profiles")
                .delete()
                .eq("id", value: userId.uuidString)
                .execute()
        } catch {
            throw ProfileError.deleteFailed("Failed to delete profile: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Handle Validation
    
    func validateHandleUniqueness(_ handle: String, excludingUserId: UUID?) async throws {
        let trimmedHandle = handle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        do {
            var query = supabase
                .from("profiles")
                .select("id")
                .eq("handle", value: trimmedHandle)
            
            // If updating existing profile, exclude current user
            if let excludingUserId = excludingUserId {
                query = query.neq("id", value: excludingUserId.uuidString)
            }
            
            let response: [HandleCheckResponse] = try await query.execute().value
            
            if !response.isEmpty {
                throw ProfileError.handleNotAvailable("This username is already taken")
            }
        } catch let profileError as ProfileError {
            throw profileError
        } catch {
            throw ProfileError.validationFailed("Unable to validate username: \(error.localizedDescription)")
        }
    }
    
    func isHandleAvailable(_ handle: String) async -> Bool {
        do {
            try await validateHandleUniqueness(handle, excludingUserId: nil)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Avatar Management
    
    func uploadAvatar(_ avatarUpload: AvatarUpload) async throws -> String {
        guard let imageData = avatarUpload.compressedImageData else {
            throw AvatarError.compressionFailed
        }
        
        // Validate image size (max 5MB)
        guard imageData.count <= 5 * 1024 * 1024 else {
            throw AvatarError.imageTooLarge
        }
        
        let fileName = "avatar_\(avatarUpload.userId.uuidString)_\(Date().timeIntervalSince1970).jpg"
        let filePath = "avatars/\(fileName)"
        
        do {
            try await storage
                .from("profiles")
                .upload(filePath, data: imageData, options: FileOptions(contentType: "image/jpeg"))
            
            // Get public URL
            let url = try storage
                .from("profiles")
                .getPublicURL(path: filePath)
            
            return url.absoluteString
        } catch {
            throw AvatarError.uploadFailed(error.localizedDescription)
        }
    }
    
    func deleteAvatar(path: String) async throws {
        // Extract file path from full URL if needed
        let filePath: String
        if path.contains("/") && path.contains("profiles") {
            // Extract path from full URL
            if let pathComponent = path.components(separatedBy: "/profiles/").last {
                filePath = pathComponent
            } else {
                filePath = path
            }
        } else {
            filePath = path
        }
        
        do {
            try await storage
                .from("profiles")
                .remove(paths: [filePath])
        } catch {
            // Don't throw error for avatar deletion failures
            print("Warning: Failed to delete avatar: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Profile Search and Discovery
    
    func searchProfiles(by handle: String, limit: Int = 20) async throws -> [ProfileData] {
        do {
            let response: [ProfileResponse] = try await supabase
                .from("profiles")
                .select("*")
                .ilike("handle", pattern: "%\(handle.lowercased())%")
                .limit(limit)
                .execute()
                .value
            
            return try response.compactMap { try $0.toProfileData() }
        } catch {
            throw ProfileError.searchFailed("Failed to search profiles: \(error.localizedDescription)")
        }
    }
    
    func getProfilesWithVibeTags(_ tags: [VibeTag], limit: Int = 50) async throws -> [ProfileData] {
        let tagStrings = tags.map { $0.rawValue }
        
        do {
            let response: [ProfileResponse] = try await supabase
                .from("profiles")
                .select("*")
                .overlaps("vibe_tags", value: tagStrings)
                .limit(limit)
                .execute()
                .value
            
            return try response.compactMap { try $0.toProfileData() }
        } catch {
            throw ProfileError.searchFailed("Failed to fetch profiles with vibe tags: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Types

private struct ProfileRecord: Codable {
    let id: String
    let name: String
    let handle: String
    let avatar: String?
    let vibeTags: [String]
    let bio: String
    let isCurator: Bool
    let createdAt: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case handle
        case avatar
        case vibeTags = "vibe_tags"
        case bio
        case isCurator = "is_curator"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

private struct ProfileResponse: Codable {
    let id: String
    let name: String
    let handle: String
    let avatar: String?
    let vibe_tags: [String]
    let bio: String
    let is_curator: Bool
    let created_at: String
    let updated_at: String
    
    func toProfileData() throws -> ProfileData {
        guard let uuid = UUID(uuidString: id) else {
            throw ProfileError.invalidData("Invalid profile ID format")
        }
        
        let dateFormatter = ISO8601DateFormatter()
        guard let createdAt = dateFormatter.date(from: created_at),
              let updatedAt = dateFormatter.date(from: updated_at) else {
            throw ProfileError.invalidData("Invalid date format")
        }
        
        let vibeTags = vibe_tags.compactMap { VibeTag(rawValue: $0) }
        
        return ProfileData(
            id: uuid,
            name: name,
            handle: handle,
            avatar: avatar,
            vibeTags: vibeTags,
            bio: bio,
            isCurator: is_curator,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

private struct HandleCheckResponse: Codable {
    let id: String
}

// MARK: - Profile Service Errors Extension

extension ProfileError {
    static func invalidProfileData(_ message: String) -> ProfileError { return .profileCreationFailed }
    static func createFailed(_ message: String) -> ProfileError { return .profileCreationFailed }
    static func fetchFailed(_ message: String) -> ProfileError { return .profileNotFound }
    static func updateFailed(_ message: String) -> ProfileError { return .profileUpdateFailed }
    static func deleteFailed(_ message: String) -> ProfileError { return .profileUpdateFailed }
    static func handleNotAvailable(_ message: String) -> ProfileError { return .profileCreationFailed }
    static func validationFailed(_ message: String) -> ProfileError { return .profileCreationFailed }
    static func searchFailed(_ message: String) -> ProfileError { return .networkError }
    static func invalidData(_ message: String) -> ProfileError { return .profileNotFound }
    static func userNotAuthenticated() -> ProfileError { return .networkError }
    static func unauthorized() -> ProfileError { return .networkError }
} 