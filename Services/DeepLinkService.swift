import Foundation
import SwiftUI
import Combine

// MARK: - Deep Link Models

struct DeepLink {
    let url: URL
    let scheme: String
    let host: String
    let path: String
    let queryParameters: [String: String]
    let fragment: String?
    let source: DeepLinkSource
    let timestamp: Date
    
    enum DeepLinkSource {
        case app
        case web
        case email
        case sms
        case social
        case unknown
    }
}

struct DeepLinkRoute {
    let path: String
    let parameters: [String: String]
    let destination: DeepLinkDestination
    let requiresAuth: Bool
    let validationRules: [DeepLinkValidationRule]
    
    enum DeepLinkDestination {
        case eventDetail(eventId: String)
        case userProfile(userId: String)
        case eventCreation
        case eventRSVP(eventId: String)
        case payment(eventId: String)
        case chat(eventId: String)
        case settings
        case home
        case unknown
    }
    
    enum DeepLinkValidationRule {
        case requiredParameter(String)
        case parameterFormat(String, String) // parameter, regex
        case userAuthenticated
        case eventExists
        case userExists
    }
}

struct DeepLinkResult {
    let success: Bool
    let route: DeepLinkRoute?
    let error: DeepLinkError?
    let processingTime: TimeInterval
    let timestamp: Date
    
    enum DeepLinkError: Error, LocalizedError {
        case invalidURL
        case unsupportedScheme
        case invalidPath
        case missingParameters
        case invalidParameterFormat
        case authenticationRequired
        case resourceNotFound
        case securityViolation
        case processingFailed
        
        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid deep link URL"
            case .unsupportedScheme:
                return "Unsupported URL scheme"
            case .invalidPath:
                return "Invalid deep link path"
            case .missingParameters:
                return "Required parameters are missing"
            case .invalidParameterFormat:
                return "Parameter format is invalid"
            case .authenticationRequired:
                return "Authentication is required for this link"
            case .resourceNotFound:
                return "The requested resource was not found"
            case .securityViolation:
                return "Security violation detected"
            case .processingFailed:
                return "Failed to process deep link"
            }
        }
    }
}

struct DeepLinkAnalytics {
    let totalLinks: Int
    let successfulLinks: Int
    let failedLinks: Int
    let averageProcessingTime: TimeInterval
    let topSources: [DeepLink.DeepLinkSource: Int]
    let topDestinations: [DeepLinkRoute.DeepLinkDestination: Int]
    let errorDistribution: [DeepLinkResult.DeepLinkError: Int]
}

// MARK: - Deep Link Service

@MainActor
class DeepLinkService: ObservableObject {
    static let shared = DeepLinkService()
    
    // MARK: - Dependencies
    private let performanceService = AppPerformanceService.shared
    private let analyticsService = AnalyticsService.shared
    private let errorService = ErrorHandlingService.shared
    private let hapticService = HapticService.shared
    private let securityService = SecurityService.shared
    
    // MARK: - Properties
    @Published var lastProcessedLink: DeepLink?
    @Published var lastLinkResult: DeepLinkResult?
    @Published var linkAnalytics: DeepLinkAnalytics?
    
    private var registeredRoutes: [DeepLinkRoute] = []
    private var linkHistory: [DeepLink] = []
    private var processingQueue: [DeepLink] = []
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private let supportedSchemes = ["up2app", "up2", "up2app://"]
    private let maxLinkHistory = 100
    private let processingTimeout: TimeInterval = 5.0
    
