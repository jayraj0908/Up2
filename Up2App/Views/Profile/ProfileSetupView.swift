import SwiftUI

struct ProfileSetupView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @Environment(\.dismiss) private var dismiss
    @Binding var isPresented: Bool
    @EnvironmentObject var appStateManager: AppStateManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Bar
                ProfileProgressBar(
                    currentStep: viewModel.currentStepNumber,
                    totalSteps: viewModel.totalSteps,
                    progress: viewModel.progressPercentage
                )
                .padding(.horizontal, Up2Spacing.screenEdge)
                .padding(.top, Up2Spacing.sm)
                
                // Content
                ScrollView {
                    VStack(spacing: Up2Spacing.xxl) {
                        // Header
                        VStack(spacing: Up2Spacing.sm) {
                            Text(viewModel.currentStepTitle)
                                .font(Up2Typography.displayMedium)
                                .foregroundColor(Up2Colors.textPrimary)
                                .multilineTextAlignment(.center)
                            
                            if !viewModel.isLastStep {
                                Text("Let's create your profile")
                                    .font(Up2Typography.heading3)
                                    .foregroundColor(Up2Colors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding(.top, Up2Spacing.xl)
                        
                        // Step Content
                        Group {
                            switch viewModel.currentStep {
                            case .basicInfo:
                                BasicInfoStepView(viewModel: viewModel)
                            case .avatar:
                                AvatarStepView(viewModel: viewModel)
                            case .vibeTags:
                                VibeTagsStepView(viewModel: viewModel)
                            case .bio:
                                BioStepView(viewModel: viewModel)
                            case .complete:
                                CompletionStepView(viewModel: viewModel)
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: viewModel.currentStep)
                    }
                    .padding(.horizontal, Up2Spacing.screenEdge)
                    .padding(.bottom, 100) // Space for bottom buttons
                }
                
                Spacer()
                
                // Navigation Buttons
                ProfileNavigationButtons(viewModel: viewModel, isPresented: $isPresented)
                    .padding(.horizontal, Up2Spacing.screenEdge)
                    .padding(.bottom, Up2Spacing.xxl)
            }
            .navigationBarHidden(true)
            .background(Up2Colors.background)
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
            Task {
                await viewModel.loadCurrentUserProfile()
            }
        }
    }
}

// MARK: - Progress Bar

struct ProfileProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    let progress: Double
    
    var body: some View {
        VStack(spacing: Up2Spacing.md) {
            HStack {
                Text("Step \(currentStep + 1) of \(totalSteps)")
                    .font(Up2Typography.caption)
                    .foregroundColor(Up2Colors.textSecondary)
                
                Spacer()
                
                Text("\(Int(progress * 100))%")
                    .font(Up2Typography.caption)
                    .fontWeight(.medium)
                    .foregroundColor(Up2Colors.primary)
            }
            
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: Up2Colors.primary))
        }
    }
}

// MARK: - Step Views

struct BasicInfoStepView: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        Up2Card {
            VStack(spacing: Up2Spacing.xl) {
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
}

struct AvatarStepView: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        Up2Card {
            VStack(spacing: Up2Spacing.xl) {
                Text("Add Your Photo")
                    .font(Up2Typography.heading3)
                    .foregroundColor(Up2Colors.textPrimary)
                
                Text("Choose a profile picture to help others recognize you")
                    .font(Up2Typography.bodyMedium)
                    .foregroundColor(Up2Colors.textSecondary)
                .multilineTextAlignment(.center)
            
                // Avatar Upload Component - Updated for design system
            AvatarUploadView(
                selectedImage: $viewModel.selectedAvatarImage,
                avatarURL: $viewModel.profile.avatar,
                                size: 120,
                userId: viewModel.profile.id
            )
            }
        }
    }
}

