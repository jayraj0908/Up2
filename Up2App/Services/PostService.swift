import Foundation
import Supabase

@MainActor
class PostService: ObservableObject {
    static let shared = PostService()
    
    private let supabase = SupabaseManager.shared.client
    private let authService = SupabaseAuthService.shared
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private init() {}
    
    // MARK: - Post Creation
    
    func createPost(
        content: String,
        imageUrls: [String] = [],
        isEventRelated: Bool = false,
        relatedEventId: UUID? = nil
    ) async throws -> Post {
        guard let currentUser = authService.currentUser else {
            throw PostError.userNotAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let postData: [String: String] = [
                "creator_id": currentUser.id,
                "content": content,
                "image_urls": imageUrls.joined(separator: ","),
                "is_event_related": isEventRelated ? "true" : "false",
                "related_event_id": relatedEventId?.uuidString ?? ""
            ]
            
            let response: PostModel = try await supabase
                .from("posts")
                .insert(postData)
                .select()
                .single()
                .execute()
                .value
            
            return Post(
                id: response.id,
                creatorId: response.creatorId,
                content: response.content,
                imageUrls: response.imageUrlsArray,
                isEventRelated: response.isEventRelatedBool,
                relatedEventId: response.relatedEventIdUUID,
                createdAt: response.createdAt,
                updatedAt: response.updatedAt
            )
            
        } catch {
            errorMessage = "Failed to create post: \(error.localizedDescription)"
            throw PostError.createFailed("Failed to create post: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Post Retrieval
    
    func getPosts(for userId: UUID? = nil, limit: Int = 50) async throws -> [Post] {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            var query = supabase
                .from("posts")
                .select()
            
            if let userId = userId {
                query = query.eq("creator_id", value: userId.uuidString)
            }
            
            let response: [PostModel] = try await query
                .order("created_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            return response.map { postModel in
                Post(
                    id: postModel.id,
                    creatorId: postModel.creatorId,
                    content: postModel.content,
                    imageUrls: postModel.imageUrlsArray,
                    isEventRelated: postModel.isEventRelatedBool,
                    relatedEventId: postModel.relatedEventIdUUID,
                    createdAt: postModel.createdAt,
                    updatedAt: postModel.updatedAt
                )
            }
            
        } catch {
            errorMessage = "Failed to fetch posts: \(error.localizedDescription)"
            throw PostError.fetchFailed("Failed to fetch posts: \(error.localizedDescription)")
        }
    }
    
    func getEventPosts(for eventId: UUID) async throws -> [Post] {
        return try await getPosts(limit: 100).filter { post in
            post.isEventRelated && post.relatedEventId == eventId
        }
    }
    
    // MARK: - Post Update
    
    func updatePost(_ post: Post) async throws -> Post {
        guard let currentUser = authService.currentUser,
              post.creatorId.uuidString == currentUser.id else {
            throw PostError.unauthorized
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            let updateData: [String: String] = [
                "content": post.content,
                "image_urls": post.imageUrls.joined(separator: ","),
                "updated_at": Date().ISO8601Format()
            ]
            
            let response: PostModel = try await supabase
                .from("posts")
                .update(updateData)
                .eq("id", value: post.id.uuidString)
                .select()
                .single()
                .execute()
                .value
            
            return Post(
                id: response.id,
                creatorId: response.creatorId,
                content: response.content,
                imageUrls: response.imageUrlsArray,
                isEventRelated: response.isEventRelatedBool,
                relatedEventId: response.relatedEventIdUUID,
                createdAt: response.createdAt,
                updatedAt: response.updatedAt
            )
            
        } catch {
            errorMessage = "Failed to update post: \(error.localizedDescription)"
            throw PostError.updateFailed("Failed to update post: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Post Deletion
    
    func deletePost(_ postId: UUID) async throws {
        guard let currentUser = authService.currentUser else {
            throw PostError.userNotAuthenticated
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        do {
            try await supabase
                .from("posts")
                .delete()
                .eq("id", value: postId.uuidString)
                .eq("creator_id", value: currentUser.id) // Ensure user owns the post
                .execute()
            
        } catch {
            errorMessage = "Failed to delete post: \(error.localizedDescription)"
            throw PostError.deleteFailed("Failed to delete post: \(error.localizedDescription)")
        }
    }
}

// MARK: - Post Model for Supabase
struct PostModel: Codable {
    let id: UUID
    let creatorId: UUID
    let content: String
    let imageUrls: String // Stored as comma-separated string
    let isEventRelated: String // Stored as "true"/"false" string
    let relatedEventId: String? // Stored as string, can be empty
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case creatorId = "creator_id"
        case content
        case imageUrls = "image_urls"
        case isEventRelated = "is_event_related"
        case relatedEventId = "related_event_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Computed properties for easier access
    var imageUrlsArray: [String] {
        return imageUrls.isEmpty ? [] : imageUrls.components(separatedBy: ",")
    }
    
    var isEventRelatedBool: Bool {
        return isEventRelated.lowercased() == "true"
    }
    
    var relatedEventIdUUID: UUID? {
        guard let relatedEventId = relatedEventId, !relatedEventId.isEmpty else { return nil }
        return UUID(uuidString: relatedEventId)
    }
}

// MARK: - Post Model
struct Post: Identifiable, Codable {
    let id: UUID
    let creatorId: UUID
    let content: String
    let imageUrls: [String]
    let isEventRelated: Bool
    let relatedEventId: UUID?
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Post Errors
enum PostError: LocalizedError {
    case userNotAuthenticated
    case unauthorized
    case createFailed(String)
    case fetchFailed(String)
    case updateFailed(String)
    case deleteFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User must be authenticated to create posts"
        case .unauthorized:
            return "You are not authorized to perform this action"
        case .createFailed(let message):
            return "Failed to create post: \(message)"
        case .fetchFailed(let message):
            return "Failed to fetch posts: \(message)"
        case .updateFailed(let message):
            return "Failed to update post: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete post: \(message)"
        }
    }
} 