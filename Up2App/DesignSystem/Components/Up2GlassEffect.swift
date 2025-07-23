import SwiftUI

// MARK: - Up2 Glass Effect Component
struct Up2GlassEffect: ViewModifier {
    let blurRadius: CGFloat
    let opacity: Double
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    let borderGradient: LinearGradient?
    
    init(
        blurRadius: CGFloat = 10,
        opacity: Double = 0.3,
        cornerRadius: CGFloat = 16,
        borderWidth: CGFloat = 1,
        borderGradient: LinearGradient? = nil
    ) {
        self.blurRadius = blurRadius
        self.opacity = opacity
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.borderGradient = borderGradient
    }
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .opacity(opacity)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                borderGradient ?? LinearGradient(
                                    colors: [
                                        Up2Colors.primary.opacity(0.3),
                                        Up2Colors.accent.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: borderWidth
                            )
                    )
            )
    }
}

// MARK: - Glass Card Component
struct Up2GlassCard<Content: View>: View {
    let content: Content
    let blurRadius: CGFloat
    let opacity: Double
    let cornerRadius: CGFloat
    let borderWidth: CGFloat
    let borderGradient: LinearGradient?
    let padding: EdgeInsets
    
    init(
        blurRadius: CGFloat = 10,
        opacity: Double = 0.3,
        cornerRadius: CGFloat = 16,
        borderWidth: CGFloat = 1,
        borderGradient: LinearGradient? = nil,
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16),
        @ViewBuilder content: () -> Content
    ) {
        self.blurRadius = blurRadius
        self.opacity = opacity
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.borderGradient = borderGradient
        self.padding = padding
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .modifier(Up2GlassEffect(
                blurRadius: blurRadius,
                opacity: opacity,
                cornerRadius: cornerRadius,
                borderWidth: borderWidth,
                borderGradient: borderGradient
            ))
    }
}

// MARK: - Glass Overlay Component
struct Up2GlassOverlay: View {
    let blurRadius: CGFloat
    let opacity: Double
    let content: AnyView?
    
    init(
        blurRadius: CGFloat = 20,
        opacity: Double = 0.8,
        @ViewBuilder content: () -> some View
    ) {
        self.blurRadius = blurRadius
        self.opacity = opacity
        self.content = AnyView(content())
    }
    
    var body: some View {
        ZStack {
            // Blur background
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(opacity)
                .blur(radius: blurRadius)
                .ignoresSafeArea()
            
            // Content
            if let content = content {
                content
            }
        }
    }
}

// MARK: - View Extensions
extension View {
    func up2GlassEffect(
        blurRadius: CGFloat = 10,
        opacity: Double = 0.3,
        cornerRadius: CGFloat = 16,
        borderWidth: CGFloat = 1,
        borderGradient: LinearGradient? = nil
    ) -> some View {
        modifier(Up2GlassEffect(
            blurRadius: blurRadius,
            opacity: opacity,
            cornerRadius: cornerRadius,
            borderWidth: borderWidth,
            borderGradient: borderGradient
        ))
    }
    
    func up2GlassCard(
        blurRadius: CGFloat = 10,
        opacity: Double = 0.3,
        cornerRadius: CGFloat = 16,
        borderWidth: CGFloat = 1,
        borderGradient: LinearGradient? = nil,
        padding: EdgeInsets = EdgeInsets(top: 16, leading: 16, bottom: 16, trailing: 16)
    ) -> some View {
        Up2GlassCard(
            blurRadius: blurRadius,
            opacity: opacity,
            cornerRadius: cornerRadius,
            borderWidth: borderWidth,
            borderGradient: borderGradient,
            padding: padding
        ) {
            self
        }
    }
}

// MARK: - Liquid Glass Background
struct Up2LiquidGlassBackground: View {
    @State private var animationOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                colors: [
                    Color.black,
                    Color(red: 0.1, green: 0.0, blue: 0.3),
                    Color(red: 0.3, green: 0.0, blue: 0.4)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Animated glass orbs
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Up2Colors.accent.opacity(0.3),
                                Up2Colors.accent.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 50,
                            endRadius: 150
                        )
                    )
                    .frame(width: 200, height: 200)
                    .offset(
                        x: CGFloat(index * 100) + animationOffset,
                        y: CGFloat(index * 80) + animationOffset * 0.5
                    )
                    .blur(radius: 20)
                    .opacity(0.6)
            }
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: 8)
                .repeatForever(autoreverses: true)
            ) {
                animationOffset = 50
            }
        }
    }
}

#Preview {
    ZStack {
        Up2LiquidGlassBackground()
        
        VStack(spacing: 20) {
            Text("Glass Effect Demo")
                .font(.title)
                .foregroundColor(.white)
            
            Up2GlassCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Glass Card")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("This is a glass effect card with blur and border gradient.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            
            Text("Regular Glass Effect")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .up2GlassEffect()
        }
        .padding()
    }
} 