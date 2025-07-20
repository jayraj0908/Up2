import Foundation
import SwiftUI
import Combine
import Supabase

// MARK: - App State Manager
@MainActor
class AppStateManager: ObservableObject {
    static let shared = AppStateManager()
    
    @Published var isUserAuthenticated: Bool = false
    @Published var currentUser: SupabaseAuthService.AuthUser?
    @Published var appFlow: AppFlow = .authentication
    @Published var isInitializing: Bool = true
    @Published var hasProfileSetup: Bool = false
    @Published var initializationResult: InitializationResult?
    
    private let authService = SupabaseAuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // UserDefaults keys for persistence
    private let profileSetupKey = "user_profile_setup_complete"
    
    private init() {
        setupAuthenticationObserver()
        loadPersistedState()
    }
    
    // MARK: - App Flow States
    enum AppFlow {
        case authentication
        case registration
        case profileSetup
        case mainApp
    }
    
    // MARK: - Persistence Management
    private func loadPersistedState() {
        // Load profile setup status from UserDefaults
        hasProfileSetup = UserDefaults.standard.bool(forKey: profileSetupKey)
    }
    
    private func saveProfileSetupStatus(_ completed: Bool) {
        hasProfileSetup = completed
        UserDefaults.standard.set(completed, forKey: profileSetupKey)
    }
    
    // MARK: - Authentication Observer
    private func setupAuthenticationObserver() {
        // Observe authentication state changes from SupabaseAuthService
        authService.$currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.handleAuthenticationStateChange(user: user)
            }
            .store(in: &cancellables)
        
