import Foundation
import Combine
import SwiftUI

// MARK: - App Initialization Service Protocol
protocol AppInitializationServiceProtocol {
    func initialize() async -> Result<InitializationResult, AppInitializationError>
    func checkNetworkConnection() async -> Bool
    func validateConfiguration() async -> Result<AppConfiguration, AppInitializationError>
    func checkAuthenticationStatus() async -> Result<UserSessionStatus, AppInitializationError>
}

// MARK: - App Initialization Service
@MainActor
final class AppInitializationService: ObservableObject, AppInitializationServiceProtocol {
    
    // MARK: - Dependencies
    private let authService: SupabaseAuthService
    private let appStateManager: AppStateManager
    private let userDefaults: UserDefaults
    
    // MARK: - State
    @Published var currentState: AppInitializationState = .initializing
    @Published var metrics: InitializationMetrics
    
    // MARK: - Constants
    private let maxInitializationTime: TimeInterval = 10.0
    private let networkCheckTimeout: TimeInterval = 5.0
    private let configurationCheckTimeout: TimeInterval = 3.0
    
    // MARK: - UserDefaults Keys
    private enum UserDefaultsKeys {
        static let lastLaunchDate = "lastLaunchDate"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let appVersion = "appVersion"
        static let initializationCount = "initializationCount"
    }
    
    // MARK: - Initialization
    init(
        authService: SupabaseAuthService,
        appStateManager: AppStateManager,
        userDefaults: UserDefaults = .standard
    ) {
        self.authService = authService
        self.appStateManager = appStateManager
        self.userDefaults = userDefaults
        self.metrics = InitializationMetrics()
    }
    
    // MARK: - Main Initialization
    func initialize() async -> Result<InitializationResult, AppInitializationError> {
        metrics = InitializationMetrics()
        
        do {
            // Phase 1: Basic initialization
            await updateState(.initializing)
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            
            // Phase 2: Network and configuration
            await updateState(.loadingConfiguration)
            let configuration = try await loadConfiguration()
            
            // Phase 3: Authentication check
            await updateState(.checkingAuthentication)
            let sessionStatusResult = await checkAuthenticationStatus()
            
            guard case .success(let sessionStatus) = sessionStatusResult else {
                if case .failure(let error) = sessionStatusResult {
                    throw error
                } else {
                    throw AppInitializationError.authenticationCheckFailed
                }
            }
            
            // Phase 4: Prepare navigation
            await updateState(.preparingNavigation)
            let result = try await prepareNavigation(
                sessionStatus: sessionStatus,
                configuration: configuration
            )
            
            // Phase 5: Completion
            await updateState(.completed)
            await recordSuccessfulLaunch()
            
            metrics = metrics.completed()
            return .success(result)
            
        } catch let error as AppInitializationError {
            await updateState(.error(error))
            metrics = metrics.withError()
            return .failure(error)
        } catch {
            let initError = AppInitializationError.unknown(error)
            await updateState(.error(initError))
            metrics = metrics.withError()
            return .failure(initError)
        }
    }
    
    // MARK: - Network Connection Check
    /// Checks for basic network reachability by attempting a lightweight HTTPS request.
    /// This implementation avoids multiple continuation resumes which previously caused
    /// a `SWIFT TASK CONTINUATION MISUSE` runtime crash.
    func checkNetworkConnection() async -> Bool {
        guard let url = URL(string: "https://www.apple.com") else { return false }

        var request = URLRequest(url: url)
        request.timeoutInterval = networkCheckTimeout

        do {
            // Using the async `URLSession.data(for:)` API guarantees the continuation
            // is only resumed once by the system.
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
        } catch {
            // Ignore network errors – we'll treat them as lack of connectivity
        }
        return false
    }
    
    // MARK: - Configuration Validation
    func validateConfiguration() async -> Result<AppConfiguration, AppInitializationError> {
        do {
            // For now, return default configuration
            // In the future, this could fetch from remote config
            let configuration = AppConfiguration.default
            
            // Validate minimum version requirements
            if !isVersionSupported(current: configuration.version, minimum: configuration.minimumSupportedVersion) {
                throw AppInitializationError.configurationLoadFailed
            }
            
            return .success(configuration)
        } catch {
            return .failure(.configurationLoadFailed)
        }
    }
    
    // MARK: - Authentication Status Check
    func checkAuthenticationStatus() async -> Result<UserSessionStatus, AppInitializationError> {
        do {
            let isAuthenticated = authService.isAuthenticated
            
            if isAuthenticated {
                let session = authService.currentSession
                if let session = session, let userId = session.user.id.uuidString as String? {
                    // Skip onboarding check - go directly to authenticated
                        return .success(.authenticated(userId: userId))
                } else {
                    return .success(.expired)
                }
            } else {
                return .success(.notAuthenticated)
            }
        } catch {
            return .failure(.authenticationCheckFailed)
        }
    }
    
