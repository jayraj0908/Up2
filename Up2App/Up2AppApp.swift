//
//  Up2AppApp.swift
//  Up2App
//
//  Created by jayraj patel on 15/07/25.
//

import SwiftUI

@main
struct Up2AppApp: App {
    
    // MARK: - State Objects
    @StateObject private var appStateManager = AppStateManager()
    @StateObject private var navigationCoordinator = NavigationCoordinator()
    
    // MARK: - Services
    private let eventService = EventService.shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Background gradient
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
                
                // Main Content
                if appStateManager.isLoading {
                    // Simple loading view instead of complex splash
                    VStack {
                        Image("Logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                        
                        Text("Up2")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Up2Colors.textInverse)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Up2Colors.accent))
                            .scaleEffect(1.2)
                            .padding(.top, Up2Spacing.lg)
                    }
                } else {
                    mainContentView
                }
            }
            .environmentObject(appStateManager)
            .environmentObject(navigationCoordinator)
            .preferredColorScheme(.dark)
            .task {
                // Initialize sample events for development
                await initializeSampleEvents()
            }
        }
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        Group {
            if appStateManager.isAuthenticated {
                // User is authenticated - show main app with onboarding flow if needed
                if appStateManager.softGateState == .none {
                    TabNavigationView(navigationCoordinator: navigationCoordinator)
                } else {
                    // Show onboarding flow based on soft gate state
                    onboardingFlowView
                }
            } else {
                // User is not authenticated - show soft-gated access
                // Guest users can browse ForYou, Map, Trending tabs freely
                TabNavigationView(navigationCoordinator: navigationCoordinator)
            }
        }
    }
    
    // MARK: - Onboarding Flow View
    private var onboardingFlowView: some View {
        Group {
            switch appStateManager.softGateState {
            case .profileRequired:
                RoleSelectionView()
            case .hostOnboarding:
                HostOnboardingView()
            case .paymentSetup:
                PaymentSetupView()
            case .complete:
                TabNavigationView(navigationCoordinator: navigationCoordinator)
            case .none:
                TabNavigationView(navigationCoordinator: navigationCoordinator)
            }
        }
    }
    
    // MARK: - Sample Events Initialization
    private func initializeSampleEvents() async {
        do {
            // Check if we already have events
            let existingEvents = try await eventService.fetchPublicEvents()
            if existingEvents.isEmpty {
                print("📅 No events found, creating sample events...")
                try await eventService.createSampleEvents()
                print("✅ Sample events created successfully")
            } else {
                print("📅 Found \(existingEvents.count) existing events")
            }
        } catch {
            print("❌ Error initializing sample events: \(error)")
        }
    }
}
