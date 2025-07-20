import SwiftUI
import UIKit

/// Up2 Design System Color Palette
/// Provides consistent brand and semantic colors with automatic dark mode support
struct Up2Colors {
    /// Internal helper that attempts to load a color from the asset catalogue.
    /// If the named color doesn’t exist it falls back to the supplied default so
    /// the app will still render instead of logging endless runtime errors.
    private static func safeColor(_ name: String, fallback: Color) -> Color {
        if let uiColor = UIColor(named: name) {
            return Color(uiColor)
        }
        return fallback
    }

    // MARK: - Brand Colors

    /// Primary brand color – vibrant purple for CTAs and highlights
    static let primary = safeColor("up2_primary", fallback: Raw.primaryLight)

    /// Secondary accent color for interactive elements
    static let accent = safeColor("up2_accent", fallback: Raw.accentLight)

    /// Tertiary brand color for subtle highlights
    static let tertiary = safeColor("up2_tertiary", fallback: Raw.tertiaryLight)

    // MARK: - Background Colors

    /// Primary background color (adaptive for light/dark mode)
    static let background = safeColor(
        "up2_background",
        fallback: Raw.backgroundLight
    )

    /// Secondary background for cards and containers
    static let backgroundSecondary = safeColor(
        "up2_background_secondary",
        fallback: Raw.backgroundSecondaryLight
    )

    /// Surface color for elevated elements
    static let surface = safeColor("up2_surface", fallback: Color.white)

    /// Surface variant for subtle elevation
    static let surfaceVariant = safeColor("up2_surface_variant", fallback: Color.white.opacity(0.95))

    /// Elevated surface color for higher elevation elements
    static let surfaceElevated = safeColor("up2_surface_elevated", fallback: Raw.surfaceElevated)

    // MARK: - Text Colors

    /// Primary text color (high contrast)
    static let textPrimary = safeColor("up2_text_primary", fallback: Color.black)

    /// Secondary text color (medium contrast)
    static let textSecondary = safeColor("up2_text_secondary", fallback: Color.gray)

    /// Tertiary text color (low contrast)
    static let textTertiary = safeColor("up2_text_tertiary", fallback: Color.gray.opacity(0.6))

    /// Inverse text color for dark backgrounds
    static let textInverse = safeColor("up2_text_inverse", fallback: Color.white)

    /// Text color on primary coloured backgrounds
    static let textOnPrimary = safeColor("up2_text_on_primary", fallback: Raw.textOnPrimary)

    // MARK: - Semantic Colors

    static let success = safeColor("up2_success", fallback: Raw.success)
    static let warning = safeColor("up2_warning", fallback: Raw.warning)
    static let error   = safeColor("up2_error",   fallback: Raw.error)
    static let info    = safeColor("up2_info",    fallback: Raw.info)

    // MARK: - Border & Divider Colors

    static let border           = safeColor("up2_border",           fallback: Color.gray.opacity(0.3))
    static let borderSecondary  = safeColor("up2_border_secondary", fallback: Color.gray.opacity(0.15))
    static let divider          = safeColor("up2_divider",          fallback: Color.gray.opacity(0.2))

    // MARK: - Interactive Colors

    static let disabled   = safeColor("up2_disabled",  fallback: Color.gray.opacity(0.4))
    static let overlay    = safeColor("up2_overlay",   fallback: Color.black.opacity(0.5))
    static let selection  = safeColor("up2_selection", fallback: primary.opacity(0.15))
    
    // MARK: - Static Colors (for raw values)
    
    struct Raw {
        // Brand Colors - Light Mode (Black and Blue theme)
        static let primaryLight = Color(red: 0.0, green: 0.0, blue: 0.0) // #000000 (Black)
        static let accentLight = Color(red: 0.0, green: 0.48, blue: 1.0) // #007AFF (Blue)
        static let tertiaryLight = Color(red: 0.0, green: 0.32, blue: 0.8) // #0052CC (Darker Blue)
        
        // Brand Colors - Dark Mode (Black and Blue theme)
        static let primaryDark = Color(red: 0.0, green: 0.0, blue: 0.0) // #000000 (Black)
        static let accentDark = Color(red: 0.0, green: 0.58, blue: 1.0) // #0094FF (Brighter Blue)
        static let tertiaryDark = Color(red: 0.0, green: 0.42, blue: 0.9) // #006BE6 (Medium Blue)
        
        // Background Colors - Light Mode (Black and Blue theme)
        static let backgroundLight = Color(red: 0.98, green: 0.98, blue: 1.0) // #FAFAFF (Light blue tint)
        static let backgroundSecondaryLight = Color(red: 0.94, green: 0.96, blue: 1.0) // #F0F4FF (Very light blue)
        static let surfaceLight = Color.white
        
        // Background Colors - Dark Mode (Black and Blue theme)
        static let backgroundDark = Color(red: 0.05, green: 0.05, blue: 0.08) // #0D0D14 (Very dark blue-black)
        static let backgroundSecondaryDark = Color(red: 0.08, green: 0.08, blue: 0.12) // #14141F (Dark blue-black)
        static let surfaceDark = Color(red: 0.12, green: 0.12, blue: 0.18) // #1F1F2E (Medium dark blue-black)
        
        // Semantic Colors
        static let success = Color(red: 0.2, green: 0.78, blue: 0.35) // #34C759
        static let warning = Color(red: 1.0, green: 0.58, blue: 0.0) // #FF9500
        static let error = Color(red: 1.0, green: 0.23, blue: 0.19) // #FF3B30
        static let info = Color(red: 0.0, green: 0.48, blue: 1.0) // #007AFF
        
        // Additional colors
        static let textOnPrimary = Color.white
        static let surfaceElevated = Color(red: 0.98, green: 0.98, blue: 1.0) // Slightly elevated surface
    }
}

// MARK: - Color Extensions

extension Color {
    /// Creates an adaptive color that automatically switches between light and dark variants
    static func adaptive(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
}

// MARK: - Color Scheme Support

extension Up2Colors {
    /// Returns the appropriate color for the current color scheme
    static func dynamicColor(light: Color, dark: Color) -> Color {
        return Color.adaptive(light: light, dark: dark)
    }
} 