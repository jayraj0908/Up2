import SwiftUI

/// Up2 Design System Spacing
/// Provides consistent spacing values based on 4pt grid system
struct Up2Spacing {
    
    // MARK: - Base Grid System (4pt increments)
    
    /// Extra small spacing (4pt)
    static let xs: CGFloat = 4
    
    /// Small spacing (8pt)
    static let sm: CGFloat = 8
    
    /// Medium spacing (12pt)
    static let md: CGFloat = 12
    
    /// Large spacing (16pt)
    static let lg: CGFloat = 16
    
    /// Extra large spacing (24pt)
    static let xl: CGFloat = 24
    
    /// Extra extra large spacing (32pt)
    static let xxl: CGFloat = 32
    
    /// Extra extra extra large spacing (48pt)
    static let xxxl: CGFloat = 48
    
    /// Maximum spacing (64pt)
    static let max: CGFloat = 64
    
    // MARK: - Semantic Spacing
    
    /// Screen edge padding (16pt)
    static let screenEdge: CGFloat = lg
    
    /// Card padding (16pt)
    static let cardPadding: CGFloat = lg
    
    /// Button padding horizontal (24pt)
    static let buttonPaddingHorizontal: CGFloat = xl
    
    /// Button padding vertical (12pt)
    static let buttonPaddingVertical: CGFloat = md
    
    /// Input field padding (16pt)
    static let inputPadding: CGFloat = lg
    
    /// Section spacing (32pt)
    static let sectionSpacing: CGFloat = xxl
    
    /// Component spacing (24pt)
    static let componentSpacing: CGFloat = xl
    
    /// Item spacing (8pt)
    static let itemSpacing: CGFloat = sm
    
    /// Content spacing (12pt)
    static let contentSpacing: CGFloat = md
    
    // MARK: - Layout Constants
    
    /// Minimum touch target size (44pt)
    static let minTouchTarget: CGFloat = 44
    
    /// Tab bar height (83pt) - includes safe area
    static let tabBarHeight: CGFloat = 83
    
    /// Navigation bar height (44pt)
    static let navigationBarHeight: CGFloat = 44
    
    /// Card minimum height (80pt)
    static let cardMinHeight: CGFloat = 80
    
    /// Avatar size small (32pt)
    static let avatarSmall: CGFloat = 32
    
    /// Avatar size medium (48pt)
    static let avatarMedium: CGFloat = 48
    
    /// Avatar size large (64pt)
    static let avatarLarge: CGFloat = 64
    
    /// Avatar size extra large (96pt)
    static let avatarXL: CGFloat = 96
    
    // MARK: - Corner Radius
    
    /// Extra small radius (4pt)
    static let radiusXS: CGFloat = 4
    
    /// Small radius (8pt)
    static let radiusSM: CGFloat = 8
    
    /// Medium radius (12pt)
    static let radiusMD: CGFloat = 12
    
    /// Large radius (16pt)
    static let radiusLG: CGFloat = 16
    
    /// Extra large radius (24pt)
    static let radiusXL: CGFloat = 24
    
    /// Maximum radius (32pt)
    static let radiusMax: CGFloat = 32
    
    /// Circle radius (50% of width/height)
    static let radiusCircle: CGFloat = .infinity
    
    // MARK: - Corner Radius Aliases (for component compatibility)
    
    /// Large corner radius alias (16pt) - same as radiusLG
    static let cornerRadiusLarge: CGFloat = radiusLG
    
    // MARK: - Shadow and Elevation
    
    /// Shadow offset for cards
    static let shadowOffset = CGSize(width: 0, height: 2)
    
    /// Shadow radius for cards
    static let shadowRadius: CGFloat = 8
    
    /// Shadow opacity for cards
    static let shadowOpacity: Double = 0.1
    
    /// Elevation for floating elements
    static let elevationFloat: CGFloat = 4
    
    /// Elevation for modals
    static let elevationModal: CGFloat = 8
    
    // MARK: - Grid System
    
    /// Column count for grid layouts
    static let gridColumns = 2
    
    /// Grid item spacing
    static let gridSpacing: CGFloat = md
    
    /// Grid horizontal padding
    static let gridPadding: CGFloat = screenEdge
}

// MARK: - View Extensions

extension View {
    
    // MARK: - Padding Modifiers
    
    /// Apply extra small padding (4pt)
    func paddingXS() -> some View {
        self.padding(Up2Spacing.xs)
    }
    
    /// Apply small padding (8pt)
    func paddingSM() -> some View {
        self.padding(Up2Spacing.sm)
    }
    
    /// Apply medium padding (12pt)
    func paddingMD() -> some View {
        self.padding(Up2Spacing.md)
    }
    
    /// Apply large padding (16pt)
    func paddingLG() -> some View {
        self.padding(Up2Spacing.lg)
    }
    
    /// Apply extra large padding (24pt)
    func paddingXL() -> some View {
        self.padding(Up2Spacing.xl)
    }
    
    /// Apply extra extra large padding (32pt)
    func paddingXXL() -> some View {
        self.padding(Up2Spacing.xxl)
    }
    
