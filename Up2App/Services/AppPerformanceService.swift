import Foundation
import Combine
import UIKit

/// Service for monitoring and tracking app performance metrics
class AppPerformanceService: ObservableObject {
    static let shared = AppPerformanceService()
    
    @Published var appLaunchTime: TimeInterval = 0
    @Published var lastAPIResponseTime: TimeInterval = 0
    @Published var memoryUsage: UInt64 = 0
    @Published var isPerformanceOptimal: Bool = true
    
    private var launchStartTime: Date?
    private var performanceThresholds: PerformanceThresholds
    private var cancellables = Set<AnyCancellable>()
    
    struct PerformanceThresholds {
        let maxAppLaunchTime: TimeInterval = 2.0
        let maxAPIResponseTime: TimeInterval = 0.2
        let maxMemoryUsage: UInt64 = 100 * 1024 * 1024 // 100MB
    }
    
    private init() {
        self.performanceThresholds = PerformanceThresholds()
        setupPerformanceMonitoring()
    }
    
    // MARK: - App Launch Performance
    
    func startLaunchTimer() {
        launchStartTime = Date()
    }
    
    func endLaunchTimer() {
        guard let startTime = launchStartTime else { return }
        
        let launchTime = Date().timeIntervalSince(startTime)
        appLaunchTime = launchTime
        
        // Check if launch time is within acceptable limits
        isPerformanceOptimal = launchTime <= performanceThresholds.maxAppLaunchTime
        
        // Log performance data
        logPerformanceMetric("app_launch_time", value: launchTime)
        
        // Reset timer
        launchStartTime = nil
    }
    
    // MARK: - API Performance
    
    func trackAPICall<T>(_ operation: () async throws -> T) async throws -> T {
        let startTime = Date()
        
        do {
            let result = try await operation()
            let responseTime = Date().timeIntervalSince(startTime)
            
            DispatchQueue.main.async {
                self.lastAPIResponseTime = responseTime
                self.isPerformanceOptimal = responseTime <= self.performanceThresholds.maxAPIResponseTime
            }
            
            logPerformanceMetric("api_response_time", value: responseTime)
            return result
        } catch {
            let responseTime = Date().timeIntervalSince(startTime)
            logPerformanceMetric("api_error_time", value: responseTime)
            throw error
        }
    }
    
    // MARK: - Memory Monitoring
    
    func updateMemoryUsage() {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            DispatchQueue.main.async {
                self.memoryUsage = info.resident_size
                self.isPerformanceOptimal = info.resident_size <= self.performanceThresholds.maxMemoryUsage
            }
        }
    }
    
    // MARK: - Performance Logging
    
    private func logPerformanceMetric(_ metric: String, value: TimeInterval) {
        #if DEBUG
        print("📊 Performance Metric - \(metric): \(String(format: "%.3f", value))s")
        #endif
        
        // In production, this would send to analytics service
        // AnalyticsService.shared.trackPerformanceMetric(metric, value: value)
    }
    
    // MARK: - Performance Monitoring Setup
    
    private func setupPerformanceMonitoring() {
        // Monitor memory usage periodically
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateMemoryUsage()
            }
            .store(in: &cancellables)
        
        // Monitor app state changes
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.updateMemoryUsage()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Performance Reports
    
    func generatePerformanceReport() -> PerformanceReport {
        return PerformanceReport(
            appLaunchTime: appLaunchTime,
            lastAPIResponseTime: lastAPIResponseTime,
            memoryUsage: memoryUsage,
            isOptimal: isPerformanceOptimal,
            timestamp: Date()
        )
    }
}

// MARK: - Performance Report Model

struct PerformanceReport {
    let appLaunchTime: TimeInterval
    let lastAPIResponseTime: TimeInterval
    let memoryUsage: UInt64
    let isOptimal: Bool
    let timestamp: Date
    
    var formattedReport: String {
        """
        📊 Performance Report (\(timestamp.formatted()))
        
        App Launch Time: \(String(format: "%.3f", appLaunchTime))s
        Last API Response: \(String(format: "%.3f", lastAPIResponseTime))s
        Memory Usage: \(ByteCountFormatter.string(fromByteCount: Int64(memoryUsage), countStyle: .memory))
        Performance Status: \(isOptimal ? "✅ Optimal" : "⚠️ Needs Attention")
        """
    }
}

// MARK: - Performance Extensions

extension AppPerformanceService {
    /// Convenience method for tracking async operations
    func trackOperation<T>(_ name: String, operation: () async throws -> T) async throws -> T {
        let startTime = Date()
        
        do {
            let result = try await operation()
            let duration = Date().timeIntervalSince(startTime)
            logPerformanceMetric(name, value: duration)
            return result
        } catch {
            let duration = Date().timeIntervalSince(startTime)
            logPerformanceMetric("\(name)_error", value: duration)
            throw error
        }
    }
} 