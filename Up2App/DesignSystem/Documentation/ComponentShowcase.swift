import SwiftUI

/// Up2 Design System Component Showcase
/// Interactive documentation and examples for all design system components
struct ComponentShowcase: View {
    @StateObject private var themeManager = Up2ThemeManager()
    @State private var selectedCategory: ComponentCategory = .tokens
    @State private var searchText = ""
    
    enum ComponentCategory: String, CaseIterable {
        case tokens = "Design Tokens"
        case buttons = "Buttons"
        case inputs = "Inputs"
        case cards = "Cards"
        case navigation = "Navigation"
        case feedback = "Feedback"
        case layout = "Layout"
        
        var icon: String {
            switch self {
            case .tokens: return "paintpalette"
            case .buttons: return "rectangle.and.hand.point.up.left"
            case .inputs: return "textformat"
            case .cards: return "rectangle.on.rectangle"
            case .navigation: return "safari"
            case .feedback: return "exclamationmark.bubble"
            case .layout: return "rectangle.3.group"
            }
        }
    }
    
    var body: some View {
        NavigationView {
            sidebar
            
            contentView
                .navigationTitle(selectedCategory.rawValue)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Up2ThemeToggle()
                    }
                }
        }
        .environmentObject(themeManager)
        .adaptiveColors()
    }
    
    // MARK: - Sidebar
    
    private var sidebar: some View {
        List(ComponentCategory.allCases, id: \.self) { category in
            HStack(spacing: Up2Spacing.md) {
                Image(systemName: category.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Up2SemanticColors.primary)
                    .frame(width: 20)
                
                Text(category.rawValue)
                    .font(Up2Typography.bodyMedium)
                    .foregroundColor(Up2SemanticColors.textPrimary)
            }
            .padding(.vertical, Up2Spacing.xs)
            .onTapGesture {
                selectedCategory = category
            }
        }
        .listStyle(SidebarListStyle())
        .navigationTitle("Components")
    }
    
    // MARK: - Content View
    
    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            LazyVStack(spacing: Up2Spacing.xl) {
                switch selectedCategory {
                case .tokens:
                    tokenExamples
                case .buttons:
                    buttonExamples
                case .inputs:
                    inputExamples
                case .cards:
                    cardExamples
                case .navigation:
                    navigationExamples
                case .feedback:
                    feedbackExamples
                case .layout:
                    layoutExamples
                }
            }
            .padding(Up2Spacing.xl)
        }
        .background(Up2SemanticColors.background)
    }
    
    // MARK: - Design Tokens Examples
    
    private var tokenExamples: some View {
        VStack(spacing: Up2Spacing.xxxl) {
            colorTokens
            typographyTokens
            spacingTokens
        }
    }
    
    private var colorTokens: some View {
        ComponentSection(
            title: "Colors",
            description: "Brand colors, semantic colors, and adaptive dark mode support"
        ) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: Up2Spacing.lg) {
                ColorSwatch(name: "Primary", color: Up2SemanticColors.primary)
                ColorSwatch(name: "Secondary", color: Up2SemanticColors.secondary)
                ColorSwatch(name: "Tertiary", color: Up2SemanticColors.tertiary)
                ColorSwatch(name: "Success", color: Up2SemanticColors.success)
                ColorSwatch(name: "Warning", color: Up2SemanticColors.warning)
                ColorSwatch(name: "Error", color: Up2SemanticColors.error)
                ColorSwatch(name: "Surface", color: Up2SemanticColors.surface)
                ColorSwatch(name: "Background", color: Up2SemanticColors.background)
                ColorSwatch(name: "Text Primary", color: Up2SemanticColors.textPrimary)
            }
        }
    }
    
    private var typographyTokens: some View {
        ComponentSection(
            title: "Typography",
            description: "Font hierarchy with Dynamic Type support"
        ) {
            VStack(alignment: .leading, spacing: Up2Spacing.lg) {
                TypographyExample(text: "Display XL", font: Up2Typography.displayXL)
                TypographyExample(text: "Display Large", font: Up2Typography.displayLarge)
                TypographyExample(text: "Heading 1", font: Up2Typography.heading1)
                TypographyExample(text: "Heading 2", font: Up2Typography.heading2)
                TypographyExample(text: "Heading 3", font: Up2Typography.heading3)
                TypographyExample(text: "Body Large", font: Up2Typography.bodyLarge)
                TypographyExample(text: "Body Medium", font: Up2Typography.bodyMedium)
                TypographyExample(text: "Body Small", font: Up2Typography.bodySmall)
                TypographyExample(text: "Caption Large", font: Up2Typography.captionLarge)
                TypographyExample(text: "Caption Medium", font: Up2Typography.captionMedium)
            }
        }
    }
    
    private var spacingTokens: some View {
        ComponentSection(
            title: "Spacing",
            description: "4pt grid system for consistent layouts"
        ) {
            VStack(alignment: .leading, spacing: Up2Spacing.md) {
                SpacingExample(label: "XS (4pt)", value: Up2Spacing.xs)
                SpacingExample(label: "SM (8pt)", value: Up2Spacing.sm)
                SpacingExample(label: "MD (12pt)", value: Up2Spacing.md)
                SpacingExample(label: "LG (16pt)", value: Up2Spacing.lg)
                SpacingExample(label: "XL (24pt)", value: Up2Spacing.xl)
                SpacingExample(label: "XXL (32pt)", value: Up2Spacing.xxl)
                SpacingExample(label: "XXXL (48pt)", value: Up2Spacing.xxxl)
            }
        }
    }
    
    // MARK: - Button Examples
    
    private var buttonExamples: some View {
        VStack(spacing: Up2Spacing.xxxl) {
            ComponentSection(
                title: "Button Styles",
                description: "Primary, secondary, and tertiary button variants"
            ) {
                VStack(spacing: Up2Spacing.lg) {
                    HStack(spacing: Up2Spacing.lg) {
                        Up2Button.primary("Primary") { }
                        Up2Button.secondary("Secondary") { }
                        Up2Button.tertiary("Tertiary") { }
                    }
                    
                    HStack(spacing: Up2Spacing.lg) {
                        Up2Button.destructive("Destructive") { }
                        Up2Button.primary("Disabled", isEnabled: false) { }
                        Up2Button.primary("Loading", isLoading: true) { }
                    }
                }
            }
            
            ComponentSection(
                title: "Button Sizes",
                description: "Small, medium, and large button sizes"
            ) {
                VStack(spacing: Up2Spacing.lg) {
                    Up2Button.primarySmall("Small Button") { }
                    Up2Button.primary("Medium Button") { }
                    Up2Button.primaryLarge("Large Button") { }
                }
            }
        }
    }
    
    // MARK: - Input Examples
    
    @State private var emailText = ""
    @State private var passwordText = ""
    @State private var errorText = "Invalid email"
    @State private var phoneText = ""
    
    private var inputExamples: some View {
        ComponentSection(
            title: "Text Fields",
            description: "Input fields with validation states and accessibility"
        ) {
            VStack(spacing: Up2Spacing.xl) {
                Up2TextField.email(
                    text: $emailText,
                    helperText: "We'll never share your email"
                )
                
                Up2TextField.password(
                    text: $passwordText,
                    helperText: "Must be at least 8 characters",
                    isRequired: true
                )
                
                Up2TextField.text(
                    text: $errorText,
                    placeholder: "Enter your name",
                    label: "Full Name",
                    errorText: "This field is required",
                    isRequired: true
                )
                
                Up2TextField.phone(text: $phoneText)
            }
        }
    }
    
    // MARK: - Card Examples
    
    private var cardExamples: some View {
        VStack(spacing: Up2Spacing.xxxl) {
            ComponentSection(
                title: "Card Styles",
                description: "Elevated, outlined, and filled card variants"
            ) {
                VStack(spacing: Up2Spacing.lg) {
                    Up2Card(style: .elevated) {
                        cardContent(title: "Elevated Card", subtitle: "With shadow elevation")
                    }
                    
                    Up2Card(style: .outlined) {
                        cardContent(title: "Outlined Card", subtitle: "With border styling")
                    }
                    
                    Up2Card(style: .filled) {
                        cardContent(title: "Filled Card", subtitle: "With background fill")
                    }
                }
            }
            
            ComponentSection(
                title: "Event Card",
                description: "Specialized card for event content"
            ) {
                Up2EventCard(
                    title: "Rooftop Party at The Sky",
                    subtitle: "Electronic Music • 21+",
                    imageURL: nil,
                    date: "Sat, Dec 21 • 9:00 PM",
                    location: "The Sky Rooftop, Downtown",
                    attendeeCount: 127,
                    isBookmarked: false,
                    onTap: { },
                    onBookmark: { }
                )
            }
        }
    }
    
    private func cardContent(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: Up2Spacing.md) {
            Text(title)
                .font(Up2Typography.heading3)
                .foregroundColor(Up2SemanticColors.textPrimary)
            
            Text(subtitle)
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2SemanticColors.textSecondary)
        }
    }
    
    // MARK: - Navigation Examples
    
    private var navigationExamples: some View {
        VStack(spacing: Up2Spacing.xxxl) {
            ComponentSection(
                title: "Navigation Bar",
                description: "Consistent navigation with customizable actions"
            ) {
                VStack(spacing: Up2Spacing.lg) {
                    Up2NavigationBar.withBackButton(title: "Event Details") { }
                    
                    Up2NavigationBar.withSaveAction(
                        title: "Edit Profile",
                        onBack: { },
                        onSave: { }
                    )
                    
                    Up2NavigationBar.largeTitle("Discover", subtitle: "Find your vibe")
                }
            }
            
            ComponentSection(
                title: "Tab Bar",
                description: "Main navigation with badges and selection states"
            ) {
                Up2MainTabBar(selectedTab: .constant("discover"))
            }
        }
    }
    
    // MARK: - Feedback Examples
    
    private var feedbackExamples: some View {
        VStack(spacing: Up2Spacing.xxxl) {
            ComponentSection(
                title: "Loading States",
                description: "Loading indicators for different contexts"
            ) {
                VStack(spacing: Up2Spacing.lg) {
                    Up2LoadingView(message: "Loading events...", style: .small)
                    Up2LoadingView(message: "Syncing data...", style: .medium)
                    Up2LoadingView(message: "Setting up profile...", style: .large)
                }
            }
            
            ComponentSection(
                title: "Error States",
                description: "Error handling with retry actions"
            ) {
                VStack(spacing: Up2Spacing.lg) {
                    Up2ErrorView.network(onRetry: { })
                    Up2ErrorView(
                        title: "Failed to Load",
                        message: "Something went wrong while loading your events.",
                        actionTitle: "Try Again",
                        action: { },
                        style: .card
                    )
                }
            }
            
            ComponentSection(
                title: "Empty States",
                description: "Helpful empty states with actions"
            ) {
                VStack(spacing: Up2Spacing.lg) {
                    Up2EmptyState.noEvents { }
                    Up2EmptyState.noSearchResults
                }
            }
        }
    }
    
    // MARK: - Layout Examples
    
    private var layoutExamples: some View {
        VStack(spacing: Up2Spacing.xxxl) {
            ComponentSection(
                title: "Avatars",
                description: "Profile images with different sizes and states"
            ) {
                VStack(spacing: Up2Spacing.lg) {
                    HStack(spacing: Up2Spacing.lg) {
                        Up2Avatar.initials("JS", size: .small)
                        Up2Avatar.initials("AB", size: .medium)
                        Up2Avatar.initials("XY", size: .large)
                        Up2Avatar.initials("MK", size: .extraLarge)
                    }
                    
                    HStack(spacing: Up2Spacing.lg) {
                        Up2Avatar.online(initials: "ON", isOnline: true)
                        Up2Avatar.online(initials: "OFF", isOnline: false)
                    }
                    
                    Up2AvatarGroup(avatars: [
                        .init(initials: "AB"),
                        .init(initials: "CD", backgroundColor: Up2Colors.Raw.accentLight),
                        .init(initials: "EF", backgroundColor: Up2Colors.Raw.tertiaryLight),
                        .init(initials: "GH"),
                        .init(initials: "IJ")
                    ])
                }
            }
            
            ComponentSection(
                title: "Tags",
                description: "Vibe tags and categories with selection states"
            ) {
                VStack(spacing: Up2Spacing.lg) {
                    HStack(spacing: Up2Spacing.sm) {
                        Up2Tag.primary("Electronic")
                        Up2Tag.accent("House")
                        Up2Tag.outlined("Techno")
                        Up2Tag.subtle("Chill")
                    }
                    
                    HStack(spacing: Up2Spacing.sm) {
                        Up2Tag.removable("Removable") { }
                        Up2Tag.primary("Music", icon: "music.note")
                        Up2Tag("Gradient", style: .gradient, color: Up2Colors.Raw.accentLight)
                    }
                    
                    HStack(spacing: Up2Spacing.sm) {
                        Up2VibeTag(vibe: "Chill", emoji: "😌", isSelected: true) { }
                        Up2VibeTag(vibe: "Energetic", emoji: "⚡", isSelected: false) { }
                        Up2VibeTag(vibe: "Artsy", emoji: "🎨", isSelected: false) { }
                    }
                }
            }
        }
    }
}

