import Foundation
import Combine
import UIKit

/// Comprehensive analytics service for tracking user behavior, app performance, and business metrics
class AnalyticsService: ObservableObject {
    static let shared = AnalyticsService()
    
    @Published var isAnalyticsEnabled: Bool = true
    @Published var currentSession: AnalyticsSession?
    
    private var sessionStartTime: Date?
    private var eventQueue: [AnalyticsEvent] = []
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        startNewSession()
        setupPeriodicFlush()
    }
    
    // MARK: - Session Management
    
    func startNewSession() {
        sessionStartTime = Date()
        currentSession = AnalyticsSession(
            id: UUID().uuidString,
            startTime: sessionStartTime!,
            deviceInfo: DeviceInfo.current
        )
        
        trackEvent(.sessionStart, properties: [
            "session_id": currentSession?.id ?? "",
            "device_model": DeviceInfo.current.model,
            "os_version": DeviceInfo.current.osVersion,
            "app_version": DeviceInfo.current.appVersion
        ])
    }
    
    func endCurrentSession() {
        guard let session = currentSession, let startTime = sessionStartTime else { return }
        
        let sessionDuration = Date().timeIntervalSince(startTime)
        
        trackEvent(.sessionEnd, properties: [
            "session_id": session.id,
            "duration_seconds": sessionDuration,
            "events_count": eventQueue.count
        ])
        
        flushEvents()
        currentSession = nil
        sessionStartTime = nil
    }
    
    // MARK: - Event Tracking
    
    func trackEvent(_ event: AnalyticsEventType, properties: [String: Any] = [:]) {
        guard isAnalyticsEnabled else { return }
        
        let analyticsEvent = AnalyticsEvent(
            type: event,
            properties: properties,
            timestamp: Date(),
            sessionId: currentSession?.id
        )
        
        eventQueue.append(analyticsEvent)
        
        #if DEBUG
        print("📊 Analytics Event: \(event.rawValue) - \(properties)")
        #endif
        
        // Flush immediately for critical events
        if event.isCritical {
            flushEvents()
        }
    }
    
    // MARK: - User Behavior Tracking
    
    func trackScreenView(_ screenName: String, properties: [String: Any] = [:]) {
        var props = properties
        props["screen_name"] = screenName
        props["screen_category"] = getScreenCategory(screenName)
        
        trackEvent(.screenView, properties: props)
    }
    
    func trackUserAction(_ action: String, properties: [String: Any] = [:]) {
        var props = properties
        props["action"] = action
        props["action_category"] = getActionCategory(action)
        
        trackEvent(.userAction, properties: props)
    }
    
    func trackError(_ error: Error, context: String = "", properties: [String: Any] = [:]) {
        var props = properties
        props["error_message"] = error.localizedDescription
        props["error_domain"] = (error as NSError).domain
        props["error_code"] = (error as NSError).code
        props["context"] = context
        
        trackEvent(.error, properties: props)
    }
    
    func trackPerformance(_ metric: String, value: Double, unit: String = "seconds") {
        trackEvent(.performance, properties: [
            "metric": metric,
            "value": value,
            "unit": unit
        ])
    }
    
    // MARK: - Business Metrics
    
    func trackUserRegistration(method: String, properties: [String: Any] = [:]) {
        var props = properties
        props["registration_method"] = method
        props["user_type"] = "new"
        
        trackEvent(.userRegistration, properties: props)
    }
    
    func trackUserLogin(method: String, properties: [String: Any] = [:]) {
        var props = properties
        props["login_method"] = method
        props["user_type"] = "returning"
        
        trackEvent(.userLogin, properties: props)
    }
    
    func trackEventCreation(properties: [String: Any] = [:]) {
        trackEvent(.eventCreation, properties: properties)
    }
    
    func trackEventRSVP(eventId: String, properties: [String: Any] = [:]) {
        var props = properties
        props["event_id"] = eventId
        
        trackEvent(.eventRSVP, properties: props)
    }
    
    func trackPaymentInitiated(amount: Double, currency: String = "USD", properties: [String: Any] = [:]) {
        var props = properties
        props["amount"] = amount
        props["currency"] = currency
        
        trackEvent(.paymentInitiated, properties: props)
    }
    
    func trackPaymentCompleted(amount: Double, currency: String = "USD", properties: [String: Any] = [:]) {
        var props = properties
        props["amount"] = amount
        props["currency"] = currency
        
        trackEvent(.paymentCompleted, properties: props)
    }
    
    func trackSocialAction(action: String, targetType: String, targetId: String, properties: [String: Any] = [:]) {
        var props = properties
        props["social_action"] = action
        props["target_type"] = targetType
        props["target_id"] = targetId
        
        trackEvent(.socialAction, properties: props)
    }
    
    // MARK: - App Performance Tracking
    
    func trackAppLaunch(duration: TimeInterval) {
        trackPerformance("app_launch_time", value: duration)
    }
    
    func trackAPICall(endpoint: String, duration: TimeInterval, success: Bool) {
        trackEvent(.apiCall, properties: [
            "endpoint": endpoint,
            "duration": duration,
            "success": success
        ])
    }
    
    func trackMemoryUsage(bytes: UInt64) {
        let megabytes = Double(bytes) / (1024 * 1024)
        trackPerformance("memory_usage", value: megabytes, unit: "MB")
    }
    
    // MARK: - Event Flushing
    
    private func flushEvents() {
        guard !eventQueue.isEmpty else { return }
        
        let eventsToSend = eventQueue
        eventQueue.removeAll()
        
        // In production, this would send to your analytics backend
        sendEventsToBackend(eventsToSend)
    }
    
    private func setupPeriodicFlush() {
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.flushEvents()
            }
            .store(in: &cancellables)
    }
    
    private func sendEventsToBackend(_ events: [AnalyticsEvent]) {
        // Simulate sending events to backend
        #if DEBUG
        print("📊 Sending \(events.count) events to analytics backend")
        #endif
        
        // In production, implement actual backend integration
        // AnalyticsBackend.shared.sendEvents(events)
    }
    
    // MARK: - Helper Methods
    
    private func getScreenCategory(_ screenName: String) -> String {
        if screenName.contains("Auth") || screenName.contains("Login") || screenName.contains("Register") {
            return "Authentication"
        } else if screenName.contains("Feed") || screenName.contains("Home") {
            return "Discovery"
        } else if screenName.contains("Event") || screenName.contains("Detail") {
            return "Events"
        } else if screenName.contains("Profile") {
            return "Profile"
        } else if screenName.contains("Map") {
            return "Map"
        } else if screenName.contains("Settings") {
            return "Settings"
        } else {
            return "Other"
        }
    }
    
    private func getActionCategory(_ action: String) -> String {
        if action.contains("Tap") || action.contains("Press") {
            return "Interaction"
        } else if action.contains("Swipe") || action.contains("Scroll") {
            return "Navigation"
        } else if action.contains("Submit") || action.contains("Save") {
            return "Submission"
        } else if action.contains("Share") || action.contains("Invite") {
            return "Social"
        } else {
            return "Other"
        }
    }
}

