import Foundation
import LocalAuthentication
import SwiftUI
import Combine

// MARK: - Biometric Authentication Models

struct BiometricAuthResult {
    let success: Bool
    let biometricType: BiometricType
    let error: BiometricAuthError?
    let timestamp: Date
    let authenticationTime: TimeInterval
    
    enum BiometricType {
        case faceID
        case touchID
        case none
    }
    
    enum BiometricAuthError: Error, LocalizedError {
        case notAvailable
        case notEnrolled
        case lockedOut
        case userCancel
        case userFallback
        case systemCancel
        case passcodeNotSet
        case biometryNotAvailable
        case biometryNotEnrolled
        case biometryLockout
        case appCancel
        case invalidContext
        case notInteractive
        case other
        
        var errorDescription: String? {
            switch self {
            case .notAvailable:
                return "Biometric authentication is not available on this device"
            case .notEnrolled:
                return "No biometric data is enrolled on this device"
            case .lockedOut:
                return "Biometric authentication is locked out"
            case .userCancel:
                return "Authentication was cancelled by the user"
            case .userFallback:
                return "User chose to use fallback authentication"
            case .systemCancel:
                return "Authentication was cancelled by the system"
            case .passcodeNotSet:
                return "Passcode is not set on this device"
            case .biometryNotAvailable:
                return "Biometric authentication is not available"
            case .biometryNotEnrolled:
                return "No biometric data is enrolled"
            case .biometryLockout:
                return "Biometric authentication is locked out"
            case .appCancel:
                return "Authentication was cancelled by the app"
            case .invalidContext:
                return "Invalid authentication context"
            case .notInteractive:
                return "Authentication context is not interactive"
            case .other:
                return "An unknown error occurred"
            }
        }
    }
}

struct BiometricAuthSettings {
    let isEnabled: Bool
    let biometricType: BiometricAuthResult.BiometricType
    let fallbackEnabled: Bool
    let fallbackMethod: FallbackMethod
    let maxAttempts: Int
    let lockoutDuration: TimeInterval
    
    enum FallbackMethod {
        case passcode
        case password
        case email
        case phone
        case none
    }
}

struct BiometricAuthMetrics {
    let totalAttempts: Int
    let successfulAttempts: Int
    let failedAttempts: Int
    let averageAuthTime: TimeInterval
    let lockoutEvents: Int
    let fallbackUsage: Int
    let biometricType: BiometricAuthResult.BiometricType
}

// MARK: - Biometric Authentication Service

@MainActor
class BiometricAuthService: ObservableObject {
    static let shared = BiometricAuthService()
    
    // MARK: - Dependencies
    private let performanceService = AppPerformanceService.shared
    private let analyticsService = AnalyticsService.shared
    private let errorService = ErrorHandlingService.shared
    private let hapticService = HapticService.shared
    private let securityService = SecurityService.shared
    
    // MARK: - Properties
    @Published var isBiometricAvailable = false
    @Published var biometricType: BiometricAuthResult.BiometricType = .none
    @Published var isAuthenticated = false
    @Published var authSettings: BiometricAuthSettings?
    @Published var authMetrics: BiometricAuthMetrics?
    
    private let context = LAContext()
    private var currentAttempts = 0
    private var lockoutStartTime: Date?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private let maxAttempts = 5
    private let lockoutDuration: TimeInterval = 300 // 5 minutes
    private let authTimeout: TimeInterval = 30.0
    
    // MARK: - Initialization
    private init() {
        setupBiometricAuthentication()
        loadAuthSettings()
    }
    
    // MARK: - Public Methods
    
