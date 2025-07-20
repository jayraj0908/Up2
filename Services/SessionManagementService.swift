import Foundation
import SwiftUI
import Combine
import CryptoKit

// MARK: - Session Management Models

struct SessionToken {
    let token: String
    let refreshToken: String
    let expiresAt: Date
    let issuedAt: Date
    let userId: String
    let deviceId: String
    let sessionId: String
    let permissions: [String]
    let isActive: Bool
    
    var isExpired: Bool {
        return Date() >= expiresAt
    }
    
    var timeUntilExpiry: TimeInterval {
        return expiresAt.timeIntervalSince(Date())
    }
}

struct SessionInfo {
    let sessionId: String
    let userId: String
    let deviceId: String
    let deviceInfo: DeviceInfo
    let loginTime: Date
    let lastActivity: Date
    let isActive: Bool
    let trustScore: Double
    let location: SessionLocation?
    
    struct DeviceInfo {
        let deviceName: String
        let deviceType: String
        let osVersion: String
        let appVersion: String
        let ipAddress: String?
    }
    
    struct SessionLocation {
        let latitude: Double
        let longitude: Double
        let accuracy: Double
        let timestamp: Date
    }
}

struct SessionAnomaly {
    let anomalyId: String
    let sessionId: String
    let type: AnomalyType
    let severity: AnomalySeverity
    let description: String
    let timestamp: Date
    let metadata: [String: String]
    
    enum AnomalyType {
        case unusualLocation
        case unusualTime
        case multipleSessions
        case rapidRequests
        case tokenTheft
        case deviceChange
        case behaviorChange
    }
    
    enum AnomalySeverity {
        case low
        case medium
        case high
        case critical
    }
}

struct SessionMetrics {
    let totalSessions: Int
    let activeSessions: Int
    let averageSessionDuration: TimeInterval
    let sessionRefreshRate: Double
    let anomalyCount: Int
    let averageTrustScore: Double
}

// MARK: - Session Management Service

@MainActor
class SessionManagementService: ObservableObject {
    static let shared = SessionManagementService()
    
    // MARK: - Dependencies
    private let performanceService = AppPerformanceService.shared
    private let analyticsService = AnalyticsService.shared
    private let errorService = ErrorHandlingService.shared
    private let hapticService = HapticService.shared
    private let securityService = SecurityService.shared
    private let deviceFingerprintingService = DeviceFingerprintingService.shared
    
    // MARK: - Properties
    @Published var currentSession: SessionInfo?
    @Published var currentToken: SessionToken?
    @Published var activeSessions: [SessionInfo] = []
    @Published var sessionAnomalies: [SessionAnomaly] = []
    @Published var sessionMetrics: SessionMetrics?
    
    private var refreshTimer: Timer?
    private var monitoringTimer: Timer?
    private var sessionHistory: [SessionInfo] = []
    private var tokenHistory: [SessionToken] = []
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private let tokenExpirationTime: TimeInterval = 3600 // 1 hour
    private let refreshThreshold: TimeInterval = 300 // 5 minutes before expiry
    private let sessionTimeout: TimeInterval = 1800 // 30 minutes of inactivity
    private let maxConcurrentSessions = 3
    private let maxSessionHistory = 100
    private let anomalyThreshold = 0.7
    
    // MARK: - Initialization
    private init() {
        setupSessionMonitoring()
        loadSessionData()
    }
    
    // MARK: - Public Methods
    
