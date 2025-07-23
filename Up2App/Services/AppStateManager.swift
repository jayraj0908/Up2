import Foundation
import SwiftUI
import Combine
import Supabase

// MARK: - App State Manager
@MainActor
class AppStateManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var isOnboardingComplete = false
    @Published var currentUser: User?
    @Published var isLoading = true
    @Published var softGateState: SoftGateState = .none
    
    // MARK: - Private Properties
    private let authService = SupabaseAuthService.shared
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Initialization
    init() {
        setupAuthStateListener()
        checkOnboardingStatus()
    }
    
    // MARK: - Soft Gate State Management
    enum SoftGateState {
        case none
        case profileRequired // Role selection (User vs Host)
        case hostOnboarding // Host setup flow
        case paymentSetup // Payment setup for hosts
        case complete // Onboarding complete
    }
    
    // MARK: - Authentication State Management
    private func setupAuthStateListener() {
        Task {
            do {
                let session = try await authService.currentSession
                if let session = session {
                    await handleSuccessfulAuth(session: session)
                } else {
                    await handleLoggedOutState()
                }
            } catch {
                print("❌ Auth state check failed: \(error)")
                await handleLoggedOutState()
            }
        }
    }
    
    private func handleSuccessfulAuth(session: Session) async {
        isAuthenticated = true
        currentUser = User(
            id: session.user.id.uuidString,
            email: session.user.email ?? "",
            fullName: session.user.userMetadata["full_name"]?.stringValue ?? ""
        )
        
        // Check if user needs to complete onboarding
        await checkOnboardingRequirements()
    }
    
    private func handleLoggedOutState() async {
        isAuthenticated = false
        currentUser = nil
        softGateState = .none
        isLoading = false
    }
    
    // MARK: - Onboarding Management
    private func checkOnboardingStatus() {
        isOnboardingComplete = userDefaults.bool(forKey: "isOnboardingComplete")
    }
    
    private func checkOnboardingRequirements() async {
        guard isAuthenticated, let user = currentUser else { return }
        
        do {
            // Check if profile exists
            let profileService = ProfileService.shared
            let profile = try await profileService.getProfile(for: UUID(uuidString: user.id) ?? UUID())
            
            if profile == nil {
                // No profile exists - show role selection
                softGateState = .profileRequired
            } else {
                // Profile exists - check if onboarding is complete
                if profile?.isCurator == true {
                    // User is a host - check if payment setup is needed
                    softGateState = .paymentSetup
                } else {
                    // User is a regular user - check if they want to become a host
                    softGateState = .hostOnboarding
                }
            }
            
            isLoading = false
        } catch {
            print("❌ Failed to check onboarding requirements: \(error)")
            softGateState = .profileRequired
            isLoading = false
        }
    }
    
    // MARK: - Public Methods
    func completeOnboarding() {
        isOnboardingComplete = true
        userDefaults.set(true, forKey: "isOnboardingComplete")
    }
    
    func updateSoftGateState(_ state: SoftGateState) {
        softGateState = state
    }
    
    func signOut() async {
        do {
            try await authService.signOut()
            await handleLoggedOutState()
        } catch {
            print("❌ Sign out failed: \(error)")
        }
    }
    
    // MARK: - Soft Gate Access Control
    func canAccessFeature(_ feature: RestrictedFeature) -> Bool {
        switch feature {
        case .profile:
            return isAuthenticated
        case .hostFeatures:
            return isAuthenticated && softGateState != .profileRequired
        case .paymentFeatures:
            return isAuthenticated && softGateState == .complete
        case .eventCreation:
            return isAuthenticated && softGateState != .profileRequired
        case .rsvp:
            return isAuthenticated && softGateState != .profileRequired
        }
    }
    
    func getSoftGateMessage(for feature: RestrictedFeature) -> String {
        switch feature {
        case .profile:
            return "Sign in to view your profile"
        case .hostFeatures:
            return "Complete your profile to access host features"
        case .paymentFeatures:
            return "Set up payment to access premium features"
        case .eventCreation:
            return "Complete your profile to create events"
        case .rsvp:
            return "Sign in to RSVP to events"
        }
    }
}

// MARK: - Restricted Features
enum RestrictedFeature {
    case profile
    case hostFeatures
    case paymentFeatures
    case eventCreation
    case rsvp
} 