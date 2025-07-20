import SwiftUI

// MARK: - Screen Header Component

/// Up2 Design System Screen Header Component
/// Provides consistent screen header with title, subtitle, and optional actions
struct Up2ScreenHeader: View {
    let title: String
    let subtitle: String?
    let action: ActionButton?
    
    struct ActionButton {
        let title: String
        let icon: String?
        let action: () -> Void
        
        init(title: String, icon: String? = nil, action: @escaping () -> Void) {
            self.title = title
            self.icon = icon
            self.action = action
        }
    }
    
    init(
        title: String,
        subtitle: String? = nil,
        action: ActionButton? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Up2Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: Up2Spacing.xs) {
                    Text(title)
                        .font(Up2Typography.heading1)
                        .foregroundColor(Up2Colors.Raw.primaryLight)
                        .fontWeight(.bold)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(Up2Typography.bodyMedium)
                            .foregroundColor(Color.gray)
                    }
                }
                
                Spacer()
                
                if let action = action {
                    Button(action: action.action) {
                        HStack(spacing: Up2Spacing.xs) {
                            Text(action.title)
                                .font(Up2Typography.bodyMedium)
                                .foregroundColor(Up2Colors.Raw.primaryLight)
                            
                            if let icon = action.icon {
                                Image(systemName: icon)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(Up2Colors.Raw.primaryLight)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.horizontal, Up2Spacing.screenEdge)
        .padding(.vertical, Up2Spacing.lg)
    }
}

// MARK: - Loading View Component

/// Up2 Design System Loading View Component
/// Provides consistent loading states with customizable messages
struct Up2LoadingView: View {
    let message: String?
    let style: Style
    
    enum Style {
        case small
        case medium
        case large
        case fullScreen
        
        var size: CGFloat {
            switch self {
            case .small: return 20
            case .medium: return 32
            case .large: return 48
            case .fullScreen: return 64
            }
        }
        
        var messageFont: Font {
            switch self {
            case .small: return Up2Typography.captionMedium
            case .medium: return Up2Typography.bodySmall
            case .large: return Up2Typography.bodyMedium
            case .fullScreen: return Up2Typography.heading4
            }
        }
    }
    
    init(message: String? = nil, style: Style = .medium) {
        self.message = message
        self.style = style
    }
    
    var body: some View {
        VStack(spacing: Up2Spacing.lg) {
            // Loading indicator
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Up2Colors.Raw.primaryLight))
                .scaleEffect(scaleFactor)
            
            // Message
            if let message = message {
                Text(message)
                    .font(style.messageFont)
                    .foregroundColor(Color.gray)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: style == .fullScreen ? .infinity : nil)
        .padding(style == .fullScreen ? Up2Spacing.xl : Up2Spacing.lg)
    }
    
    private var scaleFactor: CGFloat {
        style.size / 20 // Base size is 20
    }
}

// MARK: - Error View Component

/// Up2 Design System Error View Component
/// Provides consistent error states with retry actions
struct Up2ErrorView: View {
    let title: String
    let message: String?
    let actionTitle: String?
    let action: (() -> Void)?
    let style: Style
    
    enum Style {
        case inline
        case card
        case fullScreen
    }
    
