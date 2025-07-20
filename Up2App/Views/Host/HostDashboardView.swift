import SwiftUI

struct HostDashboardView: View {
    @StateObject private var viewModel = HostDashboardViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0
    @State private var showingEventAnalytics = false
    @State private var selectedEventForAnalytics: HostEvent?
    @State private var showingCreateEvent = false
    @State private var showingEventRSVP: HostEvent?
    @State private var showingEventEdit: HostEvent?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Stats
                headerStats
                
                // Tab Selector
                tabSelector
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    // My Events Tab
                    myEventsTab
                        .tag(0)
                    
                    // RSVPs Tab
                    rsvpsTab
                        .tag(1)
                    
                    // Analytics Tab
                    analyticsTab
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(Up2Colors.background.ignoresSafeArea())
            .navigationTitle("Host Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Up2Colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create Event") {
                        showingCreateEvent = true
                    }
                    .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                }
            }
            .sheet(isPresented: $showingEventAnalytics) {
                if let event = selectedEventForAnalytics {
                    EventAnalyticsView(event: event)
                }
            }
            .sheet(isPresented: $showingCreateEvent) {
                EventCreationView()
                    .onDisappear {
                        // Refresh dashboard data after event creation
                        Task {
                            await viewModel.loadDashboardData()
                        }
                    }
            }
            .sheet(item: $showingEventRSVP) { event in
                EventRSVPView(event: event)
            }
            .sheet(item: $showingEventEdit) { event in
                EventEditView(event: event)
                    .onDisappear {
                        // Refresh dashboard data after event editing
                        Task {
                            await viewModel.loadDashboardData()
                        }
                    }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadDashboardData()
            }
        }
    }
    
    // MARK: - Header Stats
    private var headerStats: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                // Total Events
                HostStatCard(
                    title: "Total Events",
                    value: "\(viewModel.totalEvents)",
                    icon: "calendar",
                    color: Color(red: 0.0, green: 0.48, blue: 1.0)
                )
                
                // Active Events
                HostStatCard(
                    title: "Active",
                    value: "\(viewModel.activeEvents)",
                    icon: "play.circle",
                    color: Color.green
                )
                
                // Total RSVPs
                HostStatCard(
                    title: "Total RSVPs",
                    value: "\(viewModel.totalRSVPs)",
                    icon: "person.3",
                    color: Color.orange
                )
            }
            
            // Quick Actions
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Create Event",
                    icon: "plus.circle",
                    action: { showingCreateEvent = true }
                )
                
                QuickActionButton(
                    title: "View Analytics",
                    icon: "chart.bar",
                    action: { selectedTab = 2 }
                )
                
                QuickActionButton(
                    title: "Manage RSVPs",
                    icon: "person.2",
                    action: { selectedTab = 1 }
                )
            }
        }
        .padding()
        .background(Up2Colors.surface)
    }
    
    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(["My Events", "RSVPs", "Analytics"], id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        selectedTab = ["My Events", "RSVPs", "Analytics"].firstIndex(of: tab) ?? 0
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tab)
                            .font(Up2Typography.buttonMedium)
                            .foregroundColor(selectedTab == ["My Events", "RSVPs", "Analytics"].firstIndex(of: tab) ? 
                                           Color(red: 0.0, green: 0.48, blue: 1.0) : Up2Colors.textSecondary)
                        
                        Rectangle()
                            .fill(selectedTab == ["My Events", "RSVPs", "Analytics"].firstIndex(of: tab) ? 
                                 Color(red: 0.0, green: 0.48, blue: 1.0) : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
        .background(Up2Colors.surface)
    }
    
    // MARK: - My Events Tab
    private var myEventsTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.isLoading {
                    ForEach(0..<3, id: \.self) { _ in
                        EventCardSkeleton()
                    }
                } else if viewModel.myEvents.isEmpty {
                    emptyStateView(
                        icon: "calendar.badge.plus",
                        title: "No Events Yet",
                        message: "Create your first event to get started!",
                        actionTitle: "Create Event",
                        action: { showingCreateEvent = true }
                    )
                } else {
                    ForEach(viewModel.myEvents, id: \.id) { event in
                        HostEventCard(
                            event: event,
                            onEdit: { showingEventEdit = event },
                            onDelete: { viewModel.deleteEvent(event) },
                            onViewRSVPs: { showingEventRSVP = event },
                            onViewAnalytics: {
                                selectedEventForAnalytics = event
                                showingEventAnalytics = true
                            }
                        )
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - RSVPs Tab
    private var rsvpsTab: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                if viewModel.isLoading {
                    ForEach(0..<3, id: \.self) { _ in
                        RSVPCardSkeleton()
                    }
                } else if viewModel.recentRSVPs.isEmpty {
                    emptyStateView(
                        icon: "person.3",
                        title: "No RSVPs Yet",
                        message: "RSVPs will appear here once people start joining your events!",
                        actionTitle: "Create Event",
                        action: { showingCreateEvent = true }
                    )
                } else {
                    ForEach(viewModel.recentRSVPs, id: \.id) { rsvp in
                        RSVPCard(rsvp: rsvp)
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Analytics Tab
    private var analyticsTab: some View {
        ScrollView {
            LazyVStack(spacing: 20) {
                // Event Performance Chart
                VStack(alignment: .leading, spacing: 12) {
                    Text("Event Performance")
                        .font(Up2Typography.heading3)
                        .foregroundColor(Up2Colors.textPrimary)
                    
                    EventPerformanceChart(data: viewModel.analyticsData)
                        .frame(height: 200)
                }
                .padding()
                .background(Up2Colors.surface)
                .cornerRadius(12)
                
                // Key Metrics
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    HostMetricCard(
                        title: "Avg. RSVPs",
                        value: "\(viewModel.averageRSVPs)",
                        change: "+12%",
                        isPositive: true
                    )
                    
                    HostMetricCard(
                        title: "Event Rating",
                        value: "4.8",
                        change: "+0.2",
                        isPositive: true
                    )
                    
                    HostMetricCard(
                        title: "Completion Rate",
                        value: "87%",
                        change: "-3%",
                        isPositive: false
                    )
                    
                    HostMetricCard(
                        title: "Revenue",
                        value: "$2,450",
                        change: "+18%",
                        isPositive: true
                    )
                }
                
                // Top Performing Events
                VStack(alignment: .leading, spacing: 12) {
                    Text("Top Performing Events")
                        .font(Up2Typography.heading3)
                        .foregroundColor(Up2Colors.textPrimary)
                    
                    ForEach(viewModel.topEvents, id: \.id) { event in
                        TopEventRow(event: event)
                    }
                }
                .padding()
                .background(Up2Colors.surface)
                .cornerRadius(12)
            }
            .padding()
        }
    }
    
    // MARK: - Empty State View
    private func emptyStateView(icon: String, title: String, message: String, actionTitle: String, action: @escaping () -> Void) -> some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(Up2Colors.textSecondary)
            
            Text(title)
                .font(Up2Typography.heading2)
                .foregroundColor(Up2Colors.textPrimary)
            
            Text(message)
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2Colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button(actionTitle, action: action)
                .font(Up2Typography.buttonMedium)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(red: 0.0, green: 0.48, blue: 1.0))
                .cornerRadius(8)
        }
        .padding(40)
    }
}

