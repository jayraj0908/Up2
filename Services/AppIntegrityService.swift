import Foundation
import UIKit
import Security
import SwiftUI
import Combine

// MARK: - App Integrity Models

struct AppIntegrityStatus {
    let isSecure: Bool
    let jailbreakDetected: Bool
    let tamperingDetected: Bool
    let keychainAccessible: Bool
    let codeSignValid: Bool
    let sandboxIntact: Bool
    let timestamp: Date
    let securityLevel: SecurityLevel
    
    enum SecurityLevel {
        case high
        case medium
        case low
        case compromised
    }
}

struct IntegrityCheckResult {
    let checkType: IntegrityCheckType
    let passed: Bool
    let details: String
    let timestamp: Date
    let severity: SecuritySeverity
    
    enum IntegrityCheckType {
        case jailbreakDetection
        case tamperingDetection
        case keychainCheck
        case codeSignCheck
        case sandboxCheck
        case debuggerCheck
        case emulatorCheck
        case certificateCheck
    }
    
    enum SecuritySeverity {
        case critical
        case high
        case medium
        case low
        case info
    }
}

struct SecurityViolation {
    let type: ViolationType
    let severity: SecuritySeverity
    let description: String
    let timestamp: Date
    let context: String
    
    enum ViolationType {
        case jailbreakDetected
        case tamperingDetected
        case keychainCompromised
        case codeSignInvalid
        case sandboxViolation
        case debuggerAttached
        case emulatorDetected
        case certificateMismatch
    }
}

// MARK: - App Integrity Service

@MainActor
class AppIntegrityService: ObservableObject {
    static let shared = AppIntegrityService()
    
    // MARK: - Dependencies
    private let performanceService = AppPerformanceService.shared
    private let analyticsService = AnalyticsService.shared
    private let errorService = ErrorHandlingService.shared
    private let hapticService = HapticService.shared
    private let securityService = SecurityService.shared
    
    // MARK: - Properties
    @Published var integrityStatus: AppIntegrityStatus?
    @Published var isAppSecure = false
    @Published var securityViolations: [SecurityViolation] = []
    @Published var lastCheckTime: Date?
    
    private var integrityCheckResults: [IntegrityCheckResult] = []
    private var securityMonitoringTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private let checkInterval: TimeInterval = 60.0 // Check every minute
    private let maxViolations = 10
    private let criticalViolationThreshold = 3
    
    // MARK: - Initialization
    private init() {
        setupSecurityMonitoring()
        performInitialIntegrityCheck()
    }
    
    // MARK: - Public Methods
    
    /// Perform comprehensive app integrity check
    func performIntegrityCheck() async -> AppIntegrityStatus {
        let startTime = Date()
        
        // Clear previous results
        integrityCheckResults.removeAll()
        
        // Perform all integrity checks
        await performJailbreakDetection()
        await performTamperingDetection()
        await performKeychainCheck()
        await performCodeSignCheck()
        await performSandboxCheck()
        await performDebuggerCheck()
        await performEmulatorCheck()
        await performCertificateCheck()
        
        // Analyze results
        let status = analyzeIntegrityResults()
        
        await MainActor.run {
            integrityStatus = status
            isAppSecure = status.isSecure
            lastCheckTime = Date()
            
            // Track integrity check
            analyticsService.trackUserAction("app_integrity_check", properties: [
                "is_secure": status.isSecure,
                "security_level": status.securityLevel.rawValue,
                "jailbreak_detected": status.jailbreakDetected,
                "tampering_detected": status.tamperingDetected,
                "check_duration": Date().timeIntervalSince(startTime)
            ])
        }
        
        return status
    }
    
    /// Check if app is secure for sensitive operations
    func isSecureForSensitiveOperations() -> Bool {
        guard let status = integrityStatus else { return false }
        return status.isSecure && status.securityLevel != .compromised
    }
    
