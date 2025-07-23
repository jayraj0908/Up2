import XCTest
import Combine
@testable import Up2App

// MARK: - Mock App Initialization Service
class MockAppInitializationService: AppInitializationService {
    var shouldSucceed = true
    var shouldTimeout = false
    var mockResult: InitializationResult = .firstLaunch
    var mockError: AppInitializationError = .networkUnavailable
    var delay: TimeInterval = 0.5
    
    override func initialize() async -> Result<InitializationResult, AppInitializationError> {
        // Simulate initialization delay
        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        
        if shouldTimeout {
            return .failure(.timeout)
        }
        
        if shouldSucceed {
            return .success(mockResult)
        } else {
            return .failure(mockError)
        }
    }
}

// MARK: - Splash View Model Tests
@MainActor
final class SplashViewModelTests: XCTestCase {
    
    private var viewModel: SplashViewModel!
    private var mockInitializationService: MockAppInitializationService!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockInitializationService = MockAppInitializationService()
        viewModel = SplashViewModel(initializationService: mockInitializationService)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        viewModel = nil
        mockInitializationService = nil
        super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization_WithDefaultService() {
        // Given
        let viewModel = SplashViewModel()
        
        // Then
        XCTAssertEqual(viewModel.initializationState, .initializing)
        XCTAssertEqual(viewModel.animationState, .preparing)
        XCTAssertFalse(viewModel.showError)
        XCTAssertEqual(viewModel.progress, 0.0)
        XCTAssertFalse(viewModel.shouldNavigate)
        XCTAssertEqual(viewModel.navigationDestination, .authentication)
    }
    
