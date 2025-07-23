import SwiftUI

struct EventCardView: View {
    let feedItem: EventFeedItem
    let onTap: () -> Void
    let onBookmark: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Hero Image Section
            heroImageSection
            
            // Event Details Section
            eventDetailsSection
            
            // Host and Attendee Section
            hostAndAttendeeSection
        }
        .up2GlassEffect(
            blurRadius: 15,
            opacity: 0.4,
            cornerRadius: 16,
            borderWidth: 1
        )
        .cornerRadius(16)
        .shadow(
            color: Up2Colors.primary.opacity(0.15),
            radius: 12,
            x: 0,
            y: 6
        )
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
        .onTapGesture(perform: onTap)
    }
    
    // MARK: - Hero Image Section
    private var heroImageSection: some View {
        ZStack(alignment: .topTrailing) {
            // Placeholder image (replace with actual event image)
            Rectangle()
                .fill(Up2Colors.accent.opacity(0.2))
                .frame(height: 200)
                .overlay(
                    VStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 40))
                            .foregroundColor(Up2Colors.accent)
                        Text("Event Image")
                            .font(Up2Typography.captionMedium)
                            .foregroundColor(Up2Colors.textSecondary)
                    }
                )
            
            // Bookmark button
            Button(action: onBookmark) {
                Image(systemName: feedItem.isBookmarked ? "bookmark.fill" : "bookmark")
                    .font(.title2)
                    .foregroundColor(feedItem.isBookmarked ? Up2Colors.accent : Up2Colors.textInverse)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Circle()
                                    .stroke(
                                        feedItem.isBookmarked ? Up2Colors.accent.opacity(0.3) : Up2Colors.textInverse.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                    )
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            }
            .padding(12)
        }
    }
    
    // MARK: - Event Details Section
    private var eventDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Event title and tags
            VStack(alignment: .leading, spacing: 8) {
                Text(feedItem.event.title)
                    .font(Up2Typography.heading3)
                    .foregroundColor(Up2Colors.textPrimary)
                    .lineLimit(2)
                
                // Event tags
                if !feedItem.event.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(feedItem.event.tags.prefix(3), id: \.self) { tag in
                            Up2Tag(tag, style: .filled, size: .small)
                        }
                    }
                }
            }
            
            // Event metadata
            VStack(alignment: .leading, spacing: 6) {
                // Date and time
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(Up2Colors.textSecondary)
                    Text(formatEventDate(feedItem.event.startTime))
                        .font(Up2Typography.captionMedium)
                        .foregroundColor(Up2Colors.textSecondary)
                }
                
                // Location
                HStack(spacing: 8) {
                    Image(systemName: "location")
                        .font(.caption)
                        .foregroundColor(Up2Colors.textSecondary)
                    Text(feedItem.event.location)
                        .font(Up2Typography.captionMedium)
                        .foregroundColor(Up2Colors.textSecondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let distance = feedItem.distanceFromUser {
                        Text(formatDistance(distance))
                            .font(Up2Typography.captionSmall)
                            .foregroundColor(Up2Colors.textTertiary)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }
    
    // MARK: - Host and Attendee Section
    private var hostAndAttendeeSection: some View {
        HStack {
            // Host info
            HStack(spacing: 8) {
                AsyncImage(url: URL(string: feedItem.host.avatarUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Up2Colors.accent.opacity(0.2))
                        .overlay(
                            Text(String(feedItem.host.name.prefix(1)))
                                .font(Up2Typography.captionMedium)
                                .foregroundColor(Up2Colors.accent)
                        )
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                
                hostDetailsView
            }
            
            Spacer()
            
            // Attendee count and friends
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(feedItem.attendeeCount) attending")
                    .font(Up2Typography.captionMedium)
                    .foregroundColor(Up2Colors.textSecondary)
                
                friendsAttendingView
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Host Details View
    private var hostDetailsView: some View {
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
    }
    
    // MARK: - Friends Attending View
    private var friendsAttendingView: some View {
        Group {
            if !feedItem.friendsAttending.isEmpty {
                HStack(spacing: -4) {
                    ForEach(Array(feedItem.friendsAttending.prefix(3)), id: \.self) { friendId in
                        Circle()
                            .fill(Up2Colors.accent.opacity(0.2))
                            .frame(width: 20, height: 20)
                            .overlay(
                                Text("F")
                                    .font(Up2Typography.captionSmall)
                                    .foregroundColor(Up2Colors.accent)
                            )
                            .overlay(
                                Circle()
                                    .stroke(Up2Colors.surface, lineWidth: 1)
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatEventDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d • h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatDistance(_ distance: Double) -> String {
        // Handle invalid or nil distance values
        guard distance.isFinite && distance >= 0 else {
            return ""
        }
        
        if distance < 1000 {
            return "\(Int(distance))m"
        } else {
            let km = distance / 1000
            return String(format: "%.1fkm", km)
        }
    }
}

#Preview {
    EventCardView(
        feedItem: EventFeedItem(
            id: UUID(),
            event: Event(
                hostId: UUID(),
                title: "Sample Event",
                description: "This is a sample event description",
                location: "San Francisco, CA",
                startTime: Date().addingTimeInterval(3600),
                endTime: Date().addingTimeInterval(7200)
            ),
            host: EventHost(
                id: UUID(),
                name: "John Doe",
                handle: "@johndoe",
                avatarUrl: nil,
                vibeTags: [.social, .music],
                isVerified: true
            ),
            score: 0.85,
            attendeeCount: 25,
            friendsAttending: [],
            isBookmarked: false,
            distanceFromUser: 1500.0
        ),
        onTap: {},
        onBookmark: {}
    )
    .padding()
} 