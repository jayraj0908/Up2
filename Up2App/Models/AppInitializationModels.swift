import Foundation
import SwiftUI

// MARK: - App Initialization State
enum AppInitializationState {
    case initializing
    case loadingConfiguration
    case checkingAuthentication
    case preparingNavigation
    case completed
    case error(AppInitializationError)
    
    var isLoading: Bool {
        switch self {
        case .initializing, .loadingConfiguration, .checkingAuthentication, .preparingNavigation:
            return true
        case .completed, .error:
            return false
        }
    }
    
    var displayMessage: String {
        switch self {
        case .initializing:
            return "Starting Up2..."
        case .loadingConfiguration:
            return "Loading configuration..."
        case .checkingAuthentication:
            return "Checking authentication..."
        case .preparingNavigation:
            return "Preparing your experience..."
        case .completed:
            return "Ready!"
        case .error(let error):
            return error.userMessage
        }
    }
    
    var progress: Double {
        switch self {
        case .initializing:
            return 0.2
        case .loadingConfiguration:
            return 0.4
        case .checkingAuthentication:
            return 0.7
        case .preparingNavigation:
            return 0.9
        case .completed:
            return 1.0
        case .error:
            return 0.0
        }
    }
}

// MARK: - App Initialization Error
enum AppInitializationError: Error, LocalizedError {
    case networkUnavailable
    case supabaseConnectionFailed
    case configurationLoadFailed
    case authenticationCheckFailed
    case criticalServiceUnavailable
    case timeout
    case unknown(Error)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network connection unavailable"
        case .supabaseConnectionFailed:
            return "Failed to connect to Up2 services"
        case .configurationLoadFailed:
            return "Failed to load app configuration"
        case .authenticationCheckFailed:
            return "Authentication verification failed"
        case .criticalServiceUnavailable:
            return "Critical service unavailable"
        case .timeout:
            return "App initialization timed out"
        case .unknown(let error):
            return "Unexpected error: \(error.localizedDescription)"
        }
    }
    
    var userMessage: String {
        switch self {
        case .networkUnavailable:
            return "Please check your internet connection"
        case .supabaseConnectionFailed:
            return "Unable to connect to Up2 services"
        case .configurationLoadFailed:
            return "Failed to load app settings"
        case .authenticationCheckFailed:
            return "Authentication error occurred"
        case .criticalServiceUnavailable:
            return "Service temporarily unavailable"
        case .timeout:
            return "Taking longer than expected..."
        case .unknown:
            return "Something went wrong"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .supabaseConnectionFailed, .timeout:
            return true
        case .configurationLoadFailed, .authenticationCheckFailed, .criticalServiceUnavailable, .unknown:
            return false
        }
    }
    
    var retryDelay: TimeInterval {
        switch self {
        case .networkUnavailable:
            return 2.0
        case .supabaseConnectionFailed:
            return 3.0
        case .timeout:
            return 1.0
        default:
            return 2.0
        }
    }
}

// MARK: - Navigation Destination
enum InitializationNavigationDestination {
    case authentication
    case registration
    case mainApp
    case onboarding
    case maintenance
    
    var description: String {
        switch self {
        case .authentication:
            return "Authentication"
        case .registration:
            return "Registration"
        case .mainApp:
            return "Main App"
        case .onboarding:
            return "Onboarding"
        case .maintenance:
            return "Maintenance"
        }
    }
}

// MARK: - App Configuration
struct AppConfiguration {
    let version: String
    let buildNumber: String
    let minimumSupportedVersion: String
    let features: [String: Bool]
    let endpoints: [String: String]
    let isMaintenanceMode: Bool
    let maintenanceMessage: String?
    
    static let `default` = AppConfiguration(
        version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0",
        buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1",
        minimumSupportedVersion: "1.0.0",
        features: [
            "eventDiscovery": true,
            "socialFeatures": true,
            "pushNotifications": true,
            "analytics": true
        ],
        endpoints: [:],
        isMaintenanceMode: false,
        maintenanceMessage: nil
    )
}

