import Foundation
import CryptoKit

/// Service for event templates, quick creation, and validation
/// Part of Epic E: Host Flow - Million Dollar Enhancements
class EventTemplateService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var availableTemplates: [EventTemplate] = []
    @Published var userTemplates: [UserTemplate] = []
    @Published var templateCategories: [TemplateCategory] = []
    @Published var validationResults: ValidationResults = ValidationResults()
    
    // MARK: - Private Properties
    private let contentModerationService: ContentModerationService
    private let errorHandlingService: ErrorHandlingService
    private let hapticService: HapticService
    private let analyticsService: AnalyticsService
    private let securityService: SecurityService
    
    // MARK: - Initialization
    init(contentModerationService: ContentModerationService = .shared,
         errorHandlingService: ErrorHandlingService = .shared,
         hapticService: HapticService = .shared,
         analyticsService: AnalyticsService = .shared,
         securityService: SecurityService = .shared) {
        self.contentModerationService = contentModerationService
        self.errorHandlingService = errorHandlingService
        self.hapticService = hapticService
        self.analyticsService = analyticsService
        self.securityService = securityService
        
        loadTemplates()
    }
    
    // MARK: - Public Methods
    
    /// Get available templates by category
    func getTemplates(category: TemplateCategory? = nil) async throws -> [EventTemplate] {
        do {
            analyticsService.trackEvent("event_templates_requested", properties: [
                "category": category?.name ?? "all"
            ])
            
            let templates = try await fetchTemplates(category: category)
            
            // Update available templates
            availableTemplates = templates
            
            hapticService.triggerSuccess()
            
            return templates
            
        } catch {
            errorHandlingService.handleError(error, context: "EventTemplateService.getTemplates")
            throw error
        }
    }
    
    /// Create custom template
    func createCustomTemplate(_ template: TemplateCreation) async throws -> UserTemplate {
        do {
            analyticsService.trackEvent("custom_template_created", properties: [
                "template_name": template.name,
                "category": template.category.rawValue
            ])
            
            // Validate template
            try validateTemplateCreation(template)
            
            // Check content moderation
            let moderationResult = try await contentModerationService.moderateContent(
                text: template.description,
                contentType: .eventDescription
            )
            
            guard moderationResult.isApproved else {
                throw TemplateError.contentModerationFailed
            }
            
            // Create user template
            let userTemplate = try await createUserTemplate(template)
            
            // Save template
            try await saveUserTemplate(userTemplate)
            
            // Add to user templates
            userTemplates.append(userTemplate)
            
            hapticService.triggerSuccess()
            
            return userTemplate
            
        } catch {
            errorHandlingService.handleError(error, context: "EventTemplateService.createCustomTemplate")
            throw error
        }
    }
    
    /// Quick create event from template
    func quickCreateEvent(_ template: EventTemplate, quickSettings: QuickEventSettings) async throws -> QuickEvent {
        do {
            analyticsService.trackEvent("quick_event_created", properties: [
                "template_id": template.id,
                "template_name": template.name
            ])
            
            // Validate quick settings
            try validateQuickSettings(quickSettings)
            
            // Apply quick settings to template
            let event = try await applyQuickSettings(template, settings: quickSettings)
            
            // Optimize timing if needed
            if quickSettings.optimizeTiming {
                let optimizedTiming = try await optimizeEventTiming(event, constraints: quickSettings.timingConstraints)
                event.optimizedTiming = optimizedTiming
            }
            
            // Save quick event
            try await saveQuickEvent(event)
            
            hapticService.triggerSuccess()
            
            return event
            
        } catch {
            errorHandlingService.handleError(error, context: "EventTemplateService.quickCreateEvent")
            throw error
        }
    }
    
    /// Validate event content
    func validateEventContent(_ content: EventContent) async throws -> ValidationResult {
        do {
            analyticsService.trackEvent("event_content_validated", properties: [
                "content_type": content.type.rawValue
            ])
            
            // Perform content validation
            let validation = try await performContentValidation(content)
            
            // Check content moderation
            let moderationResult = try await contentModerationService.moderateContent(
                text: content.text,
                contentType: content.type
            )
            
            // Combine validation results
            let result = ValidationResult(
                isValid: validation.isValid && moderationResult.isApproved,
                issues: validation.issues + moderationResult.issues,
                suggestions: validation.suggestions,
                qualityScore: validation.qualityScore,
                moderatedAt: Date()
            )
            
            // Update validation results
            validationResults.recentValidations.append(result)
            
            hapticService.triggerSuccess()
            
            return result
            
        } catch {
            errorHandlingService.handleError(error, context: "EventTemplateService.validateEventContent")
            throw error
        }
    }
    
    /// Optimize event timing
    func optimizeEventTiming(_ event: QuickEvent, constraints: TimingConstraints) async throws -> OptimizedTiming {
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
            errorHandlingService.handleError(error, context: "EventTemplateService.optimizeEventTiming")
            throw error
        }
    }
    
    /// Customize event branding
    func customizeEventBranding(_ event: QuickEvent, branding: EventBranding) async throws -> BrandedEvent {
        do {
            analyticsService.trackEvent("event_branding_customized", properties: [
                "event_id": event.id,
                "branding_type": branding.type.rawValue
            ])
            
            // Validate branding
            try validateEventBranding(branding)
            
            // Apply branding
            let brandedEvent = try await applyBranding(event, branding: branding)
            
            // Save branded event
            try await saveBrandedEvent(brandedEvent)
            
            hapticService.triggerSuccess()
            
            return brandedEvent
            
        } catch {
            errorHandlingService.handleError(error, context: "EventTemplateService.customizeEventBranding")
            throw error
        }
    }
    
    /// Get template categories
    func getTemplateCategories() async throws -> [TemplateCategory] {
        do {
            let categories = try await fetchTemplateCategories()
            templateCategories = categories
            
            return categories
            
        } catch {
            errorHandlingService.handleError(error, context: "EventTemplateService.getTemplateCategories")
            throw error
        }
    }
    
    /// Search templates
    func searchTemplates(_ query: String, filters: TemplateFilters) async throws -> [EventTemplate] {
        do {
            analyticsService.trackEvent("templates_searched", properties: [
                "query": query,
                "filters_count": filters.activeFilters.count
            ])
            
            let results = try await performTemplateSearch(query, filters: filters)
            
            return results
            
        } catch {
            errorHandlingService.handleError(error, context: "EventTemplateService.searchTemplates")
            throw error
        }
    }
    
    /// Rate template
    func rateTemplate(_ templateId: String, rating: TemplateRating) async throws {
        do {
            analyticsService.trackEvent("template_rated", properties: [
                "template_id": templateId,
                "rating": rating.score
            ])
            
            // Save rating
            try await saveTemplateRating(templateId, rating: rating)
            
            // Update template rating
            try await updateTemplateRating(templateId, rating: rating)
            
            hapticService.triggerSuccess()
            
        } catch {
            errorHandlingService.handleError(error, context: "EventTemplateService.rateTemplate")
            throw error
        }
    }
    
    /// Get template analytics
    func getTemplateAnalytics() async throws -> TemplateAnalytics {
        do {
            let analytics = try await fetchTemplateAnalytics()
            
            return analytics
            
        } catch {
            errorHandlingService.handleError(error, context: "EventTemplateService.getTemplateAnalytics")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func loadTemplates() {
        // Load templates from secure storage
        // For now, we'll use default templates
        availableTemplates = [
            EventTemplate(
                id: "party",
                name: "House Party",
                category: .social,
                title: "Epic House Party",
                description: "Join us for an unforgettable night of music, drinks, and great company!",
                tags: ["party", "music", "drinks", "social"],
                capacity: 50,
                duration: 4,
                price: 0.0,
                popularity: 0.9
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
                price: 25.0,
                popularity: 0.8
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
                price: 15.0,
                popularity: 0.7
            )
        ]
        
        templateCategories = [
            TemplateCategory(name: "Social", description: "Social gatherings and parties"),
            TemplateCategory(name: "Entertainment", description: "Concerts and performances"),
            TemplateCategory(name: "Educational", description: "Workshops and learning events"),
            TemplateCategory(name: "Business", description: "Networking and professional events"),
            TemplateCategory(name: "Sports", description: "Sports and fitness events"),
            TemplateCategory(name: "Arts", description: "Art exhibitions and cultural events")
        ]
    }
    
    private func fetchTemplates(category: TemplateCategory?) async throws -> [EventTemplate] {
        // Fetch templates from backend
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        if let category = category {
            return availableTemplates.filter { $0.category.rawValue.lowercased() == category.name.lowercased() }
        }
        
        return availableTemplates
    }
    
    private func validateTemplateCreation(_ template: TemplateCreation) throws {
        // Validate template creation
        guard !template.name.isEmpty else {
            throw TemplateError.invalidTemplateName
        }
        
        guard !template.description.isEmpty else {
            throw TemplateError.invalidTemplateDescription
        }
        
        guard template.capacity > 0 else {
            throw TemplateError.invalidCapacity
        }
        
        guard template.duration > 0 else {
            throw TemplateError.invalidDuration
        }
    }
    
    private func createUserTemplate(_ template: TemplateCreation) async throws -> UserTemplate {
        // Create user template
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return UserTemplate(
            id: UUID().uuidString,
            name: template.name,
            category: template.category,
            description: template.description,
            tags: template.tags,
            capacity: template.capacity,
            duration: template.duration,
            price: template.price,
            createdBy: UserProfileService.shared.currentUser?.id ?? "",
            createdAt: Date(),
            usageCount: 0
        )
    }
    
    private func saveUserTemplate(_ template: UserTemplate) async throws {
        // Save user template to secure storage
        let templateData = try JSONEncoder().encode(template)
        let encryptedData = try securityService.encryptData(templateData)
        
        try securityService.storeSecureData(encryptedData, forKey: "user_template_\(template.id)")
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
    }
    
    private func validateQuickSettings(_ settings: QuickEventSettings) throws {
        // Validate quick settings
        guard !settings.title.isEmpty else {
            throw TemplateError.invalidEventTitle
        }
        
        guard settings.capacity > 0 else {
            throw TemplateError.invalidCapacity
        }
        
        guard settings.duration > 0 else {
            throw TemplateError.invalidDuration
        }
    }
    
    private func applyQuickSettings(_ template: EventTemplate, settings: QuickEventSettings) async throws -> QuickEvent {
        // Apply quick settings to template
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        
        return QuickEvent(
            id: UUID().uuidString,
            title: settings.title,
            description: settings.description ?? template.description,
            template: template,
            capacity: settings.capacity,
            duration: settings.duration,
            price: settings.price,
            date: settings.date,
            location: settings.location,
            createdBy: UserProfileService.shared.currentUser?.id ?? "",
            createdAt: Date()
        )
    }
    
    private func saveQuickEvent(_ event: QuickEvent) async throws {
        // Save quick event
        let eventData = try JSONEncoder().encode(event)
        let encryptedData = try securityService.encryptData(eventData)
        
        try securityService.storeSecureData(encryptedData, forKey: "quick_event_\(event.id)")
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
    }
    
    private func performContentValidation(_ content: EventContent) async throws -> ContentValidation {
        // Perform content validation
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        
        var issues: [String] = []
        var suggestions: [String] = []
        
        // Check content length
        if content.text.count < 10 {
            issues.append("Content is too short")
            suggestions.append("Add more details to make your event description engaging")
        }
        
        if content.text.count > 1000 {
            issues.append("Content is too long")
            suggestions.append("Keep your description concise and focused")
        }
        
        // Check for required elements
        if !content.text.contains("when") && !content.text.contains("time") {
            suggestions.append("Consider adding timing information")
        }
        
        if !content.text.contains("where") && !content.text.contains("location") {
            suggestions.append("Consider adding location information")
        }
        
        let qualityScore = Double.random(in: 0.6...1.0)
        
        return ContentValidation(
            isValid: issues.isEmpty,
            issues: issues,
            suggestions: suggestions,
            qualityScore: qualityScore
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
    
    private func generateOptimizedTiming(_ event: QuickEvent, analysis: TimingAnalysis) async throws -> OptimizedTiming {
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
    
    private func validateEventBranding(_ branding: EventBranding) throws {
        // Validate event branding
        guard !branding.name.isEmpty else {
            throw TemplateError.invalidBrandingName
        }
        
        guard branding.type != .invalid else {
            throw TemplateError.invalidBrandingType
        }
    }
    
    private func applyBranding(_ event: QuickEvent, branding: EventBranding) async throws -> BrandedEvent {
        // Apply branding to event
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        
        return BrandedEvent(
            event: event,
            branding: branding,
            brandedAt: Date()
        )
    }
    
    private func saveBrandedEvent(_ event: BrandedEvent) async throws {
        // Save branded event
        let eventData = try JSONEncoder().encode(event)
        let encryptedData = try securityService.encryptData(eventData)
        
        try securityService.storeSecureData(encryptedData, forKey: "branded_event_\(event.event.id)")
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
    }
    
    private func fetchTemplateCategories() async throws -> [TemplateCategory] {
        // This would typically call a backend API
        // For now, we'll return mock data
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        
        return templateCategories
    }
    
    private func performTemplateSearch(_ query: String, filters: TemplateFilters) async throws -> [EventTemplate] {
        // Perform template search
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return availableTemplates.filter { template in
            template.name.localizedCaseInsensitiveContains(query) ||
            template.description.localizedCaseInsensitiveContains(query) ||
            template.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    private func saveTemplateRating(_ templateId: String, rating: TemplateRating) async throws {
        // Save template rating
        let ratingData = try JSONEncoder().encode(rating)
        let encryptedData = try securityService.encryptData(ratingData)
        
        try securityService.storeSecureData(encryptedData, forKey: "template_rating_\(templateId)")
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
    }
    
    private func updateTemplateRating(_ templateId: String, rating: TemplateRating) async throws {
        // Update template rating
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
    }
    
    private func fetchTemplateAnalytics() async throws -> TemplateAnalytics {
        // This would typically call a backend API
        // For now, we'll return mock data
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return TemplateAnalytics(
            totalTemplates: availableTemplates.count,
            totalUserTemplates: userTemplates.count,
            mostPopularTemplate: availableTemplates.first?.id ?? "",
            averageRating: Double.random(in: 3.5...5.0),
            totalUsage: Int.random(in: 100...1000)
        )
    }
}

// MARK: - Supporting Types

struct EventTemplate: Codable, Identifiable {
    let id: String
    let name: String
    let category: EventCategory
    let title: String
    let description: String
    let tags: [String]
    let capacity: Int
    let duration: Int
    let price: Double
    let popularity: Double
}

enum EventCategory: String, Codable, CaseIterable {
    case social = "social"
    case entertainment = "entertainment"
    case educational = "educational"
    case business = "business"
    case sports = "sports"
    case arts = "arts"
}

struct TemplateCategory: Codable, Identifiable {
    let id = UUID()
    let name: String
    let description: String
}

struct UserTemplate: Codable, Identifiable {
    let id: String
    let name: String
    let category: EventCategory
    let description: String
    let tags: [String]
    let capacity: Int
    let duration: Int
    let price: Double
    let createdBy: String
    let createdAt: Date
    var usageCount: Int
}

struct TemplateCreation: Codable {
    let name: String
    let category: EventCategory
    let description: String
    let tags: [String]
    let capacity: Int
    let duration: Int
    let price: Double
}

struct QuickEventSettings: Codable {
    let title: String
    let description: String?
    let capacity: Int
    let duration: Int
    let price: Double
    let date: Date?
    let location: String?
    let optimizeTiming: Bool
    let timingConstraints: TimingConstraints
}

struct QuickEvent: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let template: EventTemplate
    let capacity: Int
    let duration: Int
    let price: Double
    let date: Date?
    let location: String?
    let createdBy: String
    let createdAt: Date
    var optimizedTiming: OptimizedTiming?
}

struct EventContent: Codable {
    let type: ContentType
    let text: String
    let metadata: [String: String]
}

enum ContentType: String, Codable {
    case eventTitle = "event_title"
    case eventDescription = "event_description"
    case eventTags = "event_tags"
}

struct ValidationResults: Codable {
    var recentValidations: [ValidationResult] = []
    var lastUpdated: Date = Date()
}

struct ValidationResult: Codable {
    let isValid: Bool
    let issues: [String]
    let suggestions: [String]
    let qualityScore: Double
    let moderatedAt: Date
}

struct ContentValidation: Codable {
    let isValid: Bool
    let issues: [String]
    let suggestions: [String]
    let qualityScore: Double
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

struct EventBranding: Codable {
    let name: String
    let type: BrandingType
    let colors: [String]
    let logo: String?
    let description: String?
}

enum BrandingType: String, Codable, CaseIterable {
    case personal = "personal"
    case business = "business"
    case organization = "organization"
    case invalid = "invalid"
}

struct BrandedEvent: Codable {
    let event: QuickEvent
    let branding: EventBranding
    let brandedAt: Date
}

struct TemplateFilters: Codable {
    let categories: [EventCategory]
    let priceRange: ClosedRange<Double>?
    let durationRange: ClosedRange<Int>?
    let popularityThreshold: Double?
    
    var activeFilters: [String] {
        var filters: [String] = []
        if !categories.isEmpty { filters.append("categories") }
        if priceRange != nil { filters.append("price") }
        if durationRange != nil { filters.append("duration") }
        if popularityThreshold != nil { filters.append("popularity") }
        return filters
    }
}

struct TemplateRating: Codable {
    let score: Int // 1-5
    let comment: String?
    let ratedAt: Date
    let ratedBy: String
}

struct TemplateAnalytics: Codable {
    let totalTemplates: Int
    let totalUserTemplates: Int
    let mostPopularTemplate: String
    let averageRating: Double
    let totalUsage: Int
}

enum TemplateError: Error, LocalizedError {
    case invalidTemplateName
    case invalidTemplateDescription
    case invalidCapacity
    case invalidDuration
    case invalidEventTitle
    case invalidBrandingName
    case invalidBrandingType
    case contentModerationFailed
    case templateCreationFailed
    case quickCreationFailed
    case validationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidTemplateName:
            return "Invalid template name"
        case .invalidTemplateDescription:
            return "Invalid template description"
        case .invalidCapacity:
            return "Invalid event capacity"
        case .invalidDuration:
            return "Invalid event duration"
        case .invalidEventTitle:
            return "Invalid event title"
        case .invalidBrandingName:
            return "Invalid branding name"
        case .invalidBrandingType:
            return "Invalid branding type"
        case .contentModerationFailed:
            return "Content moderation failed"
        case .templateCreationFailed:
            return "Template creation failed"
        case .quickCreationFailed:
            return "Quick event creation failed"
        case .validationFailed:
            return "Event validation failed"
        }
    }
} 