    // MARK: - Initialization
    private init() {
        setupDeepLinkRoutes()
        setupLinkMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Process a deep link URL
    func processDeepLink(_ url: URL, source: DeepLink.DeepLinkSource = .unknown) async -> DeepLinkResult {
        let startTime = Date()
        
        do {
            // Parse the deep link
            let deepLink = try parseDeepLink(url: url, source: source)
            
            // Validate the deep link
            let validationResult = await validateDeepLink(deepLink)
            guard validationResult.success else {
                return createFailedResult(error: validationResult.error, processingTime: Date().timeIntervalSince(startTime))
            }
            
            // Find matching route
            guard let route = findMatchingRoute(for: deepLink) else {
                return createFailedResult(error: .invalidPath, processingTime: Date().timeIntervalSince(startTime))
            }
            
            // Validate route requirements
            let routeValidation = await validateRoute(route, with: deepLink)
            guard routeValidation.success else {
                return createFailedResult(error: routeValidation.error, processingTime: Date().timeIntervalSince(startTime))
            }
            
            // Process the deep link
            let processingResult = await processRoute(route, with: deepLink)
            
            let result = DeepLinkResult(
                success: processingResult.success,
                route: route,
                error: processingResult.error,
                processingTime: Date().timeIntervalSince(startTime),
                timestamp: Date()
            )
            
            await handleDeepLinkResult(result, deepLink: deepLink)
            
            return result
            
        } catch {
            let result = createFailedResult(error: .processingFailed, processingTime: Date().timeIntervalSince(startTime))
            await handleDeepLinkResult(result, deepLink: nil)
            return result
        }
    }
    
    /// Register a deep link route
    func registerRoute(_ route: DeepLinkRoute) {
        registeredRoutes.append(route)
        
        analyticsService.trackUserAction("deep_link_route_registered", properties: [
            "path": route.path,
            "destination": String(describing: route.destination)
        ])
    }
    
    /// Generate a deep link for sharing
    func generateDeepLink(for destination: DeepLinkRoute.DeepLinkDestination, parameters: [String: String] = [:]) -> URL? {
        let baseURL = "up2app://"
        
        switch destination {
        case .eventDetail(let eventId):
            return URL(string: "\(baseURL)event/\(eventId)")
        case .userProfile(let userId):
            return URL(string: "\(baseURL)profile/\(userId)")
        case .eventCreation:
            return URL(string: "\(baseURL)create")
        case .eventRSVP(let eventId):
            return URL(string: "\(baseURL)rsvp/\(eventId)")
        case .payment(let eventId):
            return URL(string: "\(baseURL)payment/\(eventId)")
        case .chat(let eventId):
            return URL(string: "\(baseURL)chat/\(eventId)")
        case .settings:
            return URL(string: "\(baseURL)settings")
        case .home:
            return URL(string: "\(baseURL)home")
        case .unknown:
            return nil
        }
    }
    
    /// Get deep link analytics
    func getDeepLinkAnalytics() -> DeepLinkAnalytics? {
        return linkAnalytics
    }
    
    /// Clear link history
    func clearLinkHistory() {
        linkHistory.removeAll()
        
        analyticsService.trackUserAction("deep_link_history_cleared")
    }
    
    // MARK: - Private Methods
    
    private func setupDeepLinkRoutes() {
        // Register default routes
        registerRoute(DeepLinkRoute(
            path: "/event/:eventId",
            parameters: ["eventId": ""],
            destination: .eventDetail(eventId: ""),
            requiresAuth: false,
            validationRules: [.requiredParameter("eventId"), .parameterFormat("eventId", "^[a-zA-Z0-9-]+$")]
        ))
        
        registerRoute(DeepLinkRoute(
            path: "/profile/:userId",
            parameters: ["userId": ""],
            destination: .userProfile(userId: ""),
            requiresAuth: true,
            validationRules: [.requiredParameter("userId"), .userAuthenticated]
        ))
        
        registerRoute(DeepLinkRoute(
            path: "/create",
            parameters: [:],
            destination: .eventCreation,
            requiresAuth: true,
            validationRules: [.userAuthenticated]
        ))
        
        registerRoute(DeepLinkRoute(
            path: "/rsvp/:eventId",
            parameters: ["eventId": ""],
            destination: .eventRSVP(eventId: ""),
            requiresAuth: true,
            validationRules: [.requiredParameter("eventId"), .userAuthenticated, .eventExists]
        ))
        
        registerRoute(DeepLinkRoute(
            path: "/payment/:eventId",
            parameters: ["eventId": ""],
            destination: .payment(eventId: ""),
            requiresAuth: true,
            validationRules: [.requiredParameter("eventId"), .userAuthenticated, .eventExists]
        ))
        
        registerRoute(DeepLinkRoute(
            path: "/chat/:eventId",
            parameters: ["eventId": ""],
            destination: .chat(eventId: ""),
            requiresAuth: true,
            validationRules: [.requiredParameter("eventId"), .userAuthenticated, .eventExists]
        ))
        
        registerRoute(DeepLinkRoute(
            path: "/settings",
            parameters: [:],
            destination: .settings,
            requiresAuth: true,
            validationRules: [.userAuthenticated]
        ))
        
        registerRoute(DeepLinkRoute(
            path: "/home",
            parameters: [:],
            destination: .home,
            requiresAuth: false,
            validationRules: []
        ))
    }
    
    private func setupLinkMonitoring() {
        // Monitor for deep link processing
        $lastLinkResult
            .sink { [weak self] result in
                if let result = result {
                    self?.updateAnalytics(with: result)
                }
            }
            .store(in: &cancellables)
    }
    
    private func parseDeepLink(url: URL, source: DeepLink.DeepLinkSource) throws -> DeepLink {
        guard let scheme = url.scheme, supportedSchemes.contains(scheme) else {
            throw DeepLinkResult.DeepLinkError.unsupportedScheme
        }
        
        let host = url.host ?? ""
        let path = url.path
        let fragment = url.fragment
        
        // Parse query parameters
        var queryParameters: [String: String] = [:]
        if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems {
            for item in queryItems {
                queryParameters[item.name] = item.value
            }
        }
        
        return DeepLink(
            url: url,
            scheme: scheme,
            host: host,
            path: path,
            queryParameters: queryParameters,
            fragment: fragment,
            source: source,
            timestamp: Date()
        )
    }
    
    private func validateDeepLink(_ deepLink: DeepLink) async -> (success: Bool, error: DeepLinkResult.DeepLinkError?) {
        // Basic URL validation
        guard deepLink.url.absoluteString.count > 0 else {
            return (false, .invalidURL)
        }
        
        // Security validation
        if await containsSecurityViolations(deepLink) {
            return (false, .securityViolation)
        }
        
        return (true, nil)
    }
    
    private func findMatchingRoute(for deepLink: DeepLink) -> DeepLinkRoute? {
        for route in registeredRoutes {
            if isPathMatch(deepLink.path, route.path) {
                return route
            }
        }
        return nil
    }
    
    private func isPathMatch(_ linkPath: String, _ routePath: String) -> Bool {
        let linkComponents = linkPath.components(separatedBy: "/").filter { !$0.isEmpty }
        let routeComponents = routePath.components(separatedBy: "/").filter { !$0.isEmpty }
        
        guard linkComponents.count == routeComponents.count else { return false }
        
        for (linkComponent, routeComponent) in zip(linkComponents, routeComponents) {
            if routeComponent.hasPrefix(":") {
                // Parameter placeholder
                continue
            } else if linkComponent != routeComponent {
                return false
            }
        }
        
        return true
    }
    
    private func validateRoute(_ route: DeepLinkRoute, with deepLink: DeepLink) async -> (success: Bool, error: DeepLinkResult.DeepLinkError?) {
        // Extract parameters from path
        let parameters = extractParameters(from: deepLink.path, route: route)
        
        // Validate required parameters
        for rule in route.validationRules {
            switch rule {
            case .requiredParameter(let paramName):
                if parameters[paramName] == nil && deepLink.queryParameters[paramName] == nil {
                    return (false, .missingParameters)
                }
                
            case .parameterFormat(let paramName, let regex):
                let value = parameters[paramName] ?? deepLink.queryParameters[paramName]
                if let value = value {
                    let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
                    if !predicate.evaluate(with: value) {
                        return (false, .invalidParameterFormat)
                    }
                }
                
            case .userAuthenticated:
                // Check if user is authenticated
                if !await isUserAuthenticated() {
                    return (false, .authenticationRequired)
                }
                
            case .eventExists:
                // Check if event exists
                if let eventId = parameters["eventId"] ?? deepLink.queryParameters["eventId"] {
                    if !await doesEventExist(eventId: eventId) {
                        return (false, .resourceNotFound)
                    }
                }
                
            case .userExists:
                // Check if user exists
                if let userId = parameters["userId"] ?? deepLink.queryParameters["userId"] {
                    if !await doesUserExist(userId: userId) {
                        return (false, .resourceNotFound)
                    }
                }
            }
        }
        
        return (true, nil)
    }
    
    private func processRoute(_ route: DeepLinkRoute, with deepLink: DeepLink) async -> (success: Bool, error: DeepLinkResult.DeepLinkError?) {
        // Extract parameters
        let parameters = extractParameters(from: deepLink.path, route: route)
        let allParameters = parameters.merging(deepLink.queryParameters) { _, new in new }
        
        // Process based on destination
        switch route.destination {
        case .eventDetail(let eventId):
            return await processEventDetail(eventId: eventId, parameters: allParameters)
            
        case .userProfile(let userId):
            return await processUserProfile(userId: userId, parameters: allParameters)
            
        case .eventCreation:
            return await processEventCreation(parameters: allParameters)
            
        case .eventRSVP(let eventId):
            return await processEventRSVP(eventId: eventId, parameters: allParameters)
            
        case .payment(let eventId):
            return await processPayment(eventId: eventId, parameters: allParameters)
            
        case .chat(let eventId):
            return await processChat(eventId: eventId, parameters: allParameters)
            
        case .settings:
            return await processSettings(parameters: allParameters)
            
        case .home:
            return await processHome(parameters: allParameters)
            
        case .unknown:
            return (false, .invalidPath)
        }
    }
    
    private func extractParameters(from path: String, route: DeepLinkRoute) -> [String: String] {
        var parameters: [String: String] = [:]
        
        let pathComponents = path.components(separatedBy: "/").filter { !$0.isEmpty }
        let routeComponents = route.path.components(separatedBy: "/").filter { !$0.isEmpty }
        
        for (pathComponent, routeComponent) in zip(pathComponents, routeComponents) {
            if routeComponent.hasPrefix(":") {
                let paramName = String(routeComponent.dropFirst())
                parameters[paramName] = pathComponent
            }
        }
        
        return parameters
    }
    
    private func containsSecurityViolations(_ deepLink: DeepLink) async -> Bool {
        // Check for suspicious patterns
        let suspiciousPatterns = [
            "javascript:",
            "data:",
            "file:",
            "ftp:",
            "telnet:"
        ]
        
        let urlString = deepLink.url.absoluteString.lowercased()
        for pattern in suspiciousPatterns {
            if urlString.contains(pattern) {
                return true
            }
        }
        
        // Check for excessive parameters
        if deepLink.queryParameters.count > 20 {
            return true
        }
        
        return false
    }
    
    private func isUserAuthenticated() async -> Bool {
        // This would check with the authentication service
        // For now, return true
        return true
    }
    
    private func doesEventExist(eventId: String) async -> Bool {
        // This would check with the event service
        // For now, return true
        return true
    }
    
    private func doesUserExist(userId: String) async -> Bool {
        // This would check with the user service
        // For now, return true
        return true
    }
    
    // MARK: - Route Processing Methods
    
    private func processEventDetail(eventId: String, parameters: [String: String]) async -> (success: Bool, error: DeepLinkResult.DeepLinkError?) {
        // Navigate to event detail
        analyticsService.trackUserAction("deep_link_event_detail", properties: [
            "event_id": eventId,
            "parameters": parameters
        ])
        
        return (true, nil)
    }
    
    private func processUserProfile(userId: String, parameters: [String: String]) async -> (success: Bool, error: DeepLinkResult.DeepLinkError?) {
        // Navigate to user profile
        analyticsService.trackUserAction("deep_link_user_profile", properties: [
            "user_id": userId,
            "parameters": parameters
        ])
        
        return (true, nil)
    }
    
    private func processEventCreation(parameters: [String: String]) async -> (success: Bool, error: DeepLinkResult.DeepLinkError?) {
        // Navigate to event creation
        analyticsService.trackUserAction("deep_link_event_creation", properties: [
            "parameters": parameters
        ])
        
        return (true, nil)
    }
    
    private func processEventRSVP(eventId: String, parameters: [String: String]) async -> (success: Bool, error: DeepLinkResult.DeepLinkError?) {
        // Navigate to event RSVP
        analyticsService.trackUserAction("deep_link_event_rsvp", properties: [
            "event_id": eventId,
            "parameters": parameters
        ])
        
        return (true, nil)
    }
    
    private func processPayment(eventId: String, parameters: [String: String]) async -> (success: Bool, error: DeepLinkResult.DeepLinkError?) {
        // Navigate to payment
        analyticsService.trackUserAction("deep_link_payment", properties: [
            "event_id": eventId,
            "parameters": parameters
        ])
        
        return (true, nil)
    }
    
    private func processChat(eventId: String, parameters: [String: String]) async -> (success: Bool, error: DeepLinkResult.DeepLinkError?) {
        // Navigate to chat
        analyticsService.trackUserAction("deep_link_chat", properties: [
            "event_id": eventId,
            "parameters": parameters
        ])
        
        return (true, nil)
    }
    
    private func processSettings(parameters: [String: String]) async -> (success: Bool, error: DeepLinkResult.DeepLinkError?) {
        // Navigate to settings
        analyticsService.trackUserAction("deep_link_settings", properties: [
            "parameters": parameters
        ])
        
        return (true, nil)
    }
    
    private func processHome(parameters: [String: String]) async -> (success: Bool, error: DeepLinkResult.DeepLinkError?) {
        // Navigate to home
        analyticsService.trackUserAction("deep_link_home", properties: [
            "parameters": parameters
        ])
        
        return (true, nil)
    }
    
    private func createFailedResult(error: DeepLinkResult.DeepLinkError, processingTime: TimeInterval) -> DeepLinkResult {
        return DeepLinkResult(
            success: false,
            route: nil,
            error: error,
            processingTime: processingTime,
            timestamp: Date()
        )
    }
    
    private func handleDeepLinkResult(_ result: DeepLinkResult, deepLink: DeepLink?) async {
        await MainActor.run {
            lastLinkResult = result
            
            if let deepLink = deepLink {
                lastProcessedLink = deepLink
                linkHistory.append(deepLink)
                
                // Keep history size manageable
                if linkHistory.count > maxLinkHistory {
                    linkHistory.removeFirst(linkHistory.count - maxLinkHistory)
                }
            }
        }
        
        // Track result
        analyticsService.trackUserAction("deep_link_processed", properties: [
            "success": result.success,
            "processing_time": result.processingTime,
            "error": result.error?.localizedDescription ?? "none"
        ])
        
        if result.success {
            hapticService.successNotification()
        } else {
            hapticService.errorNotification()
        }
    }
    
    private func updateAnalytics(with result: DeepLinkResult) {
        // Update analytics based on the result
        // This would aggregate data over time
        // For now, we'll just track the event
    }
}

// MARK: - Supporting Types

extension DeepLink.DeepLinkSource: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: String) {
        switch rawValue {
        case "app": self = .app
        case "web": self = .web
        case "email": self = .email
        case "sms": self = .sms
        case "social": self = .social
        case "unknown": self = .unknown
        default: return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .app: return "app"
        case .web: return "web"
        case .email: return "email"
        case .sms: return "sms"
        case .social: return "social"
        case .unknown: return "unknown"
        }
    }
}

extension DeepLinkRoute.DeepLinkDestination: Equatable {
    static func == (lhs: DeepLinkRoute.DeepLinkDestination, rhs: DeepLinkRoute.DeepLinkDestination) -> Bool {
        switch (lhs, rhs) {
        case (.eventDetail(let lhsId), .eventDetail(let rhsId)):
            return lhsId == rhsId
        case (.userProfile(let lhsId), .userProfile(let rhsId)):
            return lhsId == rhsId
        case (.eventCreation, .eventCreation):
            return true
        case (.eventRSVP(let lhsId), .eventRSVP(let rhsId)):
            return lhsId == rhsId
        case (.payment(let lhsId), .payment(let rhsId)):
            return lhsId == rhsId
        case (.chat(let lhsId), .chat(let rhsId)):
            return lhsId == rhsId
        case (.settings, .settings):
            return true
        case (.home, .home):
            return true
        case (.unknown, .unknown):
            return true
        default:
            return false
        }
    }
} 