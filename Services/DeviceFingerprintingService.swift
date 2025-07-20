import Foundation
import UIKit
import SystemConfiguration
import Network
import SwiftUI
import Combine

// MARK: - Device Fingerprinting Models

struct DeviceFingerprint {
    let deviceId: String
    let hardwareFingerprint: String
    let softwareFingerprint: String
    let networkFingerprint: String
    let behavioralFingerprint: String
    let timestamp: Date
    let version: String
}

struct DeviceTrustScore {
    let deviceId: String
    let score: Double
    let factors: [TrustFactor]
    let riskLevel: RiskLevel
    let lastUpdated: Date
    
    enum RiskLevel {
        case low
        case medium
        case high
        case critical
    }
    
    struct TrustFactor {
        let type: FactorType
        let weight: Double
        let score: Double
        let description: String
        
        enum FactorType {
            case hardware
            case software
            case network
            case behavioral
            case location
            case time
        }
    }
}

struct DeviceSecurityEvent {
    let eventId: String
    let deviceId: String
    let eventType: SecurityEventType
    let severity: SecuritySeverity
    let description: String
    let timestamp: Date
    let metadata: [String: String]
    
    enum SecurityEventType {
        case suspiciousActivity
        case locationAnomaly
        case timeAnomaly
        case networkChange
        case hardwareChange
        case softwareChange
        case behavioralAnomaly
        case trustScoreDrop
    }
    
    enum SecuritySeverity {
        case low
        case medium
        case high
        case critical
    }
}

struct DeviceManagementInfo {
    let deviceId: String
    let deviceName: String
    let deviceType: DeviceType
    let isTrusted: Bool
    let trustScore: Double
    let lastSeen: Date
    let isActive: Bool
    let canRevoke: Bool
    
    enum DeviceType {
        case primary
        case secondary
        case shared
        case unknown
    }
}

struct DeviceAnalytics {
    let totalDevices: Int
    let trustedDevices: Int
    let suspiciousDevices: Int
    let averageTrustScore: Double
    let securityEvents: Int
    let deviceTypes: [DeviceManagementInfo.DeviceType: Int]
}

// MARK: - Device Fingerprinting Service

@MainActor
class DeviceFingerprintingService: ObservableObject {
    static let shared = DeviceFingerprintingService()
    
    // MARK: - Dependencies
    private let performanceService = AppPerformanceService.shared
    private let analyticsService = AnalyticsService.shared
    private let errorService = ErrorHandlingService.shared
    private let hapticService = HapticService.shared
    private let securityService = SecurityService.shared
    private let appIntegrityService = AppIntegrityService.shared
    
    // MARK: - Properties
    @Published var currentDeviceFingerprint: DeviceFingerprint?
    @Published var deviceTrustScore: DeviceTrustScore?
    @Published var securityEvents: [DeviceSecurityEvent] = []
    @Published var managedDevices: [DeviceManagementInfo] = []
    @Published var deviceAnalytics: DeviceAnalytics?
    
    private var fingerprintHistory: [DeviceFingerprint] = []
    private var trustScoreHistory: [DeviceTrustScore] = []
    private var monitoringTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private let fingerprintVersion = "1.0.0"
    private let trustScoreThreshold = 0.7
    private let monitoringInterval: TimeInterval = 300 // 5 minutes
    private let maxFingerprintHistory = 100
    private let maxSecurityEvents = 50
    
    // MARK: - Initialization
    private init() {
        setupDeviceMonitoring()
        generateInitialFingerprint()
    }
    
    // MARK: - Public Methods
    
    /// Generate device fingerprint
    func generateDeviceFingerprint() async -> DeviceFingerprint {
        let startTime = Date()
        
        let hardwareFingerprint = await generateHardwareFingerprint()
        let softwareFingerprint = await generateSoftwareFingerprint()
        let networkFingerprint = await generateNetworkFingerprint()
        let behavioralFingerprint = await generateBehavioralFingerprint()
        
        let fingerprint = DeviceFingerprint(
            deviceId: getDeviceId(),
            hardwareFingerprint: hardwareFingerprint,
            softwareFingerprint: softwareFingerprint,
            networkFingerprint: networkFingerprint,
            behavioralFingerprint: behavioralFingerprint,
            timestamp: Date(),
            version: fingerprintVersion
        )
        
        await MainActor.run {
            currentDeviceFingerprint = fingerprint
            addToFingerprintHistory(fingerprint)
        }
        
        let generationTime = Date().timeIntervalSince(startTime)
        
        analyticsService.trackUserAction("device_fingerprint_generated", properties: [
            "generation_time": generationTime,
            "fingerprint_version": fingerprintVersion
        ])
        
        return fingerprint
    }
    
