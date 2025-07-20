import Foundation
import SwiftUI
import Combine
import CryptoKit

// MARK: - Multi-Factor Authentication Models

struct MFAMethod {
    let id: String
    let type: MFAType
    let isEnabled: Bool
    let isVerified: Bool
    let createdAt: Date
    let lastUsed: Date?
    
    enum MFAType {
        case sms
        case email
        case totp
        case backup
    }
}

struct MFACode {
    let code: String
    let type: MFAMethod.MFAType
    let expiresAt: Date
    let attempts: Int
    let maxAttempts: Int
    let isUsed: Bool
    
    var isValid: Bool {
        return !isUsed && Date() < expiresAt && attempts < maxAttempts
    }
}

struct MFARecoveryCode {
    let code: String
    let isUsed: Bool
    let usedAt: Date?
    let createdAt: Date
}

struct MFASession {
    let sessionId: String
    let userId: String
    let mfaMethod: MFAMethod
    let createdAt: Date
    let expiresAt: Date
    let isActive: Bool
}

struct MFAResult {
    let success: Bool
    let session: MFASession?
    let error: MFAError?
    let requiresAdditionalVerification: Bool
    let nextStep: MFANextStep?
    
    enum MFAError: Error, LocalizedError {
        case invalidCode
        case expiredCode
        case tooManyAttempts
        case methodNotEnabled
        case methodNotVerified
        case sessionExpired
        case networkError
        case biometricRequired
        case backupCodeRequired
        
        var errorDescription: String? {
            switch self {
            case .invalidCode:
                return "Invalid verification code"
            case .expiredCode:
                return "Verification code has expired"
            case .tooManyAttempts:
                return "Too many failed attempts"
            case .methodNotEnabled:
                return "MFA method is not enabled"
            case .methodNotVerified:
                return "MFA method is not verified"
            case .sessionExpired:
                return "MFA session has expired"
            case .networkError:
                return "Network error occurred"
            case .biometricRequired:
                return "Biometric authentication required"
            case .backupCodeRequired:
                return "Backup code required"
            }
        }
    }
    
    enum MFANextStep {
        case biometricAuth
        case backupCode
        case newMethod
        case complete
    }
}

struct MFAMetrics {
    let totalAttempts: Int
    let successfulAttempts: Int
    let failedAttempts: Int
    let averageVerificationTime: TimeInterval
    let methodUsage: [MFAMethod.MFAType: Int]
    let securityEvents: Int
}

// MARK: - Multi-Factor Authentication Service

@MainActor
class MultiFactorAuthService: ObservableObject {
    static let shared = MultiFactorAuthService()
    
    // MARK: - Dependencies
    private let performanceService = AppPerformanceService.shared
    private let analyticsService = AnalyticsService.shared
    private let errorService = ErrorHandlingService.shared
    private let hapticService = HapticService.shared
    private let securityService = SecurityService.shared
    private let biometricAuthService = BiometricAuthService.shared
    
    // MARK: - Properties
    @Published var enabledMethods: [MFAMethod] = []
    @Published var currentSession: MFASession?
    @Published var isMFAEnabled = false
    @Published var mfaMetrics: MFAMetrics?
    
    private var activeCodes: [String: MFACode] = [:]
    private var recoveryCodes: [MFARecoveryCode] = []
    private var sessionTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private let codeLength = 6
    private let codeExpirationTime: TimeInterval = 300 // 5 minutes
    private let maxAttempts = 3
    private let sessionExpirationTime: TimeInterval = 3600 // 1 hour
    private let recoveryCodeCount = 10
    
    // MARK: - Initialization
    private init() {
        setupMFAMonitoring()
        loadMFASettings()
    }
    
    // MARK: - Public Methods
    
    /// Enable MFA for a user
    func enableMFA(for userId: String) async -> Bool {
        do {
            // Generate recovery codes
            recoveryCodes = generateRecoveryCodes()
            
            // Save MFA settings
            await saveMFASettings(userId: userId)
            
            await MainActor.run {
                isMFAEnabled = true
            }
            
            analyticsService.trackUserAction("mfa_enabled", properties: [
                "user_id": userId,
                "recovery_codes_generated": recoveryCodes.count
            ])
            
            return true
            
        } catch {
            await errorService.handleMFAError(error)
            return false
        }
    }
    
