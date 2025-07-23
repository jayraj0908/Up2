import SwiftUI

struct EventDetailView: View {
    let event: Event
    let host: EventHost?
    @Environment(\.dismiss) private var dismiss
    @State private var isBookmarked = false
    @State private var showingRSVP = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Image
                    heroImageSection
                    
                    // Event Details
                    eventDetailsSection
                    
                    // Host Information
                    if let host = host {
                        hostSection(host: host)
                    }
                    
                    // Action Buttons
                    actionButtonsSection
                }
            }
            .background(Up2Colors.background.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(Up2Colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isBookmarked.toggle()
                    }) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .foregroundColor(isBookmarked ? Up2Colors.accent : Up2Colors.textSecondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingRSVP) {
            RSVPSheetView(event: event)
        }
    }
    
    // MARK: - Hero Image Section
    private var heroImageSection: some View {
        ZStack(alignment: .topTrailing) {
            // Placeholder image (replace with actual event image)
            Rectangle()
                .fill(Up2Colors.accent.opacity(0.2))
                .frame(height: 250)
                .overlay(
                    VStack {
                        Image(systemName: "calendar")
                            .font(.system(size: 60))
                            .foregroundColor(Up2Colors.accent)
                        Text("Event Image")
                            .font(Up2Typography.bodyMedium)
                            .foregroundColor(Up2Colors.textSecondary)
                    }
                )
            
            // Price tag
            if let price = event.price, price > 0 {
                VStack {
                    Text(event.formattedPrice)
                        .font(Up2Typography.bodySmall)
                        .fontWeight(.semibold)
                        .foregroundColor(Up2Colors.textInverse)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Up2Colors.accent)
                        .cornerRadius(16)
                }
                .padding(16)
            }
        }
    }
    
    // MARK: - Event Details Section
    private var eventDetailsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Title and Tags
            VStack(alignment: .leading, spacing: 12) {
                Text(event.title)
                    .font(Up2Typography.heading1)
                    .foregroundColor(Up2Colors.textPrimary)
                    .lineLimit(nil)
                
                if !event.tags.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(event.tags, id: \.self) { tag in
                            Up2Tag(tag, style: .filled, size: .small)
                        }
                    }
                }
            }
            
            // Event Metadata
            VStack(spacing: 16) {
                // Date and Time
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.title3)
                        .foregroundColor(Up2Colors.accent)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Date & Time")
                            .font(Up2Typography.captionMedium)
                            .foregroundColor(Up2Colors.textSecondary)
                        Text(event.formattedDate)
                            .font(Up2Typography.bodyMedium)
                            .foregroundColor(Up2Colors.textPrimary)
                    }
                    
                    Spacer()
                }
                
                // Location
                HStack(spacing: 12) {
                    Image(systemName: "location")
                        .font(.title3)
                        .foregroundColor(Up2Colors.accent)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Location")
                            .font(Up2Typography.captionMedium)
                            .foregroundColor(Up2Colors.textSecondary)
                        Text(event.location)
                            .font(Up2Typography.bodyMedium)
                            .foregroundColor(Up2Colors.textPrimary)
                    }
                    
                    Spacer()
                }
                
                // Price
                HStack(spacing: 12) {
                    Image(systemName: "ticket")
                        .font(.title3)
                        .foregroundColor(Up2Colors.accent)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Price")
                            .font(Up2Typography.captionMedium)
                            .foregroundColor(Up2Colors.textSecondary)
                        Text(event.formattedPrice)
                            .font(Up2Typography.bodyMedium)
                            .foregroundColor(Up2Colors.textPrimary)
                    }
                    
                    Spacer()
                }
            }
            
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("About this event")
                    .font(Up2Typography.heading3)
                    .foregroundColor(Up2Colors.textPrimary)
                
                Text(event.description)
                    .font(Up2Typography.bodyMedium)
                    .foregroundColor(Up2Colors.textSecondary)
                    .lineLimit(nil)
            }
        }
        .padding(20)
        .background(Up2Colors.surface)
    }
    
    // MARK: - Host Section
    private func hostSection(host: EventHost) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hosted by")
                .font(Up2Typography.heading3)
                .foregroundColor(Up2Colors.textPrimary)
            
            HStack(spacing: 12) {
                // Host Avatar
                if let avatarUrl = host.avatarUrl {
                    AsyncImage(url: URL(string: avatarUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(Up2Colors.accent.opacity(0.2))
                            .overlay(
                                Image(systemName: "person.fill")
                                    .foregroundColor(Up2Colors.accent)
                            )
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Up2Colors.accent.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(Up2Colors.accent)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(host.name)
                            .font(Up2Typography.bodyMedium)
                            .fontWeight(.semibold)
                            .foregroundColor(Up2Colors.textPrimary)
                        
                        if host.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(Up2Colors.accent)
                                .font(.caption)
                        }
                    }
                    
                    Text(host.handle)
                        .font(Up2Typography.bodySmall)
                        .foregroundColor(Up2Colors.textSecondary)
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(Up2Colors.surface)
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Up2Button(
                "RSVP to Event",
                style: .primary,
                action: {
                    showingRSVP = true
                }
            )
            
            Up2Button(
                "Share Event",
                style: .secondary,
                action: {
                    // TODO: Implement share functionality
                }
            )
        }
        .padding(20)
        .background(Up2Colors.surface)
    }
}

// MARK: - RSVP Sheet View
struct RSVPSheetView: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss
    @State private var selectedOption = "Going"
    
    private let rsvpOptions = ["Going", "Maybe", "Not Going"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("RSVP to \(event.title)")
                    .font(Up2Typography.heading2)
                    .foregroundColor(Up2Colors.textPrimary)
                
                VStack(spacing: 16) {
                    ForEach(rsvpOptions, id: \.self) { option in
                        Button(action: {
                            selectedOption = option
                        }) {
                            HStack {
                                Text(option)
                                    .font(Up2Typography.bodyMedium)
                                    .foregroundColor(Up2Colors.textPrimary)
                                
                                Spacer()
                                
                                if selectedOption == option {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(Up2Colors.accent)
                                }
                            }
                            .padding()
                            .background(selectedOption == option ? Up2Colors.accent.opacity(0.1) : Up2Colors.surface)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedOption == option ? Up2Colors.accent : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Spacer()
                
                Up2Button(
                    "Confirm RSVP",
                    style: .primary,
                    action: {
                        // TODO: Implement RSVP functionality
                        dismiss()
                    }
                )
            }
            .padding(20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Up2Colors.textSecondary)
                }
            }
        }
    }
}

#Preview {
    EventDetailView(
        event: Event(
            hostId: UUID(),
            title: "Sample Event",
            description: "This is a sample event description that shows how the event detail view looks.",
            tags: ["Music", "Festival"],
            location: "Los Angeles, CA",
            startTime: Date().addingTimeInterval(86400),
            endTime: Date().addingTimeInterval(90000),
            price: 25.0
        ),
        host: EventHost(
            id: UUID(),
            name: "John Doe",
            handle: "@johndoe",
            avatarUrl: nil,
            vibeTags: [.music, .social],
            isVerified: true
        )
    )
} 