// MARK: - Supporting Components

struct HostStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(Up2Typography.heading2)
                .fontWeight(.bold)
                .foregroundColor(Up2Colors.textPrimary)
            
            Text(title)
                .font(Up2Typography.caption)
                .foregroundColor(Up2Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Up2Colors.background)
        .cornerRadius(12)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                
                Text(title)
                    .font(Up2Typography.caption)
                    .foregroundColor(Up2Colors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Up2Colors.background)
            .cornerRadius(8)
        }
    }
}

struct HostEventCard: View {
    let event: HostEvent
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onViewRSVPs: () -> Void
    let onViewAnalytics: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Event Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(Up2Typography.heading3)
                        .foregroundColor(Up2Colors.textPrimary)
                    
                    Text(event.venueName)
                        .font(Up2Typography.bodyMedium)
                        .foregroundColor(Up2Colors.textSecondary)
                }
                
                Spacer()
                
                StatusBadge(status: event.status)
            }
            
            // Event Details
            HStack(spacing: 16) {
                DetailItem(icon: "calendar", text: event.formattedDate)
                DetailItem(icon: "person.3", text: "\(event.rsvpCount) RSVPs")
                DetailItem(icon: "dollarsign.circle", text: event.formattedPrice)
            }
            
            // Action Buttons
            HStack(spacing: 12) {
                Button("Edit") {
                    onEdit()
                }
                .font(Up2Typography.buttonSmall)
                .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.1))
                .cornerRadius(6)
                
                Button("Analytics") {
                    onViewAnalytics()
                }
                .font(Up2Typography.buttonSmall)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.green)
                .cornerRadius(6)
                
                Button("RSVPs") {
                    onViewRSVPs()
                }
                .font(Up2Typography.buttonSmall)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(red: 0.0, green: 0.48, blue: 1.0))
                .cornerRadius(6)
                
                Spacer()
                
                Button("Delete") {
                    onDelete()
                }
                .font(Up2Typography.buttonSmall)
                .foregroundColor(.red)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding()
        .background(Up2Colors.surface)
        .cornerRadius(12)
    }
}

struct StatusBadge: View {
    let status: EventStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(Up2Typography.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch status {
        case .upcoming:
            return Color(red: 0.0, green: 0.48, blue: 1.0)
        case .active:
            return Color.green
        case .completed:
            return Color.gray
        case .cancelled:
            return Color.red
        }
    }
}

