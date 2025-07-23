import Foundation
import SwiftUI
import Combine

// MARK: - Splash View Model
@MainActor
final class SplashViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var initializationState: AppInitializationState = .initializing
    @Published var animationState: SplashAnimationState = .preparing
    @Published var showError: Bool = false
    @Published var errorMessage: String = ""
    @Published var canRetry: Bool = false
    @Published var isRetrying: Bool = false
    @Published var progress: Double = 0.0
    @Published var shouldNavigate: Bool = false
    @Published var navigationDestination: InitializationNavigationDestination = .authentication
    
    // MARK: - Animation Properties
    @Published var logoOpacity: Double = 0.0
    @Published var logoScale: Double = 0.8
    @Published var brandingOpacity: Double = 0.0
    @Published var loadingOpacity: Double = 0.0
    @Published var backgroundGradientOpacity: Double = 0.0
    
    // MARK: - Dependencies
    private let initializationService: AppInitializationService
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Animation Timers
    private var animationTimer: Timer?
    private var progressTimer: Timer?
    
    // MARK: - Constants
    private let minimumSplashDuration: TimeInterval = 2.0
    private let maximumSplashDuration: TimeInterval = 8.0
    private let animationStepDuration: TimeInterval = 0.3
    
    // MARK: - Initialization
    init(initializationService: AppInitializationService? = nil) {
        self.initializationService = initializationService ?? AppInitializationService(
            authService: SupabaseAuthService.shared,
            appStateManager: AppStateManager()
        )
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    /// Start the splash screen initialization process
    func startInitialization() {
        resetState()
        startAnimations()
        performInitialization()
    }
    
    /// Retry initialization after an error
    func retryInitialization() {
        guard !isRetrying else { return }
        
        isRetrying = true
        showError = false
        errorMessage = ""
        canRetry = false
        
        Task {
            await performRetryInitialization()
        }
    }
    
    /// Skip splash screen (for debug purposes)
    func skipSplash() {
        navigationDestination = .authentication
        shouldNavigate = true
    }
    
    // MARK: - Private Methods
    
    private func setupObservers() {
        // Observe initialization service state changes
        initializationService.$currentState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.handleInitializationStateChange(state)
            }
            .store(in: &cancellables)
    }
    
    private func resetState() {
        initializationState = .initializing
        animationState = .preparing
        showError = false
        errorMessage = ""
        canRetry = false
        isRetrying = false
        progress = 0.0
        shouldNavigate = false
        
        // Reset animation properties
        logoOpacity = 0.0
        logoScale = 0.8
        brandingOpacity = 0.0
        loadingOpacity = 0.0
        backgroundGradientOpacity = 0.0
    }
    
    private func startAnimations() {
        backgroundGradientOpacity = 1.0
        
        // Start the animation sequence
        animateSequence()
    }
    
    private func animateSequence() {
        var currentStep = 0
        let animationSteps: [SplashAnimationState] = [
            .preparing,
            .logoFadeIn,
            .logoScale,
            .brandingAppear,
            .loadingStart
        ]
        
        animationTimer = Timer.scheduledTimer(withTimeInterval: animationStepDuration, repeats: true) { [weak self] timer in
            guard let self = self, currentStep < animationSteps.count else {
                timer.invalidate()
                return
            }
            
            let step = animationSteps[currentStep]
            Task { @MainActor in
                self.performAnimationStep(step)
            }
            currentStep += 1
            
            if currentStep >= animationSteps.count {
                timer.invalidate()
                Task { @MainActor in
                    self.animationState = .completed
                }
            }
        }
    }
    
    private func performAnimationStep(_ step: SplashAnimationState) {
        withAnimation(.easeInOut(duration: step.duration)) {
            animationState = step
            
            switch step {
            case .preparing:
                break
            case .logoFadeIn:
                logoOpacity = 1.0
            case .logoScale:
                logoScale = 1.0
            case .brandingAppear:
                brandingOpacity = 1.0
            case .loadingStart:
                loadingOpacity = 1.0
            case .completed:
                break
            }
        }
    }
    
    private func performInitialization() {
        Task {
            let startTime = Date()
            
            let result = await initializationService.initializeWithTimeout()
            
            // Ensure minimum splash duration
            let elapsedTime = Date().timeIntervalSince(startTime)
            let remainingTime = max(0, minimumSplashDuration - elapsedTime)
            
            if remainingTime > 0 {
                try? await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
            }
            
            await MainActor.run {
                handleInitializationResult(result)
            }
        }
    }
    
    private func performRetryInitialization() async {
        let result = await initializationService.retryInitialization()
        await MainActor.run {
            handleInitializationResult(result)
        }
        isRetrying = false
    }
    
    private func handleInitializationResult(_ result: Result<InitializationResult, AppInitializationError>) {
        switch result {
        case .success(let initResult):
            handleSuccessfulInitialization(initResult)
        case .failure(let error):
            handleInitializationError(error)
        }
    }
    
    private func handleSuccessfulInitialization(_ result: InitializationResult) {
        navigationDestination = result.navigationDestination
        
        withAnimation(.easeInOut(duration: 0.5)) {
            progress = 1.0
        }
        
        // Delay navigation to allow animation to complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.shouldNavigate = true
        }
    }
    
    private func handleInitializationError(_ error: AppInitializationError) {
        errorMessage = error.userMessage
        canRetry = error.isRetryable
        showError = true
        
        withAnimation(.easeInOut(duration: 0.3)) {
            loadingOpacity = 0.0
        }
    }
    
    private func handleInitializationStateChange(_ state: AppInitializationState) {
        initializationState = state
        
        withAnimation(.easeInOut(duration: 0.3)) {
            progress = state.progress
        }
        
        // Update loading opacity based on state
        if state.isLoading && loadingOpacity < 1.0 {
            withAnimation(.easeInOut(duration: 0.3)) {
                loadingOpacity = 1.0
            }
        }
    }
    
    // MARK: - Progress Animation
    private func startProgressAnimation() {
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self, self.initializationState.isLoading else {
                    timer.invalidate()
                    return
                }
                
                // Smooth progress animation
                let targetProgress = self.initializationState.progress
                if self.progress < targetProgress {
                    withAnimation(.linear(duration: 0.1)) {
                        self.progress = min(self.progress + 0.05, targetProgress)
                    }
                }
            }
        }
    }
    
    private func stopProgressAnimation() {
        progressTimer?.invalidate()
        progressTimer = nil
    }
    
    // MARK: - Cleanup
    deinit {
        animationTimer?.invalidate()
        progressTimer?.invalidate()
        cancellables.removeAll()
    }
}