    func testInitialization_WithInjectedService() {
        // Then
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.initializationState, .initializing)
        XCTAssertEqual(viewModel.animationState, .preparing)
    }
    
    // MARK: - Animation State Tests
    
    func testAnimationSequence_StartInitialization() async {
        // Given
        mockInitializationService.delay = 0.1
        
        // When
        viewModel.startInitialization()
        
        // Then - Check initial state immediately
        XCTAssertEqual(viewModel.animationState, .logoFadeIn)
        XCTAssertEqual(viewModel.logoOpacity, 0.0) // Will animate to 1.0
        
        // Wait for animation to progress
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        // Verify animation progresses
        XCTAssertGreaterThan(viewModel.logoOpacity, 0.0)
    }
    
    func testAnimationSequence_LogoScale() async {
        // Given
        let expectation = XCTestExpectation(description: "Logo scale animation")
        var observedScaleValues: [Double] = []
        
        viewModel.$logoScale
            .sink { scale in
                observedScaleValues.append(scale)
                if scale == 1.0 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.startInitialization()
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertTrue(observedScaleValues.contains(0.8)) // Initial value
        XCTAssertTrue(observedScaleValues.contains(1.0)) // Final value
    }
    
    // MARK: - State Management Tests
    
    func testSuccessfulInitialization() async {
        // Given
        mockInitializationService.shouldSucceed = true
        mockInitializationService.mockResult = .returningUser
        mockInitializationService.delay = 0.1
        
        let expectation = XCTestExpectation(description: "Successful initialization")
        
        viewModel.$shouldNavigate
            .dropFirst() // Skip initial false value
            .sink { shouldNavigate in
                if shouldNavigate {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.startInitialization()
        
        // Then
        await fulfillment(of: [expectation], timeout: 3.0)
        XCTAssertTrue(viewModel.shouldNavigate)
        XCTAssertEqual(viewModel.initializationState, .completed)
        XCTAssertEqual(viewModel.navigationDestination, .mainApp)
        XCTAssertFalse(viewModel.showError)
    }
    
    func testFailedInitialization() async {
        // Given
        mockInitializationService.shouldSucceed = false
        mockInitializationService.mockError = .networkUnavailable
        mockInitializationService.delay = 0.1
        
        let expectation = XCTestExpectation(description: "Failed initialization shows error")
        
        viewModel.$showError
            .dropFirst() // Skip initial false value
            .sink { showError in
                if showError {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.startInitialization()
        
        // Then
        await fulfillment(of: [expectation], timeout: 3.0)
        XCTAssertTrue(viewModel.showError)
        XCTAssertEqual(viewModel.initializationState, .error(.networkUnavailable))
        XCTAssertTrue(viewModel.canRetry)
        XCTAssertFalse(viewModel.shouldNavigate)
    }
    
    // MARK: - Error Handling Tests
    
    func testRetryFunctionality() async {
        // Given - First attempt fails
        mockInitializationService.shouldSucceed = false
        mockInitializationService.delay = 0.1
        viewModel.startInitialization()
        
        // Wait for error state
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        XCTAssertTrue(viewModel.showError)
        
        // When - Retry with success
        mockInitializationService.shouldSucceed = true
        mockInitializationService.mockResult = .firstLaunch
        
        let retryExpectation = XCTestExpectation(description: "Retry succeeds")
        
        viewModel.$shouldNavigate
            .dropFirst()
            .sink { shouldNavigate in
                if shouldNavigate {
                    retryExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        viewModel.retryInitialization()
        
        // Then
        await fulfillment(of: [retryExpectation], timeout: 3.0)
        XCTAssertFalse(viewModel.showError)
        XCTAssertTrue(viewModel.shouldNavigate)
        XCTAssertEqual(viewModel.navigationDestination, .authentication)
    }
    
    func testRetryLoading_State() {
        // Given
        viewModel.showError = true
        
        // When
        viewModel.retryInitialization()
        
        // Then
        XCTAssertTrue(viewModel.isRetrying)
        XCTAssertFalse(viewModel.showError)
    }
    
    // MARK: - Navigation Tests
    
    func testNavigationDestination_FirstLaunch() async {
        // Given
        mockInitializationService.mockResult = .firstLaunch
        mockInitializationService.delay = 0.1
        
        let expectation = XCTestExpectation(description: "Navigate to authentication")
        
        viewModel.$navigationDestination
            .dropFirst()
            .sink { destination in
                if destination == .authentication {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.startInitialization()
        
        // Then
        await fulfillment(of: [expectation], timeout: 3.0)
        XCTAssertEqual(viewModel.navigationDestination, .authentication)
    }
    
    func testNavigationDestination_ReturningUser() async {
        // Given
        mockInitializationService.mockResult = .returningUser
        mockInitializationService.delay = 0.1
        
        let expectation = XCTestExpectation(description: "Navigate to main app")
        
        viewModel.$navigationDestination
            .dropFirst()
            .sink { destination in
                if destination == .mainApp {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.startInitialization()
        
        // Then
        await fulfillment(of: [expectation], timeout: 3.0)
        XCTAssertEqual(viewModel.navigationDestination, .mainApp)
    }
    
    // MARK: - Timing Tests
    
    func testMinimumSplashDuration() async {
        // Given
        mockInitializationService.delay = 0.1 // Very fast initialization
        let startTime = Date()
        
        let expectation = XCTestExpectation(description: "Minimum duration enforced")
        
        viewModel.$shouldNavigate
            .dropFirst()
            .sink { shouldNavigate in
                if shouldNavigate {
                    let elapsedTime = Date().timeIntervalSince(startTime)
                    XCTAssertGreaterThanOrEqual(elapsedTime, 2.0, "Should enforce minimum 2 second duration")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.startInitialization()
        
        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
    }
    
    func testTimeout_Handling() async {
        // Given
        mockInitializationService.shouldTimeout = true
        mockInitializationService.delay = 0.1
        
        let expectation = XCTestExpectation(description: "Timeout handled properly")
        
        viewModel.$initializationState
            .sink { state in
                if case .error(.timeout) = state {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.startInitialization()
        
        // Then
        await fulfillment(of: [expectation], timeout: 3.0)
        XCTAssertTrue(viewModel.showError)
        XCTAssertTrue(viewModel.canRetry)
    }
    
    // MARK: - Progress Tests
    
    func testProgressUpdates() async {
        // Given
        mockInitializationService.delay = 1.0 // Longer delay to observe progress
        let expectation = XCTestExpectation(description: "Progress updates observed")
        var progressValues: [Double] = []
        
        viewModel.$progress
            .sink { progress in
                progressValues.append(progress)
                if progress >= 0.5 { // Halfway point
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.startInitialization()
        
        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
        XCTAssertTrue(progressValues.contains(0.0)) // Started at 0
        XCTAssertTrue(progressValues.contains { $0 > 0.0 && $0 < 1.0 }) // Has intermediate values
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryCleanup() {
        // Given
        weak var weakViewModel = viewModel
        
        // When
        viewModel = nil
        
        // Then
        XCTAssertNil(weakViewModel, "ViewModel should be deallocated")
    }
    
    func testCancellablesCleanup() {
        // Given
        let initialCancelablesCount = viewModel.getCancellablesCount()
        
        // When
        viewModel.startInitialization()
        let afterStartCount = viewModel.getCancellablesCount()
        
        // Simulate cleanup
        viewModel.cleanup()
        let afterCleanupCount = viewModel.getCancellablesCount()
        
        // Then
        XCTAssertGreaterThan(afterStartCount, initialCancelablesCount)
        XCTAssertEqual(afterCleanupCount, 0)
    }
    
    // MARK: - Edge Cases
    
    func testMultipleStartCalls() {
        // Given
        XCTAssertEqual(viewModel.animationState, .preparing)
        
        // When
        viewModel.startInitialization()
        viewModel.startInitialization() // Second call
        
        // Then - Should handle gracefully without crashing
        XCTAssertEqual(viewModel.animationState, .logoFadeIn)
    }
    
    func testSkipSplash_DebugMode() async {
        // Given
        let expectation = XCTestExpectation(description: "Skip splash immediately")
        
        viewModel.$shouldNavigate
            .dropFirst()
            .sink { shouldNavigate in
                if shouldNavigate {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        viewModel.skipSplash()
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(viewModel.shouldNavigate)
        XCTAssertEqual(viewModel.navigationDestination, .authentication) // Default destination
    }
}

// MARK: - Test Helper Extensions
extension SplashViewModel {
    func getCancellablesCount() -> Int {
        // This would need to be exposed in the actual implementation for testing
        // For now, we'll assume a method exists to check cancellables count
        return 0 // Placeholder
    }
    
    func cleanup() {
        // This would need to be exposed in the actual implementation for testing
        // Method to clean up cancellables and timers
    }
}

// MARK: - Animation State Tests
extension SplashViewModelTests {
    
    func testAnimationStateTransitions() async {
        // Given
        let expectedStates: [SplashAnimationState] = [
            .preparing,
            .logoFadeIn,
            .logoScale,
            .brandingAppear,
            .loadingStart,
            .complete
        ]
        
        var observedStates: [SplashAnimationState] = []
        let expectation = XCTestExpectation(description: "All animation states observed")
        expectation.expectedFulfillmentCount = expectedStates.count
        
        viewModel.$animationState
            .sink { state in
                observedStates.append(state)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // When
        mockInitializationService.delay = 0.5
        viewModel.startInitialization()
        
        // Then
        await fulfillment(of: [expectation], timeout: 3.0)
        
        // Verify state progression (order matters for animations)
        for expectedState in expectedStates {
            XCTAssertTrue(observedStates.contains(expectedState), "Missing animation state: \(expectedState)")
        }
    }
} 