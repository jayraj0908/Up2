import SwiftUI

struct ForYouFeedView: View {
    @StateObject private var viewModel = EventFeedViewModel()
    @State private var showingFilterSheet = false
    @State private var showingSortSheet = false
    @State private var selectedEventItem: EventFeedItem?
    @State private var scrollOffset: CGFloat = 0
    @State private var isNavCollapsed = false
    
    var body: some View {
        NavigationView {
            ZStack {
                backgroundGradientView
                VStack(spacing: 0) {
                    ForYouHeaderView(
                        showingFilterSheet: $showingFilterSheet,
                        showingSortSheet: $showingSortSheet,
                        isCollapsed: isNavCollapsed
                    )
                    ForYouFeedContentView(
                        viewModel: viewModel,
                        selectedEventItem: $selectedEventItem,
                        scrollOffset: $scrollOffset
                    )
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheetView()
        }
        .sheet(isPresented: $showingSortSheet) {
            SortSheetView()
        }
        .sheet(item: $selectedEventItem) { item in
            EventDetailView(
                event: item.event,
                host: item.host
            )
        }
        .onAppear {
            Task {
                await viewModel.loadInitialFeed()
            }
        }
        .onChange(of: scrollOffset) { newOffset in
            withAnimation(.easeInOut(duration: 0.2)) {
                isNavCollapsed = newOffset > 50
            }
        }
    }

    private var backgroundGradientView: some View {
        Up2LiquidGlassBackground()
    }
}

// MARK: - ForYouHeaderView
struct ForYouHeaderView: View {
    @Binding var showingFilterSheet: Bool
    @Binding var showingSortSheet: Bool
    let isCollapsed: Bool
    
    var body: some View {
        VStack(spacing: isCollapsed ? Up2Spacing.sm : Up2Spacing.md) {
            if !isCollapsed {
                headerTitleView
            }
            headerActionButtonsView
        }
        .padding(.horizontal, Up2Spacing.lg)
        .padding(.top, isCollapsed ? Up2Spacing.md : Up2Spacing.xl)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(isCollapsed ? 0.8 : 0)
                .blur(radius: isCollapsed ? 10 : 0)
                .animation(.easeInOut(duration: 0.2), value: isCollapsed)
        )
        .scaleEffect(isCollapsed ? 0.9 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isCollapsed)
    }

    private var headerTitleView: some View {
        HStack {
            VStack(alignment: .leading, spacing: Up2Spacing.sm) {
                Text("For You")
                    .font(Up2Typography.heading1)
                    .foregroundColor(Up2Colors.textPrimary)
                
                Text("Discover events tailored to your interests")
                    .font(Up2Typography.bodySmall)
                    .foregroundColor(Up2Colors.textSecondary)
            }
            Spacer()
        }
    }
    
    private var headerActionButtonsView: some View {
        HStack(spacing: Up2Spacing.md) {
            Up2Button(
                "Filter",
                style: .secondary,
                action: {
                    showingFilterSheet = true
                }
            )
            
            Up2Button(
                "Sort",
                style: .secondary,
                action: {
                    showingSortSheet = true
                }
            )
            
            Spacer()
        }
    }
}

// MARK: - ForYouFeedContentView
struct ForYouFeedContentView: View {
    @ObservedObject var viewModel: EventFeedViewModel
    @Binding var selectedEventItem: EventFeedItem?
    @Binding var scrollOffset: CGFloat
    
    var body: some View {
        Group {
            switch viewModel.feedState {
            case .loading:
                loadingView
            case .loaded(let items):
                if items.isEmpty {
                    emptyStateView()
                } else {
                    feedListView(items: items)
    }
            case .error(let message):
                errorView(message: message)
            case .idle:
                loadingView
            case .refreshing(let items):
                if items.isEmpty {
                    emptyStateView()
                } else {
                    feedListView(items: items)
                }
            case .loadingMore(let items):
                feedListView(items: items)
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: Up2Spacing.xl) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Discovering events for you...")
                .font(Up2Typography.bodySmall)
                .foregroundColor(Up2Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Up2Colors.background)
    }

    private func feedListView(items: [EventFeedItem]) -> some View {
        ScrollView {
            LazyVStack(spacing: Up2Spacing.md) {
                ForEach(items) { item in
                    EventCardView(
                        feedItem: item,
                        onTap: {
                            selectedEventItem = item
                        },
                        onBookmark: {
                            Task {
                                await viewModel.toggleBookmark(for: item)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, Up2Spacing.lg)
            .padding(.bottom, Up2Spacing.xl)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                }
            )
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            scrollOffset = -value
        }
        .refreshable {
            await viewModel.refreshFeed()
        }
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: Up2Spacing.xl) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(Up2Colors.warning)
            
            Text("Something went wrong")
                .font(Up2Typography.heading2)
                .fontWeight(.semibold)
                .foregroundColor(Up2Colors.textInverse)
            
            Text(message)
                .font(Up2Typography.bodySmall)
                .foregroundColor(Up2Colors.textInverse.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Up2Spacing.xxl)
            
            Up2Button(
                "Try Again",
                style: .primary,
                action: {
                    Task {
                        await viewModel.refreshFeed()
                    }
                }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear) // Make background transparent
    }
    
    private func emptyStateView() -> some View {
        VStack(spacing: Up2Spacing.xl) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(Up2Colors.textSecondary)
            
            Text("No events found")
                .font(Up2Typography.heading2)
                .fontWeight(.semibold)
                .foregroundColor(Up2Colors.textInverse)
            
            Text("Check back later for new events in your area")
                .font(Up2Typography.bodySmall)
                .foregroundColor(Up2Colors.textInverse.opacity(0.8))
                .multilineTextAlignment(.center)
                .padding(.horizontal, Up2Spacing.xxl)
            
            Up2Button(
                "Refresh",
                style: .primary,
                action: {
                    Task {
                        await viewModel.refreshFeed()
                    }
                }
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Up2Colors.background)
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - FilterSheetView
struct FilterSheetView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Filter Options")
                    .font(Up2Typography.heading2)
                    .padding()
                Spacer()
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - SortSheetView
struct SortSheetView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Sort Options")
                    .font(Up2Typography.heading2)
                    .padding()
                        Spacer()
            }
            .navigationTitle("Sort")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - EventDetailSheetView
struct EventDetailSheetView: View {
    let eventItem: EventFeedItem
    
    var body: some View {
        NavigationView {
                VStack {
                Text("Event Details")
                    .font(Up2Typography.heading2)
                    .padding()
                Spacer()
            }
            .navigationTitle("Event")
            .navigationBarTitleDisplayMode(.inline)
        }
        }
    }

#Preview {
    ForYouFeedView()
} 