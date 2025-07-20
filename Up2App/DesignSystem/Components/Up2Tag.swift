import SwiftUI

/// Up2 Design System Tag Component
/// Provides consistent tag styling for vibe tags, categories, and labels
struct Up2Tag: View {
    
    // MARK: - Tag Styles
    
    enum Style {
        case filled
        case outlined
        case subtle
        case gradient
    }
    
    enum Size {
        case small
        case medium
        case large
        
        var fontSize: Font {
            switch self {
            case .small:
                return Up2Typography.captionMedium
            case .medium:
                return Up2Typography.bodySmall
            case .large:
                return Up2Typography.bodyMedium
            }
        }
        
        var padding: EdgeInsets {
            switch self {
            case .small:
                return EdgeInsets(top: Up2Spacing.xs, leading: Up2Spacing.sm, bottom: Up2Spacing.xs, trailing: Up2Spacing.sm)
            case .medium:
                return EdgeInsets(top: Up2Spacing.sm, leading: Up2Spacing.md, bottom: Up2Spacing.sm, trailing: Up2Spacing.md)
            case .large:
                return EdgeInsets(top: Up2Spacing.md, leading: Up2Spacing.lg, bottom: Up2Spacing.md, trailing: Up2Spacing.lg)
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small:
                return Up2Spacing.radiusXS
            case .medium:
                return Up2Spacing.radiusSM
            case .large:
                return Up2Spacing.radiusMD
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small:
                return 12
            case .medium:
                return 16
            case .large:
                return 20
            }
        }
    }
    
    // MARK: - Tag States
    
    enum TagState {
        case normal
        case selected
        case disabled
    }
    
    // MARK: - Properties
    
    let text: String
    let style: Style
    let size: Size
    let state: TagState
    let color: Color
    let icon: String?
    let isRemovable: Bool
    let action: (() -> Void)?
    let onRemove: (() -> Void)?
    
    @State private var isPressed = false
    
    // MARK: - Initializer
    
    init(
        _ text: String,
        style: Style = .filled,
        size: Size = .medium,
        state: TagState = .normal,
        color: Color = Up2Colors.Raw.primaryLight,
        icon: String? = nil,
        isRemovable: Bool = false,
        action: (() -> Void)? = nil,
        onRemove: (() -> Void)? = nil
    ) {
        self.text = text
        self.style = style
        self.size = size
        self.state = state
        self.color = color
        self.icon = icon
        self.isRemovable = isRemovable
        self.action = action
        self.onRemove = onRemove
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    tagContent
                }
                .buttonStyle(TagButtonStyle(isPressed: $isPressed))
            } else {
                tagContent
            }
        }
        .disabled(state == .disabled)
        .opacity(state == .disabled ? 0.6 : 1.0)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
    }
    
    // MARK: - Tag Content
    
    private var tagContent: some View {
        HStack(spacing: Up2Spacing.xs) {
            // Leading icon
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: size.iconSize))
                    .foregroundColor(textColor)
            }
            
            // Text
            Text(text)
                .font(size.fontSize)
                .fontWeight(.medium)
                .foregroundColor(textColor)
                .lineLimit(1)
            
            // Remove button
            if isRemovable, let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.system(size: size.iconSize * 0.8))
                        .foregroundColor(textColor.opacity(0.7))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(size.padding)
        .background(backgroundView)
        .cornerRadius(size.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .stroke(borderColor, lineWidth: borderWidth)
        )
    }
    
    // MARK: - Background View
    
    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .filled:
            backgroundColor
        case .outlined:
            Color.clear
        case .subtle:
            backgroundColor.opacity(0.1)
        case .gradient:
            LinearGradient(
                colors: [color, color.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var backgroundColor: Color {
        switch state {
        case .normal:
            return color
        case .selected:
            return color
        case .disabled:
            return Color.gray
        }
    }
    
    private var textColor: Color {
        switch style {
        case .filled, .gradient:
            return .white
        case .outlined, .subtle:
            switch state {
            case .normal:
                return color
            case .selected:
                return color
            case .disabled:
                return Color.gray
            }
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .filled, .subtle, .gradient:
            return Color.clear
        case .outlined:
            switch state {
            case .normal:
                return color
            case .selected:
                return color
            case .disabled:
                return Color.gray
            }
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .filled, .subtle, .gradient:
            return 0
        case .outlined:
            return 1
        }
    }
}

// MARK: - Tag Button Style

private struct TagButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { oldValue, newValue in
                isPressed = newValue
            }
    }
}

