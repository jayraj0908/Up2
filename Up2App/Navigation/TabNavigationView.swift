import SwiftUI

// MARK: - Tab Navigation View
struct TabNavigationView: View {
    
    // MARK: - Environment and State
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject var appStateManager: AppStateManager
    // Create event state removed - functionality moved to "Become a Host"
    
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
            VStack(spacing: 0) {
                // Main Content Area
                contentArea
                
                // Tab Bar
                tabBarSection
            }
            
            // Floating Action Button for Create Event - REMOVED
            // Create event functionality moved to "Become a Host" in More tab
        }
        .sheet(item: Binding<NavigationDestination?>(
            get: { navigationCoordinator.presentedModal },
            set: { _ in navigationCoordinator.dismissModal() }
        )) { destination in
            modalContent(for: destination)
        }
        // Create event sheet removed - functionality moved to "Become a Host"
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }
    
    // MARK: - Content Area
    private var contentArea: some View {
        ZStack {
            // Tab Content
            ForEach(AppTab.allCases, id: \.rawValue) { tab in
                if tab == navigationCoordinator.selectedTab {
                    tabContentView(for: tab)
                        .transition(.opacity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.2), value: navigationCoordinator.selectedTab)
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
    
    private func handleTabSelection(_ tabId: String) {
        guard let selectedTab = AppTab(rawValue: tabId) else { return }
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Handle double-tap to scroll to top or pop to root
        if navigationCoordinator.selectedTab == selectedTab {
            // Same tab tapped - pop to root if there's a navigation stack
            if navigationCoordinator.canNavigateBack(in: selectedTab) {
                navigationCoordinator.popToRoot(for: selectedTab)
            }
            // TODO: Add scroll to top functionality when we implement the tab content views
        }
        
        print("📱 Tab selected: \(selectedTab.title)")
    }
    
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

 