    /// Get security violations
    func getSecurityViolations() -> [SecurityViolation] {
        return securityViolations
    }
    
    /// Clear security violations
    func clearSecurityViolations() {
        securityViolations.removeAll()
        
        analyticsService.trackUserAction("security_violations_cleared")
    }
    
    /// Start continuous security monitoring
    func startSecurityMonitoring() {
        securityMonitoringTimer = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.performIntegrityCheck()
            }
        }
        
        analyticsService.trackUserAction("security_monitoring_started")
    }
    
    /// Stop continuous security monitoring
    func stopSecurityMonitoring() {
        securityMonitoringTimer?.invalidate()
        securityMonitoringTimer = nil
        
        analyticsService.trackUserAction("security_monitoring_stopped")
    }
    
    /// Report security violation
    func reportSecurityViolation(_ violation: SecurityViolation) {
        securityViolations.append(violation)
        
        // Keep only recent violations
        if securityViolations.count > maxViolations {
            securityViolations.removeFirst(securityViolations.count - maxViolations)
        }
        
        // Check for critical violations
        let criticalViolations = securityViolations.filter { $0.severity == .critical }
        if criticalViolations.count >= criticalViolationThreshold {
            handleCriticalSecurityViolations()
        }
        
        // Track violation
        analyticsService.trackUserAction("security_violation_detected", properties: [
            "violation_type": violation.type.rawValue,
            "severity": violation.severity.rawValue,
            "description": violation.description
        ])
        
        hapticService.errorNotification()
    }
    
    // MARK: - Private Methods
    
    private func setupSecurityMonitoring() {
        // Monitor app state changes for security
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleAppBecameActive()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.handleAppWillResignActive()
                }
            }
            .store(in: &cancellables)
    }
    
    private func performInitialIntegrityCheck() {
        Task {
            await performIntegrityCheck()
        }
    }
    
    private func performJailbreakDetection() async {
        let jailbreakDetected = await detectJailbreak()
        
        let result = IntegrityCheckResult(
            checkType: .jailbreakDetection,
            passed: !jailbreakDetected,
            details: jailbreakDetected ? "Jailbreak detected" : "No jailbreak detected",
            timestamp: Date(),
            severity: jailbreakDetected ? .critical : .info
        )
        
        integrityCheckResults.append(result)
        
        if jailbreakDetected {
            let violation = SecurityViolation(
                type: .jailbreakDetected,
                severity: .critical,
                description: "Device appears to be jailbroken",
                timestamp: Date(),
                context: "Jailbreak detection check"
            )
            reportSecurityViolation(violation)
        }
    }
    
    private func performTamperingDetection() async {
        let tamperingDetected = await detectTampering()
        
        let result = IntegrityCheckResult(
            checkType: .tamperingDetection,
            passed: !tamperingDetected,
            details: tamperingDetected ? "App tampering detected" : "No tampering detected",
            timestamp: Date(),
            severity: tamperingDetected ? .critical : .info
        )
        
        integrityCheckResults.append(result)
        
        if tamperingDetected {
            let violation = SecurityViolation(
                type: .tamperingDetected,
                severity: .critical,
                description: "App appears to have been tampered with",
                timestamp: Date(),
                context: "Tampering detection check"
            )
            reportSecurityViolation(violation)
        }
    }
    
    private func performKeychainCheck() async {
        let keychainAccessible = await checkKeychainAccessibility()
        
        let result = IntegrityCheckResult(
            checkType: .keychainCheck,
            passed: keychainAccessible,
            details: keychainAccessible ? "Keychain is accessible" : "Keychain access compromised",
            timestamp: Date(),
            severity: keychainAccessible ? .info : .high
        )
        
        integrityCheckResults.append(result)
        
        if !keychainAccessible {
            let violation = SecurityViolation(
                type: .keychainCompromised,
                severity: .high,
                description: "Keychain access appears to be compromised",
                timestamp: Date(),
                context: "Keychain accessibility check"
            )
            reportSecurityViolation(violation)
        }
    }
    
    private func performCodeSignCheck() async {
        let codeSignValid = await checkCodeSignValidity()
        
        let result = IntegrityCheckResult(
            checkType: .codeSignCheck,
            passed: codeSignValid,
            details: codeSignValid ? "Code signature is valid" : "Code signature is invalid",
            timestamp: Date(),
            severity: codeSignValid ? .info : .critical
        )
        
        integrityCheckResults.append(result)
        
        if !codeSignValid {
            let violation = SecurityViolation(
                type: .codeSignInvalid,
                severity: .critical,
                description: "App code signature is invalid",
                timestamp: Date(),
                context: "Code signature validation"
            )
            reportSecurityViolation(violation)
        }
    }
    
    private func performSandboxCheck() async {
        let sandboxIntact = await checkSandboxIntegrity()
        
        let result = IntegrityCheckResult(
            checkType: .sandboxCheck,
            passed: sandboxIntact,
            details: sandboxIntact ? "Sandbox is intact" : "Sandbox appears to be compromised",
            timestamp: Date(),
            severity: sandboxIntact ? .info : .high
        )
        
        integrityCheckResults.append(result)
        
        if !sandboxIntact {
            let violation = SecurityViolation(
                type: .sandboxViolation,
                severity: .high,
                description: "App sandbox appears to be compromised",
                timestamp: Date(),
                context: "Sandbox integrity check"
            )
            reportSecurityViolation(violation)
        }
    }
    
    private func performDebuggerCheck() async {
        let debuggerAttached = await detectDebugger()
        
        let result = IntegrityCheckResult(
            checkType: .debuggerCheck,
            passed: !debuggerAttached,
            details: debuggerAttached ? "Debugger detected" : "No debugger detected",
            timestamp: Date(),
            severity: debuggerAttached ? .medium : .info
        )
        
        integrityCheckResults.append(result)
        
        if debuggerAttached {
            let violation = SecurityViolation(
                type: .debuggerAttached,
                severity: .medium,
                description: "Debugger appears to be attached",
                timestamp: Date(),
                context: "Debugger detection"
            )
            reportSecurityViolation(violation)
        }
    }
    
    private func performEmulatorCheck() async {
        let emulatorDetected = await detectEmulator()
        
        let result = IntegrityCheckResult(
            checkType: .emulatorCheck,
            passed: !emulatorDetected,
            details: emulatorDetected ? "Emulator detected" : "No emulator detected",
            timestamp: Date(),
            severity: emulatorDetected ? .medium : .info
        )
        
        integrityCheckResults.append(result)
        
        if emulatorDetected {
            let violation = SecurityViolation(
                type: .emulatorDetected,
                severity: .medium,
                description: "App appears to be running in an emulator",
                timestamp: Date(),
                context: "Emulator detection"
            )
            reportSecurityViolation(violation)
        }
    }
    
    private func performCertificateCheck() async {
        let certificateValid = await checkCertificateValidity()
        
        let result = IntegrityCheckResult(
            checkType: .certificateCheck,
            passed: certificateValid,
            details: certificateValid ? "Certificate is valid" : "Certificate is invalid",
            timestamp: Date(),
            severity: certificateValid ? .info : .high
        )
        
        integrityCheckResults.append(result)
        
        if !certificateValid {
            let violation = SecurityViolation(
                type: .certificateMismatch,
                severity: .high,
                description: "App certificate appears to be invalid",
                timestamp: Date(),
                context: "Certificate validation"
            )
            reportSecurityViolation(violation)
        }
    }
    
    private func detectJailbreak() async -> Bool {
        // Check for common jailbreak indicators
        let jailbreakPaths = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/mobile/Library/SBSettings/Themes"
        ]
        
        for path in jailbreakPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // Check for write access to system directories
        let systemPaths = ["/private/var/mobile", "/private/var/root"]
        for path in systemPaths {
            if FileManager.default.isWritableFile(atPath: path) {
                return true
            }
        }
        
        return false
    }
    
    private func detectTampering() async -> Bool {
        // Check if app bundle has been modified
        guard let bundlePath = Bundle.main.bundlePath else { return true }
        
        // Check for common tampering indicators
        let tamperingPaths = [
            bundlePath + "/_CodeSignature",
            bundlePath + "/embedded.mobileprovision"
        ]
        
        for path in tamperingPaths {
            if !FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        return false
    }
    
    private func checkKeychainAccessibility() async -> Bool {
        // Test keychain access
        let testKey = "integrity_test_key"
        let testValue = "test_value"
        
        do {
            // Try to store a test value
            securityService.secureStore(testValue, forKey: testKey)
            
            // Try to retrieve the test value
            let retrievedValue = securityService.secureRetrieveString(forKey: testKey)
            
            // Clean up
            securityService.secureDelete(forKey: testKey)
            
            return retrievedValue == testValue
        } catch {
            return false
        }
    }
    
    private func checkCodeSignValidity() async -> Bool {
        // Check if app is properly code signed
        guard let bundlePath = Bundle.main.bundlePath else { return false }
        
        let codeSignaturePath = bundlePath + "/_CodeSignature/CodeResources"
        return FileManager.default.fileExists(atPath: codeSignaturePath)
    }
    
    private func checkSandboxIntegrity() async -> Bool {
        // Check if app is running in a proper sandbox
        let sandboxPath = NSHomeDirectory()
        return sandboxPath.contains("Containers")
    }
    
    private func detectDebugger() async -> Bool {
        // Check if debugger is attached
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.size
        let junk = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        assert(junk == 0, "sysctl failed")
        
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }
    
    private func detectEmulator() async -> Bool {
        // Check for emulator indicators
        let emulatorPaths = [
            "/Applications/Xcode.app",
            "/Applications/Xcode-beta.app",
            "/Applications/Simulator.app"
        ]
        
        for path in emulatorPaths {
            if FileManager.default.fileExists(atPath: path) {
                return true
            }
        }
        
        // Check device model
        let deviceModel = UIDevice.current.model
        return deviceModel.contains("Simulator")
    }
    
    private func checkCertificateValidity() async -> Bool {
        // Check if app has valid provisioning profile
        guard let bundlePath = Bundle.main.bundlePath else { return false }
        
        let provisioningPath = bundlePath + "/embedded.mobileprovision"
        return FileManager.default.fileExists(atPath: provisioningPath)
    }
    
    private func analyzeIntegrityResults() -> AppIntegrityStatus {
        let criticalChecks = integrityCheckResults.filter { $0.severity == .critical }
        let highChecks = integrityCheckResults.filter { $0.severity == .high }
        let mediumChecks = integrityCheckResults.filter { $0.severity == .medium }
        
        let jailbreakDetected = criticalChecks.contains { $0.checkType == .jailbreakDetection && !$0.passed }
        let tamperingDetected = criticalChecks.contains { $0.checkType == .tamperingDetection && !$0.passed }
        let keychainAccessible = !highChecks.contains { $0.checkType == .keychainCheck && !$0.passed }
        let codeSignValid = !criticalChecks.contains { $0.checkType == .codeSignCheck && !$0.passed }
        let sandboxIntact = !highChecks.contains { $0.checkType == .sandboxCheck && !$0.passed }
        
        let isSecure = !jailbreakDetected && !tamperingDetected && keychainAccessible && codeSignValid && sandboxIntact
        
        let securityLevel: AppIntegrityStatus.SecurityLevel
        if criticalChecks.contains(where: { !$0.passed }) {
            securityLevel = .compromised
        } else if highChecks.contains(where: { !$0.passed }) {
            securityLevel = .low
        } else if mediumChecks.contains(where: { !$0.passed }) {
            securityLevel = .medium
        } else {
            securityLevel = .high
        }
        
        return AppIntegrityStatus(
            isSecure: isSecure,
            jailbreakDetected: jailbreakDetected,
            tamperingDetected: tamperingDetected,
            keychainAccessible: keychainAccessible,
            codeSignValid: codeSignValid,
            sandboxIntact: sandboxIntact,
            timestamp: Date(),
            securityLevel: securityLevel
        )
    }
    
    private func handleCriticalSecurityViolations() {
        // Handle critical security violations
        analyticsService.trackUserAction("critical_security_violations_detected", properties: [
            "violation_count": securityViolations.filter { $0.severity == .critical }.count
        ])
        
        // This could trigger additional security measures
        // For now, we'll just track the event
    }
    
    private func handleAppBecameActive() {
        // Perform integrity check when app becomes active
        Task {
            await performIntegrityCheck()
        }
    }
    
    private func handleAppWillResignActive() {
        // Perform final integrity check before app resigns active
        Task {
            await performIntegrityCheck()
        }
    }
}