    /// Calculate device trust score
    func calculateDeviceTrustScore() async -> DeviceTrustScore {
        guard let fingerprint = currentDeviceFingerprint else {
            return createDefaultTrustScore()
        }
        
        let startTime = Date()
        
        // Calculate trust factors
        let hardwareFactor = await calculateHardwareTrustFactor(fingerprint)
        let softwareFactor = await calculateSoftwareTrustFactor(fingerprint)
        let networkFactor = await calculateNetworkTrustFactor(fingerprint)
        let behavioralFactor = await calculateBehavioralTrustFactor(fingerprint)
        let locationFactor = await calculateLocationTrustFactor()
        let timeFactor = await calculateTimeTrustFactor()
        
        let factors = [hardwareFactor, softwareFactor, networkFactor, behavioralFactor, locationFactor, timeFactor]
        
        // Calculate weighted score
        let totalWeight = factors.reduce(0) { $0 + $1.weight }
        let weightedScore = factors.reduce(0) { $0 + ($1.score * $1.weight) }
        let finalScore = totalWeight > 0 ? weightedScore / totalWeight : 0
        
        let riskLevel = determineRiskLevel(finalScore)
        
        let trustScore = DeviceTrustScore(
            deviceId: fingerprint.deviceId,
            score: finalScore,
            factors: factors,
            riskLevel: riskLevel,
            lastUpdated: Date()
        )
        
        await MainActor.run {
            deviceTrustScore = trustScore
            addToTrustScoreHistory(trustScore)
        }
        
        let calculationTime = Date().timeIntervalSince(startTime)
        
        analyticsService.trackUserAction("device_trust_score_calculated", properties: [
            "trust_score": finalScore,
            "risk_level": riskLevel.rawValue,
            "calculation_time": calculationTime
        ])
        
        return trustScore
    }
    
    /// Detect suspicious activity
    func detectSuspiciousActivity() async -> [DeviceSecurityEvent] {
        var events: [DeviceSecurityEvent] = []
        
        // Check for fingerprint changes
        if let fingerprintChange = await detectFingerprintChanges() {
            events.append(fingerprintChange)
        }
        
        // Check for location anomalies
        if let locationAnomaly = await detectLocationAnomalies() {
            events.append(locationAnomaly)
        }
        
        // Check for time anomalies
        if let timeAnomaly = await detectTimeAnomalies() {
            events.append(timeAnomaly)
        }
        
        // Check for network changes
        if let networkChange = await detectNetworkChanges() {
            events.append(networkChange)
        }
        
        // Check for trust score drops
        if let trustScoreDrop = await detectTrustScoreDrops() {
            events.append(trustScoreDrop)
        }
        
        // Add events to history
        await MainActor.run {
            securityEvents.append(contentsOf: events)
            
            // Keep history manageable
            if securityEvents.count > maxSecurityEvents {
                securityEvents.removeFirst(securityEvents.count - maxSecurityEvents)
            }
        }
        
        // Track events
        for event in events {
            analyticsService.trackUserAction("device_security_event", properties: [
                "event_type": event.eventType.rawValue,
                "severity": event.severity.rawValue,
                "description": event.description
            ])
        }
        
        return events
    }
    
    /// Manage device trust
    func manageDeviceTrust(deviceId: String, action: DeviceTrustAction) async -> Bool {
        switch action {
        case .trust:
            return await trustDevice(deviceId)
        case .untrust:
            return await untrustDevice(deviceId)
        case .revoke:
            return await revokeDevice(deviceId)
        case .monitor:
            return await monitorDevice(deviceId)
        }
    }
    
    /// Get device management info
    func getDeviceManagementInfo() -> [DeviceManagementInfo] {
        return managedDevices
    }
    