struct VibeTagsStepView: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        Up2Card {
            VStack(alignment: .leading, spacing: Up2Spacing.xl) {
                VStack(alignment: .leading, spacing: Up2Spacing.sm) {
                    Text("Choose Your Vibe")
                        .font(Up2Typography.heading3)
                        .foregroundColor(Up2Colors.textPrimary)
                    
                    Text("Select up to 5 tags that describe your mood and interests")
                        .font(Up2Typography.bodyMedium)
                        .foregroundColor(Up2Colors.textSecondary)
                }
                
                // Vibe Tags Selection - Updated for design system
                                                VibeTagsSelectionView(
                                    selectedTags: $viewModel.selectedVibeTags,
                                    maxSelections: 5,
                                    showCategories: true
                                )
            }
        }
    }
}

struct BioStepView: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        Up2Card {
            VStack(spacing: Up2Spacing.xl) {
                VStack(alignment: .leading, spacing: Up2Spacing.sm) {
                    Text("Tell Us About Yourself")
                        .font(Up2Typography.heading3)
                        .foregroundColor(Up2Colors.textPrimary)
                    
                    Text("Write a short bio to help others get to know you (optional)")
                        .font(Up2Typography.bodyMedium)
                        .foregroundColor(Up2Colors.textSecondary)
                }
                
                                                Up2TextField(
                                    text: $viewModel.bio,
                                    placeholder: "Write something about yourself...",
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
}

struct CompletionStepView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @EnvironmentObject var appStateManager: AppStateManager
    
    var body: some View {
        Up2Card {
            VStack(spacing: Up2Spacing.xl) {
            Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(Up2Colors.success)
            
                Text("Profile Complete!")
                    .font(Up2Typography.heading2)
                    .foregroundColor(Up2Colors.textPrimary)
                
                Text("Your profile has been created successfully. You're all set to start connecting with others!")
                    .font(Up2Typography.bodyMedium)
                    .foregroundColor(Up2Colors.textSecondary)
                    .multilineTextAlignment(.center)
                
                // Bypass button for testing
                #if DEBUG
                Button("Skip to Main App (Debug)") {
                    handleProfileCompletion()
                }
                .font(Up2Typography.buttonMedium)
                .foregroundColor(Up2Colors.primary)
                .padding(.top, Up2Spacing.md)
                #endif
            }
        }
    }
    
    private func handleProfileCompletion() {
        // Mark profile setup as complete and navigate to main app
        appStateManager.handleProfileSetupComplete()
    }
}

// MARK: - Navigation Buttons

struct ProfileNavigationButtons: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Binding var isPresented: Bool
    @EnvironmentObject var appStateManager: AppStateManager
    
    var body: some View {
        VStack(spacing: Up2Spacing.lg) {
            HStack(spacing: Up2Spacing.lg) {
                // Back Button
                if !viewModel.isFirstStep {
                                            Up2Button(
                            "Back",
                            style: .secondary,
                            size: .large
                        ) {
                        viewModel.previousStep()
                    }
                }
                
                // Next/Complete Button
                                        Up2Button(
                            viewModel.isLastStep ? "Get Started" : "Continue",
                            style: .primary,
                            size: .large,
                            isEnabled: viewModel.canProceedToNextStep(),
                            isLoading: viewModel.isLoading
                        ) {
                    if viewModel.isLastStep {
                        Task {
                            await viewModel.createProfile()
                                    if viewModel.successMessage != nil {
                                        handleProfileCompletion()
                                    }
                        }
                    } else {
                        viewModel.nextStep()
                    }
                }
                .frame(maxWidth: .infinity)
            }
            
            // Skip Button (always visible for quick testing)
            Button("Skip to Main App") {
                handleProfileCompletion()
            }
            .font(Up2Typography.buttonMedium)
            .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0)) // Blue color
        }
    }
    
    private func handleProfileCompletion() {
        // Mark profile setup as complete and navigate to main app
        appStateManager.handleProfileSetupComplete()
        isPresented = false
    }
}

#Preview {
    ProfileSetupView(isPresented: .constant(true))
        .environmentObject(AppStateManager.shared)
} 