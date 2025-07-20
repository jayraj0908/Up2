import SwiftUI

// MARK: - Trending Tab View
struct TrendingTabView: View {
    
    // MARK: - Environment
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject var appStateManager: AppStateManager
    
    // MARK: - State
    @State private var selectedTimeframe: TrendingTimeframe = .today
    @State private var showingTimeframePicker = false
    @State private var refreshing = false
    
    // MARK: - Mock Data
    private let trendingEvents = [
        TrendingEvent(id: "1", title: "Summer Music Festival", attendees: 1250, growth: 45, category: .music),
        TrendingEvent(id: "2", title: "Tech Conference 2024", attendees: 800, growth: 32, category: .technology),
        TrendingEvent(id: "3", title: "Art Gallery Opening", attendees: 450, growth: 28, category: .arts),
        TrendingEvent(id: "4", title: "Food & Wine Festival", attendees: 920, growth: 25, category: .food),
        TrendingEvent(id: "5", title: "Startup Pitch Night", attendees: 320, growth: 22, category: .business),
        TrendingEvent(id: "6", title: "Outdoor Movie Night", attendees: 680, growth: 18, category: .entertainment),
        TrendingEvent(id: "7", title: "Yoga in the Park", attendees: 200, growth: 15, category: .fitness),
        TrendingEvent(id: "8", title: "Local Farmers Market", attendees: 580, growth: 12, category: .community)
    ]
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Background - Consistent with host onboarding theme
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color(red: 0.1, green: 0.0, blue: 0.3),
                        Color(red: 0.3, green: 0.0, blue: 0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    navigationHeader
                    
                    // Content
                    mainContent
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Navigation Header
    private var navigationHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Trending")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Popular events in your area")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Time frame selector
                Button(action: { showingTimeframePicker = true }) {
                    HStack(spacing: 4) {
                        Text(selectedTimeframe.displayName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // Stats overview
            statsOverview
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Stats Overview
    private var statsOverview: some View {
        HStack(spacing: 0) {
            StatCard(title: "Total Events", value: "\(trendingEvents.count)", icon: "calendar.circle.fill", color: .blue)
            
            Divider()
                .frame(height: 40)
            
            StatCard(title: "Avg Growth", value: "+23%", icon: "chart.line.uptrend.xyaxis.circle.fill", color: .green)
            
            Divider()
                .frame(height: 40)
            
            StatCard(title: "Peak Interest", value: selectedTimeframe.peakTime, icon: "clock.circle.fill", color: .orange)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Top trending section
                topTrendingSection
                
                // All trending events
                allTrendingSection
                
                // Coming soon message
                comingSoonSection
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
    
    // MARK: - Top Trending Section
    private var topTrendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🔥 Top Trending")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let topEvent = trendingEvents.first {
                TopTrendingCard(event: topEvent) {
                    navigationCoordinator.navigate(to: .eventDetail(eventId: topEvent.id))
                }
            }
        }
    }
    
    // MARK: - All Trending Section
    private var allTrendingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Trending Events")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(Array(trendingEvents.enumerated()), id: \.element.id) { index, event in
                TrendingEventRow(event: event, rank: index + 1) {
                    navigationCoordinator.navigate(to: .eventDetail(eventId: event.id))
                }
            }
        }
    }
    
    // MARK: - Coming Soon Section
    private var comingSoonSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("Enhanced Analytics Coming Soon")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Epic 2 will bring real-time trending data, detailed analytics, and personalized trending recommendations.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button("Learn More") {
                navigationCoordinator.presentModal(.help)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle)
        }
        .padding(24)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .padding(.top, 20)
    }
    
    // MARK: - Helper Methods
    private func refreshTrendingEvents() async {
        refreshing = true
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        refreshing = false
    }
}

// MARK: - Supporting Types

struct TrendingEvent: Identifiable {
    let id: String
    let title: String
    let attendees: Int
    let growth: Int // percentage
    let category: TrendingCategory
}

enum TrendingTimeframe: String, CaseIterable {
    case today = "Today"
    case thisWeek = "This Week"
    case thisMonth = "This Month"
    
    var displayName: String { rawValue }
    
    var peakTime: String {
        switch self {
        case .today: return "6-8 PM"
        case .thisWeek: return "Fri-Sun"
        case .thisMonth: return "Weekends"
        }
    }
}

// MARK: - Trending Category Enum
enum TrendingCategory: String, CaseIterable {
    case music = "Music"
    case technology = "Technology"
    case arts = "Arts"
    case food = "Food"
    case business = "Business"
    case entertainment = "Entertainment"
    case fitness = "Fitness"
    case community = "Community"
    
    var icon: String {
        switch self {
        case .music: return "music.note"
        case .technology: return "laptopcomputer"
        case .arts: return "paintbrush"
        case .food: return "fork.knife"
        case .business: return "briefcase"
        case .entertainment: return "tv"
        case .fitness: return "figure.run"
        case .community: return "person.3"
        }
    }
    
    var color: Color {
        switch self {
        case .music: return .purple
        case .technology: return .blue
        case .arts: return .pink
        case .food: return .orange
        case .business: return .green
        case .entertainment: return .red
        case .fitness: return .cyan
        case .community: return .yellow
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct TopTrendingCard: View {
    let event: TrendingEvent
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 16) {
                // Header with rank
                HStack {
                    HStack(spacing: 8) {
                        Text("#1")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.red)
                            .clipShape(Capsule())
                        
                        Text("Most Popular")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    Text("+\(event.growth)%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
                
                // Event info
                HStack(spacing: 16) {
                    // Category icon
                    Image(systemName: event.category.icon)
                        .font(.title)
                        .foregroundColor(event.category.color)
                        .frame(width: 60, height: 60)
                        .background(event.category.color.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.title)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(event.category.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("\(event.attendees) interested")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                }
            }
            .padding(20)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct TrendingEventRow: View {
    let event: TrendingEvent
    let rank: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Rank
                Text("#\(rank)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                    .frame(width: 30)
                
                // Category icon
                Image(systemName: event.category.icon)
                    .font(.title3)
                    .foregroundColor(event.category.color)
                    .frame(width: 40, height: 40)
                    .background(event.category.color.opacity(0.1))
                    .clipShape(Circle())
                
                // Event info
                VStack(alignment: .leading, spacing: 2) {
                    Text(event.title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text("\(event.attendees) interested")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Growth indicator
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Text("+\(event.growth)%")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    
                    Text("growth")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct TimeframePickerView: View {
    @Binding var selectedTimeframe: TrendingTimeframe
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(TrendingTimeframe.allCases, id: \.self) { timeframe in
                    HStack {
                        Text(timeframe.displayName)
                            .font(.body)
                        
                        Spacer()
                        
                        if selectedTimeframe == timeframe {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedTimeframe = timeframe
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .navigationTitle("Trending Timeframe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
} 