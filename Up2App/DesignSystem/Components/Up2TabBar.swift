import SwiftUI

/// Up2 Design System Tab Bar Component
/// Provides consistent tab navigation with customizable items and badges
struct Up2TabBar: View {
    
    // MARK: - Tab Item
    
    struct TabItem {
        let id: String
        let icon: String
        let selectedIcon: String?
        let title: String
        let badge: String?
        
        init(
            id: String,
            icon: String,
            selectedIcon: String? = nil,
            title: String,
            badge: String? = nil
        ) {
            self.id = id
            self.icon = icon
            self.selectedIcon = selectedIcon
            self.title = title
            self.badge = badge
        }
    }
    
    // MARK: - Properties
    
    let items: [TabItem]
    @Binding var selectedTab: String
    let onTabSelected: (String) -> Void
    
    // MARK: - Initializer
    
    init(
        items: [TabItem],
        selectedTab: Binding<String>,
        onTabSelected: @escaping (String) -> Void
    ) {
        self.items = items
        self._selectedTab = selectedTab
        self.onTabSelected = onTabSelected
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            // Divider
            Rectangle()
                .fill(dividerColor)
                .frame(height: 1)
            
            // Tab bar content
            HStack(spacing: 0) {
                ForEach(items, id: \.id) { item in
                    tabItemView(for: item)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, Up2Spacing.xs)
            .padding(.top, Up2Spacing.sm)
            .padding(.bottom, Up2Spacing.sm)
            .background(backgroundColor)
        }
    }
    
    // MARK: - Tab Item View
    
    @ViewBuilder
    private func tabItemView(for item: TabItem) -> some View {
        let isSelected = selectedTab == item.id
        
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6, blendDuration: 0)) {
                selectedTab = item.id
                onTabSelected(item.id)
            }
        }) {
            VStack(spacing: Up2Spacing.xs) {
                // Icon with badge
                ZStack {
                    if item.icon == "Logo" {
                        Image("Logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                            .scaleEffect(isSelected ? 1.2 : 1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
                    } else {
                        Image(systemName: iconName(for: item, isSelected: isSelected))
                            .font(.system(size: 24, weight: isSelected ? .semibold : .medium))
                            .foregroundColor(iconColor(isSelected: isSelected))
                            .scaleEffect(isSelected ? 1.2 : 1.0)
                            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isSelected)
                    }
                    
                    // Badge
                    if let badge = item.badge {
                        badgeView(badge: badge)
                            .offset(x: 12, y: -8)
                            .scaleEffect(isSelected ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                    }
                }
                
                // Title
                Text(item.title)
                    .font(titleFont(isSelected: isSelected))
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(titleColor(isSelected: isSelected))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .scaleEffect(isSelected ? 1.05 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
            }
            .padding(.vertical, Up2Spacing.xs)
            .padding(.horizontal, Up2Spacing.xs)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Up2Colors.primary.opacity(0.1) : Color.clear)
                    .scaleEffect(isSelected ? 1.0 : 0.8)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Badge View
    
    @ViewBuilder
    private func badgeView(badge: String) -> some View {
        Text(badge)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(.horizontal, badge.count == 1 ? 4 : 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Up2Colors.Raw.error)
            )
            .overlay(
                Capsule()
                    .stroke(backgroundColor, lineWidth: 1)
            )
    }
    
    // MARK: - Helper Methods
    
    private func iconName(for item: TabItem, isSelected: Bool) -> String {
        if isSelected, let selectedIcon = item.selectedIcon {
            return selectedIcon
        }
        return item.icon
    }
    
    private func iconColor(isSelected: Bool) -> Color {
        isSelected ? Up2Colors.Raw.primaryLight : Color.gray
    }
    
    private func titleColor(isSelected: Bool) -> Color {
        isSelected ? Up2Colors.Raw.primaryLight : Color.gray
    }
    
    private func titleFont(isSelected: Bool) -> Font {
        Up2Typography.captionMedium
    }
    
    private var backgroundColor: Color {
        Up2Colors.Raw.surfaceLight
    }
    
    private var dividerColor: Color {
        Up2Colors.Raw.backgroundSecondaryLight
    }
}

// MARK: - Tab View Container

struct Up2TabView<Content: View>: View {
    let tabs: [Up2TabBar.TabItem]
    @Binding var selectedTab: String
    @ViewBuilder let content: (String) -> Content
    
    var body: some View {
        VStack(spacing: 0) {
            // Content area
            content(selectedTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Tab bar
            Up2TabBar(
                items: tabs,
                selectedTab: $selectedTab,
                onTabSelected: { _ in }
            )
        }
        .ignoresSafeArea(.keyboard)
    }
}

// MARK: - Main App Tab Bar

struct Up2MainTabBar: View {
    @Binding var selectedTab: String
    
    private let mainTabs = [
        Up2TabBar.TabItem(
            id: "discover",
            icon: "safari",
            selectedIcon: "safari.fill",
            title: "Discover"
        ),
        Up2TabBar.TabItem(
            id: "events",
            icon: "calendar",
            selectedIcon: "calendar.fill",
            title: "Events",
            badge: "3"
        ),
        Up2TabBar.TabItem(
            id: "messages",
            icon: "message",
            selectedIcon: "message.fill",
            title: "Messages",
            badge: "2"
        ),
        Up2TabBar.TabItem(
            id: "profile",
            icon: "person",
            selectedIcon: "person.fill",
            title: "Profile"
        )
    ]
    