        authService.$currentSession
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                self?.handleSessionChange(session: session)
            }
            .store(in: &cancellables)
    }
    
    private func handleSessionChange(session: Session?) {
        let wasAuthenticated = isUserAuthenticated
        isUserAuthenticated = session != nil
        
        // Set initialization complete after first session check
        if isInitializing {
            isInitializing = false
        }
        
        // If authentication status changed, update app flow
        if wasAuthenticated != isUserAuthenticated {
            updateAppFlow()
        }
    }
    
    private func handleAuthenticationStateChange(user: SupabaseAuthService.AuthUser?) {
        self.currentUser = user
        updateAppFlow()
    }
    
    private func updateAppFlow() {
        if isUserAuthenticated, currentUser != nil {
            // User is authenticated, determine next step
            if hasProfileSetup {
                self.appFlow = .mainApp
            } else {
                self.appFlow = .profileSetup
            }
        } else {
            // User is not authenticated
            self.appFlow = .authentication
            // Clear profile setup status when logged out
            if hasProfileSetup {
                saveProfileSetupStatus(false)
            }
        }
        
        print("🔄 App flow updated to: \(appFlow)")
    }
    
    // MARK: - Initialization Management
    func updateInitializationResult(_ result: InitializationResult) {
        self.initializationResult = result
        
        // Update authentication state based on initialization result
        switch result.sessionStatus {
        case .authenticated(let userId):
            print("🔐 User authenticated during initialization: \(userId)")
        case .notAuthenticated:
            print("🔓 No authenticated user found during initialization")
        case .expired:
            print("⏰ User session expired during initialization")
        case .needsOnboarding:
            print("📚 User needs onboarding")
        case .profileIncomplete:
            print("📝 User profile incomplete")
        }
        
        // Update profile setup status based on initialization
        if !hasProfileSetup && result.hasCompletedOnboarding {
            saveProfileSetupStatus(true)
        }
        
        print("🚀 Initialization completed - navigating to: \(result.navigationDestination.description)")
    }
    
    // MARK: - State Management
    func handleRegistrationComplete() {
        // Registration complete - user needs to set up profile
        print("📝 Registration completed - redirecting to profile setup")
        updateAppFlow()
    }
    
    func handleLoginComplete() {
        // Login complete - check if profile setup is needed
        print("🔐 Login completed - checking profile status")
        updateAppFlow()
    }
    
    func handleProfileSetupComplete() {
        // Mark profile setup as complete and navigate to main app
        print("✅ Profile setup completed")
        saveProfileSetupStatus(true)
        updateAppFlow()
    }
    
    func signOut() {
        Task {
            do {
                print("🚪 Signing out user...")
                try await authService.signOut()
                // State changes will be handled automatically via observer
                print("✅ Sign out completed")
            } catch {
                print("❌ Error signing out: \(error)")
                // Fallback: manually reset state
                await MainActor.run {
                    self.isUserAuthenticated = false
                    self.currentUser = nil
                    self.saveProfileSetupStatus(false)
                    self.updateAppFlow()
                }
            }
        }
    }
    
    func setCurrentUser(_ user: SupabaseAuthService.AuthUser) {
        // This method is now primarily for backward compatibility
        // User state is managed automatically via SupabaseAuthService
        self.currentUser = user
        self.isUserAuthenticated = true
        updateAppFlow()
    }
    
    // MARK: - Utility Methods
    func resetAppState() {
        // Used for debugging or manual state reset
        isUserAuthenticated = false
        currentUser = nil
        hasProfileSetup = false
        saveProfileSetupStatus(false)
        appFlow = .authentication
        
        // Clear navigation-related state
        clearNavigationState()
    }
    
    // MARK: - Navigation State Management
    
    private let lastSelectedTabKey = "app_last_selected_tab"
    private let navigationPreferencesKey = "app_navigation_preferences"
    
    /// Save the user's last selected tab for restoration
    func saveLastSelectedTab(_ tab: String) {
        UserDefaults.standard.set(tab, forKey: lastSelectedTabKey)
    }
    
    /// Get the user's last selected tab
    func getLastSelectedTab() -> String? {
        return UserDefaults.standard.string(forKey: lastSelectedTabKey)
    }
    
    /// Clear navigation-related state on logout or reset
    private func clearNavigationState() {
        UserDefaults.standard.removeObject(forKey: lastSelectedTabKey)
        UserDefaults.standard.removeObject(forKey: navigationPreferencesKey)
    }
    
    /// Handle successful authentication completion
    func handleAuthenticationSuccessful() {
        // This is called when authentication is successful but before determining next flow
        print("🔐 Authentication successful - determining next flow")
        updateAppFlow()
    }
    
    /// Handle profile setup beginning
    func handleProfileSetupStarted() {
        print("📝 Profile setup started")
        appFlow = .profileSetup
    }
    
    /// Enhanced profile setup completion with navigation coordination
    func handleProfileSetupCompleteWithNavigation() {
        print("✅ Profile setup completed - navigating to main app")
        saveProfileSetupStatus(true)
        appFlow = .mainApp
        
        // Post notification for navigation coordinator to handle
        NotificationCenter.default.post(
            name: .profileSetupCompleted,
            object: nil,
            userInfo: ["userId": currentUser?.id ?? "unknown"]
        )
    }
    
    /// Enhanced sign out with navigation coordination
    func signOutWithNavigation() {
        Task {
            do {
                print("🚪 Enhanced sign out - clearing navigation state...")
                
                // Clear navigation state first
                clearNavigationState()
                
                // Then perform normal sign out
                try await authService.signOut()
                
                // State changes will be handled automatically via observer
                print("✅ Enhanced sign out completed")
                
                // Post notification for navigation coordinator
                NotificationCenter.default.post(name: .userSignedOut, object: nil)
                
            } catch {
                print("❌ Error during enhanced sign out: \(error)")
                // Fallback: manually reset state
                await MainActor.run {
                    self.isUserAuthenticated = false
                    self.currentUser = nil
                    self.saveProfileSetupStatus(false)
                    self.clearNavigationState()
                    self.updateAppFlow()
                }
            }
        }
    }
    
    // MARK: - Deep Link Support
    
    /// Check if the app is ready to handle deep links
    var isReadyForDeepLinks: Bool {
        return !isInitializing && appFlow == .mainApp
    }
    
    /// Get the current app state for deep link handling
    func getCurrentAppContext() -> AppContext {
        return AppContext(
            appFlow: appFlow,
            isAuthenticated: isUserAuthenticated,
            hasProfileSetup: hasProfileSetup,
            isInitializing: isInitializing,
            userId: currentUser?.id
        )
    }
}

// MARK: - Supporting Types for Navigation

struct AppContext {
    let appFlow: AppStateManager.AppFlow
    let isAuthenticated: Bool
    let hasProfileSetup: Bool
    let isInitializing: Bool
    let userId: String?
    
    var canHandleDeepLinks: Bool {
        return !isInitializing && appFlow == .mainApp
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let profileSetupCompleted = Notification.Name("profileSetupCompleted")
    static let userSignedOut = Notification.Name("userSignedOut")
    static let appFlowChanged = Notification.Name("appFlowChanged")
} 