    /// Disable MFA for a user
    func disableMFA(for userId: String) async -> Bool {
        do {
            // Clear all MFA data
            await clearMFAData(userId: userId)
            
            await MainActor.run {
                isMFAEnabled = false
                enabledMethods.removeAll()
                currentSession = nil
            }
            
            analyticsService.trackUserAction("mfa_disabled", properties: [
                "user_id": userId
            ])
            
            return true
            
        } catch {
            await errorService.handleMFAError(error)
            return false
        }
    }
    
    /// Add MFA method
    func addMFAMethod(_ type: MFAMethod.MFAType, for userId: String) async -> MFAMethod? {
        let method = MFAMethod(
            id: UUID().uuidString,
            type: type,
            isEnabled: false,
            isVerified: false,
            createdAt: Date(),
            lastUsed: nil
        )
        
        await MainActor.run {
            enabledMethods.append(method)
        }
        
        analyticsService.trackUserAction("mfa_method_added", properties: [
            "user_id": userId,
            "method_type": type.rawValue
        ])
        
        return method
    }
    
    /// Send verification code
    func sendVerificationCode(to method: MFAMethod, for userId: String) async -> Bool {
        let startTime = Date()
        
        do {
            let code = generateVerificationCode()
            let mfaCode = MFACode(
                code: code,
                type: method.type,
                expiresAt: Date().addingTimeInterval(codeExpirationTime),
                attempts: 0,
                maxAttempts: maxAttempts,
                isUsed: false
            )
            
            // Store the code
            activeCodes[method.id] = mfaCode
            
            // Send the code based on method type
            let success = await sendCode(mfaCode, to: method, for: userId)
            
            if success {
                let sendTime = Date().timeIntervalSince(startTime)
                
                analyticsService.trackUserAction("mfa_code_sent", properties: [
                    "user_id": userId,
                    "method_type": method.type.rawValue,
                    "send_time": sendTime
                ])
                
                hapticService.successNotification()
                return true
            } else {
                return false
            }
            
        } catch {
            await errorService.handleMFAError(error)
            return false
        }
    }
    
    /// Verify MFA code
    func verifyMFACode(_ code: String, for method: MFAMethod, userId: String) async -> MFAResult {
        let startTime = Date()
        
        guard let mfaCode = activeCodes[method.id] else {
            return MFAResult(
                success: false,
                session: nil,
                error: .invalidCode,
                requiresAdditionalVerification: false,
                nextStep: nil
            )
        }
        
        // Check if code is valid
        guard mfaCode.isValid else {
            if mfaCode.isUsed {
                return MFAResult(
                    success: false,
                    session: nil,
                    error: .invalidCode,
                    requiresAdditionalVerification: false,
                    nextStep: nil
                )
            } else if Date() >= mfaCode.expiresAt {
                return MFAResult(
                    success: false,
                    session: nil,
                    error: .expiredCode,
                    requiresAdditionalVerification: false,
                    nextStep: nil
                )
            } else if mfaCode.attempts >= mfaCode.maxAttempts {
                return MFAResult(
                    success: false,
                    session: nil,
                    error: .tooManyAttempts,
                    requiresAdditionalVerification: false,
                    nextStep: nil
                )
            } else {
                return MFAResult(
                    success: false,
                    session: nil,
                    error: .invalidCode,
                    requiresAdditionalVerification: false,
                    nextStep: nil
                )
            }
        }
        
        // Verify the code
        if mfaCode.code == code {
            // Code is valid
            await markCodeAsUsed(method.id)
            
            // Create MFA session
            let session = createMFASession(for: method, userId: userId)
            
            await MainActor.run {
                currentSession = session
            }
            
            let verificationTime = Date().timeIntervalSince(startTime)
            
            analyticsService.trackUserAction("mfa_verification_success", properties: [
                "user_id": userId,
                "method_type": method.type.rawValue,
                "verification_time": verificationTime
            ])
            
            hapticService.successNotification()
            
            return MFAResult(
                success: true,
                session: session,
                error: nil,
                requiresAdditionalVerification: false,
                nextStep: .complete
            )
            
        } else {
            // Invalid code
            await incrementCodeAttempts(method.id)
            
            analyticsService.trackUserAction("mfa_verification_failed", properties: [
                "user_id": userId,
                "method_type": method.type.rawValue,
                "attempts": mfaCode.attempts + 1
            ])
            
            hapticService.errorNotification()
            
            return MFAResult(
                success: false,
                session: nil,
                error: .invalidCode,
                requiresAdditionalVerification: false,
                nextStep: nil
            )
        }
    }
    
