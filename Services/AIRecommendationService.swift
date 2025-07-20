import Foundation
import CoreLocation
import Combine

@MainActor
class AIRecommendationService: ObservableObject {
    static let shared = AIRecommendationService()
    
    // MARK: - Dependencies
    private let analyticsService = AnalyticsService.shared
    private let performanceService = AppPerformanceService.shared
    private let errorService = ErrorHandlingService.shared
    private let hapticService = HapticService.shared
    
    // MARK: - Configuration
    private let maxRecommendationHistory = 1000
    private let learningRate: Double = 0.1
    private let decayFactor: Double = 0.95
    
    // MARK: - Published Properties
    @Published var isLearningEnabled = true
    @Published var recommendationQuality: Double = 0.0
    @Published var lastModelUpdate: Date?
    
    // MARK: - Private Properties
    private var userBehaviorHistory: [UserBehaviorEvent] = []
    private var recommendationModel = RecommendationModel()
    private var collaborativeFiltering = CollaborativeFiltering()
    private var contentBasedFiltering = ContentBasedFiltering()
    
    private init() {
        loadUserBehaviorHistory()
        loadRecommendationModel()
    }
    
    // MARK: - Public Interface
    
    /// Generate AI-powered recommendations for events
    func generateRecommendations(
        for userId: UUID,
        events: [Event],
        userProfile: ProfileData,
        userLocation: CLLocation?,
        friendIds: [UUID],
        context: RecommendationContext
    ) async throws -> [EventRecommendation] {
        
        let startTime = Date()
        
        do {
            // Track performance
            let result = try await performanceService.trackAPICall {
                try await performRecommendationGeneration(
                    userId: userId,
                    events: events,
                    userProfile: userProfile,
                    userLocation: userLocation,
                    friendIds: friendIds,
                    context: context
                )
            }
            
            // Update recommendation quality
            updateRecommendationQuality()
            
            // Track analytics
            analyticsService.trackUserAction("ai_recommendations_generated", properties: [
                "user_id": userId.uuidString,
                "event_count": events.count,
                "recommendation_count": result.count,
                "processing_time": Date().timeIntervalSince(startTime),
                "context": context.rawValue
            ])
            
            return result
            
        } catch {
            errorService.handleSystemError(error, context: "AIRecommendationService.generateRecommendations")
            throw error
        }
    }
    
    /// Learn from user interactions
    func learnFromInteraction(
        userId: UUID,
        eventId: UUID,
        interactionType: UserInteractionType,
        context: InteractionContext
    ) async {
        
        do {
            let behaviorEvent = UserBehaviorEvent(
                userId: userId,
                eventId: eventId,
                interactionType: interactionType,
                context: context,
                timestamp: Date()
            )
            
            // Add to behavior history
            addBehaviorEvent(behaviorEvent)
            
            // Update recommendation model
            await updateRecommendationModel(with: behaviorEvent)
            
            // Track analytics
            analyticsService.trackUserAction("user_interaction_learned", properties: [
                "user_id": userId.uuidString,
                "event_id": eventId.uuidString,
                "interaction_type": interactionType.rawValue,
                "context": context.rawValue
            ])
            
        } catch {
            errorService.handleSystemError(error, context: "AIRecommendationService.learnFromInteraction")
        }
    }
    
    /// Get trending events with viral detection
    func getTrendingEvents(
        timeWindow: TimeWindow = .last24Hours,
        location: CLLocation? = nil,
        radius: Double = 50000
    ) async throws -> [TrendingEvent] {
        
        do {
            let trendingEvents = try await performTrendingAnalysis(
                timeWindow: timeWindow,
                location: location,
                radius: radius
            )
            
            // Track analytics
            analyticsService.trackUserAction("trending_events_analyzed", properties: [
                "time_window": timeWindow.rawValue,
                "event_count": trendingEvents.count,
                "location_radius": radius
            ])
            
            return trendingEvents
            
        } catch {
            errorService.handleSystemError(error, context: "AIRecommendationService.getTrendingEvents")
            throw error
        }
    }
    
