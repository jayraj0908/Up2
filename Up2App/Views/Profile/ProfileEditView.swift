import SwiftUI

struct ProfileEditView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    let existingProfile: ProfileData
    
    @State private var showingDeleteConfirmation = false
    
    init(existingProfile: ProfileData) {
        self.existingProfile = existingProfile
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: Up2Spacing.xxl) {
                    // Header
                    VStack(spacing: Up2Spacing.lg) {
                        Text("Edit Profile")
                            .font(Up2Typography.displayMedium)
                            .foregroundColor(Up2Colors.textPrimary)
                        
                        Text("Update your information and preferences")
                            .font(Up2Typography.bodyMedium)
                            .foregroundColor(Up2Colors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, Up2Spacing.xl)
                    
                    // Avatar Section
                    Up2Card {
                        VStack(spacing: Up2Spacing.lg) {
                            HStack {
                        Text("Profile Photo")
                                    .font(Up2Typography.heading4)
                                    .foregroundColor(Up2Colors.textPrimary)
                                
                                Spacer()
                            }
                        
                        AvatarUploadView(
                            selectedImage: $viewModel.selectedAvatarImage,
                            avatarURL: $viewModel.profile.avatar,
                            size: 120,
                            userId: viewModel.profile.id
                        )
                        }
                    }
                    
                    // Basic Information
                    Up2Card {
                        VStack(spacing: Up2Spacing.lg) {
                            HStack {
                        Text("Basic Information")
                                    .font(Up2Typography.heading4)
                                    .foregroundColor(Up2Colors.textPrimary)
                                
                                Spacer()
                            }
                            
                            VStack(spacing: Up2Spacing.lg) {
                                // Name Field
                                Up2TextField(
                                    text: $viewModel.name,
                                    placeholder: "Enter your full name",
                                    label: "Full Name",
                                    errorText: viewModel.validation.nameValidation.isValid ? nil : viewModel.validation.nameValidation.errorMessage,
                                    fieldType: .text,
                                    isRequired: true
                                )
                                
                                // Handle Field
                                VStack(alignment: .leading, spacing: Up2Spacing.xs) {
                                    Up2TextField(
                                        text: $viewModel.handle,
                                        placeholder: "Choose a unique username",
                                        label: "Username",
                                        errorText: viewModel.validation.handleValidation.isValid ? nil : viewModel.validation.handleValidation.errorMessage,
                                        fieldType: .text,
                                        isRequired: true
                                    )
                            
                            HStack {
                                if viewModel.isCheckingHandle {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                        Text("Checking availability...")
                                                    .font(Up2Typography.caption)
                                                    .foregroundColor(Up2Colors.textSecondary)
                                    }
                                } else if let message = viewModel.handleAvailabilityMessage {
                                    Text(message)
                                                .font(Up2Typography.caption)
                                                .foregroundColor(message.contains("✓") ? Up2Colors.success : Up2Colors.error)
                                }
                                
                                Spacer()
                            }
                                    .padding(.horizontal, Up2Spacing.xs)
                                }
                            }
                        }
                    }
                    
                    // Bio Section
                    Up2Card {
                        VStack(spacing: Up2Spacing.lg) {
                            HStack {
                        Text("About You")
                                    .font(Up2Typography.heading4)
                                    .foregroundColor(Up2Colors.textPrimary)
                                
                                Spacer()
                            }
                            
                            VStack(spacing: Up2Spacing.sm) {
                                Up2TextField(
                                    text: $viewModel.bio,
                                    placeholder: "Tell others about yourself...",
                                    label: "Bio",
                                    fieldType: .text,
                                    maxLength: 150
                                )
                                
                                HStack {
                                    Spacer()
                                    Text("\(viewModel.bio.count) / 150")
                                        .font(Up2Typography.caption)
                                        .foregroundColor(Up2Colors.textSecondary)
                                }
                            }
                        }
                    }
                    
                    // Vibe Tags Section
                    Up2Card {
                        VStack(alignment: .leading, spacing: Up2Spacing.lg) {
                            HStack {
                                Text("Vibe Tags")
                                    .font(Up2Typography.heading4)
                                    .foregroundColor(Up2Colors.textPrimary)
                                
                                Spacer()
                                
                                Text("\(viewModel.selectedVibeTags.count) / 5")
                                    .font(Up2Typography.caption)
                                    .foregroundColor(Up2Colors.textSecondary)
                            }
                            
                            VibeTagsSelectionView(
                                selectedTags: $viewModel.selectedVibeTags,
                                maxSelections: 5,
                                showCategories: true
                            )
                        }
                    }
                    
                    // Privacy & Settings
                    Up2Card {
                        VStack(spacing: Up2Spacing.lg) {
                            HStack {
                                Text("Privacy & Settings")
                                    .font(Up2Typography.heading4)
                                    .foregroundColor(Up2Colors.textPrimary)
                                
                                Spacer()
                            }
                            
                            VStack(spacing: Up2Spacing.md) {
                                ToggleRow(
                                    title: "Show Event History",
                                    description: "Allow others to see your event attendance",
                                    isOn: $viewModel.showEventHistory
                                )
                                
                                ToggleRow(
                                    title: "Profile Discoverable",
                                    description: "Allow others to find your profile",
                                    isOn: $viewModel.isProfileDiscoverable
                                )
                                
                                ToggleRow(
                                    title: "Receive Notifications",
                                    description: "Get notified about events and updates",
                                    isOn: $viewModel.receiveNotifications
                                )
                            }
                        }
                    }
                    
                    // Danger Zone
                    Up2Card {
                        VStack(spacing: Up2Spacing.lg) {
                            HStack {
                                Text("Danger Zone")
                                    .font(Up2Typography.heading4)
                                    .foregroundColor(Up2Colors.error)
                                
                                Spacer()
                            }
                            
                            Up2Button(
                                "Delete Profile",
                                style: .destructive,
                                size: .medium
                            ) {
                                showingDeleteConfirmation = true
                            }
                        }
                    }
                }
                .padding(.horizontal, Up2Spacing.screenEdge)
                .padding(.bottom, 100) // Space for navigation buttons
            }
            .background(Up2Colors.background)
            .navigationBarHidden(true)
            .overlay(alignment: .bottom) {
                // Action Buttons
                VStack(spacing: Up2Spacing.lg) {
                    Divider()
                    
                    HStack(spacing: Up2Spacing.lg) {
                        Up2Button(
                            "Cancel",
                            style: .secondary,
                            size: .large
                        ) {
                        dismiss()
                        }
                        
                        Up2Button(
                            "Save Changes",
                            style: .primary,
                            size: .large,
                            isEnabled: viewModel.isFormValid,
                            isLoading: viewModel.isSaving
                        ) {
                        Task {
                            await viewModel.updateProfile()
                            if viewModel.successMessage != nil {
                                dismiss()
                            }
                        }
                    }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, Up2Spacing.screenEdge)
                    .padding(.bottom, Up2Spacing.xl)
                }
                .background(Up2Colors.background)
            }
        }
        .alert("Delete Profile", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteProfile()
                    if viewModel.successMessage != nil {
                        dismiss()
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete your profile? This action cannot be undone.")
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearMessages()
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
        .onAppear {
        viewModel.profile = existingProfile
        viewModel.name = existingProfile.name
        viewModel.handle = existingProfile.handle
        viewModel.bio = existingProfile.bio
        viewModel.selectedVibeTags = existingProfile.vibeTags
    }
    }
}

