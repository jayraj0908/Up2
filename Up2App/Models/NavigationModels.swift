import Foundation
import SwiftUI

// MARK: - Navigation State Management

/// Main app tab identifiers
enum AppTab: String, CaseIterable, Identifiable, Codable {
    case forYou = "for_you"
    case map = "map"
    case trending = "trending"
    case profile = "profile"
    case more = "more"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .forYou: return "For You"
        case .map: return "Map"
        case .trending: return "Trending"
        case .profile: return "Profile"
        case .more: return "More"
        }
    }
    
    var icon: String {
        switch self {
        case .forYou: return "safari"
        case .map: return "map"
        case .trending: return "Logo"
        case .profile: return "person"
        case .more: return "ellipsis"
        }
    }
    
    var selectedIcon: String {
        switch self {
        case .forYou: return "safari.fill"
        case .map: return "map.fill"
        case .trending: return "Logo"
        case .profile: return "person.fill"
        case .more: return "ellipsis"
        }
    }
    
    var accessibilityLabel: String {
        switch self {
        case .forYou: return "For You events feed"
        case .map: return "Map view"
        case .trending: return "Trending events"
        case .profile: return "User profile"
        case .more: return "More options and settings"
        }
    }
}

// MARK: - Navigation Stack Management

/// Represents a navigation destination within the app
enum NavigationDestination: Hashable, Identifiable, Codable {
    // Authentication Flow
    case login
    case registration
    case profileSetup
    
    // Main App Tabs
    case tab(AppTab)
    
    // Event-related destinations
    case eventDetail(eventId: String)
    case eventMap(location: String?)
    case eventSearch(query: String?)
    
    // Profile-related destinations
    case profileEdit
    case profileView(userId: String)
    case settings
    
    // General destinations
    case help
    case notifications
    case maintenance(message: String?)
    
    var id: String {
        switch self {
        case .login: return "login"
        case .registration: return "registration"
        case .profileSetup: return "profile_setup"
        case .tab(let tab): return "tab_\(tab.rawValue)"
        case .eventDetail(let eventId): return "event_detail_\(eventId)"
        case .eventMap(let location): return "event_map_\(location ?? "default")"
        case .eventSearch(let query): return "event_search_\(query ?? "default")"
        case .profileEdit: return "profile_edit"
        case .profileView(let userId): return "profile_view_\(userId)"
        case .settings: return "settings"
        case .help: return "help"
        case .notifications: return "notifications"
        case .maintenance(let message): return "maintenance_\(message ?? "default")"
        }
    }
    
    // MARK: - Codable Implementation
    
    enum CodingKeys: String, CodingKey {
        case type
        case tab
        case eventId
        case location
        case query
        case userId
        case message
    }
    
    enum DestinationType: String, Codable {
        case login, registration, profileSetup
        case tab
        case eventDetail, eventMap, eventSearch
        case profileEdit, profileView, settings
        case help, notifications, maintenance
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .login:
            try container.encode(DestinationType.login, forKey: .type)
        case .registration:
            try container.encode(DestinationType.registration, forKey: .type)
        case .profileSetup:
            try container.encode(DestinationType.profileSetup, forKey: .type)
        case .tab(let tab):
            try container.encode(DestinationType.tab, forKey: .type)
            try container.encode(tab, forKey: .tab)
        case .eventDetail(let eventId):
            try container.encode(DestinationType.eventDetail, forKey: .type)
            try container.encode(eventId, forKey: .eventId)
        case .eventMap(let location):
            try container.encode(DestinationType.eventMap, forKey: .type)
            try container.encodeIfPresent(location, forKey: .location)
        case .eventSearch(let query):
            try container.encode(DestinationType.eventSearch, forKey: .type)
            try container.encodeIfPresent(query, forKey: .query)
        case .profileEdit:
            try container.encode(DestinationType.profileEdit, forKey: .type)
        case .profileView(let userId):
            try container.encode(DestinationType.profileView, forKey: .type)
            try container.encode(userId, forKey: .userId)
        case .settings:
            try container.encode(DestinationType.settings, forKey: .type)
        case .help:
            try container.encode(DestinationType.help, forKey: .type)
        case .notifications:
            try container.encode(DestinationType.notifications, forKey: .type)
        case .maintenance(let message):
            try container.encode(DestinationType.maintenance, forKey: .type)
            try container.encodeIfPresent(message, forKey: .message)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(DestinationType.self, forKey: .type)
        
        switch type {
        case .login:
            self = .login
        case .registration:
            self = .registration
        case .profileSetup:
            self = .profileSetup
        case .tab:
            let tab = try container.decode(AppTab.self, forKey: .tab)
            self = .tab(tab)
        case .eventDetail:
            let eventId = try container.decode(String.self, forKey: .eventId)
            self = .eventDetail(eventId: eventId)
        case .eventMap:
            let location = try container.decodeIfPresent(String.self, forKey: .location)
            self = .eventMap(location: location)
        case .eventSearch:
            let query = try container.decodeIfPresent(String.self, forKey: .query)
            self = .eventSearch(query: query)
        case .profileEdit:
            self = .profileEdit
        case .profileView:
            let userId = try container.decode(String.self, forKey: .userId)
            self = .profileView(userId: userId)
        case .settings:
            self = .settings
        case .help:
            self = .help
        case .notifications:
            self = .notifications
        case .maintenance:
            let message = try container.decodeIfPresent(String.self, forKey: .message)
            self = .maintenance(message: message)
        }
    }
}

// MARK: - Navigation State

