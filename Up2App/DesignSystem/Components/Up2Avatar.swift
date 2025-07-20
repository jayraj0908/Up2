import SwiftUI

/// Up2 Design System Avatar Component
/// Provides consistent avatar styling for profile images with fallback states
struct Up2Avatar: View {
    
    // MARK: - Avatar Sizes
    
    enum Size {
        case small
        case medium
        case large
        case extraLarge
        case custom(CGFloat)
        
        var dimension: CGFloat {
            switch self {
            case .small:
                return Up2Spacing.avatarSmall
            case .medium:
                return Up2Spacing.avatarMedium
            case .large:
                return Up2Spacing.avatarLarge
            case .extraLarge:
                return Up2Spacing.avatarXL
            case .custom(let size):
                return size
            }
        }
        
        var iconSize: CGFloat {
            return dimension * 0.5
        }
        
        var fontSize: Font {
            switch self {
            case .small:
                return Up2Typography.captionMedium
            case .medium:
                return Up2Typography.bodyMedium
            case .large:
                return Up2Typography.heading4
            case .extraLarge:
                return Up2Typography.heading2
            case .custom(let size):
                return Font.system(size: size * 0.4)
            }
        }
    }
    
    // MARK: - Avatar Styles
    
    enum Style {
        case circle
        case rounded
        case square
        
        var cornerRadius: CGFloat {
            switch self {
            case .circle:
                return .infinity
            case .rounded:
                return Up2Spacing.radiusMD
            case .square:
                return 0
            }
        }
    }
    
    // MARK: - Properties
    
    let imageURL: String?
    let initials: String?
    let size: Size
    let style: Style
    let backgroundColor: Color
    let borderColor: Color?
    let borderWidth: CGFloat
    let showOnlineIndicator: Bool
    let isOnline: Bool
    let action: (() -> Void)?
    
    @State private var isImageLoaded = false
    @State private var imageLoadFailed = false
    
    // MARK: - Initializer
    
    init(
        imageURL: String? = nil,
        initials: String? = nil,
        size: Size = .medium,
        style: Style = .circle,
        backgroundColor: Color = Up2Colors.Raw.primaryLight,
        borderColor: Color? = nil,
        borderWidth: CGFloat = 0,
        showOnlineIndicator: Bool = false,
        isOnline: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.imageURL = imageURL
        self.initials = initials
        self.size = size
        self.style = style
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.showOnlineIndicator = showOnlineIndicator
        self.isOnline = isOnline
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            if let action = action {
                Button(action: action) {
                    avatarContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                avatarContent
            }
            
            // Online indicator
            if showOnlineIndicator {
                onlineIndicator
            }
        }
    }
    
    // MARK: - Avatar Content
    
    private var avatarContent: some View {
        ZStack {
            // Background
            backgroundColor
                .frame(width: size.dimension, height: size.dimension)
                .clipShape(avatarShape)
            
            // Image or fallback
            if let imageURL = imageURL, !imageLoadFailed {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: size.dimension, height: size.dimension)
                            .clipShape(avatarShape)
                            .onAppear {
                                isImageLoaded = true
                            }
                    case .failure(_):
                        fallbackContent
                            .onAppear {
                                imageLoadFailed = true
                            }
                    case .empty:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.6)
                    @unknown default:
                        fallbackContent
                    }
                }
            } else {
                fallbackContent
            }
        }
        .overlay(
            avatarShape
                .stroke(borderColor ?? Color.clear, lineWidth: borderWidth)
        )
        .shadow(
            color: Color.black.opacity(0.1),
            radius: size.dimension > 48 ? 2 : 1,
            x: 0,
            y: 1
        )
    }
    
    // MARK: - Fallback Content
    
    private var fallbackContent: some View {
        Group {
            if let initials = initials, !initials.isEmpty {
                Text(initials.uppercased())
                    .font(size.fontSize)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            } else {
                Image(systemName: "person.fill")
                    .font(.system(size: size.iconSize))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    // MARK: - Avatar Shape
    
    private var avatarShape: AnyShape {
        switch style {
        case .circle:
            return AnyShape(Circle())
        case .rounded, .square:
            return AnyShape(RoundedRectangle(cornerRadius: style.cornerRadius))
        }
    }
    
    // MARK: - Online Indicator
    
    private var onlineIndicator: some View {
        Circle()
            .fill(isOnline ? Up2Colors.Raw.success : Color.gray)
            .frame(width: onlineIndicatorSize, height: onlineIndicatorSize)
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2)
            )
            .offset(x: indicatorOffset, y: indicatorOffset)
    }
    
    private var onlineIndicatorSize: CGFloat {
        size.dimension * 0.25
    }
    
    private var indicatorOffset: CGFloat {
        (size.dimension - onlineIndicatorSize) * 0.35
    }
}

// MARK: - Convenience Initializers

extension Up2Avatar {
    
