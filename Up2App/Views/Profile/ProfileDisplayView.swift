import SwiftUI

struct ProfileDisplayView: View {
    let profile: ProfileData
    let isCurrentUser: Bool
    let onEdit: (() -> Void)?
    let onConnect: (() -> Void)?
    
    @State private var showingEditView = false
    
    init(profile: ProfileData, isCurrentUser: Bool = false, onEdit: (() -> Void)? = nil, onConnect: (() -> Void)? = nil) {
        self.profile = profile
        self.isCurrentUser = isCurrentUser
        self.onEdit = onEdit
        self.onConnect = onConnect
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: Up2Spacing.xxl) {
                // Header Section
                headerSection
                
                // Bio Section
                if !profile.bio.isEmpty {
                    bioSection
                }
                
                // Vibe Tags Section
                if !profile.vibeTags.isEmpty {
                    vibeTagsSection
                }
                
                // Profile Stats
                profileStatsSection
                
                // Event History Section
                eventHistorySection
            }
            .padding(.horizontal, Up2Spacing.screenEdge)
            .padding(.bottom, 100) // Space for action buttons
        }
        .background(Up2Colors.background)
        .overlay(alignment: .bottom) {
            if !isCurrentUser {
                // Connect Button for other users
                VStack(spacing: Up2Spacing.lg) {
                    Divider()
                    
                    Up2Button(
                        "Connect",
                        style: .primary,
                        size: .large
                    ) {
                        onConnect?()
                    }
                    .padding(.horizontal, Up2Spacing.screenEdge)
                    .padding(.bottom, Up2Spacing.xl)
                }
                .background(Up2Colors.background)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isCurrentUser {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Up2Button(
                        "Edit",
                        style: .secondary,
                        size: .small
                    ) {
                        if let onEdit = onEdit {
                            onEdit()
                        } else {
                            showingEditView = true
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            ProfileEditView(existingProfile: profile)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        Up2Card {
            VStack(spacing: Up2Spacing.xl) {
                // Avatar and Online Status
                Up2Avatar(
                    imageURL: profile.avatar,
                    initials: String(profile.name.prefix(2)).uppercased(),
                    size: .extraLarge,
                    style: .circle,
                    showOnlineIndicator: true,
                    isOnline: true
                )
                
                // Name and Handle
                VStack(spacing: Up2Spacing.sm) {
                    Text(profile.name)
                        .font(Up2Typography.displaySmall)
                        .foregroundColor(Up2Colors.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("@\(profile.handle)")
                        .font(Up2Typography.heading4)
                        .foregroundColor(Up2Colors.textSecondary)
                }
                
                // Quick Stats
                HStack(spacing: Up2Spacing.xl) {
                    QuickStatItem(
                        icon: "calendar",
                        value: "0",
                        label: "Events"
                    )
                    
                    QuickStatItem(
                        icon: "person.2",
                        value: "0",
                        label: "Friends"
                    )
                    
                    QuickStatItem(
                        icon: "star",
                        value: "5.0",
                        label: "Rating"
                    )
                }
            }
        }
    }
    
    // MARK: - Bio Section
    
    private var bioSection: some View {
        Up2Card {
            VStack(alignment: .leading, spacing: Up2Spacing.md) {
                HStack {
                    Text("About")
                        .font(Up2Typography.heading4)
                        .foregroundColor(Up2Colors.textPrimary)
                    
                    Spacer()
                }
                
                Text(profile.bio)
                    .font(Up2Typography.bodyMedium)
                    .foregroundColor(Up2Colors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
        }
    }
    
    // MARK: - Vibe Tags Section
    
    private var vibeTagsSection: some View {
        Up2Card {
            VStack(alignment: .leading, spacing: Up2Spacing.lg) {
                HStack {
                    Text("Vibe Tags")
                        .font(Up2Typography.heading4)
                        .foregroundColor(Up2Colors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(profile.vibeTags.count)")
                        .font(Up2Typography.caption)
                        .foregroundColor(Up2Colors.textSecondary)
                }
                
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80), spacing: Up2Spacing.sm)
                ], spacing: Up2Spacing.sm) {
                    ForEach(profile.vibeTags, id: \.self) { tag in
                        Up2Tag(
                            tag.displayName,
                            style: .filled,
                            size: .medium
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Profile Stats Section
    
    private var profileStatsSection: some View {
        Up2Card {
            VStack(spacing: Up2Spacing.lg) {
                HStack {
                    Text("Profile Stats")
                        .font(Up2Typography.heading4)
                        .foregroundColor(Up2Colors.textPrimary)
                    
                    Spacer()
                }
                
                VStack(spacing: Up2Spacing.lg) {
                    // Joined Date
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .foregroundColor(Up2Colors.primary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: Up2Spacing.xs) {
                            Text("Member Since")
                                .font(Up2Typography.caption)
                                .foregroundColor(Up2Colors.textSecondary)
                            
                            Text(DateFormatter.memberSince.string(from: profile.createdAt))
                                .font(Up2Typography.bodyMedium)
                                .foregroundColor(Up2Colors.textPrimary)
                        }
                        
                        Spacer()
                    }
                    
                    // Last Active
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(Up2Colors.primary)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: Up2Spacing.xs) {
                            Text("Last Active")
                                .font(Up2Typography.caption)
                                .foregroundColor(Up2Colors.textSecondary)
                            
                            Text(DateFormatter.lastActive.string(from: profile.updatedAt))
                                .font(Up2Typography.bodyMedium)
                                .foregroundColor(Up2Colors.textPrimary)
                        }
                        
                        Spacer()
                    }
                    
                    // Profile Completeness
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(Up2Colors.success)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: Up2Spacing.xs) {
                            Text("Profile Completeness")
                                .font(Up2Typography.caption)
                                .foregroundColor(Up2Colors.textSecondary)
                            
                            Text("\(profileCompletenessPercentage)% Complete")
                                .font(Up2Typography.bodyMedium)
                                .foregroundColor(Up2Colors.textPrimary)
                        }
                        
                        Spacer()
                        
                        Text("\(profileCompletenessPercentage)%")
                            .font(Up2Typography.heading4)
                            .foregroundColor(Up2Colors.primary)
                    }
                }
            }
        }
    }
    
    // MARK: - Event History Section
    
    private var eventHistorySection: some View {
        Up2Card {
            VStack(alignment: .leading, spacing: Up2Spacing.lg) {
                HStack {
                    Text("Event History")
                        .font(Up2Typography.heading4)
                        .foregroundColor(Up2Colors.textPrimary)
                    
                    Spacer()
                    
                    if isCurrentUser {
                        Button("Privacy") {
                            // TODO: Navigate to privacy settings
                        }
                        .font(Up2Typography.caption)
                        .foregroundColor(Up2Colors.primary)
                    }
                }
                
                // Placeholder for events (Epic 2 integration)
                VStack(spacing: Up2Spacing.lg) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 48))
                        .foregroundColor(Up2Colors.textSecondary)
                    
                    VStack(spacing: Up2Spacing.sm) {
                        Text("No Events Yet")
                            .font(Up2Typography.heading4)
                            .foregroundColor(Up2Colors.textPrimary)
                        
                        Text(isCurrentUser ? "Join events to build your history" : "This user hasn't attended any events yet")
                            .font(Up2Typography.bodyMedium)
                            .foregroundColor(Up2Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    if isCurrentUser {
                        Up2Button(
                            "Discover Events",
                            style: .secondary,
                            size: .medium
                        ) {
                            // TODO: Navigate to events discovery
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Up2Spacing.xl)
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var profileCompletenessPercentage: Int {
        var completedFields = 0
        let totalFields = 5
        
        // Check basic info
        if !profile.name.isEmpty { completedFields += 1 }
        if !profile.handle.isEmpty { completedFields += 1 }
        
        // Check optional fields
        if profile.avatar != nil { completedFields += 1 }
        if !profile.bio.isEmpty { completedFields += 1 }
        if !profile.vibeTags.isEmpty { completedFields += 1 }
        
        return Int((Double(completedFields) / Double(totalFields)) * 100)
    }
}

// MARK: - Quick Stat Item

struct QuickStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: Up2Spacing.xs) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Up2Colors.primary)
            
            Text(value)
                .font(Up2Typography.heading4)
                .foregroundColor(Up2Colors.textPrimary)
            
            Text(label)
                .font(Up2Typography.caption)
                .foregroundColor(Up2Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Compact Profile Card (for lists)

struct CompactProfileCard: View {
    let profile: ProfileData
    let onTap: () -> Void
    
    var body: some View {
        Up2Card {
            HStack(spacing: Up2Spacing.lg) {
                Up2Avatar(
                    imageURL: profile.avatar,
                    initials: String(profile.name.prefix(2)).uppercased(),
                    size: .medium,
                    style: .circle
                )
                
                VStack(alignment: .leading, spacing: Up2Spacing.xs) {
                    Text(profile.name)
                        .font(Up2Typography.bodyMedium)
                        .foregroundColor(Up2Colors.textPrimary)
                    
                    Text("@\(profile.handle)")
                        .font(Up2Typography.caption)
                        .foregroundColor(Up2Colors.textSecondary)
                    
                    if !profile.vibeTags.isEmpty {
                        CompactVibeTagsView(
                            tags: profile.vibeTags,
                            maxDisplayed: 2
                        )
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(Up2Colors.textSecondary)
                    .font(.system(size: 14))
            }
        }
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Profile Preview Card (for profile setup)

struct ProfilePreviewCard: View {
    let profile: ProfileData
    let selectedImage: UIImage?
    
    var body: some View {
        Up2Card {
            VStack(spacing: Up2Spacing.lg) {
                Up2Avatar(
                    imageURL: selectedImage != nil ? nil : profile.avatar,
                    initials: String(profile.name.prefix(2)).uppercased(),
                    size: .large,
                    style: .circle
                )
                
                VStack(spacing: Up2Spacing.sm) {
                    Text(profile.name.isEmpty ? "Your Name" : profile.name)
                        .font(Up2Typography.heading3)
                        .foregroundColor(Up2Colors.textPrimary)
                    
                    Text("@\(profile.handle.isEmpty ? "username" : profile.handle)")
                        .font(Up2Typography.bodyMedium)
                        .foregroundColor(Up2Colors.textSecondary)
                    
                    if !profile.bio.isEmpty {
                        Text(profile.bio)
                            .font(Up2Typography.bodyMedium)
                            .foregroundColor(Up2Colors.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }
                    
                    if !profile.vibeTags.isEmpty {
                        CompactVibeTagsView(
                            tags: profile.vibeTags,
                            maxDisplayed: 3
                        )
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Date Formatter Extensions

extension DateFormatter {
    static let memberSince: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }()
    
    static let lastActive: DateFormatter = {
        let formatter = DateFormatter()
        formatter.doesRelativeDateFormatting = true
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
}

#Preview {
    NavigationView {
        ProfileDisplayView(
            profile: ProfileData(
                id: UUID(),
                name: "John Doe",
                handle: "johndoe",
                avatar: nil,
                vibeTags: [],
                bio: "Love exploring new places and meeting new people! Always up for an adventure.",
                createdAt: Date().addingTimeInterval(-86400 * 30), // 30 days ago
                updatedAt: Date().addingTimeInterval(-3600) // 1 hour ago
            ),
            isCurrentUser: true
        )
    }
} 