import SwiftUI

struct BecomeHostView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appStateManager: AppStateManager
    @State private var currentStep = 0
    @State private var showingHostDashboard = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    // Services
    private let profileService = ProfileService.shared
    private let authService = SupabaseAuthService.shared
    
    // Host application data
    @State private var businessName = ""
    @State private var businessDescription = ""
    @State private var businessCategory = ""
    @State private var contactEmail = ""
    @State private var phoneNumber = ""
    @State private var website = ""
    @State private var socialMedia = ""
    @State private var experienceLevel = ""
    @State private var eventTypes = Set<String>()
    
    private let categories = ["Music & Entertainment", "Food & Dining", "Technology", "Art & Culture", "Sports & Fitness", "Business & Networking", "Education", "Other"]
    private let experienceLevels = ["Beginner", "Intermediate", "Experienced", "Professional"]
    private let eventTypeOptions = ["Live Music", "Food Festivals", "Tech Meetups", "Art Exhibitions", "Sports Events", "Networking", "Workshops", "Parties", "Conferences", "Pop-ups"]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
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
                    // Progress indicator
                    progressIndicator
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 24) {
                            switch currentStep {
                            case 0:
                                welcomeStep
                            case 1:
                                businessInfoStep
                            case 2:
                                experienceStep
                            case 3:
                                eventTypesStep
                            case 4:
                                reviewStep
                            default:
                                welcomeStep
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                    }
                    
                    // Navigation buttons
                    navigationButtons
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingHostDashboard) {
                HostDashboardView()
            }
        }
    }
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        VStack(spacing: 8) {
            HStack {
                ForEach(0..<5) { index in
                    Rectangle()
                        .fill(index <= currentStep ? Color.blue : Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .animation(.easeInOut(duration: 0.3), value: currentStep)
                }
            }
            .padding(.horizontal, 20)
            
            Text("Step \(currentStep + 1) of 5")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.top, 16)
    }
    
    // MARK: - Welcome Step
    private var welcomeStep: some View {
        VStack(spacing: 32) {
            // Logo and title
            VStack(spacing: 16) {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                
                Text("Become a Host")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Join our community of event creators and start sharing amazing experiences with the world.")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            // Benefits
            VStack(spacing: 16) {
                BenefitRow(icon: "chart.bar.fill", title: "Analytics Dashboard", description: "Track your event performance and audience engagement")
                BenefitRow(icon: "creditcard.fill", title: "Revenue Tracking", description: "Monitor your earnings and payment processing")
                BenefitRow(icon: "person.2.fill", title: "Guest Management", description: "Manage RSVPs and communicate with attendees")
                BenefitRow(icon: "megaphone.fill", title: "Promotion Tools", description: "Reach more people with our marketing features")
            }
        }
    }
    
    // MARK: - Business Info Step
    private var businessInfoStep: some View {
        VStack(spacing: 24) {
            Text("Tell us about your business")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                CustomTextField(title: "Business Name", text: $businessName, placeholder: "Enter your business name")
                CustomTextField(title: "Business Description", text: $businessDescription, placeholder: "Describe what you do", isMultiline: true)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Picker("Category", selection: $businessCategory) {
                        Text("Select a category").tag("")
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
                
                CustomTextField(title: "Contact Email", text: $contactEmail, placeholder: "your@email.com")
                CustomTextField(title: "Phone Number", text: $phoneNumber, placeholder: "+1 (555) 123-4567")
                CustomTextField(title: "Website (Optional)", text: $website, placeholder: "https://yourwebsite.com")
                CustomTextField(title: "Social Media (Optional)", text: $socialMedia, placeholder: "@yourhandle")
            }
        }
    }
    
    // MARK: - Experience Step
    private var experienceStep: some View {
        VStack(spacing: 24) {
            Text("Your Experience")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Help us understand your experience level to provide the best support.")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            VStack(spacing: 16) {
                ForEach(experienceLevels, id: \.self) { level in
                    Button(action: {
                        experienceLevel = level
                    }) {
                        HStack {
                            Text(level)
                                .font(.body)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            if experienceLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding()
                        .background(experienceLevel == level ? Color.blue.opacity(0.2) : Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(experienceLevel == level ? Color.blue : Color.clear, lineWidth: 2)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Event Types Step
    private var eventTypesStep: some View {
        VStack(spacing: 24) {
            Text("Event Types")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Select the types of events you plan to host.")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(eventTypeOptions, id: \.self) { eventType in
                    Button(action: {
                        if eventTypes.contains(eventType) {
                            eventTypes.remove(eventType)
                        } else {
                            eventTypes.insert(eventType)
                        }
                    }) {
                        HStack {
                            Text(eventType)
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            if eventTypes.contains(eventType) {
                                Image(systemName: "checkmark")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(eventTypes.contains(eventType) ? Color.blue.opacity(0.2) : Color.white.opacity(0.1))
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(eventTypes.contains(eventType) ? Color.blue : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Review Step
    private var reviewStep: some View {
        VStack(spacing: 24) {
            Text("Review Your Application")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                ReviewRow(title: "Business Name", value: businessName)
                ReviewRow(title: "Category", value: businessCategory)
                ReviewRow(title: "Experience Level", value: experienceLevel)
                ReviewRow(title: "Event Types", value: Array(eventTypes).joined(separator: ", "))
                ReviewRow(title: "Contact Email", value: contactEmail)
            }
            
            Text("Your application will be reviewed within 24-48 hours. We'll notify you via email once approved.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.top, 16)
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        VStack(spacing: 12) {
            // Error message
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 20)
            }
            
            HStack(spacing: 16) {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation {
                            currentStep -= 1
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
                    .disabled(isSubmitting)
                }
                
                Button(currentStep == 4 ? "Submit Application" : "Continue") {
                    if currentStep == 4 {
                        submitApplication()
                    } else {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .cornerRadius(12)
                .disabled(!canProceed || isSubmitting)
                .overlay(
                    Group {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                    }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Helper Properties
    private var canProceed: Bool {
        switch currentStep {
        case 0:
            return true
        case 1:
            return !businessName.isEmpty && !businessCategory.isEmpty && !contactEmail.isEmpty
        case 2:
            return !experienceLevel.isEmpty
        case 3:
            return !eventTypes.isEmpty
        case 4:
            return true
        default:
            return false
        }
    }
    
    // MARK: - Helper Methods
    private func submitApplication() {
        guard let currentUser = authService.currentUser else {
            errorMessage = "User not authenticated"
            return
        }
        
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                print("🔄 Starting host onboarding for user: \(currentUser.id)")
                
                let userId = UUID(uuidString: currentUser.id) ?? UUID()
                
                // Update profile to become a host (ProfileService will create profile if needed)
                print("🔄 Updating profile to host status...")
                _ = try await profileService.updateProfileToHost(userId: userId)
                print("✅ Profile updated to host successfully")
                
                // Update app state with new host status
                await MainActor.run {
                    // The host status is now managed through the profile system
                    // Update the soft gate state to reflect completion
                    appStateManager.updateSoftGateState(.complete)
                    
                    isSubmitting = false
                    showingHostDashboard = true
                    
                    // Dismiss the onboarding view
                    presentationMode.wrappedValue.dismiss()
                }
                
                print("✅ Host onboarding completed successfully")
                
            } catch {
                print("❌ Host onboarding failed: \(error)")
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = "Failed to submit application: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct CustomTextField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var isMultiline: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            
            if isMultiline {
                TextEditor(text: $text)
                    .frame(minHeight: 100)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundColor(.white)
            } else {
                TextField(placeholder, text: $text)
                    .padding()
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .foregroundColor(.white)
            }
        }
    }
}

struct ReviewRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))
            
            Spacer()
            
            Text(value.isEmpty ? "Not provided" : value)
                .font(.body)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    BecomeHostView()
        .environmentObject(AppStateManager())
} 