    /// Verify with biometric authentication
    func verifyWithBiometrics(for userId: String) async -> MFAResult {
        let biometricResult = await biometricAuthService.authenticateWithBiometrics(
            reason: "Complete multi-factor authentication"
        )
        
        if biometricResult.success {
            // Create MFA session
            let method = MFAMethod(
                id: "biometric",
                type: .totp,
                isEnabled: true,
                isVerified: true,
                createdAt: Date(),
                lastUsed: Date()
            )
            
            let session = createMFASession(for: method, userId: userId)
            
            await MainActor.run {
                currentSession = session
            }
            
            analyticsService.trackUserAction("mfa_biometric_success", properties: [
                "user_id": userId,
                "auth_time": biometricResult.authenticationTime
            ])
            
            return MFAResult(
                success: true,
                session: session,
                error: nil,
                requiresAdditionalVerification: false,
                nextStep: .complete
            )
            
        } else {
            analyticsService.trackUserAction("mfa_biometric_failed", properties: [
                "user_id": userId,
                "error": biometricResult.error?.localizedDescription ?? "unknown"
            ])
            
            return MFAResult(
                success: false,
                session: nil,
                error: .biometricRequired,
                requiresAdditionalVerification: true,
                nextStep: .biometricAuth
            )
        }
    }
    
    /// Verify with recovery code
    func verifyWithRecoveryCode(_ code: String, for userId: String) async -> MFAResult {
        guard let recoveryCode = recoveryCodes.first(where: { $0.code == code && !$0.isUsed }) else {
            return MFAResult(
                success: false,
                session: nil,
                error: .invalidCode,
                requiresAdditionalVerification: false,
                nextStep: nil
            )
        }
        
        // Mark recovery code as used
        await markRecoveryCodeAsUsed(code)
        
        // Create MFA session
        let method = MFAMethod(
            id: "recovery",
            type: .backup,
            isEnabled: true,
            isVerified: true,
            createdAt: Date(),
            lastUsed: Date()
        )
        
        let session = createMFASession(for: method, userId: userId)
        
        await MainActor.run {
            currentSession = session
        }
        
        analyticsService.trackUserAction("mfa_recovery_success", properties: [
            "user_id": userId
        ])
        
        return MFAResult(
            success: true,
            session: session,
            error: nil,
            requiresAdditionalVerification: false,
            nextStep: .complete
        )
    }
    
    /// Get recovery codes
    func getRecoveryCodes() -> [MFARecoveryCode] {
        return recoveryCodes
    }
    
    /// Generate new recovery codes
    func generateNewRecoveryCodes() async -> [MFARecoveryCode] {
        recoveryCodes = generateRecoveryCodes()
        
        analyticsService.trackUserAction("mfa_recovery_codes_regenerated")
        
        return recoveryCodes
    }
    
    /// Check if MFA session is valid
    func isSessionValid() -> Bool {
        guard let session = currentSession else { return false }
        return session.isActive && Date() < session.expiresAt
    }
    
    /// Invalidate current session
    func invalidateSession() {
        currentSession = nil
        sessionTimer?.invalidate()
        sessionTimer = nil
        
        analyticsService.trackUserAction("mfa_session_invalidated")
    }
    
    /// Get MFA metrics
    func getMFAMetrics() -> MFAMetrics? {
        return mfaMetrics
    }
    
    // MARK: - Private Methods
    