    /// Avatar with image URL
    static func image(
        url: String,
        size: Size = .medium,
        style: Style = .circle,
        borderColor: Color? = nil,
        borderWidth: CGFloat = 0
    ) -> Up2Avatar {
        Up2Avatar(
            imageURL: url,
            size: size,
            style: style,
            borderColor: borderColor,
            borderWidth: borderWidth
        )
    }
    
    /// Avatar with initials
    static func initials(
        _ initials: String,
        size: Size = .medium,
        style: Style = .circle,
        backgroundColor: Color = Up2Colors.Raw.primaryLight
    ) -> Up2Avatar {
        Up2Avatar(
            initials: initials,
            size: size,
            style: style,
            backgroundColor: backgroundColor
        )
    }
    
    /// Avatar with online status
    static func online(
        imageURL: String? = nil,
        initials: String? = nil,
        isOnline: Bool,
        size: Size = .medium,
        style: Style = .circle
    ) -> Up2Avatar {
        Up2Avatar(
            imageURL: imageURL,
            initials: initials,
            size: size,
            style: style,
            showOnlineIndicator: true,
            isOnline: isOnline
        )
    }
    
    /// Interactive avatar with tap action
    static func interactive(
        imageURL: String? = nil,
        initials: String? = nil,
        size: Size = .medium,
        style: Style = .circle,
        action: @escaping () -> Void
    ) -> Up2Avatar {
        Up2Avatar(
            imageURL: imageURL,
            initials: initials,
            size: size,
            style: style,
            action: action
        )
    }
}

// MARK: - Avatar Group

struct Up2AvatarGroup: View {
    let avatars: [AvatarData]
    let maxDisplayed: Int
    let size: Up2Avatar.Size
    let spacing: CGFloat
    
    struct AvatarData {
        let imageURL: String?
        let initials: String?
        let backgroundColor: Color
        
        init(imageURL: String? = nil, initials: String? = nil, backgroundColor: Color = Up2Colors.Raw.primaryLight) {
            self.imageURL = imageURL
            self.initials = initials
            self.backgroundColor = backgroundColor
        }
    }
    
    init(
        avatars: [AvatarData],
        maxDisplayed: Int = 3,
        size: Up2Avatar.Size = .small,
        spacing: CGFloat = -8
    ) {
        self.avatars = avatars
        self.maxDisplayed = maxDisplayed
        self.size = size
        self.spacing = spacing
    }
    
    var body: some View {
        HStack(spacing: spacing) {
            let displayAvatars = Array(avatars.prefix(maxDisplayed))
            
            ForEach(0..<displayAvatars.count, id: \.self) { index in
                let avatar = displayAvatars[index]
                
                Up2Avatar(
                    imageURL: avatar.imageURL,
                    initials: avatar.initials,
                    size: size,
                    backgroundColor: avatar.backgroundColor,
                    borderColor: .white,
                    borderWidth: 2
                )
                .zIndex(Double(displayAvatars.count - index))
            }
            
            // Additional count indicator
            if avatars.count > maxDisplayed {
                ZStack {
                    Circle()
                        .fill(Color.gray.opacity(0.8))
                        .frame(width: size.dimension, height: size.dimension)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                    
                    Text("+\(avatars.count - maxDisplayed)")
                        .font(size.fontSize)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Preview

#if DEBUG
struct Up2Avatar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: Up2Spacing.xl) {
            // Different sizes
            HStack(spacing: Up2Spacing.lg) {
                Up2Avatar.initials("JS", size: .small)
                Up2Avatar.initials("AB", size: .medium)
                Up2Avatar.initials("XY", size: .large)
                Up2Avatar.initials("MK", size: .extraLarge)
            }
            
            // Different styles
            HStack(spacing: Up2Spacing.lg) {
                Up2Avatar.initials("CR", style: .circle)
                Up2Avatar.initials("RD", style: .rounded)
                Up2Avatar.initials("SQ", style: .square)
            }
            
            // With borders
            HStack(spacing: Up2Spacing.lg) {
                Up2Avatar(
                    initials: "BD",
                    borderColor: Up2Colors.Raw.accentLight,
                    borderWidth: 2
                )
                
                Up2Avatar(
                    initials: "GR",
                    backgroundColor: Up2Colors.Raw.accentLight,
                    borderColor: Up2Colors.Raw.primaryLight,
                    borderWidth: 3
                )
            }
            
            // Online status
            HStack(spacing: Up2Spacing.lg) {
                Up2Avatar.online(
                    initials: "ON",
                    isOnline: true
                )
                
                Up2Avatar.online(
                    initials: "OFF",
                    isOnline: false
                )
            }
            
            // Avatar group
            Up2AvatarGroup(avatars: [
                .init(initials: "AB"),
                .init(initials: "CD", backgroundColor: Up2Colors.Raw.accentLight),
                .init(initials: "EF", backgroundColor: Up2Colors.Raw.tertiaryLight),
                .init(initials: "GH"),
                .init(initials: "IJ")
            ])
            
            Spacer()
        }
        .padding(Up2Spacing.xl)
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Up2Avatar Variants")
    }
}
#endif 