    /// Check if biometric authentication is available
    func checkBiometricAvailability() async -> Bool {
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            await MainActor.run {
                isBiometricAvailable = true
                biometricType = determineBiometricType()
            }
            return true
        } else {
            await MainActor.run {
                isBiometricAvailable = false
                biometricType = .none
            }
            
            if let error = error {
                await handleBiometricError(error)
            }
            
            return false
        }
    }
    
    /// Authenticate using biometrics
    func authenticateWithBiometrics(reason: String = "Authenticate to access your account") async -> BiometricAuthResult {
        let startTime = Date()
        
        // Check if locked out
        if isLockedOut() {
            let result = BiometricAuthResult(
                success: false,
                biometricType: biometricType,
                error: .lockedOut,
                timestamp: Date(),
                authenticationTime: Date().timeIntervalSince(startTime)
            )
            
            await handleAuthResult(result)
            return result
        }
        
        // Check availability
        guard await checkBiometricAvailability() else {
            let result = BiometricAuthResult(
                success: false,
                biometricType: biometricType,
                error: .notAvailable,
                timestamp: Date(),
                authenticationTime: Date().timeIntervalSince(startTime)
            )
            
            await handleAuthResult(result)
            return result
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            
            let authTime = Date().timeIntervalSince(startTime)
            
            if success {
                let result = BiometricAuthResult(
                    success: true,
                    biometricType: biometricType,
                    error: nil,
                    timestamp: Date(),
                    authenticationTime: authTime
                )
                
                await handleSuccessfulAuth(result)
                return result
            } else {
                let result = BiometricAuthResult(
                    success: false,
                    biometricType: biometricType,
                    error: .other,
                    timestamp: Date(),
                    authenticationTime: authTime
                )
                
                await handleAuthResult(result)
                return result
            }
            
        } catch {
            let authTime = Date().timeIntervalSince(startTime)
            let biometricError = mapLAError(error)
            
            let result = BiometricAuthResult(
                success: false,
                biometricType: biometricType,
                error: biometricError,
                timestamp: Date(),
                authenticationTime: authTime
            )
            
            await handleAuthResult(result)
            return result
        }
    }
    
    /// Authenticate with fallback
    func authenticateWithFallback(reason: String = "Authenticate to access your account") async -> BiometricAuthResult {
        // First try biometric authentication
        let biometricResult = await authenticateWithBiometrics(reason: reason)
        
        if biometricResult.success {
            return biometricResult
        }
        
        // If biometric fails, try fallback method
        if let settings = authSettings, settings.fallbackEnabled {
            return await performFallbackAuthentication(method: settings.fallbackMethod)
        }
        
        return biometricResult
    }
    
    /// Enable biometric authentication
    func enableBiometricAuthentication(fallbackMethod: BiometricAuthSettings.FallbackMethod = .passcode) async -> Bool {
        guard await checkBiometricAvailability() else {
            return false
        }
        
        let settings = BiometricAuthSettings(
            isEnabled: true,
            biometricType: biometricType,
            fallbackEnabled: true,
            fallbackMethod: fallbackMethod,
            maxAttempts: maxAttempts,
            lockoutDuration: lockoutDuration
        )
        
        await MainActor.run {
            authSettings = settings
        }
        
        // Save settings securely
        await saveAuthSettings(settings)
        
        analyticsService.trackUserAction("biometric_auth_enabled", properties: [
            "biometric_type": biometricType.rawValue,
            "fallback_method": fallbackMethod.rawValue
        ])
        
        return true
    }
    
    /// Disable biometric authentication
    func disableBiometricAuthentication() async {
        let settings = BiometricAuthSettings(
            isEnabled: false,
            biometricType: .none,
            fallbackEnabled: false,
            fallbackMethod: .none,
            maxAttempts: 0,
            lockoutDuration: 0
        )
        
        await MainActor.run {
            authSettings = settings
            isAuthenticated = false
        }
        
        // Save settings securely
        await saveAuthSettings(settings)
        
        analyticsService.trackUserAction("biometric_auth_disabled")
    }
    
    /// Get authentication metrics
    func getAuthMetrics() -> BiometricAuthMetrics? {
        return authMetrics
    }
    
    /// Reset authentication attempts
    func resetAuthAttempts() {
        currentAttempts = 0
        lockoutStartTime = nil
        
        analyticsService.trackUserAction("biometric_auth_attempts_reset")
    }
    
    // MARK: - Private Methods
    
    private func setupBiometricAuthentication() {
        // Check initial availability
        Task {
            await checkBiometricAvailability()
        }
    }
    
    private func determineBiometricType() -> BiometricAuthResult.BiometricType {
        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .none:
            return .none
        @unknown default:
            return .none
        }
    }
    
    private func handleSuccessfulAuth(_ result: BiometricAuthResult) async {
        await MainActor.run {
            isAuthenticated = true
            currentAttempts = 0
            lockoutStartTime = nil
        }
        
        // Update metrics
        await updateAuthMetrics(success: true, authTime: result.authenticationTime)
        
        // Track successful authentication
        analyticsService.trackUserAction("biometric_auth_success", properties: [
            "biometric_type": result.biometricType.rawValue,
            "auth_time": result.authenticationTime
        ])
        
        hapticService.successNotification()
    }
    
    private func handleAuthResult(_ result: BiometricAuthResult) async {
        await MainActor.run {
            isAuthenticated = false
        }
        
        if !result.success {
            currentAttempts += 1
            
            // Check if should lockout
            if currentAttempts >= maxAttempts {
                await handleLockout()
            }
        }
        
        // Update metrics
        await updateAuthMetrics(success: result.success, authTime: result.authenticationTime)
        
        // Track authentication attempt
        analyticsService.trackUserAction("biometric_auth_attempt", properties: [
            "success": result.success,
            "biometric_type": result.biometricType.rawValue,
            "error": result.error?.localizedDescription ?? "none",
            "auth_time": result.authenticationTime,
            "attempts": currentAttempts
        ])
        
        if !result.success {
            hapticService.errorNotification()
        }
    }
    
    private func handleLockout() async {
        await MainActor.run {
            lockoutStartTime = Date()
        }
        
        analyticsService.trackUserAction("biometric_auth_lockout", properties: [
            "attempts": currentAttempts,
            "lockout_duration": lockoutDuration
        ])
        
        hapticService.errorNotification()
    }
    
    private func isLockedOut() -> Bool {
        guard let lockoutStart = lockoutStartTime else { return false }
        return Date().timeIntervalSince(lockoutStart) < lockoutDuration
    }
    
    private func performFallbackAuthentication(method: BiometricAuthSettings.FallbackMethod) async -> BiometricAuthResult {
        let startTime = Date()
        
        // This would implement the actual fallback authentication
        // For now, we'll simulate a successful fallback
        let authTime = Date().timeIntervalSince(startTime)
        
        let result = BiometricAuthResult(
            success: true,
            biometricType: .none,
            error: nil,
            timestamp: Date(),
            authenticationTime: authTime
        )
        
        await MainActor.run {
            isAuthenticated = true
        }
        
        analyticsService.trackUserAction("fallback_auth_used", properties: [
            "fallback_method": method.rawValue,
            "auth_time": authTime
        ])
        
        return result
    }
    
    private func handleBiometricError(_ error: NSError) async {
        let biometricError = mapLAError(error)
        
        await errorService.handleBiometricError(biometricError)
        
        analyticsService.trackUserAction("biometric_error", properties: [
            "error_code": error.code,
            "error_description": biometricError.localizedDescription
        ])
    }
    
    private func mapLAError(_ error: Error) -> BiometricAuthResult.BiometricAuthError {
        guard let laError = error as? LAError else {
            return .other
        }
        
        switch laError.code {
        case .biometryNotAvailable:
            return .biometryNotAvailable
        case .biometryNotEnrolled:
            return .biometryNotEnrolled
        case .biometryLockout:
            return .biometryLockout
        case .userCancel:
            return .userCancel
        case .userFallback:
            return .userFallback
        case .systemCancel:
            return .systemCancel
        case .passcodeNotSet:
            return .passcodeNotSet
        case .appCancel:
            return .appCancel
        case .invalidContext:
            return .invalidContext
        case .notInteractive:
            return .notInteractive
        default:
            return .other
        }
    }
    
    private func updateAuthMetrics(success: Bool, authTime: TimeInterval) async {
        await MainActor.run {
            let currentMetrics = authMetrics ?? BiometricAuthMetrics(
                totalAttempts: 0,
                successfulAttempts: 0,
                failedAttempts: 0,
                averageAuthTime: 0,
                lockoutEvents: 0,
                fallbackUsage: 0,
                biometricType: biometricType
            )
            
            let newTotalAttempts = currentMetrics.totalAttempts + 1
            let newSuccessfulAttempts = currentMetrics.successfulAttempts + (success ? 1 : 0)
            let newFailedAttempts = currentMetrics.failedAttempts + (success ? 0 : 1)
            
            let newAverageAuthTime = (currentMetrics.averageAuthTime * Double(currentMetrics.totalAttempts) + authTime) / Double(newTotalAttempts)
            
            authMetrics = BiometricAuthMetrics(
                totalAttempts: newTotalAttempts,
                successfulAttempts: newSuccessfulAttempts,
                failedAttempts: newFailedAttempts,
                averageAuthTime: newAverageAuthTime,
                lockoutEvents: currentMetrics.lockoutEvents + (isLockedOut() ? 1 : 0),
                fallbackUsage: currentMetrics.fallbackUsage,
                biometricType: biometricType
            )
        }
    }
    
    private func loadAuthSettings() {
        // Load settings from secure storage
        Task {
            if let settingsData = securityService.secureRetrieveData(forKey: "biometric_auth_settings"),
               let settings = try? JSONDecoder().decode(BiometricAuthSettings.self, from: settingsData) {
                await MainActor.run {
                    authSettings = settings
                }
            }
        }
    }
    
    private func saveAuthSettings(_ settings: BiometricAuthSettings) async {
        if let settingsData = try? JSONEncoder().encode(settings) {
            securityService.secureStore(settingsData, forKey: "biometric_auth_settings")
        }
    }
}

// MARK: - Supporting Types

extension BiometricAuthResult.BiometricType: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: String) {
        switch rawValue {
        case "faceID": self = .faceID
        case "touchID": self = .touchID
        case "none": self = .none
        default: return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .faceID: return "faceID"
        case .touchID: return "touchID"
        case .none: return "none"
        }
    }
}

extension BiometricAuthSettings.FallbackMethod: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: String) {
        switch rawValue {
        case "passcode": self = .passcode
        case "password": self = .password
        case "email": self = .email
        case "phone": self = .phone
        case "none": self = .none
        default: return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .passcode: return "passcode"
        case .password: return "password"
        case .email: return "email"
        case .phone: return "phone"
        case .none: return "none"
        }
    }
}

extension BiometricAuthSettings: Codable {}
extension BiometricAuthMetrics: Codable {} 