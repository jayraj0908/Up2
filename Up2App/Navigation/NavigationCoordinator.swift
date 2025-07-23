import Foundation
import SwiftUI
import Combine

// MARK: - Navigation Coordinator
@MainActor
final class NavigationCoordinator: ObservableObject, @preconcurrency NavigationCoordinatorProtocol {
    
    // MARK: - Published Properties
    @Published private(set) var navigationState: NavigationState
    @Published var selectedTab: AppTab {
        didSet {
            navigationState.selectTab(selectedTab)
            saveNavigationState()
            trackNavigation(to: .tab(selectedTab), method: .tabSwitch)
        }
    }
    
    @Published var presentedModal: NavigationDestination? {
        didSet {
            saveNavigationState()
        }
    }
    
    // MARK: - Configuration
    private let configuration: NavigationConfiguration
    private let appStateManager: AppStateManager
    
    // MARK: - Analytics
    private var navigationEvents: [NavigationEvent] = []
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UserDefaults Keys
    private let navigationStateKey = "navigation_state"
    private let lastSelectedTabKey = "last_selected_tab"
    
    // MARK: - Initialization
    init(
        configuration: NavigationConfiguration = .default,
        appStateManager: AppStateManager? = nil
    ) {
        self.configuration = configuration
        self.appStateManager = appStateManager ?? AppStateManager()
        
        // Initialize with default state
        self.navigationState = NavigationState()
        self.selectedTab = .forYou
        
        // Restore state if enabled
        if configuration.persistNavigationState {
            restoreNavigationState()
        }
        
        // Setup observers
        setupObservers()
    }
    
    // MARK: - Setup Methods
    
