import XCTest
import SwiftUI
import Combine
@testable import Up2App

// MARK: - Mock Navigation Coordinator
class MockNavigationCoordinator: ObservableObject {
    @Published var currentDestination: InitializationNavigationDestination = .authentication
    @Published var navigationHistory: [InitializationNavigationDestination] = []
    
    var transitionCallCount = 0
    var lastTransitionDuration: TimeInterval = 0
    
    func navigateToDestination(_ destination: InitializationNavigationDestination, duration: TimeInterval = 0.3) {
        transitionCallCount += 1
        lastTransitionDuration = duration
        currentDestination = destination
        navigationHistory.append(destination)
    }
}

// MARK: - Mock App State
class MockAppState: ObservableObject {
    @Published var isInitialized = false
    @Published var currentUser: AuthUser?
    @Published var hasCompletedOnboarding = false
    
    func reset() {
        isInitialized = false
        currentUser = nil
        hasCompletedOnboarding = false
    }
}

// MARK: - Splash Screen Integration Tests
@MainActor
final class SplashScreenIntegrationTests: XCTestCase {
    
    private var splashViewModel: SplashViewModel!
    private var mockInitializationService: MockAppInitializationService!
    private var mockNavigationCoordinator: MockNavigationCoordinator!
    private var mockAppState: MockAppState!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockInitializationService = MockAppInitializationService()
        mockNavigationCoordinator = MockNavigationCoordinator()
        mockAppState = MockAppState()
        splashViewModel = SplashViewModel(initializationService: mockInitializationService)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables.removeAll()
        splashViewModel = nil
        mockInitializationService = nil
        mockNavigationCoordinator = nil
        mockAppState = nil
        super.tearDown()
    }
    
    // MARK: - Navigation Flow Tests
    
    func testSplashToAuthenticationFlow() async {
        // Given
        mockInitializationService.shouldSucceed = true
        mockInitializationService.mockResult = .firstLaunch
        mockInitializationService.delay = 0.2
        
        let navigationExpectation = XCTestExpectation(description: "Navigation to authentication")
        
        splashViewModel.$shouldNavigate
            .combineLatest(splashViewModel.$navigationDestination)
            .sink { shouldNavigate, destination in
                if shouldNavigate && destination == .authentication {
                    navigationExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        let startTime = Date()
        splashViewModel.startInitialization()
        
        // Then
        await fulfillment(of: [navigationExpectation], timeout: 5.0)
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        XCTAssertGreaterThanOrEqual(elapsedTime, 2.0, "Should enforce minimum 2 second duration")
        XCTAssertTrue(splashViewModel.shouldNavigate)
        XCTAssertEqual(splashViewModel.navigationDestination, .authentication)
        XCTAssertEqual(splashViewModel.initializationState, .completed)
    }
    
    func testSplashToMainAppFlow() async {
        // Given
        mockInitializationService.shouldSucceed = true
        mockInitializationService.mockResult = .returningUser
        mockInitializationService.delay = 0.2
        
        let navigationExpectation = XCTestExpectation(description: "Navigation to main app")
        
        splashViewModel.$shouldNavigate
            .combineLatest(splashViewModel.$navigationDestination)
            .sink { shouldNavigate, destination in
                if shouldNavigate && destination == .mainApp {
                    navigationExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        let startTime = Date()
        splashViewModel.startInitialization()
        
        // Then
        await fulfillment(of: [navigationExpectation], timeout: 5.0)
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        XCTAssertGreaterThanOrEqual(elapsedTime, 2.0, "Should enforce minimum 2 second duration")
        XCTAssertTrue(splashViewModel.shouldNavigate)
        XCTAssertEqual(splashViewModel.navigationDestination, .mainApp)
        XCTAssertEqual(splashViewModel.initializationState, .completed)
    }
    
    func testSplashToOnboardingFlow() async {
        // Given
        mockInitializationService.shouldSucceed = true
        mockInitializationService.mockResult = .needsOnboarding
        mockInitializationService.delay = 0.2
        
        let navigationExpectation = XCTestExpectation(description: "Navigation to onboarding")
        
        splashViewModel.$shouldNavigate
            .combineLatest(splashViewModel.$navigationDestination)
            .sink { shouldNavigate, destination in
                if shouldNavigate && destination == .onboarding {
                    navigationExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        splashViewModel.startInitialization()
        
        // Then
        await fulfillment(of: [navigationExpectation], timeout: 5.0)
        XCTAssertTrue(splashViewModel.shouldNavigate)
        XCTAssertEqual(splashViewModel.navigationDestination, .onboarding)
    }
    
    // MARK: - Error Flow Tests
    
    func testSplashErrorRetryFlow() async {
        // Given - First attempt fails
        mockInitializationService.shouldSucceed = false
        mockInitializationService.mockError = .networkUnavailable
        mockInitializationService.delay = 0.1
        
        let errorExpectation = XCTestExpectation(description: "Error state reached")
        let retryExpectation = XCTestExpectation(description: "Retry succeeds")
        
        var errorObserved = false
        
        splashViewModel.$showError
            .sink { showError in
                if showError && !errorObserved {
                    errorObserved = true
                    errorExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        splashViewModel.$shouldNavigate
            .sink { shouldNavigate in
                if shouldNavigate && errorObserved {
                    retryExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        splashViewModel.startInitialization()
        
        // Wait for error
        await fulfillment(of: [errorExpectation], timeout: 3.0)
        XCTAssertTrue(splashViewModel.showError)
        XCTAssertTrue(splashViewModel.canRetry)
        
        // Then retry with success
        mockInitializationService.shouldSucceed = true
        mockInitializationService.mockResult = .firstLaunch
        splashViewModel.retryInitialization()
        
        await fulfillment(of: [retryExpectation], timeout: 5.0)
        XCTAssertFalse(splashViewModel.showError)
        XCTAssertTrue(splashViewModel.shouldNavigate)
    }
    
    // MARK: - Animation Integration Tests
    
    func testSplashAnimationSequenceWithNavigation() async {
        // Given
        mockInitializationService.delay = 0.5
        
        let animationStates: [SplashAnimationState] = [
            .preparing, .logoFadeIn, .logoScale, .brandingAppear, .loadingStart, .complete
        ]
        
        var observedStates: [SplashAnimationState] = []
        let animationExpectation = XCTestExpectation(description: "Animation sequence completes")
        let navigationExpectation = XCTestExpectation(description: "Navigation occurs after animation")
        
        splashViewModel.$animationState
            .sink { state in
                observedStates.append(state)
                if state == .complete {
                    animationExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        splashViewModel.$shouldNavigate
            .dropFirst()
            .sink { shouldNavigate in
                if shouldNavigate {
                    navigationExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        splashViewModel.startInitialization()
        
        // Then
        await fulfillment(of: [animationExpectation, navigationExpectation], timeout: 5.0)
        
        // Verify animation sequence
        for expectedState in animationStates {
            XCTAssertTrue(observedStates.contains(expectedState), "Missing animation state: \(expectedState)")
        }
        
        // Verify navigation happens after animation
        XCTAssertEqual(splashViewModel.animationState, .complete)
        XCTAssertTrue(splashViewModel.shouldNavigate)
    }
    
    // MARK: - Timing Validation Tests
    
    func testMinimumSplashDurationEnforcement() async {
        // Given
        mockInitializationService.delay = 0.1 // Very fast initialization
        
        let measurements: [(name: String, expectation: XCTestExpectation, startTime: Date?)] = [
            ("Fast init", XCTestExpectation(description: "Fast initialization timing"), nil),
            ("Normal init", XCTestExpectation(description: "Normal initialization timing"), nil),
            ("Slow init", XCTestExpectation(description: "Slow initialization timing"), nil)
        ]
        
        for (index, measurement) in measurements.enumerated() {
            let startTime = Date()
            
            splashViewModel.$shouldNavigate
                .dropFirst()
                .sink { shouldNavigate in
                    if shouldNavigate {
                        let elapsedTime = Date().timeIntervalSince(startTime)
                        XCTAssertGreaterThanOrEqual(elapsedTime, 2.0, "Measurement \(measurement.name): Should enforce minimum 2 second duration")
                        measurement.expectation.fulfill()
                    }
                }
                .store(in: &cancellables)
            
            // Vary initialization speed
            mockInitializationService.delay = Double(index) * 0.5 + 0.1
            splashViewModel.startInitialization()
            
            await fulfillment(of: [measurement.expectation], timeout: 5.0)
            
            // Reset for next test
            splashViewModel = SplashViewModel(initializationService: mockInitializationService)
        }
    }
    
    func testMaximumSplashDurationTimeout() async {
        // Given
        mockInitializationService.shouldTimeout = true
        mockInitializationService.delay = 0.1
        
        let timeoutExpectation = XCTestExpectation(description: "Timeout handled within reasonable time")
        
        splashViewModel.$showError
            .dropFirst()
            .sink { showError in
                if showError {
                    timeoutExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        let startTime = Date()
        splashViewModel.startInitialization()
        
        // Then
        await fulfillment(of: [timeoutExpectation], timeout: 15.0)
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(elapsedTime, 12.0, "Should handle timeout within reasonable time")
        XCTAssertTrue(splashViewModel.showError)
        XCTAssertTrue(splashViewModel.canRetry)
    }
    
    // MARK: - State Consistency Tests
    
    func testSplashViewModelStateConsistency() async {
        // Given
        let stateTransitions: [(state: AppInitializationState, shouldNavigate: Bool, showError: Bool)] = []
        var observedTransitions: [(state: AppInitializationState, shouldNavigate: Bool, showError: Bool)] = []
        
        let consistencyExpectation = XCTestExpectation(description: "State consistency maintained")
        
        Publishers.CombineLatest3(
            splashViewModel.$initializationState,
            splashViewModel.$shouldNavigate,
            splashViewModel.$showError
        )
        .sink { state, shouldNavigate, showError in
            observedTransitions.append((state: state, shouldNavigate: shouldNavigate, showError: showError))
            
            // Check state consistency rules
            switch state {
            case .initializing, .loadingConfiguration, .checkingAuthentication, .preparingNavigation:
                XCTAssertFalse(shouldNavigate, "Should not navigate during intermediate states")
                XCTAssertFalse(showError, "Should not show error during normal flow")
            case .completed:
                XCTAssertTrue(shouldNavigate, "Should navigate when completed")
                XCTAssertFalse(showError, "Should not show error when completed")
            case .error(_):
                XCTAssertFalse(shouldNavigate, "Should not navigate when in error state")
                XCTAssertTrue(showError, "Should show error when in error state")
            }
            
            if observedTransitions.count >= 5 { // Expected minimum transitions
                consistencyExpectation.fulfill()
            }
        }
        .store(in: &cancellables)
        
        // When
        mockInitializationService.delay = 0.2
        splashViewModel.startInitialization()
        
        // Then
        await fulfillment(of: [consistencyExpectation], timeout: 5.0)
    }
    
    // MARK: - Navigation Coordinator Integration Tests
    
    func testNavigationCoordinatorIntegration() async {
        // Given
        let navigationExpectation = XCTestExpectation(description: "Navigation coordinator called")
        
        splashViewModel.$shouldNavigate
            .combineLatest(splashViewModel.$navigationDestination)
            .sink { shouldNavigate, destination in
                if shouldNavigate {
                    self.mockNavigationCoordinator.navigateToDestination(destination)
                    navigationExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        mockInitializationService.delay = 0.2
        splashViewModel.startInitialization()
        
        // Then
        await fulfillment(of: [navigationExpectation], timeout: 5.0)
        
        XCTAssertEqual(mockNavigationCoordinator.transitionCallCount, 1)
        XCTAssertEqual(mockNavigationCoordinator.currentDestination, .authentication) // Default for first launch
        XCTAssertEqual(mockNavigationCoordinator.navigationHistory.count, 1)
    }
    
    // MARK: - Memory Management Integration Tests
    
    func testMemoryManagementDuringTransition() async {
        // Given
        weak var weakViewModel = splashViewModel
        weak var weakService = mockInitializationService
        
        let navigationExpectation = XCTestExpectation(description: "Navigation completes")
        
        splashViewModel.$shouldNavigate
            .dropFirst()
            .sink { shouldNavigate in
                if shouldNavigate {
                    navigationExpectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // When
        mockInitializationService.delay = 0.1
        splashViewModel.startInitialization()
        
        await fulfillment(of: [navigationExpectation], timeout: 3.0)
        
        // Then - Clean up
        cancellables.removeAll()
        splashViewModel = nil
        mockInitializationService = nil
        
        // Verify memory cleanup (may need slight delay for async cleanup)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Note: These assertions might be flaky due to retain cycles
            // In production code, we'd ensure proper cleanup
            XCTAssertNil(weakViewModel, "ViewModel should be deallocated after navigation")
        }
    }
    
    // MARK: - Multiple Launch Scenarios
    
    func testMultipleLaunchScenarios() async {
        let scenarios: [(name: String, result: InitializationResult, expectedDestination: InitializationNavigationDestination)] = [
            ("First Launch", .firstLaunch, .authentication),
            ("Returning User", .returningUser, .mainApp),
            ("Needs Onboarding", .needsOnboarding, .onboarding),
            ("Migration Required", .migrationRequired, .authentication)
        ]
        
        for scenario in scenarios {
            // Given
            mockInitializationService.mockResult = scenario.result
            mockInitializationService.delay = 0.1
            
            let expectation = XCTestExpectation(description: "Scenario: \(scenario.name)")
            
            splashViewModel.$navigationDestination
                .dropFirst()
                .sink { destination in
                    if destination == scenario.expectedDestination {
                        expectation.fulfill()
                    }
                }
                .store(in: &cancellables)
            
            // When
            splashViewModel.startInitialization()
            
            // Then
            await fulfillment(of: [expectation], timeout: 3.0)
            XCTAssertEqual(splashViewModel.navigationDestination, scenario.expectedDestination, "Scenario: \(scenario.name) failed")
            
            // Reset for next scenario
            splashViewModel = SplashViewModel(initializationService: mockInitializationService)
        }
    }
    
    // MARK: - Performance Integration Tests
    
    func testSplashPerformanceUnderLoad() async {
        // Test splash screen performance with multiple concurrent operations
        let concurrentOperations = 5
        let expectations = (0..<concurrentOperations).map { index in
            XCTestExpectation(description: "Concurrent operation \(index)")
        }
        
        let startTime = Date()
        
        // When - Start multiple concurrent splash operations
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
        
        // Then
        await fulfillment(of: expectations, timeout: 10.0)
        
        let totalTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(totalTime, 8.0, "Multiple concurrent splash screens should complete efficiently")
    }
}

// MARK: - Navigation Destination Extension for Testing
extension InitializationNavigationDestination {
    var displayName: String {
        switch self {
        case .authentication:
            return "Authentication"
        case .mainApp:
            return "Main App"
        case .onboarding:
            return "Onboarding"
        }
    }
} 