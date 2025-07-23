//
//  ContentView.swift
//  Up2App
//
//  Created by jayraj patel on 15/07/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appStateManager = AppStateManager()
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView(
                    shouldShowSplash: $showSplash,
                    onNavigationComplete: handleSplashNavigation
                )
                .transition(.opacity)
            } else {
                mainContentView
                    .transition(.opacity)
            }
        }
        .environmentObject(appStateManager)
        .environmentObject(navigationCoordinator)
        .animation(.easeInOut(duration: 0.5), value: showSplash)
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        Group {
            if appStateManager.isLoading {
                // Show loading state
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Up2Colors.background)
            } else if !appStateManager.isAuthenticated {
                // Show authentication
                LoginView()
            } else {
                // User is authenticated - check soft gate state
                switch appStateManager.softGateState {
                case .profileRequired:
                    // Show role selection/profile setup
                    RoleSelectionView()
                case .hostOnboarding:
                    // Show host onboarding
                    HostOnboardingView()
                case .paymentSetup:
                    // Show payment setup
                    PaymentSetupView()
                case .complete:
                    // Show main app
                    TabNavigationView(navigationCoordinator: navigationCoordinator)
                case .none:
                    // Fallback to main app
                    TabNavigationView(navigationCoordinator: navigationCoordinator)
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appStateManager.softGateState)
    }
    
    // MARK: - Navigation Handling
    private func handleSplashNavigation(_ destination: InitializationNavigationDestination) {
        // Update app state manager based on initialization destination
        switch destination {
        case .authentication, .registration:
            // Authentication will be handled by the main content view based on isAuthenticated
            navigationCoordinator.resetToInitialState()
        case .onboarding:
            // Onboarding will be handled by soft gate state
            if appStateManager.isAuthenticated {
                appStateManager.updateSoftGateState(.profileRequired)
            }
        case .mainApp:
            // Main app will be shown if user is authenticated and onboarding is complete
            navigationCoordinator.handleAuthenticationComplete()
        case .maintenance:
            // Show maintenance modal if we reach main app, otherwise show authentication
            // This will be handled by the main content view
            break
        }
        
        // Mark initialization as complete
        // Note: isInitializing property no longer exists in AppStateManager
    }
}

#Preview {
    ContentView()
}
