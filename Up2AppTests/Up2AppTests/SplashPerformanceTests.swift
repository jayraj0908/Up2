import XCTest
import SwiftUI
import Combine
@testable import Up2App

// MARK: - Performance Metrics Collector
class PerformanceMetricsCollector {
    private var measurements: [String: TimeInterval] = [:]
    private var memoryUsage: [String: Double] = [:]
    private var frameRates: [String: Double] = [:]
    
    func recordTiming(for operation: String, duration: TimeInterval) {
        measurements[operation] = duration
    }
    
    func recordMemoryUsage(for operation: String, usage: Double) {
        memoryUsage[operation] = usage
    }
    
    func recordFrameRate(for operation: String, fps: Double) {
        frameRates[operation] = fps
    }
    
    func getTiming(for operation: String) -> TimeInterval? {
        return measurements[operation]
    }
    
    func getMemoryUsage(for operation: String) -> Double? {
        return memoryUsage[operation]
    }
    
    func getFrameRate(for operation: String) -> Double? {
        return frameRates[operation]
    }
    
    func generateReport() -> String {
        var report = "Performance Report:\n"
        report += "===================\n"
        
        report += "\nTiming Measurements:\n"
        for (operation, duration) in measurements {
            report += "  \(operation): \(String(format: "%.3f", duration))s\n"
        }
        
        report += "\nMemory Usage:\n"
        for (operation, usage) in memoryUsage {
            report += "  \(operation): \(String(format: "%.2f", usage))MB\n"
        }
        
        report += "\nFrame Rates:\n"
        for (operation, fps) in frameRates {
            report += "  \(operation): \(String(format: "%.1f", fps))fps\n"
        }
        
        return report
    }
}

// MARK: - Memory Monitor
class MemoryMonitor {
    static func getCurrentMemoryUsage() -> Double {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Double(taskInfo.resident_size) / 1024.0 / 1024.0 // Convert to MB
        } else {
            return 0.0
        }
    }
}

// MARK: - Frame Rate Monitor
class FrameRateMonitor {
    private var displayLink: CADisplayLink?
    private var frameCount: Int = 0
    private var startTime: CFTimeInterval = 0
    private var completion: ((Double) -> Void)?
    
    func startMonitoring(duration: TimeInterval, completion: @escaping (Double) -> Void) {
        self.completion = completion
        frameCount = 0
        
        displayLink = CADisplayLink(target: self, selector: #selector(frameUpdate))
        displayLink?.add(to: .current, forMode: .common)
        startTime = CACurrentMediaTime()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.stopMonitoring()
        }
    }
    
    @objc private func frameUpdate() {
        frameCount += 1
    }
    
    private func stopMonitoring() {
        displayLink?.invalidate()
        displayLink = nil
        
        let endTime = CACurrentMediaTime()
        let duration = endTime - startTime
        let fps = Double(frameCount) / duration
        
        completion?(fps)
    }
}

// MARK: - Splash Performance Tests
@MainActor
final class SplashPerformanceTests: XCTestCase {
    
    private var splashViewModel: SplashViewModel!
    private var mockInitializationService: MockAppInitializationService!
    private var performanceCollector: PerformanceMetricsCollector!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockInitializationService = MockAppInitializationService()
        splashViewModel = SplashViewModel(initializationService: mockInitializationService)
        performanceCollector = PerformanceMetricsCollector()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        splashViewModel = nil
        mockInitializationService = nil
        performanceCollector = nil
        super.tearDown()
        
