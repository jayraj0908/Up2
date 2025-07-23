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
    @State private var showingLoginSheet = false
    
    // MARK: - Soft Gate Overlay
    private var softGateOverlay: some View {
        VStack {
            Spacer()
            
            VStack(spacing: Up2Spacing.lg) {
                // Lock Icon
                Image(systemName: "lock.fill")
                    .font(.system(size: 40))
                    .foregroundColor(Up2Colors.accent)
                
                // Message
                VStack(spacing: Up2Spacing.sm) {
                    Text("Sign In to Access More Features")
                        .font(Up2Typography.heading2)
                        .fontWeight(.semibold)
                        .foregroundColor(Up2Colors.textInverse)
                    
                    Text("Create an account or sign in to access host tools, settings, and additional features.")
                        .font(Up2Typography.bodySmall)
                        .foregroundColor(Up2Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Up2Spacing.xl)
                }
                
                // Action Buttons
                VStack(spacing: Up2Spacing.md) {
                    Up2Button("Sign In", style: .primary) {
                        showingLoginSheet = true
                    }
                    
                    Up2Button("Continue Browsing", style: .secondary) {
                        // Dismiss overlay - user can continue browsing
                    }
                }
            }
            .padding(Up2Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Up2Colors.primary.opacity(0.3), Up2Colors.accent.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .padding(.horizontal, Up2Spacing.lg)
            
            Spacer()
        }
        .background(
            Rectangle()
                .fill(.black.opacity(0.3))
                .ignoresSafeArea()
        )
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Liquid Glass Background
                Up2LiquidGlassBackground()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Host Dashboard Section (Soft Gated)
                        hostDashboardSection
                        
                        // Public Features (Always Accessible)
                        publicFeaturesSection
                        
                        // Authenticated Features (Soft Gated)
                        if appStateManager.isAuthenticated {
                            authenticatedFeaturesSection
                        } else {
                            guestFeaturesSection
                        }
                    }
                    .padding(.vertical)
                }
                
                // Soft Gate Overlay for Guest Users
                if !appStateManager.isAuthenticated {
                    softGateOverlay
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingHostDashboard) {
                HostDashboardView()
            }
            .sheet(isPresented: $showingBecomeHost) {
                BecomeHostView()
            }
            .sheet(isPresented: $showingLoginSheet) {
                LoginView()
            }
        }
    }
    
    // MARK: - Host Dashboard Section
    private var hostDashboardSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Host Tools", icon: "crown")
            
            // Become a Host option (Soft Gated)
            if appStateManager.isAuthenticated {
                MoreRow(
                    icon: "plus.circle.fill",
                    title: "Become a Host",
                    subtitle: "Start creating and managing events",
                    color: Color.orange,
                    badge: "New",
                    isLocked: false
                ) {
                    showingBecomeHost = true
                }
                
                // Host Dashboard (only show if user has completed host onboarding)
                if appStateManager.softGateState == .complete {
                    MoreRow(
                        icon: "chart.bar",
                        title: "Host Dashboard",
                        subtitle: "Manage your events and view analytics",
                        color: Color(red: 0.0, green: 0.48, blue: 1.0),
                        badge: nil,
                        isLocked: false
                    ) {
                        showingHostDashboard = true
                    }
                }
            } else {
                // Guest version - show locked
                MoreRow(
                    icon: "plus.circle.fill",
                    title: "Become a Host",
                    subtitle: "Start creating and managing events",
                    color: Color.orange,
                    badge: "New",
                    isLocked: true
                ) {
                    showingLoginSheet = true
                }
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Public Features Section
    private var publicFeaturesSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "App Info", icon: "info.circle")
            
            MoreRow(
                icon: "questionmark.circle",
                title: "Help & Support",
                subtitle: "Get help and contact us",
                color: Color.blue,
                badge: nil,
                isLocked: false
            ) {
                // TODO: Navigate to help
            }
            
            MoreRow(
                icon: "doc.text",
                title: "Terms of Service",
                subtitle: "Read our terms and conditions",
                color: Color.gray,
                badge: nil,
                isLocked: false
            ) {
                // TODO: Navigate to terms
            }
            
            MoreRow(
                icon: "hand.raised",
                title: "Privacy Policy",
                subtitle: "How we protect your data",
                color: Color.green,
                badge: nil,
                isLocked: false
            ) {
                // TODO: Navigate to privacy
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Authenticated Features Section
    private var authenticatedFeaturesSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Account", icon: "person.circle")
            
            MoreRow(
                icon: "gearshape",
                title: "Settings",
                subtitle: "Manage your preferences",
                color: Color.purple,
                badge: nil,
                isLocked: false
            ) {
                // TODO: Navigate to settings
            }
            
            MoreRow(
                icon: "bell",
                title: "Notifications",
                subtitle: "Manage your notifications",
                color: Color.orange,
                badge: nil,
                isLocked: false
            ) {
                // TODO: Navigate to notifications
            }
            
            MoreRow(
                icon: "creditcard",
                title: "Payment Methods",
                subtitle: "Manage your payment info",
                color: Color.green,
                badge: nil,
                isLocked: false
            ) {
                // TODO: Navigate to payments
            }
            
            MoreRow(
                icon: "person.2",
                title: "Invite Friends",
                subtitle: "Share Up2 with friends",
                color: Color.blue,
                badge: nil,
                isLocked: false
            ) {
                // TODO: Share app
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Guest Features Section (Soft Gated)
    private var guestFeaturesSection: some View {
        VStack(spacing: 16) {
            SectionHeader(title: "Account", icon: "person.circle")
            
            MoreRow(
                icon: "gearshape",
                title: "Settings",
                subtitle: "Manage your preferences",
                color: Color.purple,
                badge: nil,
                isLocked: true
            ) {
                showingLoginSheet = true
            }
            
            MoreRow(
                icon: "bell",
                title: "Notifications",
                subtitle: "Manage your notifications",
                color: Color.orange,
                badge: nil,
                isLocked: true
            ) {
                showingLoginSheet = true
            }
            
            MoreRow(
                icon: "creditcard",
                title: "Payment Methods",
                subtitle: "Manage your payment info",
                color: Color.green,
                badge: nil,
                isLocked: true
            ) {
                showingLoginSheet = true
            }
            
            MoreRow(
                icon: "person.2",
                title: "Invite Friends",
                subtitle: "Share Up2 with friends",
                color: Color.blue,
                badge: nil,
                isLocked: true
            ) {
                showingLoginSheet = true
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
    let isLocked: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isLocked ? Color.gray : color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(isLocked ? Color.gray : .primary)
                        
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(Color.gray)
                        }
                    }
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(isLocked ? Color.gray.opacity(0.7) : .secondary)
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
                    .foregroundColor(isLocked ? Color.gray : .secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .opacity(isLocked ? 0.6 : 1.0)
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