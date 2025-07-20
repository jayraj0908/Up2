import SwiftUI

// MARK: - Profile Tab View
struct ProfileTabView: View {
    
    // MARK: - Environment
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject var appStateManager: AppStateManager
    
    // MARK: - State
    @State private var showingEditProfile = false
    @State private var showingSettings = false
    @State private var refreshing = false
    
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
                
                VStack(spacing: 0) {
                    // Header
                    profileHeader
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Quick Stats
                            quickStats
                            
                            // Profile Actions
                            profileActions
                            
                            // Recent Activity
                            recentActivity
                            
                            // Sign Out Section
                            signOutSection
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 100) // Account for tab bar
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Navigation header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Profile")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Manage your account")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Settings button
                Button(action: { 
                    navigationCoordinator.presentModal(.settings)
                }) {
                    Image(systemName: "gear")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            
            // Profile info card
            profileInfoCard
        }
    }
    
    // MARK: - Profile Info Card
    private var profileInfoCard: some View {
        VStack(spacing: 16) {
            // Avatar and basic info
            HStack(spacing: 16) {
                // Avatar
                profileAvatar
                
                // User info
                VStack(alignment: .leading, spacing: 4) {
                    if let user = appStateManager.currentUser {
                        Text(user.email?.components(separatedBy: "@").first ?? user.phone ?? "User")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(user.email ?? user.phone ?? "No contact info")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Note: Join date will be available when profile integration is complete
                        Text("Member since this version")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Profile Loading...")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Edit button
                Button("Edit") {
                    showingEditProfile = true
                }
                .buttonStyle(.bordered)
                .buttonBorderShape(.roundedRectangle)
            }
            
            // Bio or placeholder
            if let bio = getCurrentUserBio() {
                Text(bio)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Add a bio to tell others about yourself")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .onTapGesture {
                        showingEditProfile = true
                    }
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Profile Avatar
    private var profileAvatar: some View {
        Group {
            if let avatarURL = getCurrentUserAvatarURL() {
                AsyncImage(url: avatarURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ProgressView()
                }
            } else {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(Circle())
        .overlay(
            Circle()
                .stroke(Color(.systemBackground), lineWidth: 3)
        )
    }
    
    // MARK: - Quick Stats
    private var quickStats: some View {
        HStack(spacing: 0) {
            StatItem(title: "Events", value: "12", subtitle: "Attended")
            
            Divider().frame(height: 50)
            
            StatItem(title: "Friends", value: "24", subtitle: "Following")
            
            Divider().frame(height: 50)
            
            StatItem(title: "Reviews", value: "8", subtitle: "Written")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Profile Actions
    private var profileActions: some View {
        VStack(spacing: 12) {
            Text("Profile Actions")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 8) {
                ProfileActionRow(
                    icon: "person.circle",
                    title: "Edit Profile",
                    subtitle: "Update your information",
                    color: .blue
                ) {
                    showingEditProfile = true
                }
                
                ProfileActionRow(
                    icon: "heart.circle",
                    title: "Saved Events",
                    subtitle: "Events you're interested in",
                    color: .red
                ) {
                    // Navigate to saved events (placeholder)
                }
                
                ProfileActionRow(
                    icon: "person.2.circle",
                    title: "Friends",
                    subtitle: "Manage your connections",
                    color: .green
                ) {
                    // Navigate to friends list (placeholder)
                }
                
                ProfileActionRow(
                    icon: "star.circle",
                    title: "Reviews",
                    subtitle: "Your event reviews",
                    color: .yellow
                ) {
                    // Navigate to reviews (placeholder)
                }
                
                ProfileActionRow(
                    icon: "bell.circle",
                    title: "Notifications",
                    subtitle: "Manage your alerts",
                    color: .orange
                ) {
                    navigationCoordinator.presentModal(.notifications)
                }
            }
        }
    }
    
    // MARK: - Recent Activity
    private var recentActivity: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("See All") {
                    // Navigate to full activity feed
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                ActivityRow(
                    icon: "calendar.badge.plus",
                    title: "Attended Summer Music Festival",
                    time: "2 days ago",
                    color: .blue
                )
                
                ActivityRow(
                    icon: "heart.fill",
                    title: "Saved Tech Conference 2024",
                    time: "1 week ago",
                    color: .red
                )
                
                ActivityRow(
                    icon: "star.fill",
                    title: "Reviewed Art Gallery Opening",
                    time: "2 weeks ago",
                    color: .yellow
                )
            }
            
            // Placeholder message
            Text("More activity features coming in Epic 2!")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 8)
        }
    }
    
    // MARK: - Sign Out Section
    private var signOutSection: some View {
        VStack(spacing: 16) {
            Button("Sign Out") {
                appStateManager.signOut()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(12)
            .font(.headline)
            
            Text("You can always sign back in later")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Helper Methods
    
    private func refreshProfile() async {
        refreshing = true
        // Simulate API call to refresh profile data
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        refreshing = false
    }
    
    private func getCurrentUserBio() -> String? {
        // This would integrate with the profile service to get the user's bio
        // For now, return nil as placeholder
        return nil
    }
    
    private func getCurrentUserAvatarURL() -> URL? {
        // This would integrate with the profile service to get the user's avatar
        // For now, return nil as placeholder
        return nil
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ProfileActionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
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

struct ActivityRow: View {
    let icon: String
    let title: String
    let time: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
    }
}

// MARK: - Sheet Views

struct ProfileEditSheet: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Profile editing will integrate with existing ProfileEditView from Epic 1")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                
                Spacer()
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}

struct SettingsSheet: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                Text("Settings will be implemented as part of the navigation modal system")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("Settings")
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