    /// Create a new session
    func createSession(for userId: String, deviceId: String) async -> SessionInfo? {
        let startTime = Date()
        
        do {
            // Generate session tokens
            let token = await generateSessionToken(userId: userId, deviceId: deviceId)
            
            // Create session info
            let sessionInfo = SessionInfo(
                sessionId: token.sessionId,
                userId: userId,
                deviceId: deviceId,
                deviceInfo: await getDeviceInfo(),
                loginTime: Date(),
                lastActivity: Date(),
                isActive: true,
                trustScore: await calculateSessionTrustScore(),
                location: await getCurrentLocation()
            )
            
            await MainActor.run {
                currentSession = sessionInfo
                currentToken = token
                activeSessions.append(sessionInfo)
                addToSessionHistory(sessionInfo)
                addToTokenHistory(token)
            }
            
            // Start session monitoring
            startSessionMonitoring()
            
            let creationTime = Date().timeIntervalSince(startTime)
            
            analyticsService.trackUserAction("session_created", properties: [
                "user_id": userId,
                "device_id": deviceId,
                "session_id": sessionInfo.sessionId,
                "creation_time": creationTime,
                "trust_score": sessionInfo.trustScore
            ])
            
            hapticService.successNotification()
            return sessionInfo
            
        } catch {
            await errorService.handleSessionError(error)
            return nil
        }
    }
    
    /// Refresh session token
    func refreshSessionToken() async -> Bool {
        guard let currentToken = currentToken else { return false }
        
        let startTime = Date()
        
        do {
            // Check if refresh is needed
            if currentToken.timeUntilExpiry > refreshThreshold {
                return true // No refresh needed yet
            }
            
            // Generate new token
            let newToken = await generateSessionToken(
                userId: currentToken.userId,
                deviceId: currentToken.deviceId
            )
            
            await MainActor.run {
                self.currentToken = newToken
                addToTokenHistory(newToken)
            }
            
            let refreshTime = Date().timeIntervalSince(startTime)
            
            analyticsService.trackUserAction("session_token_refreshed", properties: [
                "user_id": currentToken.userId,
                "session_id": currentToken.sessionId,
                "refresh_time": refreshTime
            ])
            
            return true
            
        } catch {
            await errorService.handleSessionError(error)
            return false
        }
    }
    
    /// Update session activity
    func updateSessionActivity() async {
        guard var session = currentSession else { return }
        
        session.lastActivity = Date()
        
        await MainActor.run {
            currentSession = session
            
            // Update in active sessions
            if let index = activeSessions.firstIndex(where: { $0.sessionId == session.sessionId }) {
                activeSessions[index] = session
            }
        }
        
        // Check for anomalies
        await detectSessionAnomalies()
    }
    
    /// End current session
    func endCurrentSession() async -> Bool {
        guard let session = currentSession else { return false }
        
        await MainActor.run {
            // Mark session as inactive
            currentSession?.isActive = false
            currentToken?.isActive = false
            
            // Remove from active sessions
            activeSessions.removeAll { $0.sessionId == session.sessionId }
        }
        
        analyticsService.trackUserAction("session_ended", properties: [
            "user_id": session.userId,
            "session_id": session.sessionId,
            "session_duration": Date().timeIntervalSince(session.loginTime)
        ])
        
        stopSessionMonitoring()
        hapticService.successNotification()
        
        return true
    }
    
    /// End all sessions for user
    func endAllSessions(for userId: String) async -> Bool {
        let sessionsToEnd = activeSessions.filter { $0.userId == userId }
        
        for session in sessionsToEnd {
            await endSession(session.sessionId)
        }
        
        analyticsService.trackUserAction("all_sessions_ended", properties: [
            "user_id": userId,
            "sessions_ended": sessionsToEnd.count
        ])
        
        return true
    }
    
    /// Get session info
    func getSessionInfo(for sessionId: String) -> SessionInfo? {
        return activeSessions.first { $0.sessionId == sessionId }
    }
    
    /// Get all active sessions for user
    func getActiveSessions(for userId: String) -> [SessionInfo] {
        return activeSessions.filter { $0.userId == userId }
    }
    
    /// Check if session is valid
    func isSessionValid() -> Bool {
        guard let session = currentSession,
              let token = currentToken else { return false }
        
        return session.isActive && 
               !token.isExpired && 
               Date().timeIntervalSince(session.lastActivity) < sessionTimeout
    }
    
    /// Get session metrics
    func getSessionMetrics() -> SessionMetrics? {
        return sessionMetrics
    }
    