// MARK: - Supporting Types

extension SecurityViolation.ViolationType: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: String) {
        switch rawValue {
        case "jailbreakDetected": self = .jailbreakDetected
        case "tamperingDetected": self = .tamperingDetected
        case "keychainCompromised": self = .keychainCompromised
        case "codeSignInvalid": self = .codeSignInvalid
        case "sandboxViolation": self = .sandboxViolation
        case "debuggerAttached": self = .debuggerAttached
        case "emulatorDetected": self = .emulatorDetected
        case "certificateMismatch": self = .certificateMismatch
        default: return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .jailbreakDetected: return "jailbreakDetected"
        case .tamperingDetected: return "tamperingDetected"
        case .keychainCompromised: return "keychainCompromised"
        case .codeSignInvalid: return "codeSignInvalid"
        case .sandboxViolation: return "sandboxViolation"
        case .debuggerAttached: return "debuggerAttached"
        case .emulatorDetected: return "emulatorDetected"
        case .certificateMismatch: return "certificateMismatch"
        }
    }
}

extension AppIntegrityStatus.SecurityLevel: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: String) {
        switch rawValue {
        case "high": self = .high
        case "medium": self = .medium
        case "low": self = .low
        case "compromised": self = .compromised
        default: return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .high: return "high"
        case .medium: return "medium"
        case .low: return "low"
        case .compromised: return "compromised"
        }
    }
}