// MARK: - Analytics Models

struct AnalyticsSession {
    let id: String
    let startTime: Date
    let deviceInfo: DeviceInfo
}

struct AnalyticsEvent {
    let type: AnalyticsEventType
    let properties: [String: Any]
    let timestamp: Date
    let sessionId: String?
}

enum AnalyticsEventType: String, CaseIterable {
    case sessionStart = "session_start"
    case sessionEnd = "session_end"
    case screenView = "screen_view"
    case userAction = "user_action"
    case userRegistration = "user_registration"
    case userLogin = "user_login"
    case eventCreation = "event_creation"
    case eventRSVP = "event_rsvp"
    case paymentInitiated = "payment_initiated"
    case paymentCompleted = "payment_completed"
    case socialAction = "social_action"
    case apiCall = "api_call"
    case performance = "performance"
    case error = "error"
    
    var isCritical: Bool {
        switch self {
        case .error, .paymentCompleted, .userRegistration:
            return true
        default:
            return false
        }
    }
}

struct DeviceInfo {
    let model: String
    let osVersion: String
    let appVersion: String
    let deviceId: String
    
    static var current: DeviceInfo {
        return DeviceInfo(
            model: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
        )
    }
}

// MARK: - Analytics Extensions

extension AnalyticsService {
    /// Convenience methods for common tracking scenarios
    
    func trackButtonTap(_ buttonName: String, screen: String) {
        trackUserAction("button_tap", properties: [
            "button_name": buttonName,
            "screen": screen
        ])
    }
    
    func trackFormSubmission(_ formName: String, success: Bool, properties: [String: Any] = [:]) {
        var props = properties
        props["form_name"] = formName
        props["success"] = success
        
        trackUserAction("form_submission", properties: props)
    }
    
    func trackNavigation(from: String, to: String) {
        trackUserAction("navigation", properties: [
            "from_screen": from,
            "to_screen": to
        ])
    }
    
    func trackSearch(query: String, resultsCount: Int) {
        trackUserAction("search", properties: [
            "query": query,
            "results_count": resultsCount
        ])
    }
    
    func trackShare(contentType: String, platform: String? = nil) {
        var props: [String: Any] = ["content_type": contentType]
        if let platform = platform {
            props["platform"] = platform
        }
        
        trackSocialAction(action: "share", targetType: contentType, targetId: "", properties: props)
    }
} 