struct DetailItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(Up2Colors.textSecondary)
            
            Text(text)
                .font(Up2Typography.caption)
                .foregroundColor(Up2Colors.textSecondary)
        }
    }
}

struct RSVPCard: View {
    let rsvp: RSVPData
    
    var body: some View {
        HStack(spacing: 12) {
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
            
            // RSVP Details
            VStack(alignment: .leading, spacing: 4) {
                Text(rsvp.userName)
                    .font(Up2Typography.bodyMedium)
                    .foregroundColor(Up2Colors.textPrimary)
                
                Text(rsvp.eventTitle)
                    .font(Up2Typography.caption)
                    .foregroundColor(Up2Colors.textSecondary)
                
                Text("RSVP'd \(rsvp.formattedDate)")
                    .font(Up2Typography.caption)
                    .foregroundColor(Up2Colors.textTertiary)
            }
            
            Spacer()
            
            // RSVP Status
            Text(rsvp.status.rawValue)
                .font(Up2Typography.caption)
                .foregroundColor(rsvp.status == .confirmed ? .green : .orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background((rsvp.status == .confirmed ? Color.green : Color.orange).opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Up2Colors.surface)
        .cornerRadius(12)
    }
}

struct EventPerformanceChart: View {
    let data: [AnalyticsDataPoint]
    
    var body: some View {
        // Simple bar chart implementation
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(data, id: \.label) { point in
                VStack {
                    Text("\(point.value)")
                        .font(Up2Typography.caption)
                        .foregroundColor(Up2Colors.textSecondary)
                    
                    Rectangle()
                        .fill(Color(red: 0.0, green: 0.48, blue: 1.0))
                        .frame(width: 30, height: CGFloat(point.value) * 2)
                        .cornerRadius(4)
                    
                    Text(point.label)
                        .font(Up2Typography.caption)
                        .foregroundColor(Up2Colors.textSecondary)
                }
            }
        }
    }
}

struct HostMetricCard: View {
    let title: String
    let value: String
    let change: String
    let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Up2Typography.caption)
                .foregroundColor(Up2Colors.textSecondary)
            
            Text(value)
                .font(Up2Typography.heading3)
                .fontWeight(.bold)
                .foregroundColor(Up2Colors.textPrimary)
            
            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                    .font(.caption)
                    .foregroundColor(isPositive ? .green : .red)
                
                Text(change)
                    .font(Up2Typography.caption)
                    .foregroundColor(isPositive ? .green : .red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Up2Colors.surface)
        .cornerRadius(12)
    }
}

struct TopEventRow: View {
    let event: TopEvent
    
    var body: some View {
        HStack(spacing: 12) {
            // Event Image
            AsyncImage(url: URL(string: event.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Up2Colors.textSecondary.opacity(0.2))
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            
            // Event Details
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(Up2Typography.bodyMedium)
                    .foregroundColor(Up2Colors.textPrimary)
                
                Text("\(event.rsvpCount) RSVPs • \(event.rating)★")
                    .font(Up2Typography.caption)
                    .foregroundColor(Up2Colors.textSecondary)
            }
            
            Spacer()
            
            // Revenue
            Text(event.formattedRevenue)
                .font(Up2Typography.bodyMedium)
                .fontWeight(.semibold)
                .foregroundColor(Color.green)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Skeleton Views
struct EventCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Rectangle()
                    .fill(Up2Colors.textSecondary.opacity(0.2))
                    .frame(width: 120, height: 20)
                    .cornerRadius(4)
                
                Spacer()
                
                Rectangle()
                    .fill(Up2Colors.textSecondary.opacity(0.2))
                    .frame(width: 80, height: 20)
                    .cornerRadius(4)
            }
            
            HStack(spacing: 16) {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle()
                        .fill(Up2Colors.textSecondary.opacity(0.2))
                        .frame(height: 16)
                        .cornerRadius(4)
                }
            }
            
            HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    Rectangle()
                        .fill(Up2Colors.textSecondary.opacity(0.2))
                        .frame(height: 32)
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Up2Colors.surface)
        .cornerRadius(12)
    }
}

struct RSVPCardSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Up2Colors.textSecondary.opacity(0.2))
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Rectangle()
                    .fill(Up2Colors.textSecondary.opacity(0.2))
                    .frame(width: 100, height: 16)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Up2Colors.textSecondary.opacity(0.2))
                    .frame(width: 150, height: 12)
                    .cornerRadius(4)
            }
            
            Spacer()
            
            Rectangle()
                .fill(Up2Colors.textSecondary.opacity(0.2))
                .frame(width: 60, height: 24)
                .cornerRadius(8)
        }
        .padding()
        .background(Up2Colors.surface)
        .cornerRadius(12)
    }
}

#Preview {
    HostDashboardView()
} 