    init(
        title: String = "Something went wrong",
        message: String? = nil,
        actionTitle: String? = "Try Again",
        action: (() -> Void)? = nil,
        style: Style = .card
    ) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
        self.style = style
    }
    
    var body: some View {
        VStack(spacing: Up2Spacing.lg) {
            // Error icon
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(Up2Colors.Raw.error)
            
            // Content
            VStack(spacing: Up2Spacing.md) {
                Text(title)
                    .font(titleFont)
                    .foregroundColor(Up2Colors.Raw.primaryLight)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                if let message = message {
                    Text(message)
                        .font(Up2Typography.bodyMedium)
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.center)
                }
            }
            
            // Action button
            if let action = action, let actionTitle = actionTitle {
                Up2Button.secondary(actionTitle, action: action)
                    .frame(maxWidth: buttonMaxWidth)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: style == .fullScreen ? .infinity : nil)
        .padding(padding)
        .background(backgroundColor)
        .cornerRadius(cornerRadius)
    }
    
    private var iconSize: CGFloat {
        switch style {
        case .inline: return 24
        case .card: return 32
        case .fullScreen: return 48
        }
    }
    
    private var titleFont: Font {
        switch style {
        case .inline: return Up2Typography.bodyMedium
        case .card: return Up2Typography.heading3
        case .fullScreen: return Up2Typography.heading1
        }
    }
    
    private var padding: CGFloat {
        switch style {
        case .inline: return Up2Spacing.md
        case .card: return Up2Spacing.xl
        case .fullScreen: return Up2Spacing.xl
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .inline: return Color.clear
        case .card: return Up2Colors.Raw.surfaceLight
        case .fullScreen: return Color.clear
        }
    }
    
    private var cornerRadius: CGFloat {
        switch style {
        case .inline, .fullScreen: return 0
        case .card: return Up2Spacing.radiusMD
        }
    }
    
    private var buttonMaxWidth: CGFloat? {
        switch style {
        case .inline, .card: return 200
        case .fullScreen: return nil
        }
    }
}

// MARK: - Empty State Component

/// Up2 Design System Empty State Component
/// Provides consistent empty states with customizable content
struct Up2EmptyState: View {
    let icon: String
    let title: String
    let message: String?
    let actionTitle: String?
    let action: (() -> Void)?
    let style: Style
    
    enum Style {
        case minimal
        case illustrated
        case fullScreen
    }
    
    init(
        icon: String = "tray",
        title: String,
        message: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil,
        style: Style = .illustrated
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
        self.style = style
    }
    
