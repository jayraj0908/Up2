//
//  Up2AppApp.swift
//  Up2App
//
//  Created by jayraj patel on 15/07/25.
//

import SwiftUI

@main
struct Up2App: App {
    @StateObject private var appStateManager = AppStateManager.shared
    @StateObject private var navigationCoordinator: NavigationCoordinator
    @StateObject private var deepLinkHandler: DeepLinkHandler
    @StateObject private var performanceService = AppPerformanceService.shared
    @StateObject private var securityService = SecurityService.shared
    @StateObject private var hapticService = HapticService.shared
    @StateObject private var analyticsService = AnalyticsService.shared
    @StateObject private var errorService = ErrorHandlingService.shared
    @State private var showSplash = true
    
    init() {
        // Initialize navigation coordinator first
        let coordinator = NavigationCoordinator()
        let linkHandler = DeepLinkHandler(navigationCoordinator: coordinator)
        
        _navigationCoordinator = StateObject(wrappedValue: coordinator)
        _deepLinkHandler = StateObject(wrappedValue: linkHandler)
    }
    
    var body: some Scene {
        WindowGroup {
            mainContentView
                .environmentObject(appStateManager)
                .environmentObject(navigationCoordinator)
                .environmentObject(deepLinkHandler)
                .environmentObject(performanceService)
                .environmentObject(securityService)
                .environmentObject(hapticService)
                .environmentObject(analyticsService)
                .environmentObject(errorService)
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
                .onAppear {
                    initializeAppServices()
                }
        }
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
        .onAppear {
            // Start with authentication flow
            if appStateManager.appFlow == .authentication {
                appStateManager.appFlow = .authentication
            }
        }
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
            
            // Process any pending deep links after reaching main app
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.deepLinkHandler.processPendingDeepLink()
            }
        case .maintenance:
            // Show maintenance modal if we reach main app, otherwise show authentication
            if appStateManager.isUserAuthenticated {
                appStateManager.appFlow = .mainApp
                navigationCoordinator.presentModal(.maintenance(message: "App is under maintenance"))
            } else {
                appStateManager.appFlow = .authentication
            }
        }
        
        // Mark initialization as complete
        appStateManager.isInitializing = false
    }
    
    // MARK: - App Services Initialization
    
    private func initializeAppServices() {
        // Start performance monitoring
        performanceService.startLaunchTimer()
        
        // Track app launch
        analyticsService.trackScreenView("AppLaunch")
        
        // Perform security checks
        securityService.performSecurityChecks()
        
        // End launch timer after a brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.performanceService.endLaunchTimer()
            
            // Track app launch performance
            self.analyticsService.trackAppLaunch(duration: self.performanceService.appLaunchTime)
            
            // Provide haptic feedback for successful launch
            self.hapticService.successNotification()
        }
    }
    
    // MARK: - Deep Link Handling
    private func handleIncomingURL(_ url: URL) {
        print("📱 Up2App received URL: \(url)")
        
        // Track deep link interaction
        analyticsService.trackUserAction("deep_link_opened", properties: [
            "url": url.absoluteString
        ])
        
        // Provide haptic feedback
        hapticService.lightImpact()
        
        // Handle the deep link through the deep link handler
        let handled = deepLinkHandler.handleDeepLink(url)
        
        if !handled {
            print("⚠️ Failed to handle deep link: \(url)")
            analyticsService.trackError(NSError(domain: "DeepLink", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Failed to handle deep link"
            ]), context: "handleIncomingURL")
        }
    }
}
