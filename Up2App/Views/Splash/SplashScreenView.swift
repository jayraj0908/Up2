import SwiftUI

// MARK: - Splash Screen View
struct SplashScreenView: View {
    
    // MARK: - View Model
    @StateObject private var viewModel = SplashViewModel()
    
    // MARK: - Navigation
    @Binding var shouldShowSplash: Bool
    let onNavigationComplete: (InitializationNavigationDestination) -> Void
    
    // MARK: - Animation Properties
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var shimmerOffset: CGFloat = -1.0
    @State private var pulseAnimation = false
    @State private var showEnterButton = false
    
    // U-Shape Drawing Animation Properties
    @State private var drawingProgress: CGFloat = 0.0
    @State private var showLogoImage = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background Gradient
            backgroundView
            
            // Main Content
            VStack(spacing: Up2Spacing.xl) {
                Spacer()
                
                // Logo Section
                logoSection
                
                // Branding Section
                brandingSection
                
                Spacer()
                
                // Loading Section
                loadingSection
                
                // Error Section
                if viewModel.showError {
                    errorSection
                }
                
                // Enter App Button (Fallback)
                if showEnterButton {
                    enterAppButton
                }
                
                Spacer(minLength: Up2Spacing.xxl)
            }
            .padding(.horizontal, Up2Spacing.lg)
            .padding(.vertical, Up2Spacing.xl)
        }
        .ignoresSafeArea()
        .onAppear {
            startInitialization()
            startLogoAnimation()
            startAutoNavigation()
        }
        .onChange(of: viewModel.shouldNavigate) { shouldNavigate in
            if shouldNavigate {
                handleNavigation()
            }
        }
    }
    
    // MARK: - Background View
    private var backgroundView: some View {
        ZStack {
            // Base gradient - vibrant dark gradient (indigo → magenta)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.0, blue: 0.3), // Deep indigo
                    Color(red: 0.3, green: 0.0, blue: 0.4), // Purple
                    Color(red: 0.5, green: 0.0, blue: 0.3), // Magenta
                    Color(red: 0.2, green: 0.0, blue: 0.2)  // Deep violet
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Animated overlay gradient with shimmer
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.white.opacity(0.1),
                    Color.clear
                ]),
                center: .center,
                startRadius: 100,
                endRadius: 500
            )
            .opacity(viewModel.backgroundGradientOpacity)
            .scaleEffect(pulseAnimation ? 1.2 : 1.0)
            .animation(
                .easeInOut(duration: 3.0).repeatForever(autoreverses: true),
                value: pulseAnimation
            )
            .onAppear {
                pulseAnimation = true
            }
            
            // Shimmer effect overlay
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.clear,
                            Color.white.opacity(0.1),
                            Color.clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .offset(x: shimmerOffset * UIScreen.main.bounds.width)
                .animation(
                    .linear(duration: 2.0).repeatForever(autoreverses: false),
                    value: shimmerOffset
                )
                .onAppear {
                    shimmerOffset = 1.0
                }
        }
    }
    
    // MARK: - Logo Section
    private var logoSection: some View {
        VStack(spacing: Up2Spacing.md) {
            // Main Logo with actual image
            logoImage
                .opacity(logoOpacity)
                .scaleEffect(logoScale)
                .animation(.easeOut(duration: 1.5), value: logoScale)
                .animation(.easeIn(duration: 1.0), value: logoOpacity)
            
            // Logo Badge (Optional enhancement)
            if viewModel.shouldShowElement(.logo) {
                logoBadge
                    .opacity(viewModel.logoOpacity)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Logo Image
    private var logoImage: some View {
        ZStack {
            // Background circle with glow
            Circle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Up2Colors.primary,
                            Up2Colors.accent
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 140, height: 140)
                .shadow(
                    color: Up2Colors.primary.opacity(0.5),
                    radius: 30,
                    x: 0,
                    y: 15
                )
            
            // Animated U-Shape Drawing
            animatedUShape
                .opacity(showLogoImage ? 0.0 : 1.0)
                .animation(.easeInOut(duration: 0.5), value: showLogoImage)
            
            // Actual logo image (appears after drawing animation)
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .shadow(
                    color: Color.black.opacity(0.3),
                    radius: 5,
                    x: 0,
                    y: 2
                )
                .opacity(showLogoImage ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.5), value: showLogoImage)
            
            // Shimmer effect on logo
            if viewModel.isInitializing && showLogoImage {
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.white.opacity(0.4),
                                Color.clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .clipShape(Circle())
                    .offset(x: shimmerOffset * 280)
                    .animation(
                        .linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: shimmerOffset
                    )
            }
        }
    }
    
    // MARK: - Animated U-Shape Drawing
    private var animatedUShape: some View {
        ZStack {
            // U-Shape path with drawing animation
            Path { path in
                let width: CGFloat = 80
                let height: CGFloat = 80
                let centerX: CGFloat = 0
                let centerY: CGFloat = 0
                
                // Start from top-right of U
                let startX = centerX + width/2
                let startY = centerY - height/2
                
                // Calculate drawing progress
                let totalLength = width + height + width // Right side + bottom + left side
                let currentLength = totalLength * drawingProgress
                
                if currentLength <= width {
                    // Drawing right side (top to bottom)
                    let progress = currentLength / width
                    let endY = startY + (height * progress)
                    path.move(to: CGPoint(x: startX, y: startY))
                    path.addLine(to: CGPoint(x: startX, y: endY))
                } else if currentLength <= width + height {
                    // Drawing bottom curve
                    let progress = (currentLength - width) / height
                    let endX = startX - (width * progress)
                    path.move(to: CGPoint(x: startX, y: startY))
                    path.addLine(to: CGPoint(x: startX, y: startY + height))
                    path.addLine(to: CGPoint(x: endX, y: startY + height))
                } else {
                    // Drawing left side (bottom to top)
                    let progress = (currentLength - width - height) / width
                    let endY = startY + height - (height * progress)
                    path.move(to: CGPoint(x: startX, y: startY))
                    path.addLine(to: CGPoint(x: startX, y: startY + height))
                    path.addLine(to: CGPoint(x: startX - width, y: startY + height))
                    path.addLine(to: CGPoint(x: startX - width, y: endY))
                }
            }
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Up2Colors.primary,
                        Up2Colors.accent
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                style: StrokeStyle(lineWidth: 8, lineCap: .round, lineJoin: .round)
            )
            .shadow(
                color: Up2Colors.primary.opacity(0.6),
                radius: 10,
                x: 0,
                y: 5
            )
            
            // Arrow pointing up from the right side of U
            if drawingProgress > 0.8 {
                Path { path in
                    let arrowStartX: CGFloat = 40
                    let arrowStartY: CGFloat = -20
                    let arrowLength: CGFloat = 20
                    
                    path.move(to: CGPoint(x: arrowStartX, y: arrowStartY))
                    path.addLine(to: CGPoint(x: arrowStartX, y: arrowStartY - arrowLength))
                    path.move(to: CGPoint(x: arrowStartX - 5, y: arrowStartY - arrowLength + 5))
                    path.addLine(to: CGPoint(x: arrowStartX, y: arrowStartY - arrowLength))
                    path.addLine(to: CGPoint(x: arrowStartX + 5, y: arrowStartY - arrowLength + 5))
                }
                .stroke(
                    Up2Colors.accent,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                )
                .opacity((drawingProgress - 0.8) / 0.2)
                .animation(.easeInOut(duration: 0.3), value: drawingProgress)
            }
        }
    }
    
    // MARK: - Logo Badge
    private var logoBadge: some View {
        HStack(spacing: Up2Spacing.xs) {
            Circle()
                .fill(Up2Colors.success)
                .frame(width: 8, height: 8)
                .opacity(viewModel.isInitializing ? 0.5 : 1.0)
                .animation(
                    .easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                    value: viewModel.isInitializing
                )
            
            Text("NIGHTLIFE")
                .font(Up2Typography.caption.weight(.bold))
                .foregroundColor(Up2Colors.textOnPrimary)
        }
        .padding(.horizontal, Up2Spacing.sm)
        .padding(.vertical, Up2Spacing.xs)
        .background(
            Capsule()
                .fill(Up2Colors.surfaceElevated)
                .stroke(Up2Colors.border, lineWidth: 1)
        )
    }
    
    // MARK: - Branding Section
    private var brandingSection: some View {
        VStack(spacing: Up2Spacing.sm) {
            // App Name
            Text("Up2")
                .font(Up2Typography.heading1.weight(.bold))
                .foregroundColor(Up2Colors.textOnPrimary)
                .opacity(viewModel.brandingOpacity)
            
            // Tagline
            Text("Where the night begins")
                .font(Up2Typography.body)
                .foregroundColor(Up2Colors.textOnPrimary.opacity(0.8))
                .opacity(viewModel.brandingOpacity)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Loading Section
    private var loadingSection: some View {
        VStack(spacing: Up2Spacing.lg) {
            if viewModel.showLoadingIndicator {
                // Progress Bar
                VStack(spacing: Up2Spacing.sm) {
                    // Status Message
                    Text(viewModel.statusMessage)
                        .font(Up2Typography.body)
                        .foregroundColor(Up2Colors.textOnPrimary.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .opacity(viewModel.loadingOpacity)
                    
                    // Progress Indicator
                    progressIndicator
                        .opacity(viewModel.loadingOpacity)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Progress Indicator
    private var progressIndicator: some View {
        VStack(spacing: Up2Spacing.sm) {
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: Up2Spacing.cornerRadiusLarge)
                        .fill(Up2Colors.surfaceElevated.opacity(0.3))
                        .frame(height: 4)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: Up2Spacing.cornerRadiusLarge)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Up2Colors.primary,
                                    Up2Colors.accent
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * viewModel.progress, height: 4)
                        .animation(.easeInOut(duration: 0.3), value: viewModel.progress)
                }
            }
            .frame(height: 4)
            
            // Loading Dots (Alternative indicator)
            if viewModel.progress < 0.1 {
                HStack(spacing: Up2Spacing.xs) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Up2Colors.primary)
                            .frame(width: 8, height: 8)
                            .scaleEffect(pulseAnimation && index % 2 == 0 ? 1.2 : 0.8)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                                value: pulseAnimation
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Error Section
    private var errorSection: some View {
        VStack(spacing: Up2Spacing.lg) {
            // Error Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title)
                .foregroundColor(Up2Colors.warning)
            
            // Error Message
            Text(viewModel.errorMessage)
                .font(Up2Typography.body)
                .foregroundColor(Up2Colors.textOnPrimary.opacity(0.8))
                .multilineTextAlignment(.center)
            
            // Retry Button
            if viewModel.showRetryButton {
                Up2Button(
                    "Try Again",
                    style: .secondary,
                    size: .medium,
                    isLoading: viewModel.isRetrying
                ) {
                    viewModel.retryInitialization()
                }
                .padding(.horizontal, Up2Spacing.xl)
            }
            
            // Debug Skip Button (Debug only)
            #if DEBUG
            Up2Button(
                "Skip Splash",
                style: .tertiary,
                size: .small
            ) {
                viewModel.skipSplash()
            }
            .padding(.top, Up2Spacing.sm)
            #endif
        }
        .padding(.horizontal, Up2Spacing.lg)
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Enter App Button
    private var enterAppButton: some View {
        Up2Button(
            "Enter App",
            style: .primary,
            size: .large
        ) {
            // Force navigation to login
            withAnimation(.easeInOut(duration: 0.5)) {
                shouldShowSplash = false
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onNavigationComplete(.authentication)
            }
        }
        .padding(.horizontal, Up2Spacing.xl)
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Helper Methods
    
    private func startInitialization() {
        viewModel.startInitialization()
    }
    
    private func startLogoAnimation() {
        // Start U-shape drawing animation
        withAnimation(.easeOut(duration: 2.0)) {
            drawingProgress = 1.0
        }
        
        // After drawing completes, show the actual logo
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                showLogoImage = true
            }
        }
        
        // Animate logo appearance
        withAnimation(.easeOut(duration: 1.0)) {
            logoOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 1.5).delay(0.3)) {
            logoScale = 1.0
        }
    }
    
    private func startAutoNavigation() {
        // Auto-navigate after 2.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            if !viewModel.shouldNavigate {
                // Show fallback button if navigation hasn't happened
                withAnimation(.easeInOut(duration: 0.5)) {
                    showEnterButton = true
                }
            }
        }
    }
    
    private func handleNavigation() {
        withAnimation(.easeInOut(duration: 0.5)) {
            shouldShowSplash = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onNavigationComplete(viewModel.navigationDestination)
        }
    }
}

// MARK: - Splash Screen View Extensions

extension SplashScreenView {
    
    // MARK: - Static Preview Helper
    static func preview() -> some View {
        SplashScreenView(
            shouldShowSplash: .constant(true),
            onNavigationComplete: { _ in }
        )
    }
}

// MARK: - Preview
#Preview("Splash Screen") {
    SplashScreenView.preview()
        .preferredColorScheme(.dark)
}

#Preview("Splash Screen Light") {
    SplashScreenView.preview()
        .preferredColorScheme(.light)
} 