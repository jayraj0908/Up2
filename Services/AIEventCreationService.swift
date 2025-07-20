import Foundation
import CryptoKit

/// Service for AI-powered event creation and intelligent suggestions
/// Part of Epic E: Host Flow - Million Dollar Enhancements
class AIEventCreationService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var aiSuggestions: AISuggestions = AISuggestions()
    @Published var eventTemplates: [EventTemplate] = []
    @Published var collaborationStatus: CollaborationStatus = CollaborationStatus()
    @Published var creationAnalytics: CreationAnalytics = CreationAnalytics()
    
    // MARK: - Private Properties
    private let aiRecommendationService: AIRecommendationService
    private let errorHandlingService: ErrorHandlingService
    private let hapticService: HapticService
    private let analyticsService: AnalyticsService
    private let securityService: SecurityService
    
    // MARK: - Initialization
    init(aiRecommendationService: AIRecommendationService = .shared,
         errorHandlingService: ErrorHandlingService = .shared,
         hapticService: HapticService = .shared,
         analyticsService: AnalyticsService = .shared,
         securityService: SecurityService = .shared) {
        self.aiRecommendationService = aiRecommendationService
        self.errorHandlingService = errorHandlingService
        self.hapticService = hapticService
        self.analyticsService = analyticsService
        self.securityService = securityService
        
        loadEventTemplates()
    }
    
    // MARK: - Public Methods
    
    /// Generate AI-powered event suggestions
    func generateEventSuggestions(context: EventContext) async throws -> EventSuggestions {
        do {
            analyticsService.trackEvent("ai_event_suggestions_generated", properties: [
                "context_type": context.type.rawValue,
                "user_id": UserProfileService.shared.currentUser?.id ?? "unknown"
            ])
            
            // Analyze context and user preferences
            let analysis = try await analyzeEventContext(context)
            
            // Generate title suggestions
            let titleSuggestions = try await generateTitleSuggestions(analysis)
            
            // Generate description suggestions
            let descriptionSuggestions = try await generateDescriptionSuggestions(analysis)
            
            // Generate tag suggestions
            let tagSuggestions = try await generateTagSuggestions(analysis)
            
            // Create suggestions package
            let suggestions = EventSuggestions(
                titles: titleSuggestions,
                descriptions: descriptionSuggestions,
                tags: tagSuggestions,
                generatedAt: Date(),
                confidence: analysis.confidence
            )
            
            // Update AI suggestions
            aiSuggestions.recentSuggestions.append(suggestions)
            
            // Keep only last 10 suggestions
            if aiSuggestions.recentSuggestions.count > 10 {
                aiSuggestions.recentSuggestions.removeFirst()
            }
            
            hapticService.triggerSuccess()
            
            return suggestions
            
        } catch {
            errorHandlingService.handleError(error, context: "AIEventCreationService.generateEventSuggestions")
            throw error
        }
    }
    
    /// Create event from template
    func createEventFromTemplate(_ template: EventTemplate, customization: EventCustomization) async throws -> Event {
        do {
            analyticsService.trackEvent("event_created_from_template", properties: [
                "template_id": template.id,
                "template_name": template.name
            ])
            
            // Validate template
            try validateEventTemplate(template)
            
            // Apply customization
            let customizedEvent = try await applyCustomization(template, customization: customization)
            
            // Generate unique event ID
            let eventId = UUID().uuidString
            
            // Create event
            let event = Event(
                id: eventId,
                title: customizedEvent.title,
                description: customizedEvent.description,
                template: template,
                customization: customization,
                createdAt: Date(),
                createdBy: UserProfileService.shared.currentUser?.id ?? ""
            )
            
            // Save event
            try await saveEvent(event)
            
            // Update creation analytics
            await updateCreationAnalytics(template: template)
            
            hapticService.triggerSuccess()
            
            return event
            
        } catch {
            errorHandlingService.handleError(error, context: "AIEventCreationService.createEventFromTemplate")
            throw error
        }
    }
    
    /// Duplicate existing event
    func duplicateEvent(_ eventId: String, modifications: EventModifications) async throws -> Event {
        do {
            analyticsService.trackEvent("event_duplicated", properties: [
                "original_event_id": eventId
            ])
            
            // Retrieve original event
            let originalEvent = try await retrieveEvent(eventId)
            
            // Apply modifications
            let duplicatedEvent = try await applyModifications(originalEvent, modifications: modifications)
            
            // Generate new event ID
            let newEventId = UUID().uuidString
            
            // Create duplicated event
            let event = Event(
                id: newEventId,
                title: duplicatedEvent.title,
                description: duplicatedEvent.description,
                originalEventId: eventId,
                modifications: modifications,
                createdAt: Date(),
                createdBy: UserProfileService.shared.currentUser?.id ?? ""
            )
            
            // Save duplicated event
            try await saveEvent(event)
            
            hapticService.triggerSuccess()
            
            return event
            
        } catch {
            errorHandlingService.handleError(error, context: "AIEventCreationService.duplicateEvent")
            throw error
        }
    }
    
    /// Create recurring event series
    func createRecurringEventSeries(_ baseEvent: Event, schedule: RecurringSchedule) async throws -> [Event] {
        do {
            analyticsService.trackEvent("recurring_event_series_created", properties: [
                "base_event_id": baseEvent.id,
                "occurrences": schedule.occurrences.count
            ])
            
            // Validate recurring schedule
            try validateRecurringSchedule(schedule)
            
            // Generate recurring events
            let recurringEvents = try await generateRecurringEvents(baseEvent, schedule: schedule)
            
            // Save all events
            for event in recurringEvents {
                try await saveEvent(event)
            }
            
            // Update creation analytics
            await updateCreationAnalytics(recurringEvents: recurringEvents)
            
            hapticService.triggerSuccess()
            
            return recurringEvents
            
        } catch {
            errorHandlingService.handleError(error, context: "AIEventCreationService.createRecurringEventSeries")
            throw error
        }
    }
    
    /// Start event collaboration
    func startEventCollaboration(_ eventId: String, collaborators: [Collaborator]) async throws -> CollaborationSession {
        do {
            analyticsService.trackEvent("event_collaboration_started", properties: [
                "event_id": eventId,
                "collaborators_count": collaborators.count
            ])
            
            // Validate collaborators
            try validateCollaborators(collaborators)
            
            // Create collaboration session
            let session = try await createCollaborationSession(eventId: eventId, collaborators: collaborators)
            
            // Send invitations
            try await sendCollaborationInvitations(session)
            
            // Update collaboration status
            collaborationStatus.activeSessions.append(session)
            
            hapticService.triggerSuccess()
            
            return session
            
        } catch {
            errorHandlingService.handleError(error, context: "AIEventCreationService.startEventCollaboration")
            throw error
        }
    }
    
    /// Join event collaboration
    func joinEventCollaboration(_ sessionId: String, role: CollaborationRole) async throws -> CollaborationMember {
        do {
            analyticsService.trackEvent("event_collaboration_joined", properties: [
                "session_id": sessionId,
                "role": role.rawValue
            ])
            
            // Get collaboration session
            let session = try await getCollaborationSession(sessionId)
            
            // Validate role assignment
            try validateRoleAssignment(session, role: role)
            
            // Create collaboration member
            let member = try await createCollaborationMember(session: session, role: role)
            
            // Update session
            try await updateCollaborationSession(session, member: member)
            
            hapticService.triggerSuccess()
            
            return member
            
        } catch {
            errorHandlingService.handleError(error, context: "AIEventCreationService.joinEventCollaboration")
            throw error
        }
    }
    
    /// Get event templates
    func getEventTemplates(category: EventCategory? = nil) async throws -> [EventTemplate] {
        do {
            let templates = try await fetchEventTemplates(category: category)
            
            analyticsService.trackEvent("event_templates_requested", properties: [
                "category": category?.rawValue ?? "all",
                "templates_count": templates.count
            ])
            
            return templates
            
        } catch {
            errorHandlingService.handleError(error, context: "AIEventCreationService.getEventTemplates")
            throw error
        }
    }
    
    /// Get creation analytics
    func getCreationAnalytics() async throws -> CreationAnalytics {
        do {
            let analytics = try await fetchCreationAnalytics()
            creationAnalytics = analytics
            
            return analytics
            
        } catch {
            errorHandlingService.handleError(error, context: "AIEventCreationService.getCreationAnalytics")
            throw error
        }
    }
    
    /// Optimize event timing
    func optimizeEventTiming(_ event: Event, constraints: TimingConstraints) async throws -> OptimizedTiming {
        do {
            analyticsService.trackEvent("event_timing_optimized", properties: [
                "event_id": event.id
            ])
            
            // Analyze timing constraints
            let analysis = try await analyzeTimingConstraints(constraints)
            
            // Generate optimized timing
            let optimizedTiming = try await generateOptimizedTiming(event, analysis: analysis)
            
            hapticService.triggerSuccess()
            
            return optimizedTiming
            
        } catch {
            errorHandlingService.handleError(error, context: "AIEventCreationService.optimizeEventTiming")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func loadEventTemplates() {
        // Load event templates from secure storage
        // For now, we'll use default templates
        eventTemplates = [
            EventTemplate(
                id: "party",
                name: "House Party",
                category: .social,
                title: "Epic House Party",
                description: "Join us for an unforgettable night of music, drinks, and great company!",
                tags: ["party", "music", "drinks", "social"],
                capacity: 50,
                duration: 4,
                price: 0.0
            ),
            EventTemplate(
                id: "concert",
                name: "Live Concert",
                category: .entertainment,
                title: "Live Music Night",
                description: "Experience amazing live performances from talented artists!",
                tags: ["concert", "music", "live", "entertainment"],
                capacity: 200,
                duration: 3,
                price: 25.0
            ),
            EventTemplate(
                id: "workshop",
                name: "Creative Workshop",
                category: .educational,
                title: "Creative Skills Workshop",
                description: "Learn new skills and unleash your creativity in this hands-on workshop!",
                tags: ["workshop", "learning", "creative", "skills"],
                capacity: 20,
                duration: 2,
                price: 15.0
            )
        ]
    }
    
    private func analyzeEventContext(_ context: EventContext) async throws -> ContextAnalysis {
        // Analyze event context and user preferences
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        return ContextAnalysis(
            type: context.type,
            userPreferences: ["music", "social", "nightlife"],
            trendingTopics: ["live music", "craft cocktails", "art exhibitions"],
            seasonalFactors: ["summer", "weekend", "evening"],
            confidence: Double.random(in: 0.7...0.95)
        )
    }
    
    private func generateTitleSuggestions(_ analysis: ContextAnalysis) async throws -> [String] {
        // Generate AI-powered title suggestions
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return [
            "Epic Night Out - Live Music & Cocktails",
            "Summer Vibes: Outdoor Party Extravaganza",
            "Craft Cocktails & Live Jazz Night",
            "Art & Music Fusion: Creative Evening",
            "Weekend Warriors: Ultimate Social Mixer"
        ]
    }
    
    private func generateDescriptionSuggestions(_ analysis: ContextAnalysis) async throws -> [String] {
        // Generate AI-powered description suggestions
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return [
            "Join us for an unforgettable evening of live music, craft cocktails, and amazing company. Perfect for networking and making new friends!",
            "Experience the best of summer with our outdoor party featuring live DJs, gourmet food trucks, and stunning sunset views.",
            "Immerse yourself in the world of jazz with our intimate venue, featuring talented musicians and handcrafted cocktails.",
            "Discover the perfect blend of art and music in our creative space. Enjoy live performances while exploring local artwork.",
            "Connect with like-minded individuals in our relaxed social setting. Great food, drinks, and conversation guaranteed!"
        ]
    }
    
    private func generateTagSuggestions(_ analysis: ContextAnalysis) async throws -> [String] {
        // Generate AI-powered tag suggestions
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        
        return [
            "live-music", "cocktails", "networking", "summer", "outdoor",
            "jazz", "art", "creative", "social", "weekend"
        ]
    }
    
    private func validateEventTemplate(_ template: EventTemplate) throws {
        // Validate event template
        guard !template.name.isEmpty else {
            throw AIEventCreationError.invalidTemplateName
        }
        
        guard template.capacity > 0 else {
            throw AIEventCreationError.invalidCapacity
        }
        
        guard template.duration > 0 else {
            throw AIEventCreationError.invalidDuration
        }
    }
    
    private func applyCustomization(_ template: EventTemplate, customization: EventCustomization) async throws -> CustomizedEvent {
        // Apply customization to template
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        
        return CustomizedEvent(
            title: customization.title ?? template.title,
            description: customization.description ?? template.description,
            tags: customization.tags ?? template.tags,
            capacity: customization.capacity ?? template.capacity,
            duration: customization.duration ?? template.duration,
            price: customization.price ?? template.price
        )
    }
    
    private func saveEvent(_ event: Event) async throws {
        // Save event to secure storage
        let eventData = try JSONEncoder().encode(event)
        let encryptedData = try securityService.encryptData(eventData)
        
        try securityService.storeSecureData(encryptedData, forKey: "event_\(event.id)")
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
    }
    
    private func updateCreationAnalytics(template: EventTemplate? = nil, recurringEvents: [Event]? = nil) async {
        // Update creation analytics
        creationAnalytics.totalEventsCreated += 1
        
        if let template = template {
            creationAnalytics.templatesUsed[template.id, default: 0] += 1
        }
        
        if let recurringEvents = recurringEvents {
            creationAnalytics.recurringEventsCreated += recurringEvents.count
        }
        
        creationAnalytics.lastCreatedAt = Date()
        
        // Save analytics
        try? await saveCreationAnalytics(creationAnalytics)
    }
    
    private func retrieveEvent(_ eventId: String) async throws -> Event {
        // Retrieve event from secure storage
        let encryptedData = try securityService.retrieveSecureData(forKey: "event_\(eventId)")
        let eventData = try securityService.decryptData(encryptedData)
        
        let event = try JSONDecoder().decode(Event.self, from: eventData)
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return event
    }
    
    private func applyModifications(_ originalEvent: Event, modifications: EventModifications) async throws -> ModifiedEvent {
        // Apply modifications to original event
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        
        return ModifiedEvent(
            title: modifications.title ?? originalEvent.title,
            description: modifications.description ?? originalEvent.description,
            tags: modifications.tags ?? originalEvent.tags,
            capacity: modifications.capacity ?? originalEvent.capacity,
            duration: modifications.duration ?? originalEvent.duration,
            price: modifications.price ?? originalEvent.price
        )
    }
    
    private func validateRecurringSchedule(_ schedule: RecurringSchedule) throws {
        // Validate recurring schedule
        guard !schedule.occurrences.isEmpty else {
            throw AIEventCreationError.invalidRecurringSchedule
        }
        
        guard schedule.occurrences.count <= 52 else { // Max 52 occurrences (weekly for a year)
            throw AIEventCreationError.tooManyOccurrences
        }
    }
    
    private func generateRecurringEvents(_ baseEvent: Event, schedule: RecurringSchedule) async throws -> [Event] {
        // Generate recurring events
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        var recurringEvents: [Event] = []
        
        for (index, occurrence) in schedule.occurrences.enumerated() {
            let event = Event(
                id: UUID().uuidString,
                title: "\(baseEvent.title) #\(index + 1)",
                description: baseEvent.description,
                originalEventId: baseEvent.id,
                occurrence: occurrence,
                createdAt: Date(),
                createdBy: UserProfileService.shared.currentUser?.id ?? ""
            )
            
            recurringEvents.append(event)
        }
        
        return recurringEvents
    }
    
    private func validateCollaborators(_ collaborators: [Collaborator]) throws {
        // Validate collaborators
        for collaborator in collaborators {
            guard !collaborator.userId.isEmpty else {
                throw AIEventCreationError.invalidCollaborator
            }
            
            guard collaborator.role != .invalid else {
                throw AIEventCreationError.invalidCollaborationRole
            }
        }
    }
    
    private func createCollaborationSession(eventId: String, collaborators: [Collaborator]) async throws -> CollaborationSession {
        // Create collaboration session
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return CollaborationSession(
            id: UUID().uuidString,
            eventId: eventId,
            collaborators: collaborators,
            status: .active,
            createdAt: Date()
        )
    }
    
    private func sendCollaborationInvitations(_ session: CollaborationSession) async throws {
        // Send collaboration invitations
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
    }
    
    private func getCollaborationSession(_ sessionId: String) async throws -> CollaborationSession {
        // Get collaboration session
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        
        return CollaborationSession(
            id: sessionId,
            eventId: "mock_event_id",
            collaborators: [],
            status: .active,
            createdAt: Date()
        )
    }
    
    private func validateRoleAssignment(_ session: CollaborationSession, role: CollaborationRole) throws {
        // Validate role assignment
        let existingRoles = session.collaborators.map { $0.role }
        
        if role == .host && existingRoles.contains(.host) {
            throw AIEventCreationError.hostRoleAlreadyAssigned
        }
    }
    
    private func createCollaborationMember(session: CollaborationSession, role: CollaborationRole) async throws -> CollaborationMember {
        // Create collaboration member
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        
        return CollaborationMember(
            userId: UserProfileService.shared.currentUser?.id ?? "",
            sessionId: session.id,
            role: role,
            joinedAt: Date()
        )
    }
    
    private func updateCollaborationSession(_ session: CollaborationSession, member: CollaborationMember) async throws {
        // Update collaboration session
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
    }
    
    private func fetchEventTemplates(category: EventCategory?) async throws -> [EventTemplate] {
        // Fetch event templates
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        if let category = category {
            return eventTemplates.filter { $0.category == category }
        }
        
        return eventTemplates
    }
    
    private func fetchCreationAnalytics() async throws -> CreationAnalytics {
        // This would typically call a backend API
        // For now, we'll return mock data
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return CreationAnalytics(
            totalEventsCreated: Int.random(in: 10...100),
            templatesUsed: [:],
            recurringEventsCreated: Int.random(in: 0...20),
            lastCreatedAt: Date(),
            averageCreationTime: Double.random(in: 30...120)
        )
    }
    
    private func analyzeTimingConstraints(_ constraints: TimingConstraints) async throws -> TimingAnalysis {
        // Analyze timing constraints
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        
        return TimingAnalysis(
            optimalTime: Date().addingTimeInterval(7 * 24 * 60 * 60), // 1 week from now
            alternativeTimes: [
                Date().addingTimeInterval(14 * 24 * 60 * 60),
                Date().addingTimeInterval(21 * 24 * 60 * 60)
            ],
            confidence: Double.random(in: 0.7...0.95)
        )
    }
    
    private func generateOptimizedTiming(_ event: Event, analysis: TimingAnalysis) async throws -> OptimizedTiming {
        // Generate optimized timing
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        
        return OptimizedTiming(
            eventId: event.id,
            recommendedTime: analysis.optimalTime,
            alternativeTimes: analysis.alternativeTimes,
            confidence: analysis.confidence,
            reasoning: "Based on user availability and event type analysis"
        )
    }
    
    // Helper methods
    private func saveCreationAnalytics(_ analytics: CreationAnalytics) async throws {
        let analyticsData = try JSONEncoder().encode(analytics)
        let encryptedData = try securityService.encryptData(analyticsData)
        
        try securityService.storeSecureData(encryptedData, forKey: "creation_analytics")
    }
}

// MARK: - Supporting Types

struct AISuggestions: Codable {
    var recentSuggestions: [EventSuggestions] = []
    var lastUpdated: Date = Date()
}

struct EventSuggestions: Codable {
    let titles: [String]
    let descriptions: [String]
    let tags: [String]
    let generatedAt: Date
    let confidence: Double
}

struct EventTemplate: Codable, Identifiable {
    let id: String
    let name: String
    let category: EventCategory
    let title: String
    let description: String
    let tags: [String]
    let capacity: Int
    let duration: Int // in hours
    let price: Double
}

enum EventCategory: String, Codable, CaseIterable {
    case social = "social"
    case entertainment = "entertainment"
    case educational = "educational"
    case business = "business"
    case sports = "sports"
    case arts = "arts"
    case food = "food"
    case technology = "technology"
}

struct EventContext: Codable {
    let type: ContextType
    let location: String?
    let date: Date?
    let preferences: [String]
}

enum ContextType: String, Codable {
    case party = "party"
    case concert = "concert"
    case workshop = "workshop"
    case networking = "networking"
    case celebration = "celebration"
}

struct ContextAnalysis: Codable {
    let type: ContextType
    let userPreferences: [String]
    let trendingTopics: [String]
    let seasonalFactors: [String]
    let confidence: Double
}

struct Event: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let template: EventTemplate?
    let customization: EventCustomization?
    let originalEventId: String?
    let modifications: EventModifications?
    let occurrence: Date?
    let createdAt: Date
    let createdBy: String
    let tags: [String] = []
    let capacity: Int = 0
    let duration: Int = 0
    let price: Double = 0.0
}

