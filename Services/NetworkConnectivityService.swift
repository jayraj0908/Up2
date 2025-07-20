import Foundation
import Network
import Combine
import SwiftUI

// MARK: - Network Connectivity Models

struct NetworkStatus {
    let isConnected: Bool
    let connectionType: ConnectionType
    let quality: NetworkQuality
    let speed: NetworkSpeed
    let latency: TimeInterval
    let timestamp: Date
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
        case none
    }
    
    enum NetworkQuality {
        case excellent
        case good
        case fair
        case poor
        case unavailable
    }
    
    enum NetworkSpeed {
        case fast
        case medium
        case slow
        case verySlow
        case unknown
    }
}

struct NetworkMetrics {
    let averageLatency: TimeInterval
    let packetLoss: Double
    let bandwidth: Double
    let connectionStability: Double
    let uptime: TimeInterval
}

struct OfflineCapability {
    let feature: String
    let isAvailable: Bool
    let dataRequired: Bool
    let fallbackStrategy: FallbackStrategy
    
    enum FallbackStrategy {
        case cachedData
        case offlineMode
        case gracefulDegradation
        case errorMessage
        case retryLater
    }
}

// MARK: - Network Connectivity Service

@MainActor
class NetworkConnectivityService: ObservableObject {
    static let shared = NetworkConnectivityService()
    
    // MARK: - Dependencies
    private let performanceService = AppPerformanceService.shared
    private let analyticsService = AnalyticsService.shared
    private let errorService = ErrorHandlingService.shared
    private let hapticService = HapticService.shared
    
    // MARK: - Properties
    @Published var currentNetworkStatus: NetworkStatus?
    @Published var isOfflineMode = false
    @Published var networkMetrics: NetworkMetrics?
    @Published var offlineCapabilities: [OfflineCapability] = []
    
    private let networkMonitor = NWPathMonitor()
    private let networkQueue = DispatchQueue(label: "NetworkConnectivityService")
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private let latencyTestURLs = [
        "https://www.google.com",
        "https://www.apple.com",
        "https://www.cloudflare.com"
    ]
    private let maxLatency: TimeInterval = 5.0
    private let minBandwidth: Double = 1.0 // 1 Mbps
    private let connectionTimeout: TimeInterval = 10.0
    
    // MARK: - Initialization
    private init() {
        setupNetworkMonitoring()
        setupOfflineCapabilities()
    }
    
    // MARK: - Public Methods
    
    /// Start network connectivity monitoring
    func startMonitoring() {
        networkMonitor.start(queue: networkQueue)
        
        analyticsService.trackUserAction("network_monitoring_started")
    }
    
    /// Stop network connectivity monitoring
    func stopMonitoring() {
        networkMonitor.cancel()
        
        analyticsService.trackUserAction("network_monitoring_stopped")
    }
    
    /// Check current network status
    func checkNetworkStatus() async -> NetworkStatus {
        let path = networkMonitor.currentPath
        
        let isConnected = path.status == .satisfied
        let connectionType = determineConnectionType(path)
        let quality = await assessNetworkQuality()
        let speed = determineNetworkSpeed(quality)
        let latency = await measureLatency()
        
        let status = NetworkStatus(
            isConnected: isConnected,
            connectionType: connectionType,
            quality: quality,
            speed: speed,
            latency: latency,
            timestamp: Date()
        )
        
        await MainActor.run {
            currentNetworkStatus = status
            isOfflineMode = !isConnected || quality == .unavailable
            
            // Track network status change
            analyticsService.trackUserAction("network_status_changed", properties: [
                "is_connected": isConnected,
                "connection_type": connectionType.rawValue,
                "quality": quality.rawValue,
                "speed": speed.rawValue,
                "latency": latency
            ])
        }
        
        return status
    }
    
    /// Assess network quality
    func assessNetworkQuality() async -> NetworkStatus.NetworkQuality {
        let latency = await measureLatency()
        let bandwidth = await measureBandwidth()
        let stability = await measureConnectionStability()
        
        // Calculate quality score
        let latencyScore = max(0, 1 - (latency / maxLatency))
        let bandwidthScore = min(1, bandwidth / minBandwidth)
        let stabilityScore = stability
        
        let qualityScore = (latencyScore + bandwidthScore + stabilityScore) / 3
        
        let quality: NetworkStatus.NetworkQuality
        switch qualityScore {
        case 0.8...1.0:
            quality = .excellent
        case 0.6..<0.8:
            quality = .good
        case 0.4..<0.6:
            quality = .fair
        case 0.2..<0.4:
            quality = .poor
        default:
            quality = .unavailable
        }
        
        // Update metrics
        await MainActor.run {
            networkMetrics = NetworkMetrics(
                averageLatency: latency,
                packetLoss: 1 - stability,
                bandwidth: bandwidth,
                connectionStability: stability,
                uptime: getUptime()
            )
        }
        
        return quality
    }
    