    private func setupObservers() {
        // Observe app state changes
        // Note: AppStateManager no longer has appFlow property
        // We'll handle state changes through other means
        
        // Auto-save navigation state periodically
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.saveNavigationState()
            }
            .store(in: &cancellables)
    }
    
    private func handleAppFlowChange(_ appFlow: String) {
        // This method is no longer needed as AppStateManager no longer has appFlow
        // Navigation state will be managed through other state changes
    }
    
    // MARK: - Navigation Methods
    
    func navigate(to destination: NavigationDestination) {
        navigate(to: destination, in: selectedTab)
    }
    
    func navigate(to destination: NavigationDestination, in tab: AppTab) {
        let currentDestination = getCurrentDestination(in: tab)
        
        switch destination {
        case .tab(let targetTab):
            // Switch to the specified tab
            if targetTab != selectedTab {
                selectedTab = targetTab
            }
            
        default:
            // Push destination to the specified tab's navigation stack
            navigationState.push(destination, to: tab)
            
            // Switch to the tab if not already selected
            if tab != selectedTab {
                selectedTab = tab
            }
        }
        
        saveNavigationState()
        trackNavigation(from: currentDestination, to: destination, method: .tap)
        
        // Add haptic feedback for navigation actions
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func presentModal(_ destination: NavigationDestination) {
        presentedModal = destination
        navigationState.presentModal(destination)
        
        let currentDestination = getCurrentDestination(in: selectedTab)
        trackNavigation(from: currentDestination, to: destination, method: .tap)
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    func dismissModal() {
        guard presentedModal != nil else { return }
        
        presentedModal = nil
        navigationState.dismissModal()
        saveNavigationState()
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    func popToRoot(for tab: AppTab) {
        navigationState.popToRoot(for: tab)
        saveNavigationState()
        
        trackNavigation(to: .tab(tab), method: .programmatic)
    }
    
    func popBack(in tab: AppTab) {
        guard navigationState.hasContent(in: tab) else { return }
        
        let currentDestination = getCurrentDestination(in: tab)
        navigationState.pop(from: tab)
        let newDestination = getCurrentDestination(in: tab) ?? .tab(tab)
        
        saveNavigationState()
        trackNavigation(from: currentDestination, to: newDestination, method: .backButton)
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    // MARK: - Deep Linking
    
    func handleDeepLink(_ url: URL) -> Bool {
        guard let deepLink = DeepLink(url: url),
              let destination = deepLink.destination else {
            print("⚠️ Failed to parse deep link: \(url)")
            return false
        }
        
        print("🔗 Handling deep link: \(url) -> \(destination)")
        
        // Handle different destination types
        switch destination {
        case .tab(let tab):
            selectedTab = tab
            
        case .eventDetail, .eventMap, .eventSearch:
            // Navigate to For You tab for event-related destinations
            navigate(to: destination, in: .forYou)
            
        case .profileView, .profileEdit:
            // Navigate to Profile tab for profile-related destinations
            navigate(to: destination, in: .profile)
            
        case .settings, .help:
            // Present as modal for general destinations
            presentModal(destination)
            
        default:
            // Navigate to appropriate tab
            navigate(to: destination)
        }
        
        trackNavigation(to: destination, method: .deepLink, metadata: ["url": url.absoluteString])
        return true
    }
    
    // MARK: - State Persistence
    
    func saveNavigationState() {
        guard configuration.persistNavigationState else { return }
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(navigationState)
            UserDefaults.standard.set(data, forKey: navigationStateKey)
            UserDefaults.standard.set(selectedTab.rawValue, forKey: lastSelectedTabKey)
        } catch {
            print("⚠️ Failed to save navigation state: \(error)")
        }
    }
    
    func restoreNavigationState() {
        // Restore selected tab
        if let tabString = UserDefaults.standard.string(forKey: lastSelectedTabKey),
           let tab = AppTab(rawValue: tabString) {
            selectedTab = tab
        }
        
        // Restore navigation state
        guard let data = UserDefaults.standard.data(forKey: navigationStateKey) else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let restoredState = try decoder.decode(NavigationState.self, from: data)
            
            // Only restore if the state is recent (within 24 hours)
            let dayAgo = Date().addingTimeInterval(-24 * 60 * 60)
            if restoredState.lastActiveDate > dayAgo {
                navigationState = restoredState
                selectedTab = restoredState.selectedTab
                print("✅ Navigation state restored")
            } else {
                print("⚠️ Navigation state too old, using fresh state")
            }
        } catch {
            print("⚠️ Failed to restore navigation state: \(error)")
        }
    }
    
    private func clearNavigationState() {
        navigationState = NavigationState()
        selectedTab = .forYou
        presentedModal = nil
        UserDefaults.standard.removeObject(forKey: navigationStateKey)
        UserDefaults.standard.removeObject(forKey: lastSelectedTabKey)
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentDestination(in tab: AppTab) -> NavigationDestination? {
        let stack = navigationState.navigationStack(for: tab)
        return stack.last ?? .tab(tab)
    }
    
    private func trackNavigation(
        from source: NavigationDestination? = nil,
        to destination: NavigationDestination,
        method: NavigationEvent.NavigationMethod,
        metadata: [String: Any] = [:]
    ) {
        guard configuration.enableAnalytics else { return }
        
        let event = NavigationEvent(
            from: source,
            to: destination,
            method: method,
            metadata: metadata
        )
        
        navigationEvents.append(event)
        
        // Keep only last 100 events to prevent memory issues
        if navigationEvents.count > 100 {
            navigationEvents.removeFirst(50)
        }
        
        // Log navigation event
        print("📊 Navigation: \(source?.id ?? "none") -> \(destination.id) (\(method))")
    }
    
    // MARK: - Tab Management
    
    func canNavigateBack(in tab: AppTab) -> Bool {
        return navigationState.hasContent(in: tab)
    }
    
    func getNavigationPath(for tab: AppTab) -> [NavigationDestination] {
        return navigationState.navigationStack(for: tab)
    }
    
    func getTabBadge(for tab: AppTab) -> String? {
        // This can be extended to show badges based on app state
        // For now, return nil for all tabs
        return nil
    }
    
    // MARK: - Analytics and Debugging
    
    func getNavigationEvents() -> [NavigationEvent] {
        return navigationEvents
    }
    
    func clearAnalytics() {
        navigationEvents.removeAll()
    }
    
    #if DEBUG
    func printNavigationState() {
        print("🔍 Navigation State Debug:")
        print("  Selected Tab: \(selectedTab)")
        print("  Modal: \(presentedModal?.id ?? "none")")
        
        for tab in AppTab.allCases {
            let stack = navigationState.navigationStack(for: tab)
            print("  \(tab.title): \(stack.map { $0.id })")
        }
    }
    #endif
}

// MARK: - Navigation Coordinator Extensions

extension NavigationCoordinator {
    
    /// Reset navigation to fresh state (useful for logout)
    func resetToInitialState() {
        clearNavigationState()
        selectedTab = .forYou
        presentedModal = nil
    }
    
    /// Handle authentication completion
    func handleAuthenticationComplete() {
        resetToInitialState()
        selectedTab = .forYou
    }
    
    /// Handle profile setup completion
    func handleProfileSetupComplete() {
        resetToInitialState()
        selectedTab = .forYou
    }
    
    /// Get the current view path for a specific tab
    func getCurrentViewPath(for tab: AppTab) -> String {
        let stack = navigationState.navigationStack(for: tab)
        let path = [tab.title] + stack.map { $0.id }
        return path.joined(separator: " > ")
    }
    
    /// Check if a specific destination is currently visible
    func isDestinationVisible(_ destination: NavigationDestination) -> Bool {
        // Check if it's the current modal
        if presentedModal == destination {
            return true
        }
        
        // Check if it's in the current tab's stack
        let currentStack = navigationState.navigationStack(for: selectedTab)
        return currentStack.contains(destination)
    }
}

// MARK: - Tab Content Provider Implementation

extension NavigationCoordinator: @preconcurrency TabContentProvider {
    
    func view(for tab: AppTab) -> AnyView {
        // This will be implemented when we create the tab views
        switch tab {
        case .forYou:
            return AnyView(Text("For You Content"))
        case .map:
            return AnyView(Text("Map Content"))
        case .trending:
            return AnyView(Text("Trending Content"))
        case .profile:
            return AnyView(Text("Profile Content"))
        case .more:
            return AnyView(Text("More Content"))
        }
    }
    
    func canNavigate(to destination: NavigationDestination, in tab: AppTab) -> Bool {
        // Define navigation rules for each tab
        switch (tab, destination) {
        case (.forYou, .eventDetail), (.forYou, .eventSearch):
            return true
        case (.map, .eventDetail), (.map, .eventMap):
            return true
        case (.trending, .eventDetail):
            return true
        case (.profile, .profileEdit), (.profile, .profileView), (.profile, .settings):
            return true
        case (.more, .settings), (.more, .help):
            return true
        default:
            // Allow tab navigation from any tab
            if case .tab = destination {
                return true
            }
            return false
        }
    }
} 