/// Manages the current navigation state of the app
struct NavigationState: Codable {
    var selectedTab: AppTab
    var tabNavigationStacks: [AppTab: [NavigationDestination]]
    var presentedModals: [NavigationDestination]
    var lastActiveDate: Date
    
    init(selectedTab: AppTab = .forYou) {
        self.selectedTab = selectedTab
        self.tabNavigationStacks = [:]
        self.presentedModals = []
        self.lastActiveDate = Date()
        
        // Initialize empty navigation stacks for each tab
        for tab in AppTab.allCases {
            tabNavigationStacks[tab] = []
        }
    }
    
    // MARK: - Stack Management
    
    mutating func push(_ destination: NavigationDestination, to tab: AppTab) {
        tabNavigationStacks[tab, default: []].append(destination)
        updateLastActiveDate()
    }
    
    mutating func pop(from tab: AppTab) {
        tabNavigationStacks[tab]?.removeLast()
        updateLastActiveDate()
    }
    
    mutating func popToRoot(for tab: AppTab) {
        tabNavigationStacks[tab] = []
        updateLastActiveDate()
    }
    
    mutating func selectTab(_ tab: AppTab) {
        selectedTab = tab
        updateLastActiveDate()
    }
    
    // MARK: - Modal Management
    
    mutating func presentModal(_ destination: NavigationDestination) {
        presentedModals.append(destination)
        updateLastActiveDate()
    }
    
    mutating func dismissModal() {
        presentedModals.removeLast()
        updateLastActiveDate()
    }
    
    mutating func dismissAllModals() {
        presentedModals.removeAll()
        updateLastActiveDate()
    }
    
    // MARK: - Utility
    
    func navigationStack(for tab: AppTab) -> [NavigationDestination] {
        return tabNavigationStacks[tab] ?? []
    }
    
    func hasContent(in tab: AppTab) -> Bool {
        return !(tabNavigationStacks[tab]?.isEmpty ?? true)
    }
    
    var currentModal: NavigationDestination? {
        return presentedModals.last
    }
    
    private mutating func updateLastActiveDate() {
        lastActiveDate = Date()
    }
}

// MARK: - Deep Linking

/// Represents a deep link into the app
struct DeepLink {
    let url: URL
    let components: URLComponents
    let destination: NavigationDestination?
    
    init?(url: URL) {
        self.url = url
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        self.components = components
        self.destination = Self.parseDestination(from: components)
    }
    
    private static func parseDestination(from components: URLComponents) -> NavigationDestination? {
        guard components.scheme == "up2" else { return nil }
        
        let host = components.host ?? ""
        let pathComponents = components.path.components(separatedBy: "/").filter { !$0.isEmpty }
        
        switch host {
        case "events":
            if let eventId = pathComponents.first {
                return .eventDetail(eventId: eventId)
            }
            return .tab(.forYou)
            
        case "map":
            let location = components.queryItems?.first(where: { $0.name == "location" })?.value
            return .eventMap(location: location)
            
        case "profile":
            if let userId = pathComponents.first {
                return .profileView(userId: userId)
            }
            return .tab(.profile)
            
        case "trending":
            return .tab(.trending)
            
        case "search":
            let query = components.queryItems?.first(where: { $0.name == "q" })?.value
            return .eventSearch(query: query)
            
        case "settings":
            return .settings
            
        case "help":
            return .help
            
        default:
            return nil
        }
    }
}

// MARK: - Navigation Analytics

/// Tracks navigation events for analytics
struct NavigationEvent {
    let timestamp: Date
    let source: NavigationDestination?
    let destination: NavigationDestination
    let method: NavigationMethod
    let metadata: [String: Any]
    
    enum NavigationMethod {
        case tap
        case deepLink
        case programmatic
        case backButton
        case tabSwitch
    }
    
    init(
        from source: NavigationDestination?,
        to destination: NavigationDestination,
        method: NavigationMethod,
        metadata: [String: Any] = [:]
    ) {
        self.timestamp = Date()
        self.source = source
        self.destination = destination
        self.method = method
        self.metadata = metadata
    }
}

// MARK: - Navigation Coordinator Protocol

/// Protocol for navigation coordination
protocol NavigationCoordinatorProtocol: ObservableObject {
    var navigationState: NavigationState { get }
    var selectedTab: AppTab { get set }
    
    func navigate(to destination: NavigationDestination)
    func navigate(to destination: NavigationDestination, in tab: AppTab)
    func presentModal(_ destination: NavigationDestination)
    func dismissModal()
    func handleDeepLink(_ url: URL) -> Bool
    func popToRoot(for tab: AppTab)
    func saveNavigationState()
    func restoreNavigationState()
}

// MARK: - Tab Content Provider

/// Protocol for providing tab content
protocol TabContentProvider {
    func view(for tab: AppTab) -> AnyView
    func canNavigate(to destination: NavigationDestination, in tab: AppTab) -> Bool
}

// MARK: - Navigation Configuration

/// Configuration for navigation behavior
struct NavigationConfiguration {
    let persistNavigationState: Bool
    let enableDeepLinking: Bool
    let enableAnalytics: Bool
    let tabSwitchAnimation: Animation
    let modalPresentationStyle: ModalPresentationStyle
    
    enum ModalPresentationStyle {
        case sheet
        case fullScreen
        case overlay
    }
    
    static let `default` = NavigationConfiguration(
        persistNavigationState: true,
        enableDeepLinking: true,
        enableAnalytics: true,
        tabSwitchAnimation: .easeInOut(duration: 0.2),
        modalPresentationStyle: .sheet
    )
} 