struct EventCustomization: Codable {
    let title: String?
    let description: String?
    let tags: [String]?
    let capacity: Int?
    let duration: Int?
    let price: Double?
}

struct CustomizedEvent: Codable {
    let title: String
    let description: String
    let tags: [String]
    let capacity: Int
    let duration: Int
    let price: Double
}

struct EventModifications: Codable {
    let title: String?
    let description: String?
    let tags: [String]?
    let capacity: Int?
    let duration: Int?
    let price: Double?
}

struct ModifiedEvent: Codable {
    let title: String
    let description: String
    let tags: [String]
    let capacity: Int
    let duration: Int
    let price: Double
}

struct RecurringSchedule: Codable {
    let occurrences: [Date]
    let frequency: RecurringFrequency
    let endDate: Date?
}

enum RecurringFrequency: String, Codable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
}

struct CollaborationStatus: Codable {
    var activeSessions: [CollaborationSession] = []
    var lastUpdated: Date = Date()
}

struct CollaborationSession: Codable, Identifiable {
    let id: String
    let eventId: String
    let collaborators: [Collaborator]
    let status: CollaborationStatus
    let createdAt: Date
}

struct Collaborator: Codable {
    let userId: String
    let role: CollaborationRole
    let invitedAt: Date
}

enum CollaborationRole: String, Codable, CaseIterable {
    case host = "host"
    case coHost = "co_host"
    case organizer = "organizer"
    case assistant = "assistant"
    case invalid = "invalid"
}

