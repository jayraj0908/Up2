import SwiftUI

// MARK: - Tab Navigation View
struct TabNavigationView: View {
    
    // MARK: - Environment and State
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject var appStateManager: AppStateManager
    
    // MARK: - Tab Items Configuration
    private var tabItems: [Up2TabBar.TabItem] {
        AppTab.allCases.map { tab in
            Up2TabBar.TabItem(
                id: tab.rawValue,
                icon: tab.icon,
                selectedIcon: tab.selectedIcon,
                title: tab.title,
                badge: navigationCoordinator.getTabBadge(for: tab)
            )
        }
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Main Tab View
            TabView(selection: $navigationCoordinator.selectedTab) {
                ForYouTabView()
                    .tag(AppTab.forYou)
                
                MapTabView()
                    .tag(AppTab.map)
                
                TrendingTabView()
                    .tag(AppTab.trending)
                
                ProfileTabView()
                    .tag(AppTab.profile)
                
                MoreTabView()
                    .tag(AppTab.more)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Custom Tab Bar
            VStack {
                Spacer()
                                           Up2TabBar(
                               items: tabItems,
                               selectedTab: Binding(
                                   get: { navigationCoordinator.selectedTab.rawValue },
                                   set: { _ in }
                               ),
                               onTabSelected: { tabId in
                                   handleTabSelection(tabId)
                               }
                           )
            }
        }
        .environmentObject(appStateManager)
    }
    
    // MARK: - Tab Selection Handler
    private func handleTabSelection(_ tabId: String) {
        guard let tab = AppTab(rawValue: tabId) else { return }
        
        // Check if user can access this tab
        if canAccessTab(tab) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                navigationCoordinator.selectedTab = tab
            }
        } else {
            // Show soft gate overlay
            showSoftGateOverlay(for: tab)
        }
    }
    
    // MARK: - Access Control
    private func canAccessTab(_ tab: AppTab) -> Bool {
        // Development mode: allow all tabs for testing
        #if DEBUG
        return true
        #else
        switch tab {
        case .forYou, .map, .trending:
            return true // Always accessible to guests
        case .profile, .more:
            return appStateManager.isAuthenticated // Require authentication
        }
        #endif
    }
    
    private func showSoftGateOverlay(for tab: AppTab) {
        // Show login modal for restricted tabs
        navigationCoordinator.presentModal(.login)
    }
    
    // MARK: - Blur Overlay for Restricted Tabs
    @ViewBuilder
    private func blurOverlay(for tab: AppTab) -> some View {
        ZStack {
            // Blur background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            // Login prompt
            VStack(spacing: Up2Spacing.lg) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(Up2Colors.textOnPrimary)
                
                Text("Sign in to access \(tab.title)")
                    .font(Up2Typography.heading2)
                    .foregroundColor(Up2Colors.textOnPrimary)
                    .multilineTextAlignment(.center)
                
                Text("Create an account to unlock all features")
                    .font(Up2Typography.bodyMedium)
                    .foregroundColor(Up2Colors.textOnPrimary.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Up2Button(
                    "Sign In",
                    style: .primary,
                    action: {
                        navigationCoordinator.presentModal(.login)
                    }
                )
                .frame(maxWidth: 200)
            }
            .padding(Up2Spacing.xl)
        }
    }
    
    // MARK: - Check if Tab is Restricted
    private func isRestrictedTab(_ tab: AppTab) -> Bool {
        switch tab {
        case .forYou, .map, .trending:
            return false // These tabs are accessible to guests
        case .profile, .more:
            return true // These tabs require authentication
        }
    }
    
    // MARK: - Tab Content Views
    @ViewBuilder
    private func tabContentView(for tab: AppTab) -> some View {
        NavigationView {
            Group {
                switch tab {
                case .forYou:
                    ForYouTabView()
                case .map:
                    MapTabView()
                case .trending:
                    TrendingTabView()
                case .profile:
                    ProfileTabView()
                case .more:
                    MoreTabView()
                }
            }
            .environmentObject(navigationCoordinator)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Create Event Button - REMOVED
    // Create event functionality moved to "Become a Host" in More tab
    
    // MARK: - Tab Bar Section
    private var tabBarSection: some View {
        Up2TabBar(
            items: tabItems,
            selectedTab: Binding(
                get: { navigationCoordinator.selectedTab.rawValue },
                set: { tabId in
                    if let tab = AppTab(rawValue: tabId) {
                        navigationCoordinator.selectedTab = tab
                    }
                }
            ),
            onTabSelected: { tabId in
                handleTabSelection(tabId)
            }
        )
    }
    
    // MARK: - Modal Content
    @ViewBuilder
    private func modalContent(for destination: NavigationDestination) -> some View {
        NavigationView {
            modalDestinationView(for: destination)
        }
    }
    
    @ViewBuilder
    private func modalDestinationView(for destination: NavigationDestination) -> some View {
        switch destination {
        case .settings:
            SettingsView()
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            navigationCoordinator.dismissModal()
                        }
                    }
                }
                
        case .help:
            HelpView()
                .navigationTitle("Help & Support")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            navigationCoordinator.dismissModal()
                        }
                    }
                }
                
        case .notifications:
            NotificationsView()
                .navigationTitle("Notifications")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            navigationCoordinator.dismissModal()
                        }
                    }
                }
                
        case .maintenance(let message):
            MaintenanceView(message: message)
                .navigationTitle("Maintenance")
                .navigationBarTitleDisplayMode(.inline)
                
        default:
            // For other destinations that shouldn't be modals
            Text("This destination should not be presented as a modal")
                .foregroundColor(.secondary)
                .navigationTitle("Error")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") {
                            navigationCoordinator.dismissModal()
                        }
                    }
                }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleDeepLink(_ url: URL) {
        print("🔗 Deep link received: \(url)")
        
        // Handle the deep link through the navigation coordinator
        let handled = navigationCoordinator.handleDeepLink(url)
        
        if !handled {
            print("⚠️ Deep link could not be handled: \(url)")
            // Optionally show an alert or toast message
        }
    }
}

