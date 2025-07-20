//
//  ContentView.swift
//  Up2App
//
//  Created by jayraj patel on 15/07/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appStateManager = AppStateManager.shared
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
            switch appStateManager.appFlow {
            case .authentication:
                LoginView()
            case .registration:
                RegistrationView()
            case .profileSetup:
                ProfileSetupView(isPresented: .constant(true))
            case .mainApp:
                TabNavigationView(navigationCoordinator: navigationCoordinator)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appStateManager.appFlow)
    }
    
    // MARK: - Navigation Handling
    private func handleSplashNavigation(_ destination: InitializationNavigationDestination) {
        // Update app state manager based on initialization destination
        switch destination {
        case .authentication, .registration:
            appStateManager.appFlow = .authentication
            navigationCoordinator.resetToInitialState()
        case .onboarding:
            // For now, redirect to profile setup
            // In the future, this would go to a dedicated onboarding flow
            appStateManager.appFlow = .profileSetup
        case .mainApp:
            appStateManager.appFlow = .mainApp
            navigationCoordinator.handleAuthenticationComplete()
        case .maintenance:
            // Show maintenance modal if we reach main app, otherwise show authentication
            if appStateManager.isUserAuthenticated {
                appStateManager.appFlow = .mainApp
            } else {
                appStateManager.appFlow = .authentication
            }
        }
        
        // Mark initialization as complete
        appStateManager.isInitializing = false
    }
}

#Preview {
    ContentView()
}