// MARK: - View Model Extensions

extension SplashViewModel {
    
    // MARK: - Computed Properties
    var isInitializing: Bool {
        initializationState.isLoading
    }
    
    var statusMessage: String {
        if showError {
            return errorMessage
        } else {
            return initializationState.displayMessage
        }
    }
    
    var showLoadingIndicator: Bool {
        isInitializing && !showError && loadingOpacity > 0.0
    }
    
    var showRetryButton: Bool {
        showError && canRetry && !isRetrying
    }
    
    // MARK: - Animation Helpers
    func logoTransform() -> CGAffineTransform {
        return CGAffineTransform(scaleX: logoScale, y: logoScale)
    }
    
    func shouldShowElement(_ element: SplashElement) -> Bool {
        switch element {
        case .logo:
            return logoOpacity > 0.0
        case .branding:
            return brandingOpacity > 0.0
        case .loading:
            return loadingOpacity > 0.0 && !showError
        case .error:
            return showError
        }
    }
    
    func getElementOpacity(_ element: SplashElement) -> Double {
        switch element {
        case .logo:
            return logoOpacity
        case .branding:
            return brandingOpacity
        case .loading:
            return loadingOpacity
        case .error:
            return showError ? 1.0 : 0.0
        }
    }
    
    // MARK: - Debug Methods
    func getDebugInfo() -> [String: Any] {
        return [
            "initializationState": String(describing: initializationState),
            "animationState": String(describing: animationState),
            "progress": progress,
            "logoOpacity": logoOpacity,
            "logoScale": logoScale,
            "brandingOpacity": brandingOpacity,
            "loadingOpacity": loadingOpacity,
            "showError": showError,
            "canRetry": canRetry,
            "isRetrying": isRetrying,
            "shouldNavigate": shouldNavigate,
            "navigationDestination": String(describing: navigationDestination)
        ]
    }
}

// MARK: - Supporting Enums

enum SplashElement: CaseIterable {
    case logo
    case branding
    case loading
    case error
    
    var description: String {
        switch self {
        case .logo:
            return "Logo"
        case .branding:
            return "Branding"
        case .loading:
            return "Loading"
        case .error:
            return "Error"
        }
    }
} 