    var body: some View {
        Up2TabBar(
            items: mainTabs,
            selectedTab: $selectedTab,
            onTabSelected: { tabId in
                // Handle tab selection logic
                handleTabSelection(tabId)
            }
        )
    }
    
    private func handleTabSelection(_ tabId: String) {
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Handle specific tab logic
        switch tabId {
        case "discover":
            print("Switched to Discover")
        case "events":
            print("Switched to Events")
        case "messages":
            print("Switched to Messages")
        case "profile":
            print("Switched to Profile")
        default:
            break
        }
    }
}

// MARK: - Floating Tab Bar

struct Up2FloatingTabBar: View {
    let items: [Up2TabBar.TabItem]
    @Binding var selectedTab: String
    let onTabSelected: (String) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.id) { item in
                floatingTabItem(for: item)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Up2Spacing.lg)
        .padding(.vertical, Up2Spacing.md)
        .background(
            Capsule()
                .fill(Up2Colors.Raw.surfaceLight)
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 12,
                    x: 0,
                    y: 4
                )
        )
        .padding(.horizontal, Up2Spacing.xl)
        .padding(.bottom, Up2Spacing.lg)
    }
    
    @ViewBuilder
    private func floatingTabItem(for item: Up2TabBar.TabItem) -> some View {
        let isSelected = selectedTab == item.id
        
        Button(action: {
            selectedTab = item.id
            onTabSelected(item.id)
        }) {
            VStack(spacing: Up2Spacing.xs) {
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(Up2Colors.Raw.primaryLight)
                            .frame(width: 32, height: 32)
                    }
                    
                    if item.icon == "Logo" {
                        Image("Logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 20, height: 20)
                    } else {
                        Image(systemName: item.selectedIcon != nil && isSelected ? item.selectedIcon! : item.icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(isSelected ? .white : Color.gray)
                    }
                    
                    if let badge = item.badge {
                        Text(badge)
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Up2Colors.Raw.error)
                            )
                            .offset(x: 10, y: -10)
                    }
                }
                
                if isSelected {
                    Text(item.title)
                        .font(Up2Typography.captionSmall)
                        .fontWeight(.medium)
                        .foregroundColor(Up2Colors.Raw.primaryLight)
                        .lineLimit(1)
                }
            }
            .padding(.vertical, Up2Spacing.xs)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Preview

#if DEBUG
struct Up2TabBar_Previews: PreviewProvider {
    @State static var selectedTab = "discover"
    @State static var selectedFloatingTab = "home"
    
    static let sampleTabs = [
        Up2TabBar.TabItem(
            id: "discover",
            icon: "safari",
            selectedIcon: "safari.fill",
            title: "Discover"
        ),
        Up2TabBar.TabItem(
            id: "events",
            icon: "calendar",
            selectedIcon: "calendar.fill",
            title: "Events",
            badge: "3"
        ),
        Up2TabBar.TabItem(
            id: "messages",
            icon: "message",
            selectedIcon: "message.fill",
            title: "Messages",
            badge: "12"
        ),
        Up2TabBar.TabItem(
            id: "profile",
            icon: "person",
            selectedIcon: "person.fill",
            title: "Profile"
        )
    ]
    
    static let floatingTabs = [
        Up2TabBar.TabItem(
            id: "home",
            icon: "house",
            selectedIcon: "house.fill",
            title: "Home"
        ),
        Up2TabBar.TabItem(
            id: "search",
            icon: "magnifyingglass",
            title: "Search"
        ),
        Up2TabBar.TabItem(
            id: "add",
            icon: "plus",
            title: "Add"
        ),
        Up2TabBar.TabItem(
            id: "favorites",
            icon: "heart",
            selectedIcon: "heart.fill",
            title: "Favorites",
            badge: "5"
        )
    ]
    
    static var previews: some View {
        VStack(spacing: Up2Spacing.xl) {
            // Standard tab bar
            VStack {
                Text("Standard Tab Bar")
                    .font(Up2Typography.heading3)
                    .foregroundColor(Up2Colors.Raw.primaryLight)
                
                Up2TabBar(
                    items: sampleTabs,
                    selectedTab: $selectedTab,
                    onTabSelected: { tab in
                        print("Selected: \(tab)")
                    }
                )
            }
            
            Spacer()
            
            // Main app tab bar
            VStack {
                Text("Main App Tab Bar")
                    .font(Up2Typography.heading3)
                    .foregroundColor(Up2Colors.Raw.primaryLight)
                
                Up2MainTabBar(selectedTab: $selectedTab)
            }
            
            Spacer()
            
            // Floating tab bar
            VStack {
                Text("Floating Tab Bar")
                    .font(Up2Typography.heading3)
                    .foregroundColor(Up2Colors.Raw.primaryLight)
                
                Spacer()
                
                Up2FloatingTabBar(
                    items: floatingTabs,
                    selectedTab: $selectedFloatingTab,
                    onTabSelected: { tab in
                        print("Floating selected: \(tab)")
                    }
                )
            }
        }
        .padding(Up2Spacing.xl)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Up2TabBar Variants")
    }
}
#endif 