// MARK: - Toggle Row Component

struct ToggleRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Up2Spacing.xs) {
                Text(title)
                    .font(Up2Typography.bodyMedium)
                    .foregroundColor(Up2Colors.textPrimary)
                
                Text(description)
                    .font(Up2Typography.caption)
                    .foregroundColor(Up2Colors.textSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Up2Colors.primary))
        }
        .padding(.vertical, Up2Spacing.xs)
    }
}

// MARK: - Profile Statistics Card

struct ProfileStatsCard: View {
    let eventsAttended: Int
    let friendsCount: Int
    let joinDate: Date
    
    var body: some View {
        Up2Card {
            VStack(spacing: Up2Spacing.lg) {
                HStack {
                    Text("Profile Stats")
                        .font(Up2Typography.heading4)
                        .foregroundColor(Up2Colors.textPrimary)
                    
                    Spacer()
                }
                
                HStack(spacing: Up2Spacing.xl) {
                    ProfileStatItem(
                        title: "Events",
                        value: "\(eventsAttended)",
                        subtitle: "attended"
                    )
                    
                    ProfileStatItem(
                        title: "Friends",
                        value: "\(friendsCount)",
                        subtitle: "connections"
                    )
                    
                    ProfileStatItem(
                        title: "Member Since",
                        value: DateFormatter.monthYear.string(from: joinDate),
                        subtitle: ""
                    )
                }
            }
        }
    }
}

// MARK: - Profile Stat Item

struct ProfileStatItem: View {
    let title: String
    let value: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: Up2Spacing.xs) {
            Text(value)
                .font(Up2Typography.heading3)
                .foregroundColor(Up2Colors.primary)
            
            Text(title)
                .font(Up2Typography.caption)
                .foregroundColor(Up2Colors.textSecondary)
            
            Text(subtitle)
                .font(Up2Typography.caption)
                .foregroundColor(Up2Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()
}

#Preview {
    ProfileEditView(
        existingProfile: ProfileData(
            id: UUID(),
                name: "John Doe",
                handle: "johndoe",
            avatar: nil,
            vibeTags: [],
            bio: "Love exploring new places and meeting new people!",
            createdAt: Date(),
            updatedAt: Date()
        )
    )
} 