        // Print performance report
        print(performanceCollector?.generateReport() ?? "No performance data collected")
    }
    
    // MARK: - Duration Requirement Tests (AC: 6)
    
    func testSplashDurationRequirement_MinimumDuration() async {
        // Test Acceptance Criteria 6: Appropriate duration (2-3 seconds maximum)
        
        let testCases: [(name: String, initDelay: TimeInterval, expectedMinimum: TimeInterval)] = [
            ("Ultra Fast Init", 0.05, 2.0),
            ("Fast Init", 0.1, 2.0),
            ("Normal Init", 0.5, 2.0),
            ("Slow Init", 1.0, 2.0),
            ("Very Slow Init", 2.5, 2.5) // Should not add extra delay if already slow
        ]
        
        for testCase in testCases {
            // Given
            mockInitializationService.delay = testCase.initDelay
            mockInitializationService.shouldSucceed = true
            
            let expectation = XCTestExpectation(description: "Duration test: \(testCase.name)")
            
            splashViewModel.$shouldNavigate
                .dropFirst()
                .sink { shouldNavigate in
                    if shouldNavigate {
                        expectation.fulfill()
                    }
                }
                .store(in: &cancellables)
            
            // When
            let startTime = Date()
            splashViewModel.startInitialization()
            
            // Then
            await fulfillment(of: [expectation], timeout: 5.0)
            
            let actualDuration = Date().timeIntervalSince(startTime)
            XCTAssertGreaterThanOrEqual(actualDuration, testCase.expectedMinimum, 
                                      "Test case '\(testCase.name)': Duration \(actualDuration)s should be at least \(testCase.expectedMinimum)s")
            XCTAssertLessThanOrEqual(actualDuration, 4.0, 
                                   "Test case '\(testCase.name)': Duration \(actualDuration)s should not exceed 4 seconds")
            
            performanceCollector.recordTiming(for: testCase.name, duration: actualDuration)
            
            // Reset for next test
            splashViewModel = SplashViewModel(initializationService: mockInitializationService)
        }
    }
    
    func testSplashDurationRequirement_MaximumDuration() async {
        // Verify splash never exceeds reasonable maximum duration
        
        let expectation = XCTestExpectation(description: "Maximum duration test")
        
        splashViewModel.$shouldNavigate
            .dropFirst()
            .sink { shouldNavigate in
                if shouldNavigate {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Given - Normal initialization
        mockInitializationService.delay = 0.5
        
        // When
        let startTime = Date()
        splashViewModel.startInitialization()
        
        // Then
        await fulfillment(of: [expectation], timeout: 4.0)
        
        let duration = Date().timeIntervalSince(startTime)
        XCTAssertLessThanOrEqual(duration, 3.5, "Splash duration should not exceed 3.5 seconds under normal conditions")
        
        performanceCollector.recordTiming(for: "Maximum Duration Test", duration: duration)
    }
    
    // MARK: - Animation Performance Tests
    
    func testAnimationFrameRate() async {
        // Test that animations maintain 60fps during splash screen
        
        let frameRateExpectation = XCTestExpectation(description: "Frame rate measurement")
        let frameRateMonitor = FrameRateMonitor()
        
        // Given
        mockInitializationService.delay = 1.0 // Longer to capture frame rate
        
        // Start monitoring frame rate
        frameRateMonitor.startMonitoring(duration: 2.0) { fps in
            self.performanceCollector.recordFrameRate(for: "Splash Animation", fps: fps)
            XCTAssertGreaterThanOrEqual(fps, 55.0, "Animation should maintain at least 55fps")
            frameRateExpectation.fulfill()
        }
        
        // When
        splashViewModel.startInitialization()
        
        // Then
        await fulfillment(of: [frameRateExpectation], timeout: 5.0)
    }
    
    func testAnimationMemoryUsage() async {
        // Test that splash screen animations don't cause memory spikes
        
        let memoryExpectation = XCTestExpectation(description: "Memory usage measurement")
        
        // Given
        let initialMemory = MemoryMonitor.getCurrentMemoryUsage()
        performanceCollector.recordMemoryUsage(for: "Initial Memory", usage: initialMemory)
        
        splashViewModel.$shouldNavigate
            .dropFirst()
            .sink { shouldNavigate in
                if shouldNavigate {
                    let finalMemory = MemoryMonitor.getCurrentMemoryUsage()
                    self.performanceCollector.recordMemoryUsage(for: "Final Memory", usage: finalMemory)
                    
                    let memoryIncrease = finalMemory - initialMemory
                    XCTAssertLessThan(memoryIncrease, 10.0, "Memory increase should be less than 10MB during splash")
                    
                    memoryExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        splashViewModel.startInitialization()
        
        // Then
        await fulfillment(of: [memoryExpectation], timeout: 5.0)
    }
    
    // MARK: - Performance Under Load Tests
    
    func testPerformanceUnderConcurrentLoad() async {
        // Test splash performance when system is under load
        
        let concurrentTasks = 10
        let expectations = (0..<concurrentTasks).map { index in
            XCTestExpectation(description: "Concurrent splash \(index)")
        }
        
        let startTime = Date()
        
        // Create concurrent splash screen instances
        for (index, expectation) in expectations.enumerated() {
            Task {
                let viewModel = SplashViewModel(initializationService: MockAppInitializationService())
                
                viewModel.$shouldNavigate
                    .dropFirst()
                    .sink { shouldNavigate in
                        if shouldNavigate {
                            expectation.fulfill()
                        }
                    }
                    .store(in: &cancellables)
                
                viewModel.startInitialization()
            }
        }
        
        // When
        await fulfillment(of: expectations, timeout: 10.0)
        
        // Then
        let totalTime = Date().timeIntervalSince(startTime)
        performanceCollector.recordTiming(for: "Concurrent Load Test", duration: totalTime)
        
        XCTAssertLessThan(totalTime, 6.0, "Concurrent splash screens should complete within 6 seconds")
    }
    
    func testPerformanceWithSlowNetwork() async {
        // Test splash performance with simulated slow network
        
        // Given
        mockInitializationService.delay = 2.0 // Simulate slow network
        
        let expectation = XCTestExpectation(description: "Slow network performance")
        
        splashViewModel.$shouldNavigate
            .dropFirst()
            .sink { shouldNavigate in
                if shouldNavigate {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        let startTime = Date()
        splashViewModel.startInitialization()
        
        // Then
        await fulfillment(of: [expectation], timeout: 8.0)
        
        let duration = Date().timeIntervalSince(startTime)
        performanceCollector.recordTiming(for: "Slow Network Test", duration: duration)
        
        // Should still enforce minimum but handle slow network gracefully
        XCTAssertGreaterThanOrEqual(duration, 2.0, "Should enforce minimum duration even with slow network")
        XCTAssertLessThan(duration, 5.0, "Should not take excessively long even with slow network")
    }
    
    // MARK: - Resource Usage Tests
    
    func testCPUUsageDuringSplash() {
        // Test CPU usage remains reasonable during splash screen
        measure(metrics: [XCTCPUMetric()]) {
            let expectation = XCTestExpectation(description: "CPU measurement")
            
            splashViewModel.$shouldNavigate
                .dropFirst()
                .sink { shouldNavigate in
                    if shouldNavigate {
                        expectation.fulfill()
                    }
                }
                .store(in: &cancellables)
            
            splashViewModel.startInitialization()
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testMemoryUsageDuringSplash() {
        // Test memory usage remains reasonable during splash screen
        measure(metrics: [XCTMemoryMetric()]) {
            let expectation = XCTestExpectation(description: "Memory measurement")
            
            splashViewModel.$shouldNavigate
                .dropFirst()
                .sink { shouldNavigate in
                    if shouldNavigate {
                        expectation.fulfill()
                    }
                }
                .store(in: &cancellables)
            
            splashViewModel.startInitialization()
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Timing Precision Tests
    
    func testTimingPrecision() async {
        // Test that timing is consistent across multiple runs
        
        let numberOfRuns = 5
        var durations: [TimeInterval] = []
        
        for run in 0..<numberOfRuns {
            let expectation = XCTestExpectation(description: "Timing precision run \(run)")
            
            splashViewModel.$shouldNavigate
                .dropFirst()
                .sink { shouldNavigate in
                    if shouldNavigate {
                        expectation.fulfill()
                    }
                }
                .store(in: &cancellables)
            
            // Given - Consistent initialization time
            mockInitializationService.delay = 0.2
            
            // When
            let startTime = Date()
            splashViewModel.startInitialization()
            
            await fulfillment(of: [expectation], timeout: 5.0)
            
            let duration = Date().timeIntervalSince(startTime)
            durations.append(duration)
            
            performanceCollector.recordTiming(for: "Precision Run \(run)", duration: duration)
            
            // Reset for next run
            splashViewModel = SplashViewModel(initializationService: mockInitializationService)
        }
        
        // Then - Verify consistency
        let averageDuration = durations.reduce(0, +) / Double(durations.count)
        let variance = durations.map { pow($0 - averageDuration, 2) }.reduce(0, +) / Double(durations.count)
        let standardDeviation = sqrt(variance)
        
        XCTAssertLessThan(standardDeviation, 0.3, "Timing should be consistent with low variance")
        
        for duration in durations {
            XCTAssertGreaterThanOrEqual(duration, 2.0, "All runs should meet minimum duration")
        }
    }
    
    // MARK: - Edge Case Performance Tests
    
    func testPerformanceWithMultipleRetries() async {
        // Test performance when user triggers multiple retries
        
        // Given - First attempt fails
        mockInitializationService.shouldSucceed = false
        mockInitializationService.delay = 0.1
        
        let retryExpectation = XCTestExpectation(description: "Multiple retries performance")
        retryExpectation.expectedFulfillmentCount = 3 // Test 3 retries
        
        var retryCount = 0
        
        splashViewModel.$showError
            .sink { showError in
                if showError {
                    retryCount += 1
                    if retryCount < 3 {
                        // Retry again
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            self.splashViewModel.retryInitialization()
                        }
                    } else {
                        // Success on third retry
                        self.mockInitializationService.shouldSucceed = true
                        self.splashViewModel.retryInitialization()
                    }
                    retryExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        let startTime = Date()
        splashViewModel.startInitialization()
        
        // Then
        await fulfillment(of: [retryExpectation], timeout: 10.0)
        
        let totalDuration = Date().timeIntervalSince(startTime)
        performanceCollector.recordTiming(for: "Multiple Retries", duration: totalDuration)
        
        XCTAssertLessThan(totalDuration, 8.0, "Multiple retries should not take excessively long")
    }
    
    func testPerformanceWithLowMemoryConditions() async {
        // Simulate low memory conditions and test performance
        
        // Create memory pressure
        var memoryHogs: [Data] = []
        for _ in 0..<50 {
            memoryHogs.append(Data(count: 1024 * 1024)) // 1MB each
        }
        
        let lowMemoryExpectation = XCTestExpectation(description: "Low memory performance")
        
        splashViewModel.$shouldNavigate
            .dropFirst()
            .sink { shouldNavigate in
                if shouldNavigate {
                    lowMemoryExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        let startTime = Date()
        splashViewModel.startInitialization()
        
        // Then
        await fulfillment(of: [lowMemoryExpectation], timeout: 8.0)
        
        let duration = Date().timeIntervalSince(startTime)
        performanceCollector.recordTiming(for: "Low Memory Conditions", duration: duration)
        
        // Clean up memory
        memoryHogs.removeAll()
        
        XCTAssertLessThan(duration, 6.0, "Should perform reasonably even under memory pressure")
    }
    
    // MARK: - Baseline Performance Tests
    
    func testBaselinePerformance() {
        // Establish baseline performance metrics
        measure {
            let expectation = XCTestExpectation(description: "Baseline performance")
            
            splashViewModel.$shouldNavigate
                .dropFirst()
                .sink { shouldNavigate in
                    if shouldNavigate {
                        expectation.fulfill()
                    }
                }
                .store(in: &cancellables)
            
            mockInitializationService.delay = 0.3
            splashViewModel.startInitialization()
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - Battery Usage Tests
    
    func testBatteryEfficiency() async {
        // Test that splash screen doesn't drain battery excessively
        
        // This is a placeholder for battery testing
        // In a real app, you'd use energy impact metrics
        
        let efficiencyExpectation = XCTestExpectation(description: "Battery efficiency")
        
        // Monitor energy usage would go here
        let startTime = Date()
        
        splashViewModel.$shouldNavigate
            .dropFirst()
            .sink { shouldNavigate in
                if shouldNavigate {
                    let duration = Date().timeIntervalSince(startTime)
                    
                    // Verify splash completes quickly to minimize battery drain
                    XCTAssertLessThan(duration, 4.0, "Quick completion minimizes battery usage")
                    
                    efficiencyExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        splashViewModel.startInitialization()
        
        await fulfillment(of: [efficiencyExpectation], timeout: 5.0)
    }
}

// MARK: - Performance Test Helpers
extension SplashPerformanceTests {
    
    private func measureExecutionTime<T>(of operation: () async throws -> T) async rethrows -> (result: T, duration: TimeInterval) {
        let startTime = Date()
        let result = try await operation()
        let duration = Date().timeIntervalSince(startTime)
        return (result, duration)
    }
    
    private func validatePerformanceRequirements(duration: TimeInterval, operation: String) {
        // Validate against Story 0.1 requirements
        XCTAssertGreaterThanOrEqual(duration, 2.0, "\(operation): Should enforce minimum 2 second duration")
        XCTAssertLessThanOrEqual(duration, 3.5, "\(operation): Should complete within reasonable time")
    }
}

// MARK: - Performance Benchmark Results
extension SplashPerformanceTests {
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
        
        // Generate performance summary
        let report = performanceCollector.generateReport()
        print("\n" + "="*50)
        print("SPLASH SCREEN PERFORMANCE SUMMARY")
        print("="*50)
        print(report)
        print("="*50 + "\n")
    }
} 