    /// Get session anomalies
    func getSessionAnomalies() -> [SessionAnomaly] {
        return sessionAnomalies
    }
    
    // MARK: - Private Methods
    
    private func setupSessionMonitoring() {
        // Monitor app state changes
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task {
                    await self?.handleAppBecameActive()
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                Task {
                    await self?.handleAppWillResignActive()
                }
            }
            .store(in: &cancellables)
    }
    
    private func loadSessionData() {
        // Load session data from secure storage
        Task {
            if let sessionData = securityService.secureRetrieveData(forKey: "session_data"),
               let session = try? JSONDecoder().decode(SessionInfo.self, from: sessionData) {
                await MainActor.run {
                    currentSession = session
                }
            }
        }
    }
    
    private func generateSessionToken(userId: String, deviceId: String) async -> SessionToken {
        let token = generateSecureToken()
        let refreshToken = generateSecureToken()
        let sessionId = UUID().uuidString
        
        return SessionToken(
            token: token,
            refreshToken: refreshToken,
            expiresAt: Date().addingTimeInterval(tokenExpirationTime),
            issuedAt: Date(),
            userId: userId,
            deviceId: deviceId,
            sessionId: sessionId,
            permissions: getDefaultPermissions(),
            isActive: true
        )
    }
    
    private func generateSecureToken() -> String {
        let data = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        return data.base64EncodedString()
    }
    
    private func getDefaultPermissions() -> [String] {
        return ["read", "write", "profile"]
    }
    
    private func getDeviceInfo() async -> SessionInfo.DeviceInfo {
        let device = UIDevice.current
        let bundle = Bundle.main
        
        return SessionInfo.DeviceInfo(
            deviceName: device.name,
            deviceType: device.model,
            osVersion: device.systemVersion,
            appVersion: bundle.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            ipAddress: await getIPAddress()
        )
    }
    
    private func getIPAddress() async -> String? {
        // This would get the actual IP address
        // For now, return nil
        return nil
    }
    
    private func calculateSessionTrustScore() async -> Double {
        // Get device trust score
        let deviceTrustScore = await deviceFingerprintingService.calculateDeviceTrustScore()
        return deviceTrustScore.score
    }
    
    private func getCurrentLocation() async -> SessionInfo.SessionLocation? {
        // This would get the current location
        // For now, return nil
        return nil
    }
    
    private func startSessionMonitoring() {
        // Start token refresh timer
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            Task {
                await self?.checkTokenRefresh()
            }
        }
        