struct CollaborationMember: Codable {
    let userId: String
    let sessionId: String
    let role: CollaborationRole
    let joinedAt: Date
}

enum CollaborationStatus: String, Codable {
    case active = "active"
    case pending = "pending"
    case completed = "completed"
    case cancelled = "cancelled"
}

struct CreationAnalytics: Codable {
    var totalEventsCreated: Int = 0
    var templatesUsed: [String: Int] = [:]
    var recurringEventsCreated: Int = 0
    var lastCreatedAt: Date = Date()
    var averageCreationTime: Double = 0.0
}

struct TimingConstraints: Codable {
    let preferredDates: [Date]
    let preferredTimes: [String]
    let maxDuration: Int
    let minAttendees: Int
}

struct TimingAnalysis: Codable {
    let optimalTime: Date
    let alternativeTimes: [Date]
    let confidence: Double
}

struct OptimizedTiming: Codable {
    let eventId: String
    let recommendedTime: Date
    let alternativeTimes: [Date]
    let confidence: Double
    let reasoning: String
}

enum AIEventCreationError: Error, LocalizedError {
    case invalidTemplateName
    case invalidCapacity
    case invalidDuration
    case invalidRecurringSchedule
    case tooManyOccurrences
    case invalidCollaborator
    case invalidCollaborationRole
    case hostRoleAlreadyAssigned
    case suggestionGenerationFailed
    case templateCreationFailed
    case collaborationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidTemplateName:
            return "Invalid template name"
        case .invalidCapacity:
            return "Invalid event capacity"
        case .invalidDuration:
            return "Invalid event duration"
        case .invalidRecurringSchedule:
            return "Invalid recurring schedule"
        case .tooManyOccurrences:
            return "Too many recurring occurrences"
        case .invalidCollaborator:
            return "Invalid collaborator"
        case .invalidCollaborationRole:
            return "Invalid collaboration role"
        case .hostRoleAlreadyAssigned:
            return "Host role already assigned"
        case .suggestionGenerationFailed:
            return "AI suggestion generation failed"
        case .templateCreationFailed:
            return "Event template creation failed"
        case .collaborationFailed:
            return "Event collaboration failed"
        }
    }
} 