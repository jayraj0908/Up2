import SwiftUI

// MARK: - Theme Manager

/// Up2 Theme Manager for handling dark/light mode transitions
@MainActor
class Up2ThemeManager: ObservableObject {
    @Published var currentTheme: Theme = .system
    @Published var isDarkMode: Bool = false
    
    enum Theme: String, CaseIterable {
        case light = "Light"
        case dark = "Dark"
        case system = "System"
        
        var displayName: String {
            return self.rawValue
        }
        
        var colorScheme: ColorScheme? {
            switch self {
            case .light:
                return .light
            case .dark:
                return .dark
            case .system:
                return nil
            }
        }
    }
    
    init() {
        // Load saved theme preference
        if let savedTheme = UserDefaults.standard.string(forKey: "selectedTheme"),
           let theme = Theme(rawValue: savedTheme) {
            currentTheme = theme
        }
        
        updateIsDarkMode()
    }
    
    func setTheme(_ theme: Theme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: "selectedTheme")
        updateIsDarkMode()
    }
    
    private func updateIsDarkMode() {
        switch currentTheme {
        case .light:
            isDarkMode = false
        case .dark:
            isDarkMode = true
        case .system:
            // Will be updated by environment changes
            isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        }
    }
    
    func updateForSystemAppearance(_ colorScheme: ColorScheme) {
        if currentTheme == .system {
            isDarkMode = colorScheme == .dark
        }
    }
}

// MARK: - Semantic Color System

/// Up2 Semantic Colors that adapt to light/dark mode
struct Up2SemanticColors {
    
    // MARK: - Background Colors
    
    /// Primary background (screen background)
    static let background = Color("Background")
    
    /// Secondary background (cards, containers)
    static let backgroundSecondary = Color("BackgroundSecondary")
    
    /// Tertiary background (subtle containers)
    static let backgroundTertiary = Color("BackgroundTertiary")
    
    /// Surface color (elevated elements)
    static let surface = Color("Surface")
    
    /// Surface variant (subtle elevation)
    static let surfaceVariant = Color("SurfaceVariant")
    
    // MARK: - Text Colors
    
    /// Primary text (high emphasis)
    static let textPrimary = Color("TextPrimary")
    
    /// Secondary text (medium emphasis)
    static let textSecondary = Color("TextSecondary")
    
    /// Tertiary text (low emphasis)
    static let textTertiary = Color("TextTertiary")
    
    /// Disabled text
    static let textDisabled = Color("TextDisabled")
    
    /// Text on colored backgrounds
    static let textOnColor = Color("TextOnColor")
    
    // MARK: - Brand Colors (Adaptive)
    
    /// Primary brand color
    static let primary = Color("Primary")
    
    /// Secondary brand color  
    static let secondary = Color("Secondary")
    
    /// Tertiary brand color
    static let tertiary = Color("Tertiary")
    
    // MARK: - Interactive Colors
    
    /// Button backgrounds
    static let buttonPrimary = Color("ButtonPrimary")
    static let buttonSecondary = Color("ButtonSecondary")
    static let buttonTertiary = Color("ButtonTertiary")
    
    /// Input field backgrounds
    static let inputBackground = Color("InputBackground")
    static let inputBorder = Color("InputBorder")
    static let inputBorderFocused = Color("InputBorderFocused")
    
    // MARK: - System Colors
    
    /// Success states
    static let success = Color("Success")
    
    /// Warning states
    static let warning = Color("Warning")
    
    /// Error states
    static let error = Color("Error")
    
    /// Info states
    static let info = Color("Info")
    
    // MARK: - Border and Divider Colors
    
    /// Primary borders
    static let border = Color("Border")
    
    /// Subtle borders
    static let borderSubtle = Color("BorderSubtle")
    
    /// Dividers between content
    static let divider = Color("Divider")
    
    // MARK: - Shadow and Overlay Colors
    
    /// Card shadows
    static let shadow = Color("Shadow")
    
    /// Modal overlays
    static let overlay = Color("Overlay")
    
    /// Selection highlights
    static let selection = Color("Selection")
}

// MARK: - Environment Color Scheme Detection

struct Up2ColorSchemeKey: EnvironmentKey {
    static let defaultValue: ColorScheme = .light
}

extension EnvironmentValues {
    var up2ColorScheme: ColorScheme {
        get { self[Up2ColorSchemeKey.self] }
        set { self[Up2ColorSchemeKey.self] = newValue }
    }
}

// MARK: - Adaptive Color Modifiers

extension View {
    /// Apply adaptive colors based on color scheme
    func adaptiveColors() -> some View {
        self.modifier(AdaptiveColorModifier())
    }
    
    /// Set a specific color scheme for testing
    func up2ColorScheme(_ colorScheme: ColorScheme) -> some View {
        self.environment(\.up2ColorScheme, colorScheme)
    }
}

private struct AdaptiveColorModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var themeManager: Up2ThemeManager
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                themeManager.updateForSystemAppearance(colorScheme)
            }
            .onChange(of: colorScheme) { newColorScheme in
                themeManager.updateForSystemAppearance(newColorScheme)
            }
    }
}

// MARK: - Theme Switching Component

struct Up2ThemeToggle: View {
    @EnvironmentObject var themeManager: Up2ThemeManager
    