    /// Check if feature is available offline
    func isFeatureAvailableOffline(_ feature: String) -> Bool {
        return offlineCapabilities.first { $0.feature == feature }?.isAvailable ?? false
    }
    
    /// Get offline fallback strategy for feature
    func getOfflineFallbackStrategy(for feature: String) -> OfflineCapability.FallbackStrategy? {
        return offlineCapabilities.first { $0.feature == feature }?.fallbackStrategy
    }
    
    /// Perform network operation with offline handling
    func performNetworkOperation<T>(
        operation: @escaping () async throws -> T,
        offlineFallback: @escaping () async -> T?,
        feature: String
    ) async throws -> T {
        let status = await checkNetworkStatus()
        
        if status.isConnected && status.quality != .unavailable {
            do {
                return try await operation()
            } catch {
                // If network operation fails, try offline fallback
                if let offlineResult = await offlineFallback() {
                    analyticsService.trackUserAction("offline_fallback_used", properties: [
                        "feature": feature,
                        "error": error.localizedDescription
                    ])
                    return offlineResult
                } else {
                    throw error
                }
            }
        } else {
            // Offline mode - use fallback
            if let offlineResult = await offlineFallback() {
                analyticsService.trackUserAction("offline_mode_used", properties: [
                    "feature": feature
                ])
                return offlineResult
            } else {
                throw NetworkError.offlineModeUnavailable(feature: feature)
            }
        }
    }
    
    /// Test network connectivity
    func testConnectivity() async -> ConnectivityTestResult {
        let startTime = Date()
        
        do {
            let status = await checkNetworkStatus()
            let latency = await measureLatency()
            let bandwidth = await measureBandwidth()
            
            let result = ConnectivityTestResult(
                success: status.isConnected,
                latency: latency,
                bandwidth: bandwidth,
                quality: status.quality,
                testTime: Date().timeIntervalSince(startTime)
            )
            
            analyticsService.trackUserAction("connectivity_test_completed", properties: [
                "success": result.success,
                "latency": result.latency,
                "bandwidth": result.bandwidth,
                "quality": result.quality.rawValue
            ])
            
            return result
            
        } catch {
            let result = ConnectivityTestResult(
                success: false,
                latency: 0,
                bandwidth: 0,
                quality: .unavailable,
                testTime: Date().timeIntervalSince(startTime)
            )
            
            analyticsService.trackUserAction("connectivity_test_failed", properties: [
                "error": error.localizedDescription
            ])
            
            return result
        }
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() {
        networkMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                await self?.handleNetworkPathUpdate(path)
            }
        }
    }
    
    private func setupOfflineCapabilities() {
        offlineCapabilities = [
            OfflineCapability(
                feature: "event_feed",
                isAvailable: true,
                dataRequired: false,
                fallbackStrategy: .cachedData
            ),
            OfflineCapability(
                feature: "user_profile",
                isAvailable: true,
                dataRequired: false,
                fallbackStrategy: .cachedData
            ),
            OfflineCapability(
                feature: "event_details",
                isAvailable: true,
                dataRequired: false,
                fallbackStrategy: .cachedData
            ),
            OfflineCapability(
                feature: "rsvp",
                isAvailable: false,
                dataRequired: true,
                fallbackStrategy: .retryLater
            ),
            OfflineCapability(
                feature: "event_creation",
                isAvailable: false,
                dataRequired: true,
                fallbackStrategy: .retryLater
            ),
            OfflineCapability(
                feature: "payments",
                isAvailable: false,
                dataRequired: true,
                fallbackStrategy: .errorMessage
            ),
            OfflineCapability(
                feature: "chat",
                isAvailable: false,
                dataRequired: true,
                fallbackStrategy: .retryLater
            )
        ]
    }
    
    private func handleNetworkPathUpdate(_ path: NWPath) async {
        let status = await checkNetworkStatus()
        
        // Handle network status change
        if status.isConnected && !isOfflineMode {
            hapticService.successNotification()
        } else if !status.isConnected && isOfflineMode {
            hapticService.errorNotification()
        }
        
        // Update offline mode
        isOfflineMode = !status.isConnected || status.quality == .unavailable
        
        // Track significant changes
        if let previousStatus = currentNetworkStatus,
           previousStatus.isConnected != status.isConnected {
            analyticsService.trackUserAction("network_connection_changed", properties: [
                "previous_connected": previousStatus.isConnected,
                "current_connected": status.isConnected,
                "connection_type": status.connectionType.rawValue
            ])
        }
    }
    
    private func determineConnectionType(_ path: NWPath) -> NetworkStatus.ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else if path.status == .satisfied {
            return .unknown
        } else {
            return .none
        }
    }
    
    private func determineNetworkSpeed(_ quality: NetworkStatus.NetworkQuality) -> NetworkStatus.NetworkSpeed {
        switch quality {
        case .excellent:
            return .fast
        case .good:
            return .medium
        case .fair:
            return .slow
        case .poor, .unavailable:
            return .verySlow
        }
    }
    
    private func measureLatency() async -> TimeInterval {
        var totalLatency: TimeInterval = 0
        var successfulTests = 0
        
        for urlString in latencyTestURLs {
            guard let url = URL(string: urlString) else { continue }
            
            do {
                let startTime = Date()
                let (_, response) = try await URLSession.shared.data(from: url)
                let latency = Date().timeIntervalSince(startTime)
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    totalLatency += latency
                    successfulTests += 1
                }
            } catch {
                continue
            }
        }
        
        return successfulTests > 0 ? totalLatency / Double(successfulTests) : maxLatency
    }
    
    private func measureBandwidth() async -> Double {
        // Simplified bandwidth measurement
        // In a real implementation, this would download a test file and measure speed
        let testURL = "https://www.google.com"
        guard let url = URL(string: testURL) else { return 0 }
        
        do {
            let startTime = Date()
            let (data, _) = try await URLSession.shared.data(from: url)
            let endTime = Date()
            
            let duration = endTime.timeIntervalSince(startTime)
            let bytesPerSecond = Double(data.count) / duration
            let mbps = bytesPerSecond / (1024 * 1024) * 8 // Convert to Mbps
            
            return mbps
        } catch {
            return 0
        }
    }
    
    private func measureConnectionStability() async -> Double {
        // Simplified stability measurement
        // In a real implementation, this would track connection uptime and packet loss
        let testCount = 5
        var successfulTests = 0
        
        for _ in 0..<testCount {
            do {
                let url = URL(string: "https://www.google.com")!
                let (_, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse,
                   httpResponse.statusCode == 200 {
                    successfulTests += 1
                }
            } catch {
                continue
            }
        }
        
        return Double(successfulTests) / Double(testCount)
    }
    
    private func getUptime() -> TimeInterval {
        // This would track actual connection uptime
        // For now, return a placeholder value
        return 3600 // 1 hour
    }
}

