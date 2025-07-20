import SwiftUI

/// Up2 Design System Navigation Bar Component
/// Provides consistent navigation styling with customizable actions and titles
struct Up2NavigationBar: View {
    
    // MARK: - Navigation Styles
    
    enum Style {
        case standard
        case large
        case transparent
        case colored(Color)
    }
    
    // MARK: - Action Item
    
    struct ActionItem {
        let icon: String
        let title: String?
        let action: () -> Void
        
        init(icon: String, title: String? = nil, action: @escaping () -> Void) {
            self.icon = icon
            self.title = title
            self.action = action
        }
    }
    
    // MARK: - Properties
    
    let title: String?
    let subtitle: String?
    let style: Style
    let leadingAction: ActionItem?
    let trailingActions: [ActionItem]
    let showDivider: Bool
    
    // MARK: - Initializer
    
    init(
        title: String? = nil,
        subtitle: String? = nil,
        style: Style = .standard,
        leadingAction: ActionItem? = nil,
        trailingActions: [ActionItem] = [],
        showDivider: Bool = true
    ) {
        self.title = title
        self.subtitle = subtitle
        self.style = style
        self.leadingAction = leadingAction
        self.trailingActions = trailingActions
        self.showDivider = showDivider
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Up2Spacing.md) {
                // Leading action
                leadingSection
                
                // Title section
                titleSection
                
                // Trailing actions
                trailingSection
            }
            .padding(.horizontal, Up2Spacing.screenEdge)
            .padding(.vertical, Up2Spacing.md)
            .frame(height: navigationHeight)
            .background(backgroundColor)
            
