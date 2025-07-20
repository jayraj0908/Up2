import SwiftUI

struct EventCardView: View {
    let feedItem: EventFeedItem
    let onTap: () -> Void
    let onBookmark: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // Event Image Section
                eventImageSection
                
                // Event Details Section
                eventDetailsSection
                
                // Host and Attendee Section
                hostAndAttendeeSection
            }
            .background(Up2Colors.surface)
            .cornerRadius(16)
            .shadow(color: Up2Colors.overlay.opacity(0.1), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    // MARK: - Event Image Section
    private var eventImageSection: some View {
        ZStack(alignment: .topTrailing) {
            // Event Image
            Rectangle()
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Up2Colors.primary.opacity(0.8),
                            Up2Colors.accent.opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 200)
                .overlay(
                    VStack {
                        Spacer()
                        HStack {
                            VStack(alignment: .leading, spacing: 8) {
                                // Vibe Tag
                                Text(feedItem.event.vibe)
                                    .font(Up2Typography.captionMedium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Up2Colors.primary.opacity(0.8))
                                    .cornerRadius(12)
                                
                                // Price Tag
                                if let price = feedItem.event.price, price > 0 {
                                    Text("$\(String(format: "%.0f", price))")
                                        .font(Up2Typography.bodyMedium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Up2Colors.accent.opacity(0.8))
                                        .cornerRadius(12)
                                } else {
                                    Text("Free")
                                        .font(Up2Typography.bodyMedium)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.green.opacity(0.8))
                                        .cornerRadius(12)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                )
            
            // Bookmark Button
            Button(action: onBookmark) {
                Image(systemName: feedItem.isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.title3)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Up2Colors.overlay.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding(.top, 12)
            .padding(.trailing, 12)
        }
    }
    
    // MARK: - Event Details Section
    private var eventDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            Text(feedItem.event.title)
                .font(Up2Typography.heading3)
                .foregroundColor(Up2Colors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Date and Location
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(Up2Colors.textSecondary)
                    
                    Text(formatEventDate(feedItem.event.date))
                        .font(Up2Typography.captionMedium)
                        .foregroundColor(Up2Colors.textSecondary)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "location")
                        .font(.caption)
                        .foregroundColor(Up2Colors.textSecondary)
                    
                    Text(feedItem.event.location.name)
                        .font(Up2Typography.captionMedium)
                        .foregroundColor(Up2Colors.textSecondary)
                        .lineLimit(1)
                }
            }
            
            // Distance and Attendee Count
            HStack {
                if let distance = feedItem.distanceFromUser {
                    Text(formatDistance(distance))
                        .font(Up2Typography.captionMedium)
                        .foregroundColor(Up2Colors.textSecondary)
                }
                
                Spacer()
                
                Text("\(feedItem.attendeeCount) attending")
                    .font(Up2Typography.captionMedium)
                    .foregroundColor(Up2Colors.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // MARK: - Host and Attendee Section
    private var hostAndAttendeeSection: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.horizontal, 16)
            
            HStack(spacing: 12) {
                // Host Avatar
                AsyncImage(url: URL(string: feedItem.host.avatarUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Up2Colors.primary.opacity(0.2))
                        .overlay(
                            Text(String(feedItem.host.name.prefix(1)))
                                .font(Up2Typography.bodyMedium)
                                .foregroundColor(Up2Colors.primary)
                        )
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                
                // Host Details
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(feedItem.host.name)
                            .font(Up2Typography.captionMedium)
                            .foregroundColor(Up2Colors.textPrimary)
                        
                        if feedItem.host.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.caption2)
                                .foregroundColor(Up2Colors.primary)
                        }
                    }
                    
                    Text(feedItem.host.handle)
                        .font(Up2Typography.captionSmall)
                        .foregroundColor(Up2Colors.textSecondary)
                }
                
                Spacer()
                
                // Friends attending indicator
                if !feedItem.friendsAttending.isEmpty {
                    HStack(spacing: -4) {
                        ForEach(Array(feedItem.friendsAttending.prefix(3)), id: \.id) { attendee in
                            AsyncImage(url: URL(string: attendee.avatarUrl ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Circle()
                                    .fill(Up2Colors.accent.opacity(0.2))
                                    .overlay(
                                        Text(String(attendee.name.prefix(1)))
                                            .font(Up2Typography.captionSmall)
                                            .foregroundColor(Up2Colors.accent)
                                    )
                            }
                            .frame(width: 20, height: 20)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Up2Colors.surface, lineWidth: 1)
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatEventDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d • h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            let km = distance / 1000
            return String(format: "%.1fkm", km)
        }
    }
}

// MARK: - Preview
#Preview {
    EventCardView(
        feedItem: MockEventData.generateMockFeedItems().first!,
        onTap: { print("Event tapped") },
        onBookmark: { print("Bookmark tapped") }
    )
    .padding()
    .background(Up2Colors.background)
} 