// MARK: - User Session Status
enum UserSessionStatus {
    case notAuthenticated
    case authenticated(userId: String)
    case expired
    case needsOnboarding
    case profileIncomplete
    
    var isAuthenticated: Bool {
        switch self {
        case .authenticated:
            return true
        case .notAuthenticated, .expired, .needsOnboarding, .profileIncomplete:
            return false
        }
    }
    
    var requiresOnboarding: Bool {
        switch self {
        case .needsOnboarding, .profileIncomplete:
            return true
        case .notAuthenticated, .authenticated, .expired:
            return false
        }
    }
}

// MARK: - Initialization Result
struct InitializationResult {
    let sessionStatus: UserSessionStatus
    let configuration: AppConfiguration
    let navigationDestination: InitializationNavigationDestination
    let hasCompletedOnboarding: Bool
    let lastLaunchDate: Date?
    let isFirstLaunch: Bool
    
    static func createResult(
        sessionStatus: UserSessionStatus,
        configuration: AppConfiguration = .default,
        hasCompletedOnboarding: Bool = false,
        lastLaunchDate: Date? = nil
    ) -> InitializationResult {
        let isFirstLaunch = lastLaunchDate == nil
        
        let navigationDestination: InitializationNavigationDestination
        
        if configuration.isMaintenanceMode {
            navigationDestination = .maintenance
        } else if !hasCompletedOnboarding && isFirstLaunch {
            navigationDestination = .onboarding
        } else {
            switch sessionStatus {
            case .authenticated:
                navigationDestination = .mainApp
            case .needsOnboarding, .profileIncomplete:
                navigationDestination = .onboarding
            case .notAuthenticated, .expired:
                navigationDestination = .authentication
            }
        }
        
        return InitializationResult(
            sessionStatus: sessionStatus,
            configuration: configuration,
            navigationDestination: navigationDestination,
            hasCompletedOnboarding: hasCompletedOnboarding,
            lastLaunchDate: lastLaunchDate,
            isFirstLaunch: isFirstLaunch
        )
    }
}

// MARK: - Splash Animation State
enum SplashAnimationState {
    case preparing
    case logoFadeIn
    case logoScale
    case brandingAppear
    case loadingStart
    case completed
    
    var duration: TimeInterval {
        switch self {
        case .preparing:
            return 0.2
        case .logoFadeIn:
            return 0.6
        case .logoScale:
            return 0.4
        case .brandingAppear:
            return 0.3
        case .loadingStart:
            return 0.2
        case .completed:
            return 0.3
        }
    }
}

// MARK: - Initialization Metrics
struct InitializationMetrics {
    let startTime: Date
    let endTime: Date?
    let duration: TimeInterval?
    let phase: AppInitializationState
    let errorCount: Int
    let retryCount: Int
    
    init(startTime: Date = Date()) {
        self.startTime = startTime
        self.endTime = nil
        self.duration = nil
        self.phase = .initializing
        self.errorCount = 0
        self.retryCount = 0
    }
    
    init(startTime: Date, endTime: Date?, duration: TimeInterval?, phase: AppInitializationState, errorCount: Int, retryCount: Int) {
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.phase = phase
        self.errorCount = errorCount
        self.retryCount = retryCount
    }
    
    func completed() -> InitializationMetrics {
        let endTime = Date()
        return InitializationMetrics(
            startTime: startTime,
            endTime: endTime,
            duration: endTime.timeIntervalSince(startTime),
            phase: .completed,
            errorCount: errorCount,
            retryCount: retryCount
        )
    }
    
    func withError() -> InitializationMetrics {
        return InitializationMetrics(
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            phase: phase,
            errorCount: errorCount + 1,
            retryCount: retryCount
        )
    }
    
    func withRetry() -> InitializationMetrics {
        return InitializationMetrics(
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            phase: phase,
            errorCount: errorCount,
            retryCount: retryCount + 1
        )
    }
} 