// MARK: - Supporting Modal Views

struct SettingsView: View {
    var body: some View {
        List {
            Section("Account") {
                SettingsRow(icon: "person.circle", title: "Profile Settings", destination: .constant(nil))
                SettingsRow(icon: "lock", title: "Privacy & Security", destination: .constant(nil))
                SettingsRow(icon: "bell", title: "Notifications", destination: .constant(nil))
            }
            
            Section("App") {
                SettingsRow(icon: "paintbrush", title: "Appearance", destination: .constant(nil))
                SettingsRow(icon: "location", title: "Location Services", destination: .constant(nil))
                SettingsRow(icon: "wifi", title: "Data & Storage", destination: .constant(nil))
            }
            
            Section("Support") {
                SettingsRow(icon: "questionmark.circle", title: "Help & Support", destination: .constant(nil))
                SettingsRow(icon: "envelope", title: "Contact Us", destination: .constant(nil))
                SettingsRow(icon: "star", title: "Rate App", destination: .constant(nil))
            }
            
            Section("About") {
                SettingsRow(icon: "info.circle", title: "About Up2", destination: .constant(nil))
                SettingsRow(icon: "doc.text", title: "Terms of Service", destination: .constant(nil))
                SettingsRow(icon: "hand.raised", title: "Privacy Policy", destination: .constant(nil))
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

struct HelpView: View {
    var body: some View {
        List {
            Section("Getting Started") {
                HelpRow(title: "How to create your profile", description: "Learn how to set up your profile and preferences")
                HelpRow(title: "Finding events near you", description: "Discover how to explore events in your area")
                HelpRow(title: "Following friends", description: "Connect with friends and see what events they're attending")
            }
            
            Section("Features") {
                HelpRow(title: "Event discovery", description: "Learn about our personalized event recommendations")
                HelpRow(title: "Map view", description: "Explore events using our interactive map")
                HelpRow(title: "Trending events", description: "See what's popular in your area")
            }
            
            Section("Account & Settings") {
                HelpRow(title: "Managing your account", description: "Update your profile and account settings")
                HelpRow(title: "Privacy controls", description: "Control who can see your activity")
                HelpRow(title: "Notification settings", description: "Customize your notification preferences")
            }
            
            Section("Support") {
                HelpRow(title: "Contact support", description: "Get help from our support team")
                HelpRow(title: "Report a problem", description: "Let us know about any issues you're experiencing")
                HelpRow(title: "Feature requests", description: "Suggest new features for the app")
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

struct NotificationsView: View {
    @State private var pushNotifications = true
    @State private var emailNotifications = false
    @State private var eventReminders = true
    @State private var friendActivity = true
    @State private var newEvents = false
    @State private var trending = true
    
    var body: some View {
        List {
            Section("Push Notifications") {
                Toggle("Enable Push Notifications", isOn: $pushNotifications)
            }
            
            Section("Event Notifications") {
                Toggle("Event Reminders", isOn: $eventReminders)
                    .disabled(!pushNotifications)
                Toggle("New Events in Your Area", isOn: $newEvents)
                    .disabled(!pushNotifications)
                Toggle("Trending Events", isOn: $trending)
                    .disabled(!pushNotifications)
            }
            
            Section("Social Notifications") {
                Toggle("Friend Activity", isOn: $friendActivity)
                    .disabled(!pushNotifications)
            }
            
            Section("Email Notifications") {
                Toggle("Weekly Summary", isOn: $emailNotifications)
            }
            
            Section {
                Text("You can manage notification permissions in your device settings.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .listStyle(InsetGroupedListStyle())
    }
}

struct MaintenanceView: View {
    let message: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 80))
                .foregroundColor(.orange)
            
            Text("Under Maintenance")
                .font(.title)
                .fontWeight(.bold)
            
            Text(message ?? "We're currently performing maintenance to improve your experience. Please check back shortly.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Check Again") {
                // TODO: Implement retry logic
            }
            .buttonStyle(.bordered)
            .buttonBorderShape(.roundedRectangle)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Supporting Components

struct SettingsRow: View {
    let icon: String
    let title: String
    @Binding var destination: NavigationDestination?
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // TODO: Handle navigation to specific settings
        }
    }
}

struct HelpRow: View {
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            // TODO: Navigate to detailed help content
        }
    }
}

 