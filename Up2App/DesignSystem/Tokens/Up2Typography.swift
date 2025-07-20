import SwiftUI

/// Up2 Design System Typography
/// Provides consistent font hierarchy and text styles with Dynamic Type support
struct Up2Typography {
    
    // MARK: - Font Families
    
    /// Primary font family for the app
    static let primaryFontFamily = "SF Pro Display"
    
    /// Secondary font family for specific use cases
    static let secondaryFontFamily = "SF Pro Text"
    
    // MARK: - Display Styles (Large headings and hero text)
    
    /// Extra large display text (48pt, Bold)
    static let displayXL = Font.custom(primaryFontFamily, size: 48, relativeTo: .largeTitle)
        .weight(.bold)
    
    /// Large display text (40pt, Bold)
    static let displayLarge = Font.custom(primaryFontFamily, size: 40, relativeTo: .largeTitle)
        .weight(.bold)
    
    /// Medium display text (32pt, Bold)
    static let displayMedium = Font.custom(primaryFontFamily, size: 32, relativeTo: .title)
        .weight(.bold)
    
    /// Small display text (28pt, Semibold)
    static let displaySmall = Font.custom(primaryFontFamily, size: 28, relativeTo: .title2)
        .weight(.semibold)
    
    // MARK: - Heading Styles (Section titles H1-H4)
    
    /// H1 heading (24pt, Bold)
    static let heading1 = Font.custom(primaryFontFamily, size: 24, relativeTo: .title2)
        .weight(.bold)
    
    /// H2 heading (20pt, Semibold)
    static let heading2 = Font.custom(primaryFontFamily, size: 20, relativeTo: .title3)
        .weight(.semibold)
    
    /// H3 heading (18pt, Semibold)
    static let heading3 = Font.custom(primaryFontFamily, size: 18, relativeTo: .headline)
        .weight(.semibold)
    
    /// H4 heading (16pt, Medium)
    static let heading4 = Font.custom(secondaryFontFamily, size: 16, relativeTo: .headline)
        .weight(.medium)
    
    // MARK: - Body Styles (Main content text)
    
    /// Large body text (18pt, Regular)
    static let bodyLarge = Font.custom(secondaryFontFamily, size: 18, relativeTo: .body)
        .weight(.regular)
    
    /// Medium body text (16pt, Regular) - Primary body style
    static let bodyMedium = Font.custom(secondaryFontFamily, size: 16, relativeTo: .body)
        .weight(.regular)
    
    /// Small body text (14pt, Regular)
    static let bodySmall = Font.custom(secondaryFontFamily, size: 14, relativeTo: .callout)
        .weight(.regular)
    
    /// Bold body text (16pt, Semibold)
    static let bodyBold = Font.custom(secondaryFontFamily, size: 16, relativeTo: .body)
        .weight(.semibold)
    
    // MARK: - Caption Styles (Small text and metadata)
    
    /// Large caption (14pt, Medium)
    static let captionLarge = Font.custom(secondaryFontFamily, size: 14, relativeTo: .callout)
        .weight(.medium)
    
    /// Medium caption (12pt, Regular)
    static let captionMedium = Font.custom(secondaryFontFamily, size: 12, relativeTo: .caption)
        .weight(.regular)
    
    /// Small caption (10pt, Regular)
    static let captionSmall = Font.custom(secondaryFontFamily, size: 10, relativeTo: .caption2)
        .weight(.regular)
    
    // MARK: - Button Styles (Interactive elements)
    
    /// Large button text (18pt, Semibold)
    static let buttonLarge = Font.custom(secondaryFontFamily, size: 18, relativeTo: .body)
        .weight(.semibold)
    
    /// Medium button text (16pt, Semibold)
    static let buttonMedium = Font.custom(secondaryFontFamily, size: 16, relativeTo: .body)
        .weight(.semibold)
    
    /// Small button text (14pt, Medium)
    static let buttonSmall = Font.custom(secondaryFontFamily, size: 14, relativeTo: .callout)
        .weight(.medium)
    
    // MARK: - Specialized Styles
    
    /// Label text (12pt, Semibold) - for form labels
    static let label = Font.custom(secondaryFontFamily, size: 12, relativeTo: .caption)
        .weight(.semibold)
    
    /// Overline text (10pt, Medium, All Caps) - for section headers
    static let overline = Font.custom(secondaryFontFamily, size: 10, relativeTo: .caption2)
        .weight(.medium)
    
