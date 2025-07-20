import SwiftUI

// MARK: - More Tab View
struct MoreTabView: View {
    
    // MARK: - Environment
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject var appStateManager: AppStateManager
    
    // MARK: - State
    @State private var showingAbout = false
    @State private var showingDebug = false
    @State private var showingHostDashboard = false
    @State private var showingBecomeHost = false
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Background - Consistent with host onboarding theme
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color(red: 0.1, green: 0.0, blue: 0.3),
                        Color(red: 0.3, green: 0.0, blue: 0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Host Dashboard Section
                        hostDashboardSection
                        
                        SettingsPlaceholderView()
                        HelpSupportPlaceholderView()
                        AboutPlaceholderView()
                        DeveloperDebugPlaceholderView()
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingHostDashboard) {
                HostDashboardView()
            }
            .sheet(isPresented: $showingBecomeHost) {
                BecomeHostView()
            }
        }
    }
    
    // MARK: - Host Dashboard Section
    private var hostDashboardSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Host Tools", icon: "crown")
            
            // Become a Host option
            MoreRow(
                icon: "plus.circle.fill",
                title: "Become a Host",
                subtitle: "Start creating and managing events",
                color: Color.orange,
                badge: "New"
            ) {
                showingBecomeHost = true
            }
            
            // Host Dashboard (only show if user is already a host)
            if appStateManager.currentUser?.isHost == true {
                MoreRow(
                    icon: "chart.bar",
                    title: "Host Dashboard",
                    subtitle: "Manage your events and view analytics",
                    color: Color(red: 0.0, green: 0.48, blue: 1.0),
                    badge: nil
                ) {
                    showingHostDashboard = true
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    MoreTabView()
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.headline)
                .foregroundColor(.blue)
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
        }
        .padding(.top, 8)
    }
}

struct MoreRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let badge: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if let badge = badge {
                    Text(badge)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Modal Views

struct AboutView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App icon and name
                    VStack(spacing: 16) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("Up2")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Discover Amazing Events")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About Up2")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Up2 helps you discover exciting events happening around you. From music festivals to tech meetups, food tastings to art exhibitions - find events that match your interests and connect with like-minded people.")
                            .font(.body)
                    }
                    
                    // Features
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Features")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        FeatureRow(icon: "safari.fill", title: "Personalized Discovery", description: "AI-powered recommendations based on your interests")
                        FeatureRow(icon: "map.fill", title: "Interactive Map", description: "Explore events visually on an interactive map")
                        FeatureRow(icon: "flame.fill", title: "Trending Events", description: "See what's popular in your area")
                        FeatureRow(icon: "person.2.fill", title: "Social Features", description: "Connect with friends and share experiences")
                    }
                    
                    // Team
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Team")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Up2 is built with love by a team passionate about bringing people together through amazing experiences.")
                            .font(.body)
                    }
                }
                .padding(20)
            }
            .navigationTitle("About Up2")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct DebugView: View {
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Section("Navigation State") {
                    Text("Selected Tab: \(navigationCoordinator.selectedTab.title)")
                    Text("Modal: \(navigationCoordinator.presentedModal?.id ?? "None")")
                    
                    Button("Print Navigation State") {
                        navigationCoordinator.printNavigationState()
                    }
                }
                
                Section("Deep Links") {
                    Button("Test Event Deep Link") {
                        let url = URL(string: "up2://events/test-event")!
                        _ = navigationCoordinator.handleDeepLink(url)
                        presentationMode.wrappedValue.dismiss()
                    }
                    
                    Button("Test Profile Deep Link") {
                        let url = URL(string: "up2://profile/test-user")!
                        _ = navigationCoordinator.handleDeepLink(url)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                Section("Actions") {
                    Button("Reset Navigation") {
                        navigationCoordinator.resetToInitialState()
                    }
                    
                    Button("Clear Analytics") {
                        navigationCoordinator.clearAnalytics()
                    }
                }
            }
            .navigationTitle("Debug Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    MoreTabView()
}