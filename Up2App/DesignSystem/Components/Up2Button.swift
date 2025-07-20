import SwiftUI

/// Up2 Design System Button Component
/// Provides consistent button styling with primary/secondary variants
struct Up2Button: View {
    
    // MARK: - Button Styles
    
    enum Style {
        case primary
        case secondary
        case tertiary
        case destructive
        case ghost
    }
    
    enum Size {
        case small
        case medium
        case large
    }
    
    // MARK: - Properties
    
    let title: String
    let style: Style
    let size: Size
    let isEnabled: Bool
    let isLoading: Bool
    let action: () -> Void
    
    // MARK: - Initializer
    
    init(
        _ title: String,
        style: Style = .primary,
        size: Size = .medium,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            if isEnabled && !isLoading {
                action()
            }
        }) {
            HStack(spacing: Up2Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                }
                
                if !isLoading {
                    Text(title)
                        .font(buttonFont)
                        .foregroundColor(textColor)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: buttonHeight)
            .padding(.horizontal, horizontalPadding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
        }
        .disabled(!isEnabled || isLoading)
        .opacity(isEnabled ? 1.0 : 0.6)
        .scaleEffect(isEnabled ? 1.0 : 0.98)
        .animation(.easeInOut(duration: 0.1), value: isEnabled)
    }
    
    // MARK: - Computed Properties
    
    private var buttonFont: Font {
        switch size {
        case .small:
            return Up2Typography.buttonSmall
        case .medium:
            return Up2Typography.buttonMedium
        case .large:
            return Up2Typography.buttonLarge
        }
    }
    
    private var buttonHeight: CGFloat {
        switch size {
        case .small:
            return 36
        case .medium:
            return 48
        case .large:
            return 56
        }
    }
    
    private var horizontalPadding: CGFloat {
        switch size {
        case .small:
            return Up2Spacing.lg
        case .medium:
            return Up2Spacing.xl
        case .large:
            return Up2Spacing.xl
        }
    }
    
    private var cornerRadius: CGFloat {
        switch size {
        case .small:
            return Up2Spacing.radiusSM
        case .medium:
            return Up2Spacing.radiusMD
        case .large:
            return Up2Spacing.radiusLG
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return Up2Colors.Raw.primaryLight
        case .secondary:
            return Up2Colors.Raw.surfaceLight
        case .tertiary:
            return Color.clear
        case .destructive:
            return Up2Colors.Raw.error
        case .ghost:
            return Color.clear
        }
    }
    
    private var textColor: Color {
        switch style {
        case .primary:
            return Up2Colors.Raw.surfaceLight
        case .secondary:
            return Up2Colors.Raw.primaryLight
        case .tertiary:
            return Up2Colors.Raw.primaryLight
        case .destructive:
            return Up2Colors.Raw.surfaceLight
        case .ghost:
            return Up2Colors.Raw.primaryLight
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .primary:
            return Color.clear
        case .secondary:
            return Up2Colors.Raw.primaryLight
        case .tertiary:
            return Up2Colors.Raw.primaryLight
        case .destructive:
            return Color.clear
        case .ghost:
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .primary, .destructive, .ghost:
            return 0
        case .secondary, .tertiary:
            return 1
        }
    }
}

// MARK: - Convenience Initializers

extension Up2Button {
    
    /// Primary button with medium size
    static func primary(
        _ title: String,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> Up2Button {
        Up2Button(
            title,
            style: .primary,
            size: .medium,
            isEnabled: isEnabled,
            isLoading: isLoading,
            action: action
        )
    }
    
    /// Secondary button with medium size
    static func secondary(
        _ title: String,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> Up2Button {
        Up2Button(
            title,
            style: .secondary,
            size: .medium,
            isEnabled: isEnabled,
            isLoading: isLoading,
            action: action
        )
    }
    
    /// Tertiary button with medium size
    static func tertiary(
        _ title: String,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> Up2Button {
        Up2Button(
            title,
            style: .tertiary,
            size: .medium,
            isEnabled: isEnabled,
            isLoading: isLoading,
            action: action
        )
    }
    
    /// Destructive button with medium size
    static func destructive(
        _ title: String,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> Up2Button {
        Up2Button(
            title,
            style: .destructive,
            size: .medium,
            isEnabled: isEnabled,
            isLoading: isLoading,
            action: action
        )
    }
    
    /// Small primary button
    static func primarySmall(
        _ title: String,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> Up2Button {
        Up2Button(
            title,
            style: .primary,
            size: .small,
            isEnabled: isEnabled,
            isLoading: isLoading,
            action: action
        )
    }
    
    /// Large primary button
    static func primaryLarge(
        _ title: String,
        isEnabled: Bool = true,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) -> Up2Button {
        Up2Button(
            title,
            style: .primary,
            size: .large,
            isEnabled: isEnabled,
            isLoading: isLoading,
            action: action
        )
    }
}

// MARK: - Preview

#if DEBUG
struct Up2Button_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Up2Spacing.lg) {
            // Primary buttons
            Up2Button.primary("Primary Button") {
                print("Primary tapped")
            }
            
            Up2Button.primarySmall("Small Primary") {
                print("Small primary tapped")
            }
            
            Up2Button.primaryLarge("Large Primary") {
                print("Large primary tapped")
            }
            
            // Secondary buttons
            Up2Button.secondary("Secondary Button") {
                print("Secondary tapped")
            }
            
            // Tertiary buttons
            Up2Button.tertiary("Tertiary Button") {
                print("Tertiary tapped")
            }
            
            // Destructive button
            Up2Button.destructive("Delete Account") {
                print("Destructive tapped")
            }
            
            // Disabled state
            Up2Button.primary("Disabled Button", isEnabled: false) {
                print("Should not print")
            }
            
            // Loading state
            Up2Button.primary("Loading...", isLoading: true) {
                print("Loading...")
            }
        }
        .padding(Up2Spacing.xl)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Up2Button Variants")
    }
}
#endif 