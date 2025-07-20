import Foundation
import Supabase
import UIKit

@MainActor
class ProfileService: ObservableObject {
    static let shared = ProfileService()
    
    private let authService = SupabaseAuthService.shared
    private var supabase: SupabaseClient { authService.supabaseClient }
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
            try await supabase
                .from("profiles")
                .insert(profile)
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
            try await supabase
                .from("profiles")
                .update(updatedProfile)
                .eq("id", value: updatedProfile.id.uuidString)
                .execute()
            
            return updatedProfile
        } catch {
            throw ProfileError.updateFailed("Failed to update profile: \(error.localizedDescription)")
        }
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

private struct ProfileResponse: Codable {
    let id: String
    let name: String
    let handle: String
    let avatar: String?
    let vibe_tags: [String]
    let bio: String
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
} 