    /// Get device analytics
    func getDeviceAnalytics() -> DeviceAnalytics? {
        return deviceAnalytics
    }
    
    /// Start device monitoring
    func startDeviceMonitoring() {
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: monitoringInterval, repeats: true) { [weak self] _ in
            Task {
                await self?.performDeviceMonitoring()
            }
        }
        
        analyticsService.trackUserAction("device_monitoring_started")
    }
    
    /// Stop device monitoring
    func stopDeviceMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        
        analyticsService.trackUserAction("device_monitoring_stopped")
    }
    
    // MARK: - Private Methods
    
    private func setupDeviceMonitoring() {
        // Start monitoring by default
        startDeviceMonitoring()
    }
    
    private func generateInitialFingerprint() {
        Task {
            await generateDeviceFingerprint()
            await calculateDeviceTrustScore()
        }
    }
    
    private func generateHardwareFingerprint() async -> String {
        let device = UIDevice.current
        let systemInfo = ProcessInfo.processInfo
        
        let hardwareInfo = [
            device.name,
            device.model,
            device.systemName,
            device.systemVersion,
            systemInfo.processorCount.description,
            systemInfo.physicalMemory.description,
            UIDevice.current.identifierForVendor?.uuidString ?? ""
        ].joined(separator: "|")
        
        return hashString(hardwareInfo)
    }
    
    private func generateSoftwareFingerprint() async -> String {
        let bundle = Bundle.main
        let systemInfo = ProcessInfo.processInfo
        
        let softwareInfo = [
            bundle.bundleIdentifier ?? "",
            bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "",
            bundle.infoDictionary?["CFBundleVersion"] as? String ?? "",
            systemInfo.operatingSystemVersionString,
            systemInfo.hostName,
            systemInfo.userName
        ].joined(separator: "|")
        
        return hashString(softwareInfo)
    }
    
    private func generateNetworkFingerprint() async -> String {
        let networkInfo = [
            getNetworkType(),
            getNetworkSSID(),
            getNetworkIPAddress()
        ].joined(separator: "|")
        
        return hashString(networkInfo)
    }
    
    private func generateBehavioralFingerprint() async -> String {
        let behavioralInfo = [
            getAppUsagePattern(),
            getDeviceOrientation(),
            getTimeZone(),
            getLanguage()
        ].joined(separator: "|")
        
        return hashString(behavioralInfo)
    }
    
    private func getDeviceId() -> String {
        return UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
    
    private func hashString(_ input: String) -> String {
        let data = Data(input.utf8)
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    private func calculateHardwareTrustFactor(_ fingerprint: DeviceFingerprint) async -> DeviceTrustScore.TrustFactor {
        // Check hardware integrity
        let isJailbroken = await appIntegrityService.performIntegrityCheck().jailbreakDetected
        let hardwareScore = isJailbroken ? 0.0 : 0.9
        
        return DeviceTrustScore.TrustFactor(
            type: .hardware,
            weight: 0.25,
            score: hardwareScore,
            description: isJailbroken ? "Device appears to be jailbroken" : "Hardware integrity verified"
        )
    }
    
    private func calculateSoftwareTrustFactor(_ fingerprint: DeviceFingerprint) async -> DeviceTrustScore.TrustFactor {
        // Check software integrity
        let integrityStatus = await appIntegrityService.performIntegrityCheck()
        let softwareScore = integrityStatus.isSecure ? 0.9 : 0.3
        
        return DeviceTrustScore.TrustFactor(
            type: .software,
            weight: 0.25,
            score: softwareScore,
            description: integrityStatus.isSecure ? "Software integrity verified" : "Software integrity compromised"
        )
    }
    
    private func calculateNetworkTrustFactor(_ fingerprint: DeviceFingerprint) async -> DeviceTrustScore.TrustFactor {
        // Check network security
        let networkType = getNetworkType()
        let networkScore: Double
        
        switch networkType {
        case "WiFi":
            networkScore = 0.8
        case "Cellular":
            networkScore = 0.7
        default:
            networkScore = 0.5
        }
        
        return DeviceTrustScore.TrustFactor(
            type: .network,
            weight: 0.15,
            score: networkScore,
            description: "Network type: \(networkType)"
        )
    }
    
    private func calculateBehavioralTrustFactor(_ fingerprint: DeviceFingerprint) async -> DeviceTrustScore.TrustFactor {
        // Check behavioral patterns
        let behavioralScore = 0.8 // Would analyze user behavior patterns
        
        return DeviceTrustScore.TrustFactor(
            type: .behavioral,
            weight: 0.15,
            score: behavioralScore,
            description: "Behavioral patterns normal"
        )
    }
    
    private func calculateLocationTrustFactor() async -> DeviceTrustScore.TrustFactor {
        // Check location consistency
        let locationScore = 0.9 // Would check location history and consistency
        
        return DeviceTrustScore.TrustFactor(
            type: .location,
            weight: 0.1,
            score: locationScore,
            description: "Location patterns consistent"
        )
    }
    
    private func calculateTimeTrustFactor() async -> DeviceTrustScore.TrustFactor {
        // Check time-based patterns
        let timeScore = 0.9 // Would check time-based usage patterns
        
        return DeviceTrustScore.TrustFactor(
            type: .time,
            weight: 0.1,
            score: timeScore,
            description: "Time patterns normal"
        )
    }
    
    private func determineRiskLevel(_ score: Double) -> DeviceTrustScore.RiskLevel {
        switch score {
        case 0.8...1.0:
            return .low
        case 0.6..<0.8:
            return .medium
        case 0.4..<0.6:
            return .high
        default:
            return .critical
        }
    }
    
    private func createDefaultTrustScore() -> DeviceTrustScore {
        return DeviceTrustScore(
            deviceId: getDeviceId(),
            score: 0.5,
            factors: [],
            riskLevel: .medium,
            lastUpdated: Date()
        )
    }
    
    private func detectFingerprintChanges() async -> DeviceSecurityEvent? {
        guard fingerprintHistory.count >= 2 else { return nil }
        
        let current = fingerprintHistory.last!
        let previous = fingerprintHistory[fingerprintHistory.count - 2]
        
        if current.hardwareFingerprint != previous.hardwareFingerprint ||
           current.softwareFingerprint != previous.softwareFingerprint {
            
            return DeviceSecurityEvent(
                eventId: UUID().uuidString,
                deviceId: current.deviceId,
                eventType: .hardwareChange,
                severity: .high,
                description: "Device fingerprint changed unexpectedly",
                timestamp: Date(),
                metadata: [
                    "previous_hardware": previous.hardwareFingerprint,
                    "current_hardware": current.hardwareFingerprint
                ]
            )
        }
        
        return nil
    }
    
    private func detectLocationAnomalies() async -> DeviceSecurityEvent? {
        // This would implement location anomaly detection
        // For now, return nil
        return nil
    }
    
    private func detectTimeAnomalies() async -> DeviceSecurityEvent? {
        // This would implement time anomaly detection
        // For now, return nil
        return nil
    }
    
    private func detectNetworkChanges() async -> DeviceSecurityEvent? {
        // This would implement network change detection
        // For now, return nil
        return nil
    }
    
    private func detectTrustScoreDrops() async -> DeviceSecurityEvent? {
        guard trustScoreHistory.count >= 2 else { return nil }
        
        let current = trustScoreHistory.last!
        let previous = trustScoreHistory[trustScoreHistory.count - 2]
        
        let scoreDrop = previous.score - current.score
        
        if scoreDrop > 0.2 { // Significant drop
            return DeviceSecurityEvent(
                eventId: UUID().uuidString,
                deviceId: current.deviceId,
                eventType: .trustScoreDrop,
                severity: .medium,
                description: "Device trust score dropped significantly",
                timestamp: Date(),
                metadata: [
                    "previous_score": String(previous.score),
                    "current_score": String(current.score),
                    "score_drop": String(scoreDrop)
                ]
            )
        }
        
        return nil
    }
    
    private func trustDevice(_ deviceId: String) async -> Bool {
        // Implement device trust logic
        analyticsService.trackUserAction("device_trusted", properties: ["device_id": deviceId])
        return true
    }
    
    private func untrustDevice(_ deviceId: String) async -> Bool {
        // Implement device untrust logic
        analyticsService.trackUserAction("device_untrusted", properties: ["device_id": deviceId])
        return true
    }
    
    private func revokeDevice(_ deviceId: String) async -> Bool {
        // Implement device revocation logic
        analyticsService.trackUserAction("device_revoked", properties: ["device_id": deviceId])
        return true
    }
    
    private func monitorDevice(_ deviceId: String) async -> Bool {
        // Implement device monitoring logic
        analyticsService.trackUserAction("device_monitored", properties: ["device_id": deviceId])
        return true
    }
    
    private func addToFingerprintHistory(_ fingerprint: DeviceFingerprint) {
        fingerprintHistory.append(fingerprint)
        
        if fingerprintHistory.count > maxFingerprintHistory {
            fingerprintHistory.removeFirst(fingerprintHistory.count - maxFingerprintHistory)
        }
    }
    
    private func addToTrustScoreHistory(_ trustScore: DeviceTrustScore) {
        trustScoreHistory.append(trustScore)
        
        if trustScoreHistory.count > maxFingerprintHistory {
            trustScoreHistory.removeFirst(trustScoreHistory.count - maxFingerprintHistory)
        }
    }
    
    private func performDeviceMonitoring() async {
        // Perform regular device monitoring
        await generateDeviceFingerprint()
        await calculateDeviceTrustScore()
        await detectSuspiciousActivity()
    }
    
    // MARK: - Helper Methods
    
    private func getNetworkType() -> String {
        // This would determine the actual network type
        return "WiFi"
    }
    
    private func getNetworkSSID() -> String {
        // This would get the actual network SSID
        return "Unknown"
    }
    
    private func getNetworkIPAddress() -> String {
        // This would get the actual IP address
        return "Unknown"
    }
    
    private func getAppUsagePattern() -> String {
        // This would analyze app usage patterns
        return "Normal"
    }
    
    private func getDeviceOrientation() -> String {
        return UIDevice.current.orientation.rawValue.description
    }
    
    private func getTimeZone() -> String {
        return TimeZone.current.identifier
    }
    
    private func getLanguage() -> String {
        return Locale.current.languageCode ?? "Unknown"
    }
}

// MARK: - Supporting Types

enum DeviceTrustAction {
    case trust
    case untrust
    case revoke
    case monitor
}

extension DeviceTrustScore.RiskLevel: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: String) {
        switch rawValue {
        case "low": self = .low
        case "medium": self = .medium
        case "high": self = .high
        case "critical": self = .critical
        default: return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .low: return "low"
        case .medium: return "medium"
        case .high: return "high"
        case .critical: return "critical"
        }
    }
}

