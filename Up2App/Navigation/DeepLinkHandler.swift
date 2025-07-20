import Foundation
import SwiftUI

// MARK: - Deep Link Handler
@MainActor
final class DeepLinkHandler: ObservableObject {
    
    // MARK: - Properties
    private weak var navigationCoordinator: NavigationCoordinator?
    private let appStateManager: AppStateManager
    
    // MARK: - Published State
    @Published var pendingDeepLink: DeepLink?
    @Published var lastHandledLink: DeepLink?
    @Published var linkHandlingHistory: [DeepLinkHandlingRecord] = []
    
    // MARK: - Configuration
    private let supportedSchemes = ["up2", "up2app"]
    private let maxHistorySize = 50
    
    // MARK: - Initialization
    init(
        navigationCoordinator: NavigationCoordinator? = nil,
        appStateManager: AppStateManager? = nil
    ) {
        self.navigationCoordinator = navigationCoordinator
        self.appStateManager = appStateManager ?? AppStateManager.shared
        
        setupObservers()
    }
    
    // MARK: - Setup
    private func setupObservers() {
        // Observe app state changes to handle pending deep links
        appStateManager.$appFlow
            .receive(on: DispatchQueue.main)
            .sink { [weak self] appFlow in
                self?.handleAppFlowChange(appFlow)
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    /// Handle incoming deep link URL
    func handleDeepLink(_ url: URL) -> Bool {
        print("🔗 DeepLinkHandler: Received URL: \(url)")
        
        // Validate URL scheme
        guard isValidScheme(url.scheme) else {
            recordFailedLinkHandling(url, reason: .unsupportedScheme)
            return false
        }
        
        // Create deep link object
        guard let deepLink = DeepLink(url: url) else {
            recordFailedLinkHandling(url, reason: .invalidFormat)
            return false
        }
        
        // Check if user is authenticated for protected routes
        if requiresAuthentication(deepLink.destination) && !isUserAuthenticated {
            pendingDeepLink = deepLink
            recordPendingLinkHandling(deepLink, reason: .authenticationRequired)
            return true // Return true because we can handle it later
        }
        
        // Handle the deep link immediately
        return processDeepLink(deepLink)
    }
    
    /// Process a deep link with validation and routing
    private func processDeepLink(_ deepLink: DeepLink) -> Bool {
        guard let destination = deepLink.destination else {
            recordFailedLinkHandling(deepLink.url, reason: .noDestination)
            return false
        }
        
        // Validate destination is accessible
        guard isDestinationAccessible(destination) else {
            recordFailedLinkHandling(deepLink.url, reason: .destinationNotAccessible)
            return false
        }
        
        // Route the deep link
        let success = routeToDestination(destination, from: deepLink)
        
        if success {
            recordSuccessfulLinkHandling(deepLink)
            lastHandledLink = deepLink
        } else {
            recordFailedLinkHandling(deepLink.url, reason: .routingFailed)
        }
        
        return success
    }
    
    /// Check for and handle any pending deep links
    func processPendingDeepLink() {
        guard let pendingLink = pendingDeepLink else { return }
        
        pendingDeepLink = nil
        
        if processDeepLink(pendingLink) {
            print("✅ Successfully processed pending deep link: \(pendingLink.url)")
        } else {
            print("❌ Failed to process pending deep link: \(pendingLink.url)")
        }
    }
    
    // MARK: - Validation Methods
    
    private func isValidScheme(_ scheme: String?) -> Bool {
        guard let scheme = scheme?.lowercased() else { return false }
        return supportedSchemes.contains(scheme)
    }
    
    private func requiresAuthentication(_ destination: NavigationDestination?) -> Bool {
        guard let destination = destination else { return false }
        
        switch destination {
        case .login, .registration:
            return false // These are for unauthenticated users
        case .maintenance:
            return false // Maintenance can be shown to anyone
        default:
            return true // All other destinations require authentication
        }
    }
    
    private var isUserAuthenticated: Bool {
        return appStateManager.isUserAuthenticated
    }
    
    private func isDestinationAccessible(_ destination: NavigationDestination) -> Bool {
        // Check if the destination is currently accessible based on app state
        switch destination {
        case .login, .registration:
            // Authentication destinations are only accessible when not authenticated
            return !isUserAuthenticated
            
        case .profileSetup:
            // Profile setup is only accessible when authenticated but profile incomplete
            return isUserAuthenticated && !appStateManager.hasProfileSetup
            
        case .tab(.forYou), .tab(.map), .tab(.trending), .tab(.profile), .tab(.more):
            // Main app tabs require authentication and completed profile
            return isUserAuthenticated && appStateManager.hasProfileSetup
            
        case .eventDetail, .eventMap, .eventSearch:
            // Event-related destinations require authentication
            return isUserAuthenticated
            
        case .profileEdit, .profileView:
            // Profile destinations require authentication
            return isUserAuthenticated
            
        case .settings, .help, .notifications:
            // These can be accessed if authenticated
            return isUserAuthenticated
            
        case .maintenance:
            // Maintenance is always accessible
            return true
        }
    }
    
    // MARK: - Routing Methods
    
    private func routeToDestination(_ destination: NavigationDestination, from deepLink: DeepLink) -> Bool {
        do {
            switch destination {
            case .tab(let tab):
                navigationCoordinator?.selectedTab = tab
                
            case .login, .registration, .profileSetup:
                // These should be handled by app flow, not direct navigation
                // Navigate to the appropriate app flow instead
                handleAuthenticationDestination(destination)
                
            case .eventDetail, .eventMap, .eventSearch:
                // Navigate to the appropriate tab and then to the destination
                let targetTab: AppTab = destination.suggestedTab
                navigationCoordinator?.navigate(to: destination, in: targetTab)
                
            case .profileEdit, .profileView:
                // Navigate to profile tab and then to the destination
                navigationCoordinator?.navigate(to: destination, in: .profile)
                
            case .settings, .help, .notifications:
                // Present as modal
                navigationCoordinator?.presentModal(destination)
                
            case .maintenance:
                // Present maintenance modal
                navigationCoordinator?.presentModal(destination)
            }
            
            return true
        } catch {
            print("❌ Error routing to destination \(destination): \(error)")
            return false
        }
    }
    
    private func handleAuthenticationDestination(_ destination: NavigationDestination) {
        // For authentication-related destinations, we need to work with the app flow
        switch destination {
        case .login:
            if !isUserAuthenticated {
                appStateManager.appFlow = .authentication
            }
        case .registration:
            if !isUserAuthenticated {
                appStateManager.appFlow = .authentication
                // Could add additional state to specify registration vs login
            }
        case .profileSetup:
            if isUserAuthenticated && !appStateManager.hasProfileSetup {
                appStateManager.appFlow = .profileSetup
            }
        default:
            break
        }
    }
    
    // MARK: - App Flow Handling
    
    private func handleAppFlowChange(_ appFlow: AppStateManager.AppFlow) {
        switch appFlow {
        case .mainApp:
            // When user reaches main app, process any pending deep links
            if pendingDeepLink != nil {
                processPendingDeepLink()
            }
        case .authentication, .registration, .profileSetup:
            // Don't process pending links during authentication flows
            break
        }
    }
    
    // MARK: - History and Analytics
    
    private func recordSuccessfulLinkHandling(_ deepLink: DeepLink) {
        let record = DeepLinkHandlingRecord(
            deepLink: deepLink,
            timestamp: Date(),
            status: .success,
            reason: nil,
            appState: getCurrentAppState()
        )
        addToHistory(record)
        
        print("✅ Deep link handled successfully: \(deepLink.url)")
    }
    
    private func recordFailedLinkHandling(_ url: URL, reason: DeepLinkFailureReason) {
        let record = DeepLinkHandlingRecord(
            deepLink: DeepLink(url: url), // May be nil if URL is invalid
            url: url,
            timestamp: Date(),
            status: .failed(reason),
            reason: reason.description,
            appState: getCurrentAppState()
        )
        addToHistory(record)
        
        print("❌ Deep link handling failed: \(url) - \(reason.description)")
    }
    
    private func recordPendingLinkHandling(_ deepLink: DeepLink, reason: DeepLinkPendingReason) {
        let record = DeepLinkHandlingRecord(
            deepLink: deepLink,
            timestamp: Date(),
            status: .pending(reason),
            reason: reason.description,
            appState: getCurrentAppState()
        )
        addToHistory(record)
        
        print("⏳ Deep link pending: \(deepLink.url) - \(reason.description)")
    }
    
    private func addToHistory(_ record: DeepLinkHandlingRecord) {
        linkHandlingHistory.append(record)
        
        // Limit history size
        if linkHandlingHistory.count > maxHistorySize {
            linkHandlingHistory.removeFirst(linkHandlingHistory.count - maxHistorySize)
        }
    }
    
    private func getCurrentAppState() -> AppStateSnapshot {
        return AppStateSnapshot(
            appFlow: appStateManager.appFlow,
            isAuthenticated: isUserAuthenticated,
            hasProfileSetup: appStateManager.hasProfileSetup,
            selectedTab: navigationCoordinator?.selectedTab ?? .forYou // Use optional chaining
        )
    }
    
    // MARK: - Utility Methods
    
    /// Generate a deep link URL for a destination
    func generateDeepLink(for destination: NavigationDestination) -> URL? {
        let baseScheme = "up2"
        
        switch destination {
        case .tab(let tab):
            return URL(string: "\(baseScheme)://\(tab.rawValue)")
            
        case .eventDetail(let eventId):
            return URL(string: "\(baseScheme)://events/\(eventId)")
            
        case .eventMap(let location):
            if let location = location {
                return URL(string: "\(baseScheme)://map?location=\(location)")
            } else {
                return URL(string: "\(baseScheme)://map")
            }
            
        case .eventSearch(let query):
            if let query = query {
                let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                return URL(string: "\(baseScheme)://search?q=\(encodedQuery)")
            } else {
                return URL(string: "\(baseScheme)://search")
            }
            
        case .profileView(let userId):
            return URL(string: "\(baseScheme)://profile/\(userId)")
            
        case .settings:
            return URL(string: "\(baseScheme)://settings")
            
        case .help:
            return URL(string: "\(baseScheme)://help")
            
        default:
            return nil // Some destinations don't have deep link representations
        }
    }
    
    /// Clear deep link history
    func clearHistory() {
        linkHandlingHistory.removeAll()
    }
    
    /// Get recent deep link activity
    func getRecentActivity(limit: Int = 10) -> [DeepLinkHandlingRecord] {
        return Array(linkHandlingHistory.suffix(limit))
    }
}

// MARK: - Supporting Types

struct DeepLinkHandlingRecord: Identifiable {
    let id = UUID()
    let deepLink: DeepLink?
    let url: URL?
    let timestamp: Date
    let status: DeepLinkHandlingStatus
    let reason: String?
    let appState: AppStateSnapshot
    
    init(deepLink: DeepLink?, url: URL? = nil, timestamp: Date, status: DeepLinkHandlingStatus, reason: String?, appState: AppStateSnapshot) {
        self.deepLink = deepLink
        self.url = url ?? deepLink?.url
        self.timestamp = timestamp
        self.status = status
        self.reason = reason
        self.appState = appState
    }
}

enum DeepLinkHandlingStatus {
    case success
    case failed(DeepLinkFailureReason)
    case pending(DeepLinkPendingReason)
    
    var displayName: String {
        switch self {
        case .success:
            return "Success"
        case .failed(let reason):
            return "Failed (\(reason.shortDescription))"
        case .pending(let reason):
            return "Pending (\(reason.shortDescription))"
        }
    }
}

enum DeepLinkFailureReason {
    case unsupportedScheme
    case invalidFormat
    case noDestination
    case destinationNotAccessible
    case routingFailed
    
    var description: String {
        switch self {
        case .unsupportedScheme:
            return "URL scheme is not supported"
        case .invalidFormat:
            return "URL format is invalid"
        case .noDestination:
            return "No valid destination found"
        case .destinationNotAccessible:
            return "Destination is not accessible in current app state"
        case .routingFailed:
            return "Failed to route to destination"
        }
    }
    
    var shortDescription: String {
        switch self {
        case .unsupportedScheme:
            return "Unsupported Scheme"
        case .invalidFormat:
            return "Invalid Format"
        case .noDestination:
            return "No Destination"
        case .destinationNotAccessible:
            return "Not Accessible"
        case .routingFailed:
            return "Routing Failed"
        }
    }
}

enum DeepLinkPendingReason {
    case authenticationRequired
    case profileSetupRequired
    case appInitializing
    
    var description: String {
        switch self {
        case .authenticationRequired:
            return "User authentication required"
        case .profileSetupRequired:
            return "Profile setup required"
        case .appInitializing:
            return "App is still initializing"
        }
    }
    
    var shortDescription: String {
        switch self {
        case .authenticationRequired:
            return "Auth Required"
        case .profileSetupRequired:
            return "Profile Setup"
        case .appInitializing:
            return "Initializing"
        }
    }
}

struct AppStateSnapshot {
    let appFlow: AppStateManager.AppFlow
    let isAuthenticated: Bool
    let hasProfileSetup: Bool
    let selectedTab: AppTab
}

// MARK: - NavigationDestination Extensions

extension NavigationDestination {
    /// Get the suggested tab for routing this destination
    var suggestedTab: AppTab {
        switch self {
        case .eventDetail, .eventMap, .eventSearch:
            return .forYou
        case .profileEdit, .profileView:
            return .profile
        case .tab(let tab):
            return tab
        default:
            return .forYou // Default fallback
        }
    }
}

// MARK: - Combine Support
import Combine 