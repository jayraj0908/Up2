import SwiftUI

struct RegistrationView: View {
    @StateObject private var viewModel = RegistrationViewModel()
    @EnvironmentObject var appStateManager: AppStateManager
    
    // Animation states
    @State private var formOffset: CGFloat = 50
    @State private var formOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.9
    @State private var backgroundOpacity: Double = 0
    
    // Profile setup data
    @State private var fullName: String = ""
    @State private var selectedVibeTags: Set<String> = []
    @State private var selectedAvatarIndex: Int = 0
    
    // Available vibe tags
    private let availableVibeTags = [
        "Techno", "House", "Chill", "Hip Hop", "Rock", "Jazz", 
        "Electronic", "Pop", "R&B", "Reggae", "Country", "Classical"
    ]
    
    // Mock avatar options
    private let avatarOptions = [
        "person.circle.fill", "person.crop.circle.fill", "person.badge.plus.fill",
        "person.2.fill", "person.3.fill", "person.crop.rectangle.fill"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundView
                
                VStack(spacing: Up2Spacing.xl) {
                    headerView
                    
                    switch viewModel.registrationState {
                    case .inputCredentials:
                        registrationFormView
                    case .awaitingVerification, .verifying:
                        VerificationCodeView(viewModel: viewModel)
                    case .completed:
                        registrationCompletedView
                    case .error(let message):
                        errorView(message: message)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, Up2Spacing.screenEdge)
                .opacity(backgroundOpacity)
            }
            .navigationBarHidden(true)
            .onAppear {
                startAnimations()
            }
        }
    }
    
    // MARK: - Background View
    private var backgroundView: some View {
        ZStack {
            // Base gradient - vibrant dark gradient (indigo → magenta)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.0, blue: 0.3), // Deep indigo
                    Color(red: 0.3, green: 0.0, blue: 0.4), // Purple
                    Color(red: 0.5, green: 0.0, blue: 0.3), // Magenta
                    Color(red: 0.2, green: 0.0, blue: 0.2)  // Deep violet
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // UI Blur overlay
            Color.black.opacity(0.3)
                .blur(radius: 0)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: Up2Spacing.lg) {
            // Logo
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .shadow(color: Up2Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
            
            Text("Welcome to Up2")
                .font(Up2Typography.displayMedium)
                .foregroundColor(Up2Colors.textOnPrimary)
                .multilineTextAlignment(.center)
            
            Text("Sign up to connect with friends and discover what everyone's up to")
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2Colors.textOnPrimary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.top, Up2Spacing.xxxl)
    }
    
    // MARK: - Registration Form View
    private var registrationFormView: some View {
        VStack(spacing: Up2Spacing.lg) {
            // Full Name Input
            fullNameField
            
            // Email Input
            emailField
            
            // Vibe Tags Selector
            vibeTagsSection
            
            // Avatar Picker
            avatarPickerSection
            
            // Continue Button
            continueButton
        }
        .offset(y: formOffset)
        .opacity(formOpacity)
    }
    
    // MARK: - Full Name Field
    private var fullNameField: some View {
        VStack(alignment: .leading, spacing: Up2Spacing.xs) {
            Text("Full Name")
                .font(Up2Typography.caption.weight(.medium))
                .foregroundColor(Up2Colors.textOnPrimary.opacity(0.8))
            
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(Up2Colors.textOnPrimary.opacity(0.6))
                    .frame(width: 20)
                
                TextField("Enter your full name", text: $fullName)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(Up2Typography.body)
                    .foregroundColor(Up2Colors.textOnPrimary)
                    .autocapitalization(.words)
            }
            .padding(.horizontal, Up2Spacing.lg)
            .padding(.vertical, Up2Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Up2Colors.surfaceElevated.opacity(0.2))
                    .stroke(Up2Colors.primary.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
    }
    
    // MARK: - Email Field
    private var emailField: some View {
        VStack(alignment: .leading, spacing: Up2Spacing.xs) {
            Text("Email Address")
                .font(Up2Typography.caption.weight(.medium))
                .foregroundColor(Up2Colors.textOnPrimary.opacity(0.8))
            
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(Up2Colors.textOnPrimary.opacity(0.6))
                    .frame(width: 20)
                
                TextField("Enter your email address", text: Binding(
                    get: { viewModel.registrationData.emailAddress },
                    set: { viewModel.updateEmailAddress($0) }
                ))
                .textFieldStyle(PlainTextFieldStyle())
                .font(Up2Typography.body)
                .foregroundColor(Up2Colors.textOnPrimary)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
            }
            .padding(.horizontal, Up2Spacing.lg)
            .padding(.vertical, Up2Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Up2Colors.surfaceElevated.opacity(0.2))
                    .stroke(
                        viewModel.emailValidation.errorMessage != nil ? 
                        Up2Colors.error : Up2Colors.primary.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            if let errorMessage = viewModel.emailValidation.errorMessage {
                Text(errorMessage)
                    .font(Up2Typography.caption)
                    .foregroundColor(Up2Colors.error)
                    .padding(.leading, Up2Spacing.lg)
            }
        }
    }
    
    // MARK: - Vibe Tags Section
    private var vibeTagsSection: some View {
        VStack(alignment: .leading, spacing: Up2Spacing.sm) {
            Text("What's your vibe?")
                .font(Up2Typography.caption.weight(.medium))
                .foregroundColor(Up2Colors.textOnPrimary.opacity(0.8))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Up2Spacing.sm) {
                    ForEach(availableVibeTags, id: \.self) { tag in
                        Button(action: {
                            if selectedVibeTags.contains(tag) {
                                selectedVibeTags.remove(tag)
                            } else {
                                selectedVibeTags.insert(tag)
                            }
                        }) {
                            Text(tag)
                                .font(Up2Typography.caption.weight(.medium))
                                .foregroundColor(selectedVibeTags.contains(tag) ? Up2Colors.textOnPrimary : Up2Colors.textOnPrimary.opacity(0.8))
                                .padding(.horizontal, Up2Spacing.md)
                                .padding(.vertical, Up2Spacing.sm)
                                .background(
                                    Capsule()
                                        .fill(selectedVibeTags.contains(tag) ? Up2Colors.primary : Up2Colors.surfaceElevated.opacity(0.2))
                                        .stroke(Up2Colors.primary.opacity(0.3), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding(.horizontal, Up2Spacing.lg)
            }
        }
    }
    
    // MARK: - Avatar Picker Section
    private var avatarPickerSection: some View {
        VStack(alignment: .leading, spacing: Up2Spacing.sm) {
            Text("Choose your avatar")
                .font(Up2Typography.caption.weight(.medium))
                .foregroundColor(Up2Colors.textOnPrimary.opacity(0.8))
            
            HStack(spacing: Up2Spacing.md) {
                ForEach(Array(avatarOptions.enumerated()), id: \.offset) { index, avatar in
                    Button(action: {
                        selectedAvatarIndex = index
                    }) {
                        Image(systemName: avatar)
                            .font(.system(size: 40))
                            .foregroundColor(selectedAvatarIndex == index ? Up2Colors.textOnPrimary : Up2Colors.textOnPrimary.opacity(0.6))
                            .frame(width: 60, height: 60)
                            .background(
                                Circle()
                                    .fill(selectedAvatarIndex == index ? Up2Colors.primary : Up2Colors.surfaceElevated.opacity(0.2))
                                    .stroke(Up2Colors.primary.opacity(0.3), lineWidth: selectedAvatarIndex == index ? 2 : 1)
                            )
                    }
                }
            }
            .padding(.horizontal, Up2Spacing.lg)
        }
    }
    
    // MARK: - Continue Button
    private var continueButton: some View {
        Button(action: {
            // Bypass logic for testing - allow any input
            if !fullName.isEmpty && !viewModel.registrationData.emailAddress.isEmpty {
                handleDummyRegistration()
            } else {
                viewModel.sendVerificationCode()
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Up2Colors.textOnPrimary))
                        .scaleEffect(0.8)
                } else {
                    Text("Let's Go →")
                        .font(Up2Typography.buttonLarge.weight(.semibold))
                }
            }
            .foregroundColor(Up2Colors.textOnPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Up2Colors.primary,
                        Up2Colors.accent
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Up2Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
            .scaleEffect(buttonScale)
        }
        .disabled(viewModel.isLoading)
        .animation(.easeInOut(duration: 0.2), value: buttonScale)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                buttonScale = 0.95
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    buttonScale = 1.0
                }
            }
        }
    }
    
    // MARK: - Registration Completed View
    private var registrationCompletedView: some View {
        VStack(spacing: Up2Spacing.xl) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(Up2Colors.success)
            
            Text("Registration Successful!")
                .font(Up2Typography.heading2)
                .foregroundColor(Up2Colors.textOnPrimary)
            
            Text("Your account has been created successfully.")
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2Colors.textOnPrimary.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Up2Button(
                "Continue to Profile Setup",
                style: .primary,
                size: .large
            ) {
                // Navigate to profile setup
                handleProfileSetupNavigation()
            }
        }
    }
    
    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: Up2Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(Up2Colors.error)
            
            Text("Registration Error")
                .font(Up2Typography.heading2)
                .foregroundColor(Up2Colors.textOnPrimary)
            
            Text(message)
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2Colors.textOnPrimary.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Up2Button(
                "Try Again",
                style: .primary,
                size: .large
            ) {
                viewModel.resetRegistration()
            }
        }
    }
    
    // MARK: - Animation Methods
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            backgroundOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            formOffset = 0
            formOpacity = 1.0
        }
    }
    
    // MARK: - Dummy Registration Handler
    private func handleDummyRegistration() {
        // Simulate successful registration for testing
        print("📝 Dummy registration successful with email: \(viewModel.registrationData.emailAddress)")
        print("👤 Full name: \(fullName)")
        print("🎵 Selected vibe tags: \(selectedVibeTags)")
        print("🖼️ Selected avatar: \(avatarOptions[selectedAvatarIndex])")
        
        // Create a dummy user for testing
        let dummyUser = SupabaseAuthService.AuthUser(
            id: UUID().uuidString,
            email: viewModel.registrationData.emailAddress,
            phone: nil,
            isHost: false
        )
        
        // Update app state to simulate authenticated user with profile setup needed
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            appStateManager.setCurrentUser(dummyUser)
            appStateManager.appFlow = .profileSetup
        }
    }
    
    // MARK: - Profile Setup Navigation
    private func handleProfileSetupNavigation() {
        // Navigate to profile setup
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            appStateManager.appFlow = .profileSetup
        }
    }
}

#Preview {
    RegistrationView()
        .environmentObject(AppStateManager.shared)
} 