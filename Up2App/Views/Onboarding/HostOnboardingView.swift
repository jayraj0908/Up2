import SwiftUI

struct HostOnboardingView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @State private var currentStep: OnboardingStep = .venueSelection
    @State private var selectedVenue: VenueType?
    @State private var selectedEventTypes: Set<EventType> = []
    @State private var isProcessing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    enum OnboardingStep: Int, CaseIterable {
        case venueSelection = 0
        case eventTypes = 1
        case complete = 2
    }
    
    enum VenueType: String, CaseIterable {
        case nightclub = "nightclub"
        case restaurant = "restaurant"
        case outdoor = "outdoor"
        case `private` = "private"
        case other = "other"
        
        var title: String {
            switch self {
            case .nightclub: return "Nightclub"
            case .restaurant: return "Restaurant"
            case .outdoor: return "Outdoor Venue"
            case .private: return "Private Space"
            case .other: return "Other"
            }
        }
        
        var icon: String {
            switch self {
            case .nightclub: return "music.note"
            case .restaurant: return "fork.knife"
            case .outdoor: return "leaf"
            case .private: return "house"
            case .other: return "building.2"
            }
        }
    }
    
    enum EventType: String, CaseIterable {
        case music = "music"
        case food = "food"
        case sports = "sports"
        case art = "art"
        case business = "business"
        case social = "social"
        case wellness = "wellness"
        case education = "education"
        
        var title: String {
            switch self {
            case .music: return "Music"
            case .food: return "Food & Dining"
            case .sports: return "Sports"
            case .art: return "Art & Culture"
            case .business: return "Business"
            case .social: return "Social"
            case .wellness: return "Wellness"
            case .education: return "Education"
            }
        }
        
        var icon: String {
            switch self {
            case .music: return "music.note"
            case .food: return "fork.knife"
            case .sports: return "sportscourt"
            case .art: return "paintbrush"
            case .business: return "briefcase"
            case .social: return "person.3"
            case .wellness: return "heart"
            case .education: return "book"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            VStack(spacing: Up2Spacing.xxxl) {
                // Header
                headerView
                
                // Progress indicator
                progressIndicator
                
                // Content based on current step
                switch currentStep {
                case .venueSelection:
                    venueSelectionView
                case .eventTypes:
                    eventTypesView
                case .complete:
                    completionView
                }
                
                Spacer()
                
                // Navigation buttons
                navigationButtons
            }
            .padding(.horizontal, Up2Spacing.screenEdge)
            .padding(.vertical, Up2Spacing.xl)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Background View
    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.1, green: 0.0, blue: 0.3),
                    Color(red: 0.3, green: 0.0, blue: 0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Color(red: 0.0, green: 0.2, blue: 0.4).opacity(0.1)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: Up2Spacing.lg) {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .shadow(color: Up2Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
            
            Text("Host Setup")
                .font(Up2Typography.displayMedium)
                .foregroundColor(Up2Colors.textInverse)
                .multilineTextAlignment(.center)
            
            Text("Tell us about your venue and events")
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Up2Spacing.xxxl)
    }
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        HStack(spacing: Up2Spacing.sm) {
            ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                Circle()
                    .fill(step.rawValue <= currentStep.rawValue ? Up2Colors.accent : Up2Colors.textSecondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    // MARK: - Venue Selection View
    private var venueSelectionView: some View {
        VStack(spacing: Up2Spacing.xl) {
            Text("What type of venue do you manage?")
                .font(Up2Typography.heading2)
                .foregroundColor(Up2Colors.textInverse)
                .multilineTextAlignment(.center)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Up2Spacing.lg) {
                ForEach(VenueType.allCases, id: \.self) { venue in
                    venueCard(for: venue)
                }
            }
        }
    }
    
    private func venueCard(for venue: VenueType) -> some View {
        let isSelected = selectedVenue == venue
        
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedVenue = venue
            }
        }) {
            VStack(spacing: Up2Spacing.md) {
                Image(systemName: venue.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(isSelected ? Up2Colors.accent : Up2Colors.textSecondary)
                
                Text(venue.title)
                    .font(Up2Typography.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? Up2Colors.textInverse : Up2Colors.textSecondary)
            }
            .frame(height: 100)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ? Up2Colors.accent : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    // MARK: - Event Types View
    private var eventTypesView: some View {
        VStack(spacing: Up2Spacing.xl) {
            Text("What types of events do you host?")
                .font(Up2Typography.heading2)
                .foregroundColor(Up2Colors.textInverse)
                .multilineTextAlignment(.center)
            
            Text("Select all that apply")
                .font(Up2Typography.bodySmall)
                .foregroundColor(Up2Colors.textSecondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: Up2Spacing.md) {
                ForEach(EventType.allCases, id: \.self) { eventType in
                    eventTypeCard(for: eventType)
                }
            }
        }
    }
    
    private func eventTypeCard(for eventType: EventType) -> some View {
        let isSelected = selectedEventTypes.contains(eventType)
        
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if isSelected {
                    selectedEventTypes.remove(eventType)
                } else {
                    selectedEventTypes.insert(eventType)
                }
            }
        }) {
            HStack(spacing: Up2Spacing.sm) {
                Image(systemName: eventType.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? Up2Colors.accent : Up2Colors.textSecondary)
                
                Text(eventType.title)
                    .font(Up2Typography.bodySmall)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? Up2Colors.textInverse : Up2Colors.textSecondary)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Up2Colors.accent)
                }
            }
            .padding(Up2Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected ? Up2Colors.accent : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Completion View
    private var completionView: some View {
        VStack(spacing: Up2Spacing.xl) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(Up2Colors.accent)
            
            Text("Setup Complete!")
                .font(Up2Typography.displayMedium)
                .foregroundColor(Up2Colors.textInverse)
                .multilineTextAlignment(.center)
            
            Text("You're all set to start creating events. You can update your profile anytime.")
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtons: some View {
        HStack(spacing: Up2Spacing.lg) {
            if currentStep != .venueSelection {
                Up2Button("Back", style: .secondary) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        currentStep = OnboardingStep(rawValue: currentStep.rawValue - 1) ?? .venueSelection
                    }
                }
            }
            
            Spacer()
            
            if currentStep == .venueSelection {
                Up2Button("Next", style: .primary) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        currentStep = .eventTypes
                    }
                }
                .disabled(selectedVenue == nil)
            } else if currentStep == .eventTypes {
                Up2Button("Complete", style: .primary) {
                    Task {
                        await completeOnboarding()
                    }
                }
                .disabled(selectedEventTypes.isEmpty)
            } else if currentStep == .complete {
                Up2Button("Continue", style: .primary) {
                    appStateManager.updateSoftGateState(.complete)
                }
            }
        }
    }
    
    // MARK: - Onboarding Logic
    private func completeOnboarding() async {
        isProcessing = true
        
        do {
            guard let currentUser = appStateManager.currentUser else {
                throw NSError(domain: "HostOnboarding", code: 1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
            }
            
            let profileService = ProfileService.shared
            let userId = UUID(uuidString: currentUser.id) ?? UUID()
            
            // Update profile with venue and event type preferences
            // This would typically save to the profiles table
            // For now, we'll just mark onboarding as complete
            
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                currentStep = .complete
            }
            
            isProcessing = false
            
        } catch {
            isProcessing = false
            errorMessage = error.localizedDescription
            showingError = true
            print("❌ Failed to complete onboarding: \(error)")
        }
    }
}

#Preview {
    HostOnboardingView()
        .environmentObject(AppStateManager())
} 