import SwiftUI

struct EventRSVPView: View {
    let event: HostEvent
    @StateObject private var viewModel = EventRSVPViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFilter: RSVPFilter = .all
    @State private var searchText = ""
    @State private var showingMessageSheet = false
    @State private var selectedAttendees: Set<UUID> = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Event Header
                eventHeader
                
                // Filter and Search
                filterSection
                
                // RSVP List
                rsvpList
            }
            .background(Up2Colors.background.ignoresSafeArea())
            .navigationTitle("RSVPs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Up2Colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Message") {
                        showingMessageSheet = true
                    }
                    .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                    .disabled(selectedAttendees.isEmpty)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadRSVPs(for: event.id)
            }
        }
        .sheet(isPresented: $showingMessageSheet) {
            MessageAttendeesSheet(
                event: event,
                attendees: viewModel.rsvps.filter { selectedAttendees.contains($0.id) }
            )
        }
    }
    
    // MARK: - Event Header
    private var eventHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(Up2Typography.heading2)
                        .foregroundColor(Up2Colors.textPrimary)
                    
                    Text(event.venueName)
                        .font(Up2Typography.bodyMedium)
                        .foregroundColor(Up2Colors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(viewModel.rsvps.count)")
                        .font(Up2Typography.heading2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                    
                    Text("Total RSVPs")
                        .font(Up2Typography.caption)
                        .foregroundColor(Up2Colors.textSecondary)
                }
            }
            
            // RSVP Stats
            HStack(spacing: 20) {
                RSVPStatItem(
                    count: viewModel.confirmedCount,
                    label: "Confirmed",
                    color: .green
                )
                
                RSVPStatItem(
                    count: viewModel.pendingCount,
                    label: "Pending",
                    color: .orange
                )
                
                RSVPStatItem(
                    count: viewModel.cancelledCount,
                    label: "Cancelled",
                    color: .red
                )
            }
        }
        .padding()
        .background(Up2Colors.surface)
    }
    
    // MARK: - Filter Section
    private var filterSection: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(Up2Colors.textSecondary)
                
                TextField("Search attendees...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Up2Colors.surface)
            .cornerRadius(8)
            
            // Filter Buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(RSVPFilter.allCases, id: \.self) { filter in
                        FilterButton(
                            filter: filter,
                            isSelected: selectedFilter == filter,
                            count: viewModel.countForFilter(filter)
                        ) {
                            selectedFilter = filter
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Up2Colors.surface)
    }
    
    // MARK: - RSVP List
    private var rsvpList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if viewModel.isLoading {
                    ForEach(0..<5, id: \.self) { _ in
                        RSVPRowSkeleton()
                    }
                } else if filteredRSVPs.isEmpty {
                    emptyStateView
                } else {
                    ForEach(filteredRSVPs, id: \.id) { rsvp in
                        RSVPRow(
                            rsvp: rsvp,
                            isSelected: selectedAttendees.contains(rsvp.id),
                            onToggleSelection: {
                                if selectedAttendees.contains(rsvp.id) {
                                    selectedAttendees.remove(rsvp.id)
                                } else {
                                    selectedAttendees.insert(rsvp.id)
                                }
                            },
                            onStatusChange: { newStatus in
                                viewModel.updateRSVPStatus(rsvp.id, to: newStatus)
                            }
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Computed Properties
    private var filteredRSVPs: [RSVPData] {
        var filtered = viewModel.rsvps
        
        // Apply status filter
        if selectedFilter != .all {
            filtered = filtered.filter { $0.status == selectedFilter.status }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { rsvp in
                rsvp.userName.localizedCaseInsensitiveContains(searchText) ||
                rsvp.eventTitle.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(Up2Colors.textSecondary)
            
            Text("No RSVPs Found")
                .font(Up2Typography.heading2)
                .foregroundColor(Up2Colors.textPrimary)
            
            Text("RSVPs will appear here once people start joining your event.")
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
    }
}

// MARK: - Supporting Components

struct RSVPStatItem: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(Up2Typography.heading3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(label)
                .font(Up2Typography.caption)
                .foregroundColor(Up2Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct FilterButton: View {
    let filter: RSVPFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(filter.rawValue)
                    .font(Up2Typography.buttonSmall)
                
                Text("(\(count))")
                    .font(Up2Typography.caption)
            }
            .foregroundColor(isSelected ? .white : Up2Colors.textPrimary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                isSelected ?
                Color(red: 0.0, green: 0.48, blue: 1.0) :
                Up2Colors.surface
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Up2Colors.border, lineWidth: 1)
            )
        }
    }
}

struct RSVPRow: View {
    let rsvp: RSVPData
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onStatusChange: (RSVPStatus) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Selection Checkbox
            Button(action: onToggleSelection) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? Color(red: 0.0, green: 0.48, blue: 1.0) : Up2Colors.textSecondary)
            }
            
            // User Avatar
            AsyncImage(url: URL(string: rsvp.userAvatar ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(Up2Colors.textSecondary)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            // User Details
            VStack(alignment: .leading, spacing: 4) {
                Text(rsvp.userName)
                    .font(Up2Typography.bodyMedium)
                    .foregroundColor(Up2Colors.textPrimary)
                
                Text("RSVP'd \(rsvp.formattedDate)")
                    .font(Up2Typography.caption)
                    .foregroundColor(Up2Colors.textSecondary)
            }
            
            Spacer()
            
            // Status Menu
            Menu {
                ForEach(RSVPStatus.allCases, id: \.self) { status in
                    Button(status.rawValue) {
                        onStatusChange(status)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(rsvp.status.rawValue)
                        .font(Up2Typography.caption)
                        .foregroundColor(statusColor)
                    
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(Up2Colors.textSecondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(statusColor.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Up2Colors.surface)
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch rsvp.status {
        case .confirmed:
            return .green
        case .pending:
            return .orange
        case .cancelled:
            return .red
        }
    }
}

struct RSVPRowSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Up2Colors.textSecondary.opacity(0.2))
                .frame(width: 24, height: 24)
            
            Circle()
                .fill(Up2Colors.textSecondary.opacity(0.2))
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Rectangle()
                    .fill(Up2Colors.textSecondary.opacity(0.2))
                    .frame(width: 120, height: 16)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Up2Colors.textSecondary.opacity(0.2))
                    .frame(width: 100, height: 12)
                    .cornerRadius(4)
            }
            
            Spacer()
            
            Rectangle()
                .fill(Up2Colors.textSecondary.opacity(0.2))
                .frame(width: 80, height: 24)
                .cornerRadius(8)
        }
        .padding()
        .background(Up2Colors.surface)
        .cornerRadius(12)
    }
}