        // Start session monitoring timer
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task {
                await self?.monitorSession()
            }
        }
    }
    
    private func stopSessionMonitoring() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        monitoringTimer?.invalidate()
        monitoringTimer = nil
    }
    
    private func checkTokenRefresh() async {
        await refreshSessionToken()
    }
    
    private func monitorSession() async {
        // Update session activity
        await updateSessionActivity()
        
        // Check for session timeout
        await checkSessionTimeout()
        
        // Detect anomalies
        await detectSessionAnomalies()
    }
    
    private func checkSessionTimeout() async {
        guard let session = currentSession else { return }
        
        let timeSinceLastActivity = Date().timeIntervalSince(session.lastActivity)
        
        if timeSinceLastActivity >= sessionTimeout {
            await endCurrentSession()
            
            analyticsService.trackUserAction("session_timeout", properties: [
                "user_id": session.userId,
                "session_id": session.sessionId,
                "inactive_time": timeSinceLastActivity
            ])
        }
    }
    
    private func detectSessionAnomalies() async {
        guard let session = currentSession else { return }
        
        var anomalies: [SessionAnomaly] = []
        
        // Check for unusual location
        if let locationAnomaly = await detectLocationAnomaly(session) {
            anomalies.append(locationAnomaly)
        }
        
        // Check for unusual time
        if let timeAnomaly = await detectTimeAnomaly(session) {
            anomalies.append(timeAnomaly)
        }
        
        // Check for multiple sessions
        if let multipleSessionsAnomaly = await detectMultipleSessionsAnomaly(session) {
            anomalies.append(multipleSessionsAnomaly)
        }
        
        // Check for rapid requests
        if let rapidRequestsAnomaly = await detectRapidRequestsAnomaly(session) {
            anomalies.append(rapidRequestsAnomaly)
        }
        
        // Add anomalies to history
        await MainActor.run {
            sessionAnomalies.append(contentsOf: anomalies)
            
            // Keep history manageable
            if sessionAnomalies.count > 50 {
                sessionAnomalies.removeFirst(sessionAnomalies.count - 50)
            }
        }
        
        // Track anomalies
        for anomaly in anomalies {
            analyticsService.trackUserAction("session_anomaly_detected", properties: [
                "anomaly_type": anomaly.type.rawValue,
                "severity": anomaly.severity.rawValue,
                "description": anomaly.description
            ])
        }
    }
    
    private func detectLocationAnomaly(_ session: SessionInfo) async -> SessionAnomaly? {
        // This would implement location anomaly detection
        // For now, return nil
        return nil
    }
    
    private func detectTimeAnomaly(_ session: SessionInfo) async -> SessionAnomaly? {
        // This would implement time anomaly detection
        // For now, return nil
        return nil
    }
    
    private func detectMultipleSessionsAnomaly(_ session: SessionInfo) async -> SessionAnomaly? {
        let userSessions = activeSessions.filter { $0.userId == session.userId }
        
        if userSessions.count > maxConcurrentSessions {
            return SessionAnomaly(
                anomalyId: UUID().uuidString,
                sessionId: session.sessionId,
                type: .multipleSessions,
                severity: .medium,
                description: "Multiple active sessions detected",
                timestamp: Date(),
                metadata: [
                    "session_count": String(userSessions.count),
                    "max_sessions": String(maxConcurrentSessions)
                ]
            )
        }
        
        return nil
    }
    
    private func detectRapidRequestsAnomaly(_ session: SessionInfo) async -> SessionAnomaly? {
        // This would implement rapid requests detection
        // For now, return nil
        return nil
    }
    
    private func endSession(_ sessionId: String) async {
        if let index = activeSessions.firstIndex(where: { $0.sessionId == sessionId }) {
            var session = activeSessions[index]
            session.isActive = false
            activeSessions[index] = session
        }
    }
    
    private func addToSessionHistory(_ session: SessionInfo) {
        sessionHistory.append(session)
        
        if sessionHistory.count > maxSessionHistory {
            sessionHistory.removeFirst(sessionHistory.count - maxSessionHistory)
        }
    }
    
    private func addToTokenHistory(_ token: SessionToken) {
        tokenHistory.append(token)
        
        if tokenHistory.count > maxSessionHistory {
            tokenHistory.removeFirst(tokenHistory.count - maxSessionHistory)
        }
    }
    
    private func handleAppBecameActive() async {
        await updateSessionActivity()
    }
    
    private func handleAppWillResignActive() async {
        await updateSessionActivity()
    }
}

// MARK: - Supporting Types

extension SessionAnomaly.AnomalyType: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: String) {
        switch rawValue {
        case "unusualLocation": self = .unusualLocation
        case "unusualTime": self = .unusualTime
        case "multipleSessions": self = .multipleSessions
        case "rapidRequests": self = .rapidRequests
        case "tokenTheft": self = .tokenTheft
        case "deviceChange": self = .deviceChange
        case "behaviorChange": self = .behaviorChange
        default: return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .unusualLocation: return "unusualLocation"
        case .unusualTime: return "unusualTime"
        case .multipleSessions: return "multipleSessions"
        case .rapidRequests: return "rapidRequests"
        case .tokenTheft: return "tokenTheft"
        case .deviceChange: return "deviceChange"
        case .behaviorChange: return "behaviorChange"
        }
    }
}

extension SessionAnomaly.AnomalySeverity: RawRepresentable {
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