extension DeviceSecurityEvent.SecurityEventType: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: String) {
        switch rawValue {
        case "suspiciousActivity": self = .suspiciousActivity
        case "locationAnomaly": self = .locationAnomaly
        case "timeAnomaly": self = .timeAnomaly
        case "networkChange": self = .networkChange
        case "hardwareChange": self = .hardwareChange
        case "softwareChange": self = .softwareChange
        case "behavioralAnomaly": self = .behavioralAnomaly
        case "trustScoreDrop": self = .trustScoreDrop
        default: return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .suspiciousActivity: return "suspiciousActivity"
        case .locationAnomaly: return "locationAnomaly"
        case .timeAnomaly: return "timeAnomaly"
        case .networkChange: return "networkChange"
        case .hardwareChange: return "hardwareChange"
        case .softwareChange: return "softwareChange"
        case .behavioralAnomaly: return "behavioralAnomaly"
        case .trustScoreDrop: return "trustScoreDrop"
        }
    }
}

extension DeviceSecurityEvent.SecuritySeverity: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: String) {
        switch rawValue {
        case "low": self = .low
        case "medium": self = .medium
        case "high": self = .high
        case "critical": self = .critical
        default: return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .low: return "low"
        case .medium: return "medium"
        case .high: return "high"
        case .critical: return "critical"
        }
    }
}

extension DeviceManagementInfo.DeviceType: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: String) {
        switch rawValue {
        case "primary": self = .primary
        case "secondary": self = .secondary
        case "shared": self = .shared
        case "unknown": self = .unknown
        default: return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .primary: return "primary"
        case .secondary: return "secondary"
        case .shared: return "shared"
        case .unknown: return "unknown"
        }
    }
} 