// MARK: - Convenience Initializers

extension Up2Tag {
    
    /// Primary tag with filled style
    static func primary(
        _ text: String,
        size: Size = .medium,
        icon: String? = nil,
        action: (() -> Void)? = nil
    ) -> Up2Tag {
        Up2Tag(
            text,
            style: .filled,
            size: size,
            color: Up2Colors.Raw.primaryLight,
            icon: icon,
            action: action
        )
    }
    
    /// Accent tag with accent color
    static func accent(
        _ text: String,
        size: Size = .medium,
        icon: String? = nil,
        action: (() -> Void)? = nil
    ) -> Up2Tag {
        Up2Tag(
            text,
            style: .filled,
            size: size,
            color: Up2Colors.Raw.accentLight,
            icon: icon,
            action: action
        )
    }
    
    /// Outlined tag
    static func outlined(
        _ text: String,
        size: Size = .medium,
        color: Color = Up2Colors.Raw.primaryLight,
        icon: String? = nil,
        action: (() -> Void)? = nil
    ) -> Up2Tag {
        Up2Tag(
            text,
            style: .outlined,
            size: size,
            color: color,
            icon: icon,
            action: action
        )
    }
    
    /// Subtle tag with light background
    static func subtle(
        _ text: String,
        size: Size = .medium,
        color: Color = Up2Colors.Raw.primaryLight,
        icon: String? = nil,
        action: (() -> Void)? = nil
    ) -> Up2Tag {
        Up2Tag(
            text,
            style: .subtle,
            size: size,
            color: color,
            icon: icon,
            action: action
        )
    }
    
    /// Removable tag with close button
    static func removable(
        _ text: String,
        size: Size = .medium,
        color: Color = Up2Colors.Raw.primaryLight,
        icon: String? = nil,
        onRemove: @escaping () -> Void
    ) -> Up2Tag {
        Up2Tag(
            text,
            style: .filled,
            size: size,
            color: color,
            icon: icon,
            isRemovable: true,
            onRemove: onRemove
        )
    }
    
    /// Selectable tag with state management
    static func selectable(
        _ text: String,
        isSelected: Bool,
        size: Size = .medium,
        color: Color = Up2Colors.Raw.primaryLight,
        icon: String? = nil,
        onToggle: @escaping () -> Void
    ) -> Up2Tag {
        Up2Tag(
            text,
            style: isSelected ? .filled : .outlined,
            size: size,
            state: isSelected ? .selected : .normal,
            color: color,
            icon: icon,
            action: onToggle
        )
    }
}

// MARK: - Vibe Tag

struct Up2VibeTag: View {
    let vibe: String
    let emoji: String?
    let isSelected: Bool
    let onToggle: () -> Void
    
    init(
        vibe: String,
        emoji: String? = nil,
        isSelected: Bool = false,
        onToggle: @escaping () -> Void
    ) {
        self.vibe = vibe
        self.emoji = emoji
        self.isSelected = isSelected
        self.onToggle = onToggle
    }
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: Up2Spacing.xs) {
                if let emoji = emoji {
                    Text(emoji)
                        .font(.system(size: 16))
                }
                
                Text(vibe)
                    .font(Up2Typography.bodySmall)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, Up2Spacing.md)
            .padding(.vertical, Up2Spacing.sm)
            .background(
                RoundedRectangle(cornerRadius: Up2Spacing.radiusLG)
                    .fill(isSelected ? Up2Colors.Raw.primaryLight : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Up2Spacing.radiusLG)
                    .stroke(
                        isSelected ? Color.clear : Up2Colors.Raw.primaryLight,
                        lineWidth: 1
                    )
            )
            .foregroundColor(isSelected ? .white : Up2Colors.Raw.primaryLight)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Tag Cloud