    // MARK: - Private Methods
    
    private func updateState(_ state: AppInitializationState) async {
        await MainActor.run {
            self.currentState = state
        }
    }
    
    private func loadConfiguration() async throws -> AppConfiguration {
        let hasNetworkConnection = await checkNetworkConnection()
        
        if !hasNetworkConnection {
            throw AppInitializationError.networkUnavailable
        }
        
        let configResult = await validateConfiguration()
        switch configResult {
        case .success(let configuration):
            return configuration
        case .failure(let error):
            throw error
        }
    }
    
    private func checkAuthentication() async throws -> UserSessionStatus {
        let authResult = await checkAuthenticationStatus()
        switch authResult {
        case .success(let status):
            return status
        case .failure(let error):
            throw error
        }
    }
    
    private func prepareNavigation(
        sessionStatus: UserSessionStatus,
        configuration: AppConfiguration
    ) async throws -> InitializationResult {
        
        // Skip onboarding check - always set to true
        let hasCompletedOnboarding = true
        
        // Get last launch date
        let lastLaunchDate = userDefaults.object(forKey: UserDefaultsKeys.lastLaunchDate) as? Date
        
        // Create result
        let result = InitializationResult.createResult(
            sessionStatus: sessionStatus,
            configuration: configuration,
            hasCompletedOnboarding: hasCompletedOnboarding,
            lastLaunchDate: lastLaunchDate
        )
        
        // Update app state manager based on initialization result
        // The AppStateManager now handles state through soft gates
        // We'll let the calling code handle the navigation based on the result
        
        return result
    }
    
    private func recordSuccessfulLaunch() async {
        let now = Date()
        userDefaults.set(now, forKey: UserDefaultsKeys.lastLaunchDate)
        
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        userDefaults.set(currentVersion, forKey: UserDefaultsKeys.appVersion)
        
        let initCount = userDefaults.integer(forKey: UserDefaultsKeys.initializationCount)
        userDefaults.set(initCount + 1, forKey: UserDefaultsKeys.initializationCount)
    }
    
    private func checkIfUserNeedsOnboarding(userId: String) async -> Bool {
        // This would typically check with the backend or local storage
        // For now, we'll check if onboarding was completed locally
        return !userDefaults.bool(forKey: UserDefaultsKeys.hasCompletedOnboarding)
    }
    
    private func isVersionSupported(current: String, minimum: String) -> Bool {
        return current.compare(minimum, options: .numeric) != .orderedAscending
    }
}

// MARK: - App Initialization Service Extensions

extension AppInitializationService {
    
    // MARK: - Retry Logic
    func retryInitialization() async -> Result<InitializationResult, AppInitializationError> {
        metrics = metrics.withRetry()
        
        // Add exponential backoff if there have been multiple retries
        let delay = min(2.0 * pow(2.0, Double(metrics.retryCount)), 10.0)
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        return await initialize()
    }
    
    // MARK: - Reset Methods
    func resetAppState() {
        userDefaults.removeObject(forKey: UserDefaultsKeys.hasCompletedOnboarding)
        userDefaults.removeObject(forKey: UserDefaultsKeys.lastLaunchDate)
        userDefaults.removeObject(forKey: UserDefaultsKeys.appVersion)
        userDefaults.removeObject(forKey: UserDefaultsKeys.initializationCount)
    }
    
    // MARK: - Debug Helpers
    func getInitializationMetrics() -> InitializationMetrics {
        return metrics
    }
    
    func getCurrentState() -> AppInitializationState {
        return currentState
    }
    
    // MARK: - Onboarding Completion
    func markOnboardingAsCompleted() {
        userDefaults.set(true, forKey: UserDefaultsKeys.hasCompletedOnboarding)
    }
    
    // MARK: - Force Update Check
    func checkForForceUpdate() async -> Bool {
        // This would typically check with a remote service
        // For now, always return false (no force update required)
        return false
    }
}

// MARK: - Timeout Handling
extension AppInitializationService {
    
    func initializeWithTimeout() async -> Result<InitializationResult, AppInitializationError> {
        return await withCheckedContinuation { continuation in
            let timeoutTask = Task {
                try await Task.sleep(nanoseconds: UInt64(maxInitializationTime * 1_000_000_000))
                continuation.resume(returning: .failure(.timeout))
            }
            
            let initTask = Task {
                let result = await initialize()
                timeoutTask.cancel()
                continuation.resume(returning: result)
            }
            
            // Both tasks will run concurrently, first to complete wins
        }
    }
} 