struct MessageAttendeesSheet: View {
    let event: HostEvent
    let attendees: [RSVPData]
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @State private var isSending = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("Message Attendees")
                        .font(Up2Typography.heading2)
                        .foregroundColor(Up2Colors.textPrimary)
                    
                    Text("\(attendees.count) attendees selected")
                        .font(Up2Typography.bodyMedium)
                        .foregroundColor(Up2Colors.textSecondary)
                }
                
                // Message Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Message")
                        .font(Up2Typography.bodyMedium)
                        .foregroundColor(Up2Colors.textPrimary)
                    
                    TextEditor(text: $messageText)
                        .frame(minHeight: 120)
                        .padding(8)
                        .background(Up2Colors.surface)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Up2Colors.border, lineWidth: 1)
                        )
                }
                
                // Attendee List
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recipients")
                        .font(Up2Typography.bodyMedium)
                        .foregroundColor(Up2Colors.textPrimary)
                    
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(attendees, id: \.id) { attendee in
                                HStack {
                                    Text(attendee.userName)
                                        .font(Up2Typography.bodyMedium)
                                        .foregroundColor(Up2Colors.textPrimary)
                                    
                                    Spacer()
                                    
                                    Text(attendee.status.rawValue)
                                        .font(Up2Typography.caption)
                                        .foregroundColor(Up2Colors.textSecondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .frame(maxHeight: 150)
                }
                
                Spacer()
                
                // Send Button
                Button(action: sendMessage) {
                    HStack {
                        if isSending {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        }
                        
                        Text(isSending ? "Sending..." : "Send Message")
                            .font(Up2Typography.buttonMedium)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        messageText.isEmpty || isSending ?
                        Color.gray :
                        Color(red: 0.0, green: 0.48, blue: 1.0)
                    )
                    .cornerRadius(12)
                }
                .disabled(messageText.isEmpty || isSending)
            }
            .padding()
            .navigationTitle("Message Attendees")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Up2Colors.textSecondary)
                }
            }
        }
    }
    
    private func sendMessage() {
        isSending = true
        
        // Simulate sending message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isSending = false
            dismiss()
        }
    }
}

// MARK: - Supporting Types

enum RSVPFilter: String, CaseIterable {
    case all = "All"
    case confirmed = "Confirmed"
    case pending = "Pending"
    case cancelled = "Cancelled"
    
    var status: RSVPStatus? {
        switch self {
        case .all:
            return nil
        case .confirmed:
            return .confirmed
        case .pending:
            return .pending
        case .cancelled:
            return .cancelled
        }
    }
}

// MARK: - View Model Extension

extension EventRSVPViewModel {
    var confirmedCount: Int {
        rsvps.filter { $0.status == .confirmed }.count
    }
    
    var pendingCount: Int {
        rsvps.filter { $0.status == .pending }.count
    }
    
    var cancelledCount: Int {
        rsvps.filter { $0.status == .cancelled }.count
    }
    
    func countForFilter(_ filter: RSVPFilter) -> Int {
        if filter == .all {
            return rsvps.count
        } else {
            return rsvps.filter { $0.status == filter.status }.count
        }
    }
}

#Preview {
    EventRSVPView(event: HostEvent(
        id: UUID(),
        title: "Summer Beach Party",
        venueName: "Santa Monica Beach",
        date: Date(),
        rsvpCount: 45,
        price: 25.0,
        status: .upcoming,
        imageURL: nil
    ))
} 