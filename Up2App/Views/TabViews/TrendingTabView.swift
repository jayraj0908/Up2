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
    @State private var trendingEvents: [TrendingEvent] = []
    @State private var trendingStats: TrendingStats?
    @State private var errorMessage: String?
    
    // MARK: - Services
    private let trendingService = TrendingService.shared
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Liquid Glass Background
                Up2LiquidGlassBackground()
                
                VStack(spacing: 0) {
                    // Header
                    navigationHeader
                    
                    // Content
                    mainContent
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                loadTrendingData()
            }
            .refreshable {
                await refreshTrendingData()
            }
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
            StatCard(
                title: "Total Events", 
                value: "\(trendingStats?.totalEvents ?? 0)", 
                icon: "calendar.circle.fill", 
                color: .blue
            )
            
            Divider()
                .frame(height: 40)
            
            StatCard(
                title: "Avg Growth", 
                value: "+\(Int((trendingStats?.averageGrowth ?? 0) * 100))%", 
                icon: "chart.line.uptrend.xyaxis.circle.fill", 
                color: .green
            )
            
            Divider()
                .frame(height: 40)
            
            StatCard(
                title: "Peak Interest", 
                value: trendingStats?.peakTime ?? selectedTimeframe.peakTime, 
                icon: "clock.circle.fill", 
                color: .orange
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        Group {
            if trendingService.isLoading {
                loadingView
            } else if let errorMessage = errorMessage {
                errorView(message: errorMessage)
            } else if trendingEvents.isEmpty {
                emptyStateView
            } else {
                trendingEventsView
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading trending events...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            Text("Failed to load trending events")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                loadTrendingData()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(24)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 48))
                .foregroundColor(.orange)
            
            VStack(spacing: 8) {
                Text("No Trending Events")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Check back later for trending events in your area.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(24)
    }
    
    private var trendingEventsView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Top trending section
                topTrendingSection
                
                // All trending events
                allTrendingSection
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
    
    // MARK: - Helper Methods
    private func loadTrendingData() {
        Task {
            await refreshTrendingData()
        }
    }
    
    private func refreshTrendingData() async {
        refreshing = true
        errorMessage = nil
        
        do {
            async let eventsTask = trendingService.fetchTrendingEvents(timeframe: selectedTimeframe)
            async let statsTask = trendingService.fetchTrendingStats(timeframe: selectedTimeframe)
            
            let (events, stats) = try await (eventsTask, statsTask)
            
            trendingEvents = events
            trendingStats = stats
        } catch {
            errorMessage = error.localizedDescription
        }
        
        refreshing = false
    }
}

// MARK: - Supporting Types

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