    /// Get personalized content curation
    func getCuratedContent(
        for userId: UUID,
        contentType: ContentType,
        limit: Int = 20
    ) async throws -> [CuratedContent] {
        
        do {
            let curatedContent = try await performContentCuration(
                userId: userId,
                contentType: contentType,
                limit: limit
            )
            
            // Track analytics
            analyticsService.trackUserAction("content_curated", properties: [
                "user_id": userId.uuidString,
                "content_type": contentType.rawValue,
                "content_count": curatedContent.count
            ])
            
            return curatedContent
            
        } catch {
            errorService.handleSystemError(error, context: "AIRecommendationService.getCuratedContent")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func performRecommendationGeneration(
        userId: UUID,
        events: [Event],
        userProfile: ProfileData,
        userLocation: CLLocation?,
        friendIds: [UUID],
        context: RecommendationContext
    ) async throws -> [EventRecommendation] {
        
        var recommendations: [EventRecommendation] = []
        
        for event in events {
            // Calculate content-based score
            let contentScore = contentBasedFiltering.calculateScore(
                event: event,
                userProfile: userProfile
            )
            
            // Calculate collaborative filtering score
            let collaborativeScore = collaborativeFiltering.calculateScore(
                event: event,
                userId: userId,
                similarUsers: await findSimilarUsers(for: userId)
            )
            
            // Calculate contextual score
            let contextualScore = calculateContextualScore(
                event: event,
                userLocation: userLocation,
                friendIds: friendIds,
                context: context
            )
            
            // Calculate viral potential score
            let viralScore = calculateViralPotential(event: event)
            
            // Combine scores with weights
            let finalScore = combineScores(
                contentScore: contentScore,
                collaborativeScore: collaborativeScore,
                contextualScore: contextualScore,
                viralScore: viralScore,
                context: context
            )
            
            let recommendation = EventRecommendation(
                event: event,
                score: finalScore,
                confidence: calculateConfidence(
                    contentScore: contentScore,
                    collaborativeScore: collaborativeScore,
                    contextualScore: contextualScore
                ),
                reasoning: generateReasoning(
                    contentScore: contentScore,
                    collaborativeScore: collaborativeScore,
                    contextualScore: contextualScore,
                    viralScore: viralScore
                ),
                context: context
            )
            
            recommendations.append(recommendation)
        }
        
        // Sort by score and return
        return recommendations.sorted { $0.score > $1.score }
    }
    
    private func performTrendingAnalysis(
        timeWindow: TimeWindow,
        location: CLLocation?,
        radius: Double
    ) async throws -> [TrendingEvent] {
        
        // This would typically analyze real-time data
        // For now, we'll use mock data with trending algorithms
        
        let mockTrendingEvents = MockEventData.generateMockTrendingEvents()
        
        return mockTrendingEvents.map { event in
            TrendingEvent(
                event: event.event,
                trendingScore: Double.random(in: 0.7...1.0),
                viralCoefficient: Double.random(in: 1.2...3.0),
                growthRate: Double.random(in: 0.1...0.5),
                engagementMetrics: EngagementMetrics(
                    views: Int.random(in: 100...1000),
                    shares: Int.random(in: 10...100),
                    rsvps: Int.random(in: 20...200),
                    comments: Int.random(in: 5...50)
                )
            )
        }
    }
    
    private func performContentCuration(
        userId: UUID,
        contentType: ContentType,
        limit: Int
    ) async throws -> [CuratedContent] {
        
        // This would typically use the recommendation model
        // For now, we'll return mock curated content
        
        let mockContent = MockEventData.generateMockFeedItems()
        
        return mockContent.prefix(limit).map { item in
            CuratedContent(
                event: item.event,
                curationReason: "Based on your interests and trending popularity",
                personalizationScore: Double.random(in: 0.6...0.9),
                contentType: contentType
            )
        }
    }
    
    private func calculateContextualScore(
        event: Event,
        userLocation: CLLocation?,
        friendIds: [UUID],
        context: RecommendationContext
    ) -> Double {
        
        var score: Double = 0.0
        
        // Location relevance
        if let userLocation = userLocation {
            let eventLocation = CLLocation(
                latitude: event.location.latitude,
                longitude: event.location.longitude
            )
            let distance = userLocation.distance(from: eventLocation)
            
            // Score decreases with distance
            let locationScore = max(0, 1.0 - (distance / 50000)) // 50km max
            score += locationScore * 0.3
        }
        
        // Time relevance
        let timeUntilEvent = event.date.timeIntervalSinceNow
        if timeUntilEvent > 0 {
            let timeScore = max(0, 1.0 - (timeUntilEvent / (7 * 24 * 3600))) // 7 days max
            score += timeScore * 0.2
        }
        
        // Context relevance
        switch context {
        case .discovery:
            score += 0.1 // Boost for discovery context
        case .trending:
            score += 0.2 // Boost for trending context
        case .friends:
            score += 0.3 // Boost for friends context
        case .personalized:
            score += 0.4 // Boost for personalized context
        }
        
        return min(1.0, score)
    }
    
    private func calculateViralPotential(event: Event) -> Double {
        // Simple viral potential calculation
        // In a real implementation, this would use more sophisticated algorithms
        
        var viralScore: Double = 0.0
        
        // Event type viral potential
        switch event.vibe.lowercased() {
        case "party", "club", "concert":
            viralScore += 0.3
        case "art", "culture", "food":
            viralScore += 0.2
        default:
            viralScore += 0.1
        }
        
        // Time-based viral potential (weekends are more viral)
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: event.date)
        if weekday == 1 || weekday == 7 { // Saturday or Sunday
            viralScore += 0.2
        }
        
        // Price-based viral potential (free events are more viral)
        if event.price == nil || event.price == 0 {
            viralScore += 0.2
        }
        
        return min(1.0, viralScore)
    }
    
    private func combineScores(
        contentScore: Double,
        collaborativeScore: Double,
        contextualScore: Double,
        viralScore: Double,
        context: RecommendationContext
    ) -> Double {
        
        // Weighted combination based on context
        let weights = getScoreWeights(for: context)
        
        let finalScore = (contentScore * weights.content) +
                        (collaborativeScore * weights.collaborative) +
                        (contextualScore * weights.contextual) +
                        (viralScore * weights.viral)
        
        return min(1.0, max(0.0, finalScore))
    }
    
    private func getScoreWeights(for context: RecommendationContext) -> ScoreWeights {
        switch context {
        case .discovery:
            return ScoreWeights(content: 0.3, collaborative: 0.2, contextual: 0.3, viral: 0.2)
        case .trending:
            return ScoreWeights(content: 0.2, collaborative: 0.1, contextual: 0.2, viral: 0.5)
        case .friends:
            return ScoreWeights(content: 0.2, collaborative: 0.4, contextual: 0.3, viral: 0.1)
        case .personalized:
            return ScoreWeights(content: 0.4, collaborative: 0.3, contextual: 0.2, viral: 0.1)
        }
    }
    
    private func calculateConfidence(
        contentScore: Double,
        collaborativeScore: Double,
        contextualScore: Double
    ) -> Double {
        // Calculate confidence based on score consistency
        let scores = [contentScore, collaborativeScore, contextualScore]
        let mean = scores.reduce(0, +) / Double(scores.count)
        let variance = scores.map { pow($0 - mean, 2) }.reduce(0, +) / Double(scores.count)
        let standardDeviation = sqrt(variance)
        
        // Higher confidence for more consistent scores
        return max(0.0, min(1.0, 1.0 - standardDeviation))
    }
    
    private func generateReasoning(
        contentScore: Double,
        collaborativeScore: Double,
        contextualScore: Double,
        viralScore: Double
    ) -> String {
        var reasons: [String] = []
        
        if contentScore > 0.7 {
            reasons.append("Matches your interests")
        }
        if collaborativeScore > 0.7 {
            reasons.append("Popular with similar users")
        }
        if contextualScore > 0.7 {
            reasons.append("Great location and timing")
        }
        if viralScore > 0.7 {
            reasons.append("Trending and viral potential")
        }
        
        return reasons.isEmpty ? "Recommended for you" : reasons.joined(separator: ", ")
    }
    
    private func findSimilarUsers(for userId: UUID) async -> [UUID] {
        // This would typically use collaborative filtering algorithms
        // For now, return mock similar users
        return [UUID(), UUID(), UUID()]
    }
    
    private func addBehaviorEvent(_ event: UserBehaviorEvent) {
        userBehaviorHistory.append(event)
        
        // Keep history size manageable
        if userBehaviorHistory.count > maxRecommendationHistory {
            userBehaviorHistory.removeFirst(userBehaviorHistory.count - maxRecommendationHistory)
        }
        
        // Save to persistent storage
        saveUserBehaviorHistory()
    }
    
    private func updateRecommendationModel(with event: UserBehaviorEvent) async {
        // Update the recommendation model based on user behavior
        // This is a simplified implementation
        
        recommendationModel.lastUpdate = Date()
        lastModelUpdate = Date()
        
        // Save model
        saveRecommendationModel()
    }
    
    private func updateRecommendationQuality() {
        // Calculate recommendation quality based on user feedback
        // This is a simplified implementation
        recommendationQuality = Double.random(in: 0.7...0.95)
    }
    
    private func loadUserBehaviorHistory() {
        // Load from persistent storage
        // For now, start with empty history
    }
    
    private func saveUserBehaviorHistory() {
        // Save to persistent storage
        // For now, just track in memory
    }
    
    private func loadRecommendationModel() {
        // Load from persistent storage
        // For now, use default model
    }
    
    private func saveRecommendationModel() {
        // Save to persistent storage
        // For now, just track in memory
    }
}

// MARK: - Supporting Types

struct EventRecommendation {
    let event: Event
    let score: Double
    let confidence: Double
    let reasoning: String
    let context: RecommendationContext
}

struct TrendingEvent {
    let event: Event
    let trendingScore: Double
    let viralCoefficient: Double
    let growthRate: Double
    let engagementMetrics: EngagementMetrics
}

struct EngagementMetrics {
    let views: Int
    let shares: Int
    let rsvps: Int
    let comments: Int
}

struct CuratedContent {
    let event: Event
    let curationReason: String
    let personalizationScore: Double
    let contentType: ContentType
}

struct UserBehaviorEvent {
    let userId: UUID
    let eventId: UUID
    let interactionType: UserInteractionType
    let context: InteractionContext
    let timestamp: Date
}

enum RecommendationContext: String, CaseIterable {
    case discovery = "discovery"
    case trending = "trending"
    case friends = "friends"
    case personalized = "personalized"
}

enum UserInteractionType: String, CaseIterable {
    case view = "view"
    case like = "like"
    case share = "share"
    case rsvp = "rsvp"
    case bookmark = "bookmark"
    case dismiss = "dismiss"
}

enum InteractionContext: String, CaseIterable {
    case feed = "feed"
    case map = "map"
    case trending = "trending"
    case search = "search"
    case detail = "detail"
}

enum ContentType: String, CaseIterable {
    case events = "events"
    case trending = "trending"
    case friends = "friends"
    case curated = "curated"
}

enum TimeWindow: String, CaseIterable {
    case lastHour = "last_hour"
    case last24Hours = "last_24_hours"
    case lastWeek = "last_week"
    case lastMonth = "last_month"
}

struct ScoreWeights {
    let content: Double
    let collaborative: Double
    let contextual: Double
    let viral: Double
}

// MARK: - Recommendation Models

private struct RecommendationModel {
    var lastUpdate: Date?
    var parameters: [String: Double] = [:]
}

private struct CollaborativeFiltering {
    func calculateScore(event: Event, userId: UUID, similarUsers: [UUID]) -> Double {
        // Simplified collaborative filtering
        return Double.random(in: 0.3...0.8)
    }
}

private struct ContentBasedFiltering {
    func calculateScore(event: Event, userProfile: ProfileData) -> Double {
        // Simplified content-based filtering
        return Double.random(in: 0.4...0.9)
    }
} 