    private func setupMFAMonitoring() {
        // Monitor session expiration
        sessionTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkSessionExpiration()
            }
        }
    }
    
    private func loadMFASettings() {
        // Load MFA settings from secure storage
        Task {
            if let settingsData = securityService.secureRetrieveData(forKey: "mfa_settings"),
               let settings = try? JSONDecoder().decode(MFASettings.self, from: settingsData) {
                await MainActor.run {
                    isMFAEnabled = settings.isEnabled
                    enabledMethods = settings.methods
                }
            }
        }
    }
    
    private func saveMFASettings(userId: String) async {
        let settings = MFASettings(
            userId: userId,
            isEnabled: isMFAEnabled,
            methods: enabledMethods,
            recoveryCodes: recoveryCodes
        )
        
        if let settingsData = try? JSONEncoder().encode(settings) {
            securityService.secureStore(settingsData, forKey: "mfa_settings")
        }
    }
    
    private func clearMFAData(userId: String) async {
        securityService.secureDelete(forKey: "mfa_settings")
        activeCodes.removeAll()
        recoveryCodes.removeAll()
    }
    
    private func generateVerificationCode() -> String {
        let digits = "0123456789"
        return String((0..<codeLength).map { _ in digits.randomElement()! })
    }
    
    private func generateRecoveryCodes() -> [MFARecoveryCode] {
        var codes: [MFARecoveryCode] = []
        
        for _ in 0..<recoveryCodeCount {
            let code = generateRecoveryCode()
            let recoveryCode = MFARecoveryCode(
                code: code,
                isUsed: false,
                usedAt: nil,
                createdAt: Date()
            )
            codes.append(recoveryCode)
        }
        
        return codes
    }
    
    private func generateRecoveryCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map { _ in characters.randomElement()! })
    }
    
    private func sendCode(_ mfaCode: MFACode, to method: MFAMethod, for userId: String) async -> Bool {
        switch method.type {
        case .sms:
            return await sendSMSCode(mfaCode.code, to: method.id)
        case .email:
            return await sendEmailCode(mfaCode.code, to: method.id)
        case .totp:
            return await generateTOTPCode(for: method.id)
        case .backup:
            return true // Backup codes are pre-generated
        }
    }
    
    private func sendSMSCode(_ code: String, to methodId: String) async -> Bool {
        // This would integrate with SMS service
        // For now, simulate successful SMS sending
        return true
    }
    
    private func sendEmailCode(_ code: String, to methodId: String) async -> Bool {
        // This would integrate with email service
        // For now, simulate successful email sending
        return true
    }
    
    private func generateTOTPCode(for methodId: String) async -> Bool {
        // This would generate TOTP code for authenticator apps
        // For now, simulate successful TOTP generation
        return true
    }
    
    private func markCodeAsUsed(_ methodId: String) async {
        if var code = activeCodes[methodId] {
            code.isUsed = true
            activeCodes[methodId] = code
        }
    }
    
    private func incrementCodeAttempts(_ methodId: String) async {
        if var code = activeCodes[methodId] {
            code.attempts += 1
            activeCodes[methodId] = code
        }
    }
    
    private func markRecoveryCodeAsUsed(_ code: String) async {
        if let index = recoveryCodes.firstIndex(where: { $0.code == code }) {
            recoveryCodes[index].isUsed = true
            recoveryCodes[index].usedAt = Date()
        }
    }
    
    private func createMFASession(for method: MFAMethod, userId: String) -> MFASession {
        return MFASession(
            sessionId: UUID().uuidString,
            userId: userId,
            mfaMethod: method,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(sessionExpirationTime),
            isActive: true
        )
    }
    
    private func checkSessionExpiration() {
        guard let session = currentSession else { return }
        
        if Date() >= session.expiresAt {
            invalidateSession()
            
            analyticsService.trackUserAction("mfa_session_expired", properties: [
                "session_id": session.sessionId,
                "user_id": session.userId
            ])
        }
    }
}

// MARK: - Supporting Types

struct MFASettings: Codable {
    let userId: String
    let isEnabled: Bool
    let methods: [MFAMethod]
    let recoveryCodes: [MFARecoveryCode]
}

extension MFAMethod.MFAType: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: String) {
        switch rawValue {
        case "sms": self = .sms
        case "email": self = .email
        case "totp": self = .totp
        case "backup": self = .backup
        default: return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .sms: return "sms"
        case .email: return "email"
        case .totp: return "totp"
        case .backup: return "backup"
        }
    }
}

extension MFAMethod: Codable {}
extension MFARecoveryCode: Codable {} 