            // Divider
            if showDivider {
                divider
            }
        }
    }
    
    // MARK: - Section Views
    
    @ViewBuilder
    private var leadingSection: some View {
        if let leadingAction = leadingAction {
            Button(action: leadingAction.action) {
                HStack(spacing: Up2Spacing.xs) {
                    Image(systemName: leadingAction.icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(iconColor)
                    
                    if let title = leadingAction.title {
                        Text(title)
                            .font(Up2Typography.bodyMedium)
                            .foregroundColor(textColor)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .minTouchTarget()
        } else {
            // Spacer to maintain alignment
            Color.clear
                .frame(width: 44, height: 44)
        }
    }
    
    @ViewBuilder
    private var titleSection: some View {
        VStack(spacing: Up2Spacing.xs) {
            if let title = title {
                Text(title)
                    .font(titleFont)
                    .foregroundColor(textColor)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(Up2Typography.captionLarge)
                    .foregroundColor(subtitleColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var trailingSection: some View {
        HStack(spacing: Up2Spacing.sm) {
            ForEach(0..<trailingActions.count, id: \.self) { index in
                let action = trailingActions[index]
                
                Button(action: action.action) {
                    HStack(spacing: Up2Spacing.xs) {
                        if let title = action.title {
                            Text(title)
                                .font(Up2Typography.bodyMedium)
                                .foregroundColor(textColor)
                        }
                        
                        Image(systemName: action.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(iconColor)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .minTouchTarget()
            }
            
            // Maintain minimum width if no trailing actions
            if trailingActions.isEmpty {
                Color.clear
                    .frame(width: 44, height: 44)
            }
        }
    }
    
    private var divider: some View {
        Rectangle()
            .fill(Up2Colors.Raw.backgroundSecondaryLight)
            .frame(height: 1)
    }
    
    // MARK: - Computed Properties
    
    private var navigationHeight: CGFloat {
        switch style {
        case .standard, .transparent, .colored:
            return Up2Spacing.navigationBarHeight
        case .large:
            return Up2Spacing.navigationBarHeight + 20
        }
    }
    
    private var titleFont: Font {
        switch style {
        case .standard, .transparent, .colored:
            return Up2Typography.heading3
        case .large:
            return Up2Typography.heading1
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .standard:
            return Up2Colors.Raw.surfaceLight
        case .large:
            return Up2Colors.Raw.surfaceLight
        case .transparent:
            return Color.clear
        case .colored(let color):
            return color
        }
    }
    
    private var textColor: Color {
        switch style {
        case .standard, .large, .transparent:
            return Up2Colors.Raw.primaryLight
        case .colored:
            return .white
        }
    }
    
    private var subtitleColor: Color {
        switch style {
        case .standard, .large, .transparent:
            return Color.gray
        case .colored:
            return .white.opacity(0.8)
        }
    }
    
    private var iconColor: Color {
        switch style {
        case .standard, .large, .transparent:
            return Up2Colors.Raw.primaryLight
        case .colored:
            return .white
        }
    }
}

// MARK: - Convenience Initializers

extension Up2NavigationBar {
    
    /// Standard navigation bar with back button
    static func withBackButton(
        title: String,
        onBack: @escaping () -> Void
    ) -> Up2NavigationBar {
        Up2NavigationBar(
            title: title,
            leadingAction: ActionItem(icon: "chevron.left", action: onBack)
        )
    }
    
    /// Navigation bar with close button
    static func withCloseButton(
        title: String,
        onClose: @escaping () -> Void
    ) -> Up2NavigationBar {
        Up2NavigationBar(
            title: title,
            trailingActions: [ActionItem(icon: "xmark", action: onClose)]
        )
    }
    
    /// Navigation bar with save action
    static func withSaveAction(
        title: String,
        onBack: @escaping () -> Void,
        onSave: @escaping () -> Void
    ) -> Up2NavigationBar {
        Up2NavigationBar(
            title: title,
            leadingAction: ActionItem(icon: "chevron.left", action: onBack),
            trailingActions: [ActionItem(icon: "checkmark", title: "Save", action: onSave)]
        )
    }
    
    /// Large title navigation bar
    static func largeTitle(
        _ title: String,
        subtitle: String? = nil
    ) -> Up2NavigationBar {
        Up2NavigationBar(
            title: title,
            subtitle: subtitle,
            style: .large
        )
    }
    
    /// Transparent navigation bar for overlays
    static func transparent(
        leadingAction: ActionItem? = nil,
        trailingActions: [ActionItem] = []
    ) -> Up2NavigationBar {
        Up2NavigationBar(
            style: .transparent,
            leadingAction: leadingAction,
            trailingActions: trailingActions,
            showDivider: false
        )
    }
    
    /// Colored navigation bar
    static func colored(
        title: String,
        color: Color,
        leadingAction: ActionItem? = nil,
        trailingActions: [ActionItem] = []
    ) -> Up2NavigationBar {
        Up2NavigationBar(
            title: title,
            style: .colored(color),
            leadingAction: leadingAction,
            trailingActions: trailingActions
        )
    }
}

// MARK: - Search Navigation Bar

struct Up2SearchNavigationBar: View {
    @Binding var searchText: String
    let placeholder: String
    let isSearchActive: Bool
    let onSearchToggle: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Up2Spacing.md) {
                if isSearchActive {
                    // Search field
                    HStack(spacing: Up2Spacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(Color.gray)
                            .font(.system(size: 16))
                        
                        TextField(placeholder, text: $searchText)
                            .font(Up2Typography.bodyMedium)
                            .foregroundColor(Up2Colors.Raw.primaryLight)
                    }
                    .padding(.horizontal, Up2Spacing.md)
                    .padding(.vertical, Up2Spacing.sm)
                    .background(Up2Colors.Raw.backgroundSecondaryLight)
                    .cornerRadius(Up2Spacing.radiusSM)
                    
                    // Cancel button
                    Button("Cancel", action: onCancel)
                        .font(Up2Typography.bodyMedium)
                        .foregroundColor(Up2Colors.Raw.primaryLight)
                } else {
                    // Regular navigation content
                    Spacer()
                    
                    Text("Search")
                        .font(Up2Typography.heading3)
                        .fontWeight(.semibold)
                        .foregroundColor(Up2Colors.Raw.primaryLight)
                    
                    Spacer()
                    
                    Button(action: onSearchToggle) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(Up2Colors.Raw.primaryLight)
                    }
                    .minTouchTarget()
                }
            }
            .padding(.horizontal, Up2Spacing.screenEdge)
            .padding(.vertical, Up2Spacing.md)
            .frame(height: Up2Spacing.navigationBarHeight)
            .background(Up2Colors.Raw.surfaceLight)
            
            // Divider
            Rectangle()
                .fill(Up2Colors.Raw.backgroundSecondaryLight)
                .frame(height: 1)
        }
    }
}

// MARK: - Preview

#if DEBUG
struct Up2NavigationBar_Previews: PreviewProvider {
    @State static var searchText = ""
    @State static var isSearchActive = false
    
    static var previews: some View {
        VStack(spacing: Up2Spacing.xl) {
            // Standard navigation bar
            Up2NavigationBar.withBackButton(title: "Event Details") {
                print("Back tapped")
            }
            
            // Navigation bar with save
            Up2NavigationBar.withSaveAction(
                title: "Edit Profile",
                onBack: { print("Back tapped") },
                onSave: { print("Save tapped") }
            )
            
            // Large title
            Up2NavigationBar.largeTitle(
                "Discover",
                subtitle: "Find your vibe"
            )
            
            // Transparent
            Up2NavigationBar.transparent(
                leadingAction: Up2NavigationBar.ActionItem(icon: "chevron.left") {
                    print("Back tapped")
                },
                trailingActions: [
                    Up2NavigationBar.ActionItem(icon: "heart") {
                        print("Like tapped")
                    }
                ]
            )
            
            // Colored
            Up2NavigationBar.colored(
                title: "Event Live",
                color: Up2Colors.Raw.primaryLight,
                trailingActions: [
                    Up2NavigationBar.ActionItem(icon: "square.and.arrow.up") {
                        print("Share tapped")
                    }
                ]
            )
            
            // Search navigation bar
            Up2SearchNavigationBar(
                searchText: $searchText,
                placeholder: "Search events...",
                isSearchActive: isSearchActive,
                onSearchToggle: {
                    isSearchActive.toggle()
                },
                onCancel: {
                    isSearchActive = false
                    searchText = ""
                }
            )
            
            Spacer()
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Up2NavigationBar Variants")
    }
}
#endif 