extension IntegrityCheckResult.IntegrityCheckType: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: String) {
        switch rawValue {
        case "jailbreakDetection": self = .jailbreakDetection
        case "tamperingDetection": self = .tamperingDetection
        case "keychainCheck": self = .keychainCheck
        case "codeSignCheck": self = .codeSignCheck
        case "sandboxCheck": self = .sandboxCheck
        case "debuggerCheck": self = .debuggerCheck
        case "emulatorCheck": self = .emulatorCheck
        case "certificateCheck": self = .certificateCheck
        default: return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .jailbreakDetection: return "jailbreakDetection"
        case .tamperingDetection: return "tamperingDetection"
        case .keychainCheck: return "keychainCheck"
        case .codeSignCheck: return "codeSignCheck"
        case .sandboxCheck: return "sandboxCheck"
        case .debuggerCheck: return "debuggerCheck"
        case .emulatorCheck: return "emulatorCheck"
        case .certificateCheck: return "certificateCheck"
        }
    }
}

extension IntegrityCheckResult.SecuritySeverity: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: String) {
        switch rawValue {
        case "critical": self = .critical
        case "high": self = .high
        case "medium": self = .medium
        case "low": self = .low
        case "info": self = .info
        default: return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .critical: return "critical"
        case .high: return "high"
        case .medium: return "medium"
        case .low: return "low"
        case .info: return "info"
        }
    }
} 