// MARK: - Helper Components

struct ComponentSection<Content: View>: View {
    let title: String
    let description: String
    let content: Content
    
    init(title: String, description: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.description = description
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Up2Spacing.lg) {
            VStack(alignment: .leading, spacing: Up2Spacing.sm) {
                Text(title)
                    .font(Up2Typography.heading2)
                    .foregroundColor(Up2SemanticColors.textPrimary)
                
                Text(description)
                    .font(Up2Typography.bodyMedium)
                    .foregroundColor(Up2SemanticColors.textSecondary)
            }
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ColorSwatch: View {
    let name: String
    let color: Color
    
    var body: some View {
        VStack(spacing: Up2Spacing.sm) {
            RoundedRectangle(cornerRadius: Up2Spacing.radiusMD)
                .fill(color)
                .frame(height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: Up2Spacing.radiusMD)
                        .stroke(Up2SemanticColors.border, lineWidth: 1)
                )
            
            Text(name)
                .font(Up2Typography.captionMedium)
                .foregroundColor(Up2SemanticColors.textSecondary)
                .lineLimit(1)
        }
    }
}

struct TypographyExample: View {
    let text: String
    let font: Font
    
    var body: some View {
        HStack {
            Text(text)
                .font(font)
                .foregroundColor(Up2SemanticColors.textPrimary)
            
            Spacer()
        }
    }
}

struct SpacingExample: View {
    let label: String
    let value: CGFloat
    
    var body: some View {
        HStack(spacing: Up2Spacing.md) {
            Text(label)
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2SemanticColors.textPrimary)
                .frame(width: 80, alignment: .leading)
            
            Rectangle()
                .fill(Up2SemanticColors.primary)
                .frame(width: value, height: 20)
                .cornerRadius(4)
            
            Spacer()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct ComponentShowcase_Previews: PreviewProvider {
    static var previews: some View {
        ComponentShowcase()
            .previewDisplayName("Component Showcase")
    }
}
#endif 