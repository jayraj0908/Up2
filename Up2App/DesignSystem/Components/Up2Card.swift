import SwiftUI

/// Up2 Design System Card Component
/// Provides consistent container styling for content with elevation and shadows
struct Up2Card<Content: View>: View {
    
    // MARK: - Card Styles
    
    enum Style {
        case elevated
        case outlined
        case filled
        case plain
    }
    
    enum Padding {
        case none
        case small
        case medium
        case large
        case custom(CGFloat)
        
        var value: CGFloat {
            switch self {
            case .none:
                return 0
            case .small:
                return Up2Spacing.md
            case .medium:
                return Up2Spacing.lg
            case .large:
                return Up2Spacing.xl
            case .custom(let value):
                return value
            }
        }
    }
    
    // MARK: - Properties
    
    let content: Content
    let style: Style
    let padding: Padding
    let cornerRadius: CGFloat
    let isInteractive: Bool
    let action: (() -> Void)?
    
    @State private var isPressed = false
    
    // MARK: - Initializer
    
    init(
        style: Style = .elevated,
        padding: Padding = .medium,
        cornerRadius: CGFloat = Up2Spacing.radiusMD,
        isInteractive: Bool = false,
        action: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.style = style
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.isInteractive = isInteractive
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if isInteractive, let action = action {
                Button(action: action) {
                    cardContent
                }
                .buttonStyle(CardButtonStyle(isPressed: $isPressed))
            } else {
                cardContent
            }
        }
    }
    
    // MARK: - Card Content
    
    private var cardContent: some View {
        content
            .padding(padding.value)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: shadowOffset.width,
                y: shadowOffset.height
            )
            .scaleEffect(isPressed && isInteractive ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        switch style {
        case .elevated:
            return Up2Colors.Raw.surfaceLight
        case .outlined:
            return Up2Colors.Raw.surfaceLight
        case .filled:
            return Up2Colors.Raw.backgroundSecondaryLight
        case .plain:
            return Color.clear
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .elevated, .filled, .plain:
            return Color.clear
        case .outlined:
            return Color.gray.opacity(0.2)
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .elevated, .filled, .plain:
            return 0
        case .outlined:
            return 1
        }
    }
    
    private var shadowColor: Color {
        switch style {
        case .elevated:
            return Color.black.opacity(Up2Spacing.shadowOpacity)
        case .outlined, .filled, .plain:
            return Color.clear
        }
    }
    
    private var shadowRadius: CGFloat {
        switch style {
        case .elevated:
            return Up2Spacing.shadowRadius
        case .outlined, .filled, .plain:
            return 0
        }
    }
    
    private var shadowOffset: CGSize {
        switch style {
        case .elevated:
            return Up2Spacing.shadowOffset
        case .outlined, .filled, .plain:
            return CGSize.zero
        }
    }
}

// MARK: - Card Button Style

private struct CardButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { _, pressed in
                isPressed = pressed
            }
    }
}

// MARK: - Convenience Initializers
// Note: Using direct initializer is preferred due to Swift's generic type inference limitations

// MARK: - Event Card Variant

struct Up2EventCard: View {
    let title: String
    let subtitle: String?
    let imageURL: String?
    let date: String?
    let location: String?
    let attendeeCount: Int?
    let isBookmarked: Bool
    let onTap: () -> Void
    let onBookmark: () -> Void
    