// MARK: - Supporting Types

struct ConnectivityTestResult {
    let success: Bool
    let latency: TimeInterval
    let bandwidth: Double
    let quality: NetworkStatus.NetworkQuality
    let testTime: TimeInterval
}

enum NetworkError: Error, LocalizedError {
    case offlineModeUnavailable(feature: String)
    case connectionTimeout
    case insufficientBandwidth
    case highLatency
    
    var errorDescription: String? {
        switch self {
        case .offlineModeUnavailable(let feature):
            return "Feature '\(feature)' is not available in offline mode"
        case .connectionTimeout:
            return "Network connection timed out"
        case .insufficientBandwidth:
            return "Insufficient network bandwidth"
        case .highLatency:
            return "Network latency is too high"
        }
    }
}

extension NetworkStatus.ConnectionType: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: String) {
        switch rawValue {
        case "wifi": self = .wifi
        case "cellular": self = .cellular
        case "ethernet": self = .ethernet
        case "unknown": self = .unknown
        case "none": self = .none
        default: return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .wifi: return "wifi"
        case .cellular: return "cellular"
        case .ethernet: return "ethernet"
        case .unknown: return "unknown"
        case .none: return "none"
        }
    }
}

extension NetworkStatus.NetworkQuality: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: String) {
        switch rawValue {
        case "excellent": self = .excellent
        case "good": self = .good
        case "fair": self = .fair
        case "poor": self = .poor
        case "unavailable": self = .unavailable
        default: return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .excellent: return "excellent"
        case .good: return "good"
        case .fair: return "fair"
        case .poor: return "poor"
        case .unavailable: return "unavailable"
        }
    }
}

extension NetworkStatus.NetworkSpeed: RawRepresentable {
    typealias RawValue = String
    
    init?(rawValue: String) {
        switch rawValue {
        case "fast": self = .fast
        case "medium": self = .medium
        case "slow": self = .slow
        case "verySlow": self = .verySlow
        case "unknown": self = .unknown
        default: return nil
        }
    }
    
    var rawValue: String {
        switch self {
        case .fast: return "fast"
        case .medium: return "medium"
        case .slow: return "slow"
        case .verySlow: return "verySlow"
        case .unknown: return "unknown"
        }
    }
} 