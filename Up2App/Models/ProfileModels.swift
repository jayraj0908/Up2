import Foundation
import SwiftUI

// MARK: - Profile Data Models

struct ProfileData: Codable, Identifiable {
    var id: UUID
    var name: String
    var handle: String
    var avatar: String? // URL to avatar image in Supabase Storage
    var vibeTags: [VibeTag]
    var bio: String
    var isCurator: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), name: String = "", handle: String = "", avatar: String? = nil, vibeTags: [VibeTag] = [], bio: String = "", isCurator: Bool = false, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.handle = handle
        self.avatar = avatar
        self.vibeTags = vibeTags
        self.bio = bio
        self.isCurator = isCurator
        self.createdAt = createdAt ?? Date()
        self.updatedAt = updatedAt ?? Date()
    }
    
    // Computed properties for validation
    var isValid: Bool {
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !handle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               handle.count >= 3 &&
               handle.count <= 20 &&
               vibeTags.count <= 5
    }
    
    var isComplete: Bool {
        return isValid && !vibeTags.isEmpty
    }
}

// MARK: - Vibe Tags System

enum VibeTag: String, CaseIterable, Codable {
    // Mood Tags
    case energetic = "energetic"
    case chill = "chill"
    case adventurous = "adventurous"
    case creative = "creative"
    case social = "social"
    case introspective = "introspective"
    case playful = "playful"
    case focused = "focused"
    
    // Interest Tags
    case music = "music"
    case art = "art"
    case sports = "sports"
    case technology = "technology"
    case food = "food"
    case travel = "travel"
    case gaming = "gaming"
    case fitness = "fitness"
    case reading = "reading"
    case photography = "photography"
    case nature = "nature"
    case dancing = "dancing"
    
    var displayName: String {
        switch self {
        case .energetic: return "Energetic"
        case .chill: return "Chill"
        case .adventurous: return "Adventurous"
        case .creative: return "Creative"
        case .social: return "Social"
        case .introspective: return "Introspective"
        case .playful: return "Playful"
        case .focused: return "Focused"
        case .music: return "Music"
        case .art: return "Art"
        case .sports: return "Sports"
        case .technology: return "Technology"
        case .food: return "Food"
        case .travel: return "Travel"
        case .gaming: return "Gaming"
        case .fitness: return "Fitness"
        case .reading: return "Reading"
        case .photography: return "Photography"
        case .nature: return "Nature"
        case .dancing: return "Dancing"
        }
    }
    
    var category: VibeTagCategory {
        switch self {
        case .energetic, .chill, .adventurous, .creative, .social, .introspective, .playful, .focused:
            return .mood
        case .music, .art, .sports, .technology, .food, .travel, .gaming, .fitness, .reading, .photography, .nature, .dancing:
            return .interest
        }
    }
    
    var emoji: String {
        switch self {
        case .energetic: return "⚡️"
        case .chill: return "😌"
        case .adventurous: return "🌟"
        case .creative: return "🎨"
        case .social: return "👥"
        case .introspective: return "🤔"
        case .playful: return "🎯"
        case .focused: return "🎯"
        case .music: return "🎵"
        case .art: return "🖼️"
        case .sports: return "⚽️"
        case .technology: return "💻"
        case .food: return "🍕"
        case .travel: return "✈️"
        case .gaming: return "🎮"
        case .fitness: return "💪"
        case .reading: return "📚"
        case .photography: return "📸"
        case .nature: return "🌿"
        case .dancing: return "💃"
        }
    }
}

enum VibeTagCategory: String, CaseIterable {
    case mood = "mood"
    case interest = "interest"
    
    var displayName: String {
        switch self {
        case .mood: return "Mood"
        case .interest: return "Interests"
        }
    }
    
    var tags: [VibeTag] {
        return VibeTag.allCases.filter { $0.category == self }
    }
}

// MARK: - Profile Validation Models

struct ProfileValidation {
    var nameValidation: ValidationResult = .valid
    var handleValidation: ValidationResult = .valid
    var vibeTagsValidation: ValidationResult = .valid
    var bioValidation: ValidationResult = .valid
    