    var body: some View {
        Up2Card(
            style: .elevated,
            isInteractive: true,
            action: onTap
        ) {
            VStack(alignment: .leading, spacing: Up2Spacing.md) {
                // Header with image and bookmark
                HStack {
                    if let imageURL = imageURL {
                        AsyncImage(url: URL(string: imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                        }
                        .frame(width: 60, height: 60)
                        .cornerRadius(Up2Spacing.radiusSM)
                    }
                    
                    VStack(alignment: .leading, spacing: Up2Spacing.xs) {
                        Text(title)
                            .font(Up2Typography.heading3)
                            .foregroundColor(Up2Colors.Raw.primaryLight)
                            .lineLimit(2)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(Up2Typography.bodySmall)
                                .foregroundColor(Color.gray)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: onBookmark) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundColor(isBookmarked ? Up2Colors.Raw.accentLight : Color.gray)
                            .font(.system(size: 20))
                    }
                }
                
                // Event details
                VStack(alignment: .leading, spacing: Up2Spacing.xs) {
                    if let date = date {
                        HStack(spacing: Up2Spacing.sm) {
                            Image(systemName: "calendar")
                                .foregroundColor(Up2Colors.Raw.primaryLight)
                                .font(.system(size: 14))
                            
                            Text(date)
                                .font(Up2Typography.captionLarge)
                                .foregroundColor(Color.gray)
                        }
                    }
                    
                    if let location = location {
                        HStack(spacing: Up2Spacing.sm) {
                            Image(systemName: "location")
                                .foregroundColor(Up2Colors.Raw.primaryLight)
                                .font(.system(size: 14))
                            
                            Text(location)
                                .font(Up2Typography.captionLarge)
                                .foregroundColor(Color.gray)
                                .lineLimit(1)
                        }
                    }
                    
                    if let attendeeCount = attendeeCount {
                        HStack(spacing: Up2Spacing.sm) {
                            Image(systemName: "person.2")
                                .foregroundColor(Up2Colors.Raw.primaryLight)
                                .font(.system(size: 14))
                            
                            Text("\(attendeeCount) going")
                                .font(Up2Typography.captionLarge)
                                .foregroundColor(Color.gray)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct Up2Card_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Up2Spacing.xl) {
                // Elevated card
                Up2Card(style: .elevated) {
                    VStack(alignment: .leading, spacing: Up2Spacing.md) {
                        Text("Elevated Card")
                            .font(Up2Typography.heading3)
                            .foregroundColor(Up2Colors.Raw.primaryLight)
                        
                        Text("This is an elevated card with shadow for important content.")
                            .font(Up2Typography.bodyMedium)
                            .foregroundColor(Color.gray)
                    }
                }
                
                // Outlined card
                Up2Card(style: .outlined) {
                    VStack(alignment: .leading, spacing: Up2Spacing.md) {
                        Text("Outlined Card")
                            .font(Up2Typography.heading3)
                            .foregroundColor(Up2Colors.Raw.primaryLight)
                        
                        Text("This is an outlined card with border for secondary content.")
                            .font(Up2Typography.bodyMedium)
                            .foregroundColor(Color.gray)
                    }
                }
                
                // Filled card
                Up2Card(style: .filled) {
                    VStack(alignment: .leading, spacing: Up2Spacing.md) {
                        Text("Filled Card")
                            .font(Up2Typography.heading3)
                            .foregroundColor(Up2Colors.Raw.primaryLight)
                        
                        Text("This is a filled card with background color.")
                            .font(Up2Typography.bodyMedium)
                            .foregroundColor(Color.gray)
                    }
                }
                
                // Interactive card
                Up2Card(
                    style: .elevated,
                    isInteractive: true,
                    action: {
                        print("Card tapped!")
                    }
                ) {
                    VStack(alignment: .leading, spacing: Up2Spacing.md) {
                        Text("Interactive Card")
                            .font(Up2Typography.heading3)
                            .foregroundColor(Up2Colors.Raw.primaryLight)
                        
                        Text("Tap me! This card responds to touch.")
                            .font(Up2Typography.bodyMedium)
                            .foregroundColor(Color.gray)
                    }
                }
                
                // Event card
                Up2EventCard(
                    title: "Rooftop Party at The Sky",
                    subtitle: "Electronic Music • 21+",
                    imageURL: nil,
                    date: "Sat, Dec 21 • 9:00 PM",
                    location: "The Sky Rooftop, Downtown",
                    attendeeCount: 127,
                    isBookmarked: false,
                    onTap: {
                        print("Event tapped!")
                    },
                    onBookmark: {
                        print("Bookmark tapped!")
                    }
                )
            }
            .padding(Up2Spacing.xl)
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Up2Card Variants")
    }
}
#endif 