struct Up2TagCloud: View {
    let tags: [String]
    let selectedTags: Set<String>
    let onTagToggle: (String) -> Void
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 80), spacing: Up2Spacing.sm)
        ], spacing: Up2Spacing.sm) {
            ForEach(tags, id: \.self) { tag in
                Up2Tag.selectable(
                    tag,
                    isSelected: selectedTags.contains(tag),
                    size: .small,
                    onToggle: {
                        onTagToggle(tag)
                    }
                )
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct Up2Tag_Previews: PreviewProvider {
    @State static var selectedTags: Set<String> = ["Electronic", "Rooftop"]
    
    static var previews: some View {
        ScrollView {
            VStack(spacing: Up2Spacing.xl) {
                // Different styles
                VStack(alignment: .leading, spacing: Up2Spacing.md) {
                    Text("Tag Styles")
                        .font(Up2Typography.heading3)
                        .foregroundColor(Up2Colors.Raw.primaryLight)
                    
                    HStack(spacing: Up2Spacing.sm) {
                        Up2Tag.primary("Filled")
                        Up2Tag.outlined("Outlined")
                        Up2Tag.subtle("Subtle")
                        Up2Tag("Gradient", style: .gradient, color: Up2Colors.Raw.accentLight)
                    }
                }
                
                // Different sizes
                VStack(alignment: .leading, spacing: Up2Spacing.md) {
                    Text("Tag Sizes")
                        .font(Up2Typography.heading3)
                        .foregroundColor(Up2Colors.Raw.primaryLight)
                    
                    HStack(spacing: Up2Spacing.sm) {
                        Up2Tag.primary("Small", size: .small)
                        Up2Tag.primary("Medium", size: .medium)
                        Up2Tag.primary("Large", size: .large)
                    }
                }
                
                // With icons
                VStack(alignment: .leading, spacing: Up2Spacing.md) {
                    Text("Tags with Icons")
                        .font(Up2Typography.heading3)
                        .foregroundColor(Up2Colors.Raw.primaryLight)
                    
                    HStack(spacing: Up2Spacing.sm) {
                        Up2Tag.primary("Music", icon: "music.note")
                        Up2Tag.accent("Dance", icon: "figure.dance")
                        Up2Tag.outlined("Food", icon: "fork.knife")
                    }
                }
                
                // Removable tags
                VStack(alignment: .leading, spacing: Up2Spacing.md) {
                    Text("Removable Tags")
                        .font(Up2Typography.heading3)
                        .foregroundColor(Up2Colors.Raw.primaryLight)
                    
                    HStack(spacing: Up2Spacing.sm) {
                        Up2Tag.removable("Electronic") {
                            print("Remove Electronic")
                        }
                        Up2Tag.removable("House", color: Up2Colors.Raw.accentLight) {
                            print("Remove House")
                        }
                    }
                }
                
                // Vibe tags
                VStack(alignment: .leading, spacing: Up2Spacing.md) {
                    Text("Vibe Tags")
                        .font(Up2Typography.heading3)
                        .foregroundColor(Up2Colors.Raw.primaryLight)
                    
                    HStack(spacing: Up2Spacing.sm) {
                        Up2VibeTag(vibe: "Chill", emoji: "😌", isSelected: true) {
                            print("Toggle Chill")
                        }
                        Up2VibeTag(vibe: "Energetic", emoji: "⚡", isSelected: false) {
                            print("Toggle Energetic")
                        }
                        Up2VibeTag(vibe: "Artsy", emoji: "🎨", isSelected: false) {
                            print("Toggle Artsy")
                        }
                    }
                }
                
                // Tag cloud
                VStack(alignment: .leading, spacing: Up2Spacing.md) {
                    Text("Tag Cloud")
                        .font(Up2Typography.heading3)
                        .foregroundColor(Up2Colors.Raw.primaryLight)
                    
                    Up2TagCloud(
                        tags: ["Electronic", "House", "Techno", "Rooftop", "Underground", "Live DJ", "Dancing", "21+"],
                        selectedTags: selectedTags
                    ) { tag in
                        if selectedTags.contains(tag) {
                            selectedTags.remove(tag)
                        } else {
                            selectedTags.insert(tag)
                        }
                    }
                }
            }
            .padding(Up2Spacing.xl)
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Up2Tag Variants")
    }
}
#endif 