    var body: some View {
        VStack(spacing: spacing) {
            // Icon or illustration
            iconView
            
            // Content
            VStack(spacing: Up2Spacing.md) {
                Text(title)
                    .font(titleFont)
                    .foregroundColor(Up2Colors.Raw.primaryLight)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                
                if let message = message {
                    Text(message)
                        .font(Up2Typography.bodyMedium)
                        .foregroundColor(Color.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
            }
            
            // Action button
            if let action = action, let actionTitle = actionTitle {
                Up2Button.primary(actionTitle, action: action)
                    .frame(maxWidth: buttonMaxWidth)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: style == .fullScreen ? .infinity : nil)
        .padding(padding)
    }
    
    @ViewBuilder
    private var iconView: some View {
        switch style {
        case .minimal:
            Image(systemName: icon)
                .font(.system(size: 32, weight: .light))
                .foregroundColor(Color.gray.opacity(0.6))
        
        case .illustrated:
            ZStack {
                Circle()
                    .fill(Up2Colors.Raw.backgroundSecondaryLight)
                    .frame(width: 80, height: 80)
                
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(Color.gray)
            }
        
        case .fullScreen:
            ZStack {
                Circle()
                    .fill(Up2Colors.Raw.backgroundSecondaryLight)
                    .frame(width: 120, height: 120)
                
                Image(systemName: icon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundColor(Color.gray)
            }
        }
    }
    
    private var spacing: CGFloat {
        switch style {
        case .minimal: return Up2Spacing.md
        case .illustrated: return Up2Spacing.lg
        case .fullScreen: return Up2Spacing.xl
        }
    }
    
    private var titleFont: Font {
        switch style {
        case .minimal: return Up2Typography.bodyMedium
        case .illustrated: return Up2Typography.heading3
        case .fullScreen: return Up2Typography.heading1
        }
    }
    
    private var padding: CGFloat {
        switch style {
        case .minimal: return Up2Spacing.lg
        case .illustrated: return Up2Spacing.xl
        case .fullScreen: return Up2Spacing.xl
        }
    }
    
    private var buttonMaxWidth: CGFloat? {
        switch style {
        case .minimal, .illustrated: return 200
        case .fullScreen: return 300
        }
    }
}

// MARK: - Convenience Extensions

extension Up2ScreenHeader {
    /// Screen header with view all action
    static func withViewAll(
        title: String,
        subtitle: String? = nil,
        onViewAll: @escaping () -> Void
    ) -> Up2ScreenHeader {
        Up2ScreenHeader(
            title: title,
            subtitle: subtitle,
            action: ActionButton(title: "View All", icon: "chevron.right", action: onViewAll)
        )
    }
    
    /// Screen header with add action
    static func withAddAction(
        title: String,
        subtitle: String? = nil,
        onAdd: @escaping () -> Void
    ) -> Up2ScreenHeader {
        Up2ScreenHeader(
            title: title,
            subtitle: subtitle,
            action: ActionButton(title: "Add", icon: "plus", action: onAdd)
        )
    }
}

extension Up2LoadingView {
    /// Full screen loading
    static var fullScreen: Up2LoadingView {
        Up2LoadingView(message: "Loading...", style: .fullScreen)
    }
    
    /// Small inline loading
    static var small: Up2LoadingView {
        Up2LoadingView(style: .small)
    }
}

extension Up2ErrorView {
    /// Network error
    static func network(onRetry: @escaping () -> Void) -> Up2ErrorView {
        Up2ErrorView(
            title: "Connection Error",
            message: "Please check your internet connection and try again.",
            action: onRetry
        )
    }
    
    /// Generic error
    static func generic(onRetry: @escaping () -> Void) -> Up2ErrorView {
        Up2ErrorView(
            title: "Something went wrong",
            message: "We're having trouble loading this content. Please try again.",
            action: onRetry
        )
    }
}

extension Up2EmptyState {
    /// No events empty state
    static func noEvents(onCreate: @escaping () -> Void) -> Up2EmptyState {
        Up2EmptyState(
            icon: "calendar.badge.plus",
            title: "No Events Yet",
            message: "Start by creating your first event or discover events happening around you.",
            actionTitle: "Create Event",
            action: onCreate
        )
    }
    
    /// No search results
    static var noSearchResults: Up2EmptyState {
        Up2EmptyState(
            icon: "magnifyingglass",
            title: "No Results Found",
            message: "Try adjusting your search terms or filters to find what you're looking for.",
            style: .minimal
        )
    }
    
    /// No messages
    static var noMessages: Up2EmptyState {
        Up2EmptyState(
            icon: "message",
            title: "No Messages",
            message: "Start a conversation with someone or join an event to connect with others."
        )
    }
}

// MARK: - Preview

#if DEBUG
struct Up2UtilityViews_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Up2Spacing.xxxl) {
                // Screen headers
                VStack(spacing: Up2Spacing.xl) {
                    Up2ScreenHeader(
                        title: "Discover Events",
                        subtitle: "Find your next adventure"
                    )
                    
                    Up2ScreenHeader.withViewAll(
                        title: "Popular Events",
                        onViewAll: { print("View all tapped") }
                    )
                }
                
                // Loading views
                VStack(spacing: Up2Spacing.xl) {
                    Up2LoadingView(message: "Loading events...", style: .small)
                    Up2LoadingView(message: "Syncing data...", style: .medium)
                    Up2LoadingView(message: "Setting up your profile...", style: .large)
                }
                
                // Error views
                VStack(spacing: Up2Spacing.xl) {
                    Up2ErrorView.network { print("Retry network") }
                    Up2ErrorView(
                        title: "Failed to Load",
                        message: "Something went wrong while loading your events.",
                        actionTitle: "Try Again",
                        action: { print("Retry inline") },
                        style: .inline
                    )
                }
                
                // Empty states
                VStack(spacing: Up2Spacing.xl) {
                    Up2EmptyState.noEvents { print("Create event") }
                    Up2EmptyState.noSearchResults
                    Up2EmptyState(
                        icon: "heart",
                        title: "No Favorites Yet",
                        message: "Heart events you love to see them here.",
                        style: .minimal
                    )
                }
            }
            .padding(Up2Spacing.xl)
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Up2UtilityViews")
    }
}
#endif 