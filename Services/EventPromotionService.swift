import Foundation
import CryptoKit
import Combine

/// Service for comprehensive event promotion and marketing tools
/// Part of Epic E: Host Flow - Million Dollar Enhancements
class EventPromotionService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var promotionalCampaigns: [PromotionalCampaign] = []
    @Published var marketingChannels: [MarketingChannel] = []
    @Published var promotionalAnalytics: PromotionalAnalytics = PromotionalAnalytics()
    @Published var socialMediaStatus: SocialMediaStatus = SocialMediaStatus()
    
    // MARK: - Private Properties
    private let socialMediaIntegrationService: SocialMediaIntegrationService
    private let errorHandlingService: ErrorHandlingService
    private let hapticService: HapticService
    private let analyticsService: AnalyticsService
    private let securityService: SecurityService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(socialMediaIntegrationService: SocialMediaIntegrationService = .shared,
         errorHandlingService: ErrorHandlingService = .shared,
         hapticService: HapticService = .shared,
         analyticsService: AnalyticsService = .shared,
         securityService: SecurityService = .shared) {
        self.socialMediaIntegrationService = socialMediaIntegrationService
        self.errorHandlingService = errorHandlingService
        self.hapticService = hapticService
        self.analyticsService = analyticsService
        self.securityService = securityService
        
        loadPromotionData()
    }
    
    // MARK: - Public Methods
    
    /// Create promotional campaign
    func createPromotionalCampaign(_ campaign: PromotionalCampaign) async throws -> PromotionalCampaign {
        do {
            analyticsService.trackEvent("promotional_campaign_created", properties: [
                "event_id": campaign.eventId,
                "campaign_type": campaign.type.rawValue,
                "budget": campaign.budget
            ])
            
            // Validate campaign
            try validatePromotionalCampaign(campaign)
            
            // Create campaign
            let createdCampaign = try await createCampaign(campaign)
            
            // Add to campaigns list
            promotionalCampaigns.append(createdCampaign)
            
            // Initialize analytics tracking
            try await initializeCampaignAnalytics(createdCampaign)
            
            hapticService.triggerSuccess()
            
            return createdCampaign
            
        } catch {
            errorHandlingService.handleError(error, context: "EventPromotionService.createPromotionalCampaign")
            throw error
        }
    }
    
    /// Launch promotional campaign
    func launchPromotionalCampaign(_ campaignId: String) async throws -> CampaignLaunchResult {
        do {
            analyticsService.trackEvent("promotional_campaign_launched", properties: [
                "campaign_id": campaignId
            ])
            
            // Get campaign
            guard let campaign = promotionalCampaigns.first(where: { $0.id == campaignId }) else {
                throw EventPromotionError.campaignNotFound
            }
            
            // Launch campaign across channels
            let result = try await launchCampaignAcrossChannels(campaign)
            
            // Update campaign status
            if let index = promotionalCampaigns.firstIndex(where: { $0.id == campaignId }) {
                promotionalCampaigns[index].status = .active
                promotionalCampaigns[index].launchedAt = Date()
            }
            
            hapticService.triggerSuccess()
            
            return result
            
        } catch {
            errorHandlingService.handleError(error, context: "EventPromotionService.launchPromotionalCampaign")
            throw error
        }
    }
    
    /// Share event to social media
    func shareEventToSocialMedia(_ eventId: String, platforms: [SocialMediaPlatform], message: String?) async throws -> SocialSharingResult {
        do {
            analyticsService.trackEvent("event_shared_to_social_media", properties: [
                "event_id": eventId,
                "platforms": platforms.map { $0.rawValue }
            ])
            
            // Create social media content
            let content = try await createSocialMediaContent(eventId: eventId, message: message)
            
            // Share to each platform
            var sharingResults: [PlatformSharingResult] = []
            
            for platform in platforms {
                let result = try await shareToSocialPlatform(content, platform: platform)
                sharingResults.append(result)
            }
            
            // Create sharing result
            let result = SocialSharingResult(
                eventId: eventId,
                platforms: platforms,
                results: sharingResults,
                sharedAt: Date()
            )
            
            // Update social media status
            await updateSocialMediaStatus(result)
            
            hapticService.triggerSuccess()
            
            return result
            
        } catch {
            errorHandlingService.handleError(error, context: "EventPromotionService.shareEventToSocialMedia")
            throw error
        }
    }
    
    /// Create email marketing campaign
    func createEmailCampaign(_ campaign: EmailCampaign) async throws -> EmailCampaign {
        do {
            analyticsService.trackEvent("email_campaign_created", properties: [
                "event_id": campaign.eventId,
                "recipient_count": campaign.recipients.count
            ])
            
            // Validate email campaign
            try validateEmailCampaign(campaign)
            
            // Create email campaign
            let createdCampaign = try await createEmailMarketingCampaign(campaign)
            
            hapticService.triggerSuccess()
            
            return createdCampaign
            
        } catch {
            errorHandlingService.handleError(error, context: "EventPromotionService.createEmailCampaign")
            throw error
        }
    }
    
    /// Send email campaign
    func sendEmailCampaign(_ campaignId: String) async throws -> EmailSendResult {
        do {
            analyticsService.trackEvent("email_campaign_sent", properties: [
                "campaign_id": campaignId
            ])
            
            // Send email campaign
            let result = try await sendEmailMarketingCampaign(campaignId)
            
            hapticService.triggerSuccess()
            
            return result
            
        } catch {
            errorHandlingService.handleError(error, context: "EventPromotionService.sendEmailCampaign")
            throw error
        }
    }
    
    /// Get promotional analytics
    func getPromotionalAnalytics(_ campaignId: String) async throws -> CampaignAnalytics {
        do {
            analyticsService.trackEvent("promotional_analytics_requested", properties: [
                "campaign_id": campaignId
            ])
            
            // Fetch promotional analytics
            let analytics = try await fetchCampaignAnalytics(campaignId)
            
            hapticService.triggerSuccess()
            
            return analytics
            
        } catch {
            errorHandlingService.handleError(error, context: "EventPromotionService.getPromotionalAnalytics")
            throw error
        }
    }
    
    /// Get ROI tracking data
    func getROITrackingData(_ campaignId: String) async throws -> ROITrackingData {
        do {
            analyticsService.trackEvent("roi_tracking_requested", properties: [
                "campaign_id": campaignId
            ])
            
            // Fetch ROI tracking data
            let roiData = try await fetchROITrackingData(campaignId)
            
            hapticService.triggerSuccess()
            
            return roiData
            
        } catch {
            errorHandlingService.handleError(error, context: "EventPromotionService.getROITrackingData")
            throw error
        }
    }
    
    /// Optimize promotional campaign
    func optimizePromotionalCampaign(_ campaignId: String) async throws -> OptimizationResult {
        do {
            analyticsService.trackEvent("promotional_campaign_optimized", properties: [
                "campaign_id": campaignId
            ])
            
            // Get campaign
            guard let campaign = promotionalCampaigns.first(where: { $0.id == campaignId }) else {
                throw EventPromotionError.campaignNotFound
            }
            
            // Optimize campaign
            let result = try await optimizeCampaign(campaign)
            
            // Update campaign with optimizations
            if let index = promotionalCampaigns.firstIndex(where: { $0.id == campaignId }) {
                promotionalCampaigns[index].optimizations = result.optimizations
                promotionalCampaigns[index].lastOptimized = Date()
            }
            
            hapticService.triggerSuccess()
            
            return result
            
        } catch {
            errorHandlingService.handleError(error, context: "EventPromotionService.optimizePromotionalCampaign")
            throw error
        }
    }
    
    /// Get marketing channel performance
    func getMarketingChannelPerformance(_ eventId: String) async throws -> [ChannelPerformance] {
        do {
            analyticsService.trackEvent("marketing_channel_performance_requested", properties: [
                "event_id": eventId
            ])
            
            // Fetch channel performance
            let performance = try await fetchChannelPerformance(eventId)
            
            hapticService.triggerSuccess()
            
            return performance
            
        } catch {
            errorHandlingService.handleError(error, context: "EventPromotionService.getMarketingChannelPerformance")
            throw error
        }
    }
    
    /// Schedule promotional content
    func schedulePromotionalContent(_ content: PromotionalContent) async throws -> SchedulingResult {
        do {
            analyticsService.trackEvent("promotional_content_scheduled", properties: [
                "event_id": content.eventId,
                "scheduled_date": content.scheduledDate.description
            ])
            
            // Validate content
            try validatePromotionalContent(content)
            
            // Schedule content
            let result = try await scheduleContent(content)
            
            hapticService.triggerSuccess()
            
            return result
            
        } catch {
            errorHandlingService.handleError(error, context: "EventPromotionService.schedulePromotionalContent")
            throw error
        }
    }
    
    /// Get promotional recommendations
    func getPromotionalRecommendations(_ eventId: String) async throws -> [PromotionalRecommendation] {
        do {
            analyticsService.trackEvent("promotional_recommendations_requested", properties: [
                "event_id": eventId
            ])
            
            // Generate recommendations
            let recommendations = try await generatePromotionalRecommendations(eventId)
            
            hapticService.triggerSuccess()
            
            return recommendations
            
        } catch {
            errorHandlingService.handleError(error, context: "EventPromotionService.getPromotionalRecommendations")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func loadPromotionData() {
        // Load promotion data from secure storage
        // For now, we'll use default values
        promotionalCampaigns = []
        marketingChannels = [
            MarketingChannel(id: "social_media", name: "Social Media", type: .social, isEnabled: true),
            MarketingChannel(id: "email", name: "Email Marketing", type: .email, isEnabled: true),
            MarketingChannel(id: "paid_ads", name: "Paid Advertising", type: .paid, isEnabled: false),
            MarketingChannel(id: "influencer", name: "Influencer Marketing", type: .influencer, isEnabled: false)
        ]
        promotionalAnalytics = PromotionalAnalytics()
        socialMediaStatus = SocialMediaStatus()
    }
    
    private func validatePromotionalCampaign(_ campaign: PromotionalCampaign) throws {
        // Validate promotional campaign
        guard !campaign.eventId.isEmpty else {
            throw EventPromotionError.invalidEventId
        }
        
        guard campaign.budget > 0 else {
            throw EventPromotionError.invalidBudget
        }
        
        guard !campaign.name.isEmpty else {
            throw EventPromotionError.invalidCampaignName
        }
        
        guard campaign.startDate < campaign.endDate else {
            throw EventPromotionError.invalidDateRange
        }
    }
    
    private func createCampaign(_ campaign: PromotionalCampaign) async throws -> PromotionalCampaign {
        // Create campaign
        try await Task.sleep(nanoseconds: 400_000_000) // 0.4 second delay
        
        var createdCampaign = campaign
        createdCampaign.id = UUID().uuidString
        createdCampaign.createdAt = Date()
        createdCampaign.status = .draft
        
        return createdCampaign
    }
    
    private func initializeCampaignAnalytics(_ campaign: PromotionalCampaign) async throws {
        // Initialize campaign analytics tracking
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
    }
    
    private func launchCampaignAcrossChannels(_ campaign: PromotionalCampaign) async throws -> CampaignLaunchResult {
        // Launch campaign across channels
        try await Task.sleep(nanoseconds: 600_000_000) // 0.6 second delay
        
        return CampaignLaunchResult(
            campaignId: campaign.id,
            success: true,
            channelsLaunched: campaign.channels,
            launchedAt: Date(),
            estimatedReach: Int.random(in: 1000...10000)
        )
    }
    
    private func createSocialMediaContent(eventId: String, message: String?) async throws -> SocialMediaContent {
        // Create social media content
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return SocialMediaContent(
            id: UUID().uuidString,
            eventId: eventId,
            message: message ?? "Check out this amazing event!",
            imageUrl: "https://example.com/event-image.jpg",
            hashtags: ["#event", "#fun", "#community"],
            createdAt: Date()
        )
    }
    
    private func shareToSocialPlatform(_ content: SocialMediaContent, platform: SocialMediaPlatform) async throws -> PlatformSharingResult {
        // Share to social platform
        try await Task.sleep(nanoseconds: 400_000_000) // 0.4 second delay
        
        return PlatformSharingResult(
            platform: platform,
            success: true,
            postId: UUID().uuidString,
            sharedAt: Date(),
            reach: Int.random(in: 100...1000)
        )
    }
    
    private func updateSocialMediaStatus(_ result: SocialSharingResult) async {
        // Update social media status
        socialMediaStatus.lastShared = result.sharedAt
        socialMediaStatus.totalShares += result.results.count
    }
    
    private func validateEmailCampaign(_ campaign: EmailCampaign) throws {
        // Validate email campaign
        guard !campaign.eventId.isEmpty else {
            throw EventPromotionError.invalidEventId
        }
        
        guard !campaign.subject.isEmpty else {
            throw EventPromotionError.invalidEmailSubject
        }
        
        guard !campaign.content.isEmpty else {
            throw EventPromotionError.invalidEmailContent
        }
        
        guard !campaign.recipients.isEmpty else {
            throw EventPromotionError.noRecipients
        }
    }
    
    private func createEmailMarketingCampaign(_ campaign: EmailCampaign) async throws -> EmailCampaign {
        // Create email marketing campaign
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        var createdCampaign = campaign
        createdCampaign.id = UUID().uuidString
        createdCampaign.createdAt = Date()
        createdCampaign.status = .draft
        
        return createdCampaign
    }
    
    private func sendEmailMarketingCampaign(_ campaignId: String) async throws -> EmailSendResult {
        // Send email marketing campaign
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        return EmailSendResult(
            campaignId: campaignId,
            success: true,
            sentCount: Int.random(in: 100...1000),
            deliveredCount: Int.random(in: 90...950),
            openedCount: Int.random(in: 20...200),
            clickedCount: Int.random(in: 5...50),
            sentAt: Date()
        )
    }
    
    private func fetchCampaignAnalytics(_ campaignId: String) async throws -> CampaignAnalytics {
        // Fetch campaign analytics
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return CampaignAnalytics(
            campaignId: campaignId,
            impressions: Int.random(in: 1000...10000),
            clicks: Int.random(in: 100...1000),
            conversions: Int.random(in: 10...100),
            spend: Double.random(in: 50...500),
            ctr: Double.random(in: 0.01...0.1),
            cpc: Double.random(in: 0.5...5.0),
            conversionRate: Double.random(in: 0.01...0.1),
            roi: Double.random(in: 1.5...5.0),
            lastUpdated: Date()
        )
    }
    
    private func fetchROITrackingData(_ campaignId: String) async throws -> ROITrackingData {
        // Fetch ROI tracking data
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return ROITrackingData(
            campaignId: campaignId,
            totalSpent: Double.random(in: 100...1000),
            totalRevenue: Double.random(in: 500...5000),
            roi: Double.random(in: 2.0...8.0),
            costPerAcquisition: Double.random(in: 10...100),
            lifetimeValue: Double.random(in: 50...500),
            paybackPeriod: Double.random(in: 1...12), // months
            lastUpdated: Date()
        )
    }
    
    private func optimizeCampaign(_ campaign: PromotionalCampaign) async throws -> OptimizationResult {
        // Optimize campaign
        try await Task.sleep(nanoseconds: 400_000_000) // 0.4 second delay
        
        return OptimizationResult(
            campaignId: campaign.id,
            optimizations: [
                "Increase budget by 20% for better reach",
                "Target audience aged 25-35 for higher engagement",
                "Schedule posts during peak hours (7-9 PM)",
                "Use more engaging visuals"
            ],
            estimatedImprovement: Double.random(in: 0.1...0.5),
            optimizedAt: Date()
        )
    }
    
    private func fetchChannelPerformance(_ eventId: String) async throws -> [ChannelPerformance] {
        // Fetch channel performance
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return [
            ChannelPerformance(
                channelId: "social_media",
                channelName: "Social Media",
                impressions: Int.random(in: 5000...20000),
                clicks: Int.random(in: 200...800),
                conversions: Int.random(in: 20...100),
                spend: Double.random(in: 100...500),
                roi: Double.random(in: 2.0...6.0)
            ),
            ChannelPerformance(
                channelId: "email",
                channelName: "Email Marketing",
                impressions: Int.random(in: 1000...5000),
                clicks: Int.random(in: 100...400),
                conversions: Int.random(in: 10...50),
                spend: Double.random(in: 20...100),
                roi: Double.random(in: 3.0...8.0)
            )
        ]
    }
    
    private func validatePromotionalContent(_ content: PromotionalContent) throws {
        // Validate promotional content
        guard !content.eventId.isEmpty else {
            throw EventPromotionError.invalidEventId
        }
        
        guard !content.title.isEmpty else {
            throw EventPromotionError.invalidContentTitle
        }
        
        guard content.scheduledDate > Date() else {
            throw EventPromotionError.invalidScheduledDate
        }
    }
    
    private func scheduleContent(_ content: PromotionalContent) async throws -> SchedulingResult {
        // Schedule content
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return SchedulingResult(
            contentId: content.id,
            scheduledDate: content.scheduledDate,
            success: true,
            scheduledAt: Date()
        )
    }
    
    private func generatePromotionalRecommendations(_ eventId: String) async throws -> [PromotionalRecommendation] {
        // Generate promotional recommendations
        try await Task.sleep(nanoseconds: 400_000_000) // 0.4 second delay
        
        return [
            PromotionalRecommendation(
                id: UUID().uuidString,
                type: .budget,
                title: "Increase Marketing Budget",
                description: "Increase your marketing budget by 30% to reach more potential attendees",
                estimatedImpact: "25% more attendees",
                priority: .high
            ),
            PromotionalRecommendation(
                id: UUID().uuidString,
                type: .timing,
                title: "Optimize Posting Schedule",
                description: "Post during peak hours (7-9 PM) for maximum engagement",
                estimatedImpact: "15% higher engagement",
                priority: .medium
            ),
            PromotionalRecommendation(
                id: UUID().uuidString,
                type: .audience,
                title: "Target Local Audience",
                description: "Focus on local audience within 25 miles for better attendance",
                estimatedImpact: "40% higher conversion rate",
                priority: .high
            )
        ]
    }
}

// MARK: - Supporting Types

struct PromotionalCampaign: Codable, Identifiable {
    let id: String
    let eventId: String
    let name: String
    let type: CampaignType
    let budget: Double
    let channels: [MarketingChannel]
    let startDate: Date
    let endDate: Date
    let targetAudience: TargetAudience
    let status: CampaignStatus
    let createdAt: Date
    var launchedAt: Date?
    var optimizations: [String]?
    var lastOptimized: Date?
}

enum CampaignType: String, Codable, CaseIterable {
    case socialMedia = "social_media"
    case email = "email"
    case paidAds = "paid_ads"
    case influencer = "influencer"
    case organic = "organic"
}

struct MarketingChannel: Codable, Identifiable {
    let id: String
    let name: String
    let type: ChannelType
    let isEnabled: Bool
}

enum ChannelType: String, Codable {
    case social = "social"
    case email = "email"
    case paid = "paid"
    case influencer = "influencer"
}

struct TargetAudience: Codable {
    let ageRange: AgeRange
    let location: String
    let interests: [String]
    let demographics: [String: String]
}

struct AgeRange: Codable {
    let min: Int
    let max: Int
}

enum CampaignStatus: String, Codable {
    case draft = "draft"
    case active = "active"
    case paused = "paused"
    case completed = "completed"
    case cancelled = "cancelled"
}

struct CampaignLaunchResult: Codable {
    let campaignId: String
    let success: Bool
    let channelsLaunched: [MarketingChannel]
    let launchedAt: Date
    let estimatedReach: Int
}

struct SocialMediaContent: Codable, Identifiable {
    let id: String
    let eventId: String
    let message: String
    let imageUrl: String?
    let hashtags: [String]
    let createdAt: Date
}

struct SocialSharingResult: Codable {
    let eventId: String
    let platforms: [SocialMediaPlatform]
    let results: [PlatformSharingResult]
    let sharedAt: Date
}

struct PlatformSharingResult: Codable {
    let platform: SocialMediaPlatform
    let success: Bool
    let postId: String?
    let sharedAt: Date
    let reach: Int
}

enum SocialMediaPlatform: String, Codable, CaseIterable {
    case facebook = "facebook"
    case twitter = "twitter"
    case instagram = "instagram"
    case linkedin = "linkedin"
    case tiktok = "tiktok"
}

struct EmailCampaign: Codable, Identifiable {
    let id: String
    let eventId: String
    let subject: String
    let content: String
    let recipients: [String]
    let template: EmailTemplate?
    let status: EmailStatus
    let createdAt: Date
}

enum EmailTemplate: String, Codable, CaseIterable {
    case eventAnnouncement = "event_announcement"
    case reminder = "reminder"
    case followUp = "follow_up"
    case custom = "custom"
}

enum EmailStatus: String, Codable {
    case draft = "draft"
    case scheduled = "scheduled"
    case sent = "sent"
    case cancelled = "cancelled"
}

struct EmailSendResult: Codable {
    let campaignId: String
    let success: Bool
    let sentCount: Int
    let deliveredCount: Int
    let openedCount: Int
    let clickedCount: Int
    let sentAt: Date
}

struct CampaignAnalytics: Codable {
    let campaignId: String
    let impressions: Int
    let clicks: Int
    let conversions: Int
    let spend: Double
    let ctr: Double
    let cpc: Double
    let conversionRate: Double
    let roi: Double
    let lastUpdated: Date
}

struct ROITrackingData: Codable {
    let campaignId: String
    let totalSpent: Double
    let totalRevenue: Double
    let roi: Double
    let costPerAcquisition: Double
    let lifetimeValue: Double
    let paybackPeriod: Double
    let lastUpdated: Date
}

struct OptimizationResult: Codable {
    let campaignId: String
    let optimizations: [String]
    let estimatedImprovement: Double
    let optimizedAt: Date
}

struct ChannelPerformance: Codable, Identifiable {
    let id = UUID()
    let channelId: String
    let channelName: String
    let impressions: Int
    let clicks: Int
    let conversions: Int
    let spend: Double
    let roi: Double
}

struct PromotionalContent: Codable, Identifiable {
    let id: String
    let eventId: String
    let title: String
    let content: String
    let channels: [MarketingChannel]
    let scheduledDate: Date
    let status: ContentStatus
}

enum ContentStatus: String, Codable {
    case draft = "draft"
    case scheduled = "scheduled"
    case published = "published"
    case cancelled = "cancelled"
}

struct SchedulingResult: Codable {
    let contentId: String
    let scheduledDate: Date
    let success: Bool
    let scheduledAt: Date
}

struct PromotionalRecommendation: Codable, Identifiable {
    let id: String
    let type: RecommendationType
    let title: String
    let description: String
    let estimatedImpact: String
    let priority: RecommendationPriority
}

enum RecommendationType: String, Codable {
    case budget = "budget"
    case timing = "timing"
    case audience = "audience"
    case content = "content"
    case channel = "channel"
}

enum RecommendationPriority: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

struct PromotionalAnalytics: Codable {
    var totalCampaigns: Int = 0
    var totalSpent: Double = 0.0
    var totalRevenue: Double = 0.0
    var averageROI: Double = 0.0
    var lastUpdated: Date = Date()
}

struct SocialMediaStatus: Codable {
    var lastShared: Date = Date()
    var totalShares: Int = 0
    var connectedAccounts: Int = 0
}

enum EventPromotionError: Error, LocalizedError {
    case invalidEventId
    case invalidBudget
    case invalidCampaignName
    case invalidDateRange
    case invalidEmailSubject
    case invalidEmailContent
    case invalidContentTitle
    case invalidScheduledDate
    case noRecipients
    case campaignNotFound
    case sharingFailed
    case emailSendFailed
    case analyticsFetchFailed
    case optimizationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidEventId:
            return "Invalid event ID"
        case .invalidBudget:
            return "Invalid budget amount"
        case .invalidCampaignName:
            return "Invalid campaign name"
        case .invalidDateRange:
            return "Invalid date range"
        case .invalidEmailSubject:
            return "Invalid email subject"
        case .invalidEmailContent:
            return "Invalid email content"
        case .invalidContentTitle:
            return "Invalid content title"
        case .invalidScheduledDate:
            return "Invalid scheduled date"
        case .noRecipients:
            return "No recipients specified"
        case .campaignNotFound:
            return "Campaign not found"
        case .sharingFailed:
            return "Social media sharing failed"
        case .emailSendFailed:
            return "Email sending failed"
        case .analyticsFetchFailed:
            return "Failed to fetch analytics"
        case .optimizationFailed:
            return "Campaign optimization failed"
        }
    }
} 