    /// Apply screen edge padding (16pt)
    func paddingScreenEdge() -> some View {
        self.padding(.horizontal, Up2Spacing.screenEdge)
    }
    
    /// Apply card padding (16pt)
    func paddingCard() -> some View {
        self.padding(Up2Spacing.cardPadding)
    }
    
    // MARK: - Corner Radius Modifiers
    
    /// Apply extra small corner radius (4pt)
    func cornerRadiusXS() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: Up2Spacing.radiusXS))
    }
    
    /// Apply small corner radius (8pt)
    func cornerRadiusSM() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: Up2Spacing.radiusSM))
    }
    
    /// Apply medium corner radius (12pt)
    func cornerRadiusMD() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: Up2Spacing.radiusMD))
    }
    
    /// Apply large corner radius (16pt)
    func cornerRadiusLG() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: Up2Spacing.radiusLG))
    }
    
    /// Apply large corner radius (16pt) - alias for cornerRadiusLG
    func cornerRadiusLarge() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: Up2Spacing.cornerRadiusLarge))
    }
    
    /// Apply extra large corner radius (24pt)
    func cornerRadiusXL() -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: Up2Spacing.radiusXL))
    }
    
    /// Apply circle shape
    func cornerRadiusCircle() -> some View {
        self.clipShape(Circle())
    }
    
    // MARK: - Shadow Modifiers
    
    /// Apply card shadow
    func shadowCard() -> some View {
        self.shadow(
            color: Color.black.opacity(Up2Spacing.shadowOpacity),
            radius: Up2Spacing.shadowRadius,
            x: Up2Spacing.shadowOffset.width,
            y: Up2Spacing.shadowOffset.height
        )
    }
    
    /// Apply floating element shadow
    func shadowFloat() -> some View {
        self.shadow(
            color: Color.black.opacity(0.15),
            radius: Up2Spacing.elevationFloat,
            x: 0,
            y: Up2Spacing.elevationFloat / 2
        )
    }
    
    /// Apply modal shadow
    func shadowModal() -> some View {
        self.shadow(
            color: Color.black.opacity(0.2),
            radius: Up2Spacing.elevationModal,
            x: 0,
            y: Up2Spacing.elevationModal / 2
        )
    }
    
    // MARK: - Size Modifiers
    
    /// Apply minimum touch target size
    func minTouchTarget() -> some View {
        self.frame(
            minWidth: Up2Spacing.minTouchTarget,
            minHeight: Up2Spacing.minTouchTarget
        )
    }
    
    /// Apply small avatar size
    func avatarSmall() -> some View {
        self.frame(
            width: Up2Spacing.avatarSmall,
            height: Up2Spacing.avatarSmall
        )
    }
    
    /// Apply medium avatar size
    func avatarMedium() -> some View {
        self.frame(
            width: Up2Spacing.avatarMedium,
            height: Up2Spacing.avatarMedium
        )
    }
    
    /// Apply large avatar size
    func avatarLarge() -> some View {
        self.frame(
            width: Up2Spacing.avatarLarge,
            height: Up2Spacing.avatarLarge
        )
    }
    
    /// Apply extra large avatar size
    func avatarXL() -> some View {
        self.frame(
            width: Up2Spacing.avatarXL,
            height: Up2Spacing.avatarXL
        )
    }
}

// MARK: - Spacer Extensions

extension Spacer {
    
    /// Create a fixed spacer with extra small spacing (4pt)
    static func xs() -> some View {
        Spacer().frame(width: Up2Spacing.xs, height: Up2Spacing.xs)
    }
    
    /// Create a fixed spacer with small spacing (8pt)
    static func sm() -> some View {
        Spacer().frame(width: Up2Spacing.sm, height: Up2Spacing.sm)
    }
    
    /// Create a fixed spacer with medium spacing (12pt)
    static func md() -> some View {
        Spacer().frame(width: Up2Spacing.md, height: Up2Spacing.md)
    }
    
    /// Create a fixed spacer with large spacing (16pt)
    static func lg() -> some View {
        Spacer().frame(width: Up2Spacing.lg, height: Up2Spacing.lg)
    }
    
    /// Create a fixed spacer with extra large spacing (24pt)
    static func xl() -> some View {
        Spacer().frame(width: Up2Spacing.xl, height: Up2Spacing.xl)
    }
    
    /// Create a fixed spacer with extra extra large spacing (32pt)
    static func xxl() -> some View {
        Spacer().frame(width: Up2Spacing.xxl, height: Up2Spacing.xxl)
    }
}

// MARK: - Responsive Layout

extension Up2Spacing {
    
    /// Get spacing value based on device size
    static func responsive(compact: CGFloat, regular: CGFloat) -> CGFloat {
        // This would be enhanced with actual device size detection
        // For now, returning compact as default
        return compact
    }
    
    /// Get padding for different screen sizes
    static func adaptivePadding(for sizeClass: UserInterfaceSizeClass?) -> CGFloat {
        switch sizeClass {
        case .compact:
            return screenEdge
        case .regular:
            return xl
        default:
            return screenEdge
        }
    }
} 