    var isValid: Bool {
        return nameValidation.isValid && 
               handleValidation.isValid && 
               vibeTagsValidation.isValid && 
               bioValidation.isValid
    }
    
    static func validateName(_ name: String) -> ValidationResult {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            return .invalid("Name is required")
        }
        if trimmedName.count < 2 {
            return .invalid("Name must be at least 2 characters")
        }
        if trimmedName.count > 50 {
            return .invalid("Name must be less than 50 characters")
        }
        return .valid
    }
    
    static func validateHandle(_ handle: String) -> ValidationResult {
        let trimmedHandle = handle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmedHandle.isEmpty {
            return .invalid("Username is required")
        }
        if trimmedHandle.count < 3 {
            return .invalid("Username must be at least 3 characters")
        }
        if trimmedHandle.count > 20 {
            return .invalid("Username must be less than 20 characters")
        }
        
        // Check for valid characters (alphanumeric and underscore only)
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        if trimmedHandle.unicodeScalars.contains(where: { !allowedCharacters.contains($0) }) {
            return .invalid("Username can only contain letters, numbers, and underscores")
        }
        
        // Check for reserved words
        let reservedHandles = ["admin", "support", "help", "up2", "app", "user", "system", "api", "www"]
        if reservedHandles.contains(trimmedHandle) {
            return .invalid("This username is not available")
        }
        
        return .valid
    }
    
    static func validateVibeTags(_ tags: [VibeTag]) -> ValidationResult {
        if tags.count > 5 {
            return .invalid("You can select up to 5 vibe tags")
        }
        return .valid
    }
    
    static func validateBio(_ bio: String) -> ValidationResult {
        if bio.count > 150 {
            return .invalid("Bio must be less than 150 characters")
        }
        return .valid
    }
}

// MARK: - Event History Models (Foundation for Epic 2)

struct EventAttendance: Codable, Identifiable {
    let id: UUID
    let eventId: UUID
    let userId: UUID
    let attendanceStatus: AttendanceStatus
    let joinedAt: Date
    
    enum AttendanceStatus: String, Codable {
        case attended = "attended"
        case noShow = "no_show"
        case cancelled = "cancelled"
    }
}

struct EventHistoryItem: Codable, Identifiable {
    let id: UUID
    let title: String
    let date: Date
    let attendanceStatus: EventAttendance.AttendanceStatus
    let eventType: String // Will be defined in Epic 2
    
    // Placeholder data for foundation
    static let placeholder = EventHistoryItem(
        id: UUID(),
        title: "No events yet",
        date: Date(),
        attendanceStatus: .attended,
        eventType: "placeholder"
    )
}

// MARK: - Profile Creation State

enum ProfileCreationStep: CaseIterable {
    case basicInfo
    case avatar
    case vibeTags
    case bio
    case complete
    
    var title: String {
        switch self {
        case .basicInfo: return "Basic Info"
        case .avatar: return "Profile Photo"
        case .vibeTags: return "Your Vibe"
        case .bio: return "Bio"
        case .complete: return "Complete"
        }
    }
    
    var isOptional: Bool {
        switch self {
        case .basicInfo: return false
        case .avatar: return true
        case .vibeTags: return false
        case .bio: return true
        case .complete: return false
        }
    }
}

// MARK: - Avatar Models

struct AvatarUpload {
    let image: UIImage
    let userId: UUID
    
    var compressedImageData: Data? {
        // Compress image to reasonable size for upload
        return image.jpegData(compressionQuality: 0.7)
    }
}

enum AvatarError: LocalizedError {
    case compressionFailed
    case uploadFailed(String)
    case invalidImageFormat
    case imageTooLarge
    
    var errorDescription: String? {
        switch self {
        case .compressionFailed:
            return "Failed to process image"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .invalidImageFormat:
            return "Please select a valid image format"
        case .imageTooLarge:
            return "Image is too large. Please select a smaller image"
        }
    }
} 