    /// Monospace text for codes and numbers
    static let monospace = Font.custom("SF Mono", size: 14, relativeTo: .callout)
        .weight(.regular)
    
    // MARK: - Simplified Aliases (for component compatibility)
    
    /// Simplified display alias (defaults to displayMedium)
    static let display = displayMedium
    
    /// Simplified body alias (defaults to bodyMedium)
    static let body = bodyMedium
    
    /// Simplified caption alias (defaults to captionMedium)
    static let caption = captionMedium
}

// MARK: - Text Modifiers

extension Text {
    
    // MARK: - Display Modifiers
    
    func displayXL() -> Text {
        self.font(Up2Typography.displayXL)
    }
    
    func displayLarge() -> Text {
        self.font(Up2Typography.displayLarge)
    }
    
    func displayMedium() -> Text {
        self.font(Up2Typography.displayMedium)
    }
    
    func displaySmall() -> Text {
        self.font(Up2Typography.displaySmall)
    }
    
    // MARK: - Heading Modifiers
    
    func h1() -> Text {
        self.font(Up2Typography.heading1)
    }
    
    func h2() -> Text {
        self.font(Up2Typography.heading2)
    }
    
    func h3() -> Text {
        self.font(Up2Typography.heading3)
    }
    
    func h4() -> Text {
        self.font(Up2Typography.heading4)
    }
    
    // MARK: - Body Modifiers
    
    func bodyLarge() -> Text {
        self.font(Up2Typography.bodyLarge)
    }
    
    func bodyMedium() -> Text {
        self.font(Up2Typography.bodyMedium)
    }
    
    func bodySmall() -> Text {
        self.font(Up2Typography.bodySmall)
    }
    
    func bodyBold() -> Text {
        self.font(Up2Typography.bodyBold)
    }
    
    // MARK: - Caption Modifiers
    
    func captionLarge() -> Text {
        self.font(Up2Typography.captionLarge)
    }
    
    func captionMedium() -> Text {
        self.font(Up2Typography.captionMedium)
    }
    
    func captionSmall() -> Text {
        self.font(Up2Typography.captionSmall)
    }
    
    // MARK: - Button Modifiers
    
    func buttonLarge() -> Text {
        self.font(Up2Typography.buttonLarge)
    }
    
    func buttonMedium() -> Text {
        self.font(Up2Typography.buttonMedium)
    }
    
    func buttonSmall() -> Text {
        self.font(Up2Typography.buttonSmall)
    }
    
    // MARK: - Specialized Modifiers
    
    func label() -> Text {
        self.font(Up2Typography.label)
    }
    
    func overline() -> some View {
        self.font(Up2Typography.overline)
            .textCase(.uppercase)
    }
    
    func monospace() -> Text {
        self.font(Up2Typography.monospace)
    }
}

// MARK: - Line Height and Letter Spacing

extension Up2Typography {
    
    /// Standard line height multiplier for body text
    static let bodyLineHeight: CGFloat = 1.4
    
    /// Standard line height multiplier for headings
    static let headingLineHeight: CGFloat = 1.2
    
    /// Standard line height multiplier for captions
    static let captionLineHeight: CGFloat = 1.3
    
    /// Letter spacing for display text
    static let displayLetterSpacing: CGFloat = -0.5
    
    /// Letter spacing for headings
    static let headingLetterSpacing: CGFloat = -0.3
    
    /// Letter spacing for overline text
    static let overlineLetterSpacing: CGFloat = 1.0
}

// MARK: - Accessibility Support

extension Up2Typography {
    
    /// Returns font size adjusted for accessibility
    static func accessibleFont(baseSize: CGFloat, category: UIContentSizeCategory) -> CGFloat {
        let multiplier: CGFloat
        
        switch category {
        case .extraSmall:
            multiplier = 0.85
        case .small:
            multiplier = 0.9
        case .medium:
            multiplier = 0.95
        case .large:
            multiplier = 1.0
        case .extraLarge:
            multiplier = 1.15
        case .extraExtraLarge:
            multiplier = 1.35
        case .extraExtraExtraLarge:
            multiplier = 1.55
        case .accessibilityMedium:
            multiplier = 1.8
        case .accessibilityLarge:
            multiplier = 2.15
        case .accessibilityExtraLarge:
            multiplier = 2.5
        case .accessibilityExtraExtraLarge:
            multiplier = 2.85
        case .accessibilityExtraExtraExtraLarge:
            multiplier = 3.2
        default:
            multiplier = 1.0
        }
        
        return baseSize * multiplier
    }
} 