    var body: some View {
        Menu {
            ForEach(Up2ThemeManager.Theme.allCases, id: \.self) { theme in
                Button(action: {
                    themeManager.setTheme(theme)
                }) {
                    HStack {
                        Text(theme.displayName)
                        
                        if themeManager.currentTheme == theme {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: Up2Spacing.xs) {
                Image(systemName: themeIcon)
                    .font(.system(size: 16, weight: .medium))
                
                Text("Theme")
                    .font(Up2Typography.bodyMedium)
            }
            .foregroundColor(Up2SemanticColors.textPrimary)
        }
    }
    
    private var themeIcon: String {
        switch themeManager.currentTheme {
        case .light:
            return "sun.max"
        case .dark:
            return "moon"
        case .system:
            return "circle.lefthalf.filled"
        }
    }
}

// MARK: - Dark Mode Preview Helper

struct Up2DarkModePreview<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: 0) {
            // Light mode
            VStack {
                Text("Light Mode")
                    .font(Up2Typography.captionMedium)
                    .padding(.top, Up2Spacing.sm)
                
                content
                    .environment(\.colorScheme, .light)
            }
            .frame(maxWidth: .infinity)
            .background(Color.white)
            
            // Dark mode
            VStack {
                Text("Dark Mode")
                    .font(Up2Typography.captionMedium)
                    .foregroundColor(.white)
                    .padding(.top, Up2Spacing.sm)
                
                content
                    .environment(\.colorScheme, .dark)
            }
            .frame(maxWidth: .infinity)
            .background(Color.black)
        }
    }
}

// MARK: - Color Contrast Utilities

struct Up2ColorContrast {
    
    /// Calculate contrast ratio between two colors
    static func contrastRatio(color1: Color, color2: Color) -> Double {
        let luminance1 = relativeLuminance(color: color1)
        let luminance2 = relativeLuminance(color: color2)
        
        let lighter = max(luminance1, luminance2)
        let darker = min(luminance1, luminance2)
        
        return (lighter + 0.05) / (darker + 0.05)
    }
    
    /// Check if contrast ratio meets WCAG AA standards (4.5:1)
    static func meetsWCAGAA(color1: Color, color2: Color) -> Bool {
        return contrastRatio(color1: color1, color2: color2) >= 4.5
    }
    
    /// Check if contrast ratio meets WCAG AAA standards (7:1)
    static func meetsWCAGAAA(color1: Color, color2: Color) -> Bool {
        return contrastRatio(color1: color1, color2: color2) >= 7.0
    }
    
    private static func relativeLuminance(color: Color) -> Double {
        let uiColor = UIColor(color)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Convert to relative luminance
        let r = gammaCorrect(red)
        let g = gammaCorrect(green)
        let b = gammaCorrect(blue)
        
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    }
    
    private static func gammaCorrect(_ value: CGFloat) -> Double {
        let val = Double(value)
        return val <= 0.03928 ? val / 12.92 : pow((val + 0.055) / 1.055, 2.4)
    }
}

// MARK: - Accessibility Color Extensions

extension Color {
    /// Get an accessible text color for this background
    func accessibleTextColor() -> Color {
        let contrastWithWhite = Up2ColorContrast.contrastRatio(color1: self, color2: .white)
        let contrastWithBlack = Up2ColorContrast.contrastRatio(color1: self, color2: .black)
        
        return contrastWithWhite > contrastWithBlack ? .white : .black
    }
    
    /// Check if this color provides sufficient contrast with another color
    func hasGoodContrast(with color: Color) -> Bool {
        return Up2ColorContrast.meetsWCAGAA(color1: self, color2: color)
    }
}

// MARK: - Preview

#if DEBUG
struct Up2DarkModeSupport_Previews: PreviewProvider {
    static var previews: some View {
        Up2DarkModePreview {
            VStack(spacing: Up2Spacing.lg) {
                // Theme toggle
                Up2ThemeToggle()
                
                // Color samples
                VStack(spacing: Up2Spacing.md) {
                    HStack(spacing: Up2Spacing.sm) {
                        Rectangle()
                            .fill(Up2SemanticColors.primary)
                            .frame(width: 40, height: 40)
                            .cornerRadius(8)
                        
                        VStack(alignment: .leading) {
                            Text("Primary Color")
                                .font(Up2Typography.bodyMedium)
                                .foregroundColor(Up2SemanticColors.textPrimary)
                            
                            Text("Brand primary")
                                .font(Up2Typography.captionMedium)
                                .foregroundColor(Up2SemanticColors.textSecondary)
                        }
                    }
                    
                    HStack(spacing: Up2Spacing.sm) {
                        Rectangle()
                            .fill(Up2SemanticColors.surface)
                            .frame(width: 40, height: 40)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Up2SemanticColors.border, lineWidth: 1)
                            )
                        
                        VStack(alignment: .leading) {
                            Text("Surface Color")
                                .font(Up2Typography.bodyMedium)
                                .foregroundColor(Up2SemanticColors.textPrimary)
                            
                            Text("Cards and containers")
                                .font(Up2Typography.captionMedium)
                                .foregroundColor(Up2SemanticColors.textSecondary)
                        }
                    }
                }
            }
            .padding(Up2Spacing.lg)
            .background(Up2SemanticColors.background)
        }
        .environmentObject(Up2ThemeManager())
        .previewDisplayName("Dark Mode Support")
    }
}
#endif 