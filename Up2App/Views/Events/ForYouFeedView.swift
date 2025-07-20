import SwiftUI

struct ForYouFeedView: View {
    @StateObject private var viewModel = EventFeedViewModel()
    @State private var showingFilterSheet = false
    @State private var showingSortSheet = false
    @State private var selectedEventItem: EventFeedItem?
    
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
                    // Clean Instagram-style header
                    cleanHeaderSection
                    
                    // Feed content
                    feedContentSection
                }
            }
            .navigationBarHidden(true)
            .refreshable {
                await viewModel.refreshFeed()
            }
            .sheet(isPresented: $showingFilterSheet) {
                FilterSheetView(
                    filter: $viewModel.currentFilter,
                    onApply: {
                        Task {
                            await viewModel.applyFilter()
                        }
                    }
                )
            }
            .sheet(isPresented: $showingSortSheet) {
                SortSheetView(
                    sortOption: $viewModel.currentSortOption,
                    onApply: {
                        Task {
                            await viewModel.applySorting()
                        }
                    }
                )
            }
            .sheet(item: $selectedEventItem) { item in
                EventDetailView(feedItem: item)
            }
        }
        .onAppear {
            Task {
                await viewModel.loadInitialFeed()
            }
        }
    }
    
    private var cleanHeaderSection: some View {
        VStack(spacing: 0) {
            // Clean Instagram-style header
            HStack {
                // Logo/Brand
                HStack(spacing: 8) {
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                    
                    Text("For You")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Clean filter button
                Button(action: { showingFilterSheet = true }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title3)
                        .foregroundColor(.white)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.black)
            
            // Subtle separator
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 0.5)
        }
    }
    
    private var feedStatsView: some View {
        HStack {
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.caption)
                    .foregroundColor(.orange)
                
                Text("\(viewModel.feedState.items.count) personalized events")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let lastUpdated = viewModel.lastUpdated {
                Text("Updated \(formatRelativeTime(lastUpdated))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    private var feedContentSection: some View {
        Group {
            switch viewModel.feedState {
            case .idle:
                loadingView
            case .loading:
                loadingView
            case .loaded(let items), .refreshing(let items), .loadingMore(let items):
                feedScrollView(items: items)
            case .error(let message):
                errorView(message: message)
            case .empty:
                emptyStateView
            }
        }
    }
    
    private func feedScrollView(items: [EventFeedItem]) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(items, id: \.id) { item in
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
                    .onAppear {
                        // Load more when reaching near the end
                        if item.id == items.last?.id {
                            Task {
                                await viewModel.loadMoreIfNeeded()
                            }
                        }
                    }
                }
                
                // Load more indicator
                if case .loadingMore = viewModel.feedState {
                    loadMoreIndicator
                }
                
                // End of feed indicator
                if !viewModel.hasMoreEvents && !items.isEmpty {
                    endOfFeedView
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .refreshable {
            await viewModel.refreshFeed()
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Discovering events for you...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Something went wrong")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button("Try Again") {
                Task {
                    await viewModel.refreshFeed()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text("No events found")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Try adjusting your filters or check back later for new events in your area.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 12) {
                Button("Clear Filters") {
                    viewModel.clearFilters()
                    Task {
                        await viewModel.refreshFeed()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Enable Location") {
                    viewModel.requestLocationPermission()
                }
                .buttonStyle(.bordered)
                .opacity(viewModel.isLocationEnabled ? 0 : 1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private var loadMoreIndicator: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.8)
            
            Text("Loading more events...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
    }
    
    private var endOfFeedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle")
                .font(.title2)
                .foregroundColor(.green)
            
            Text("You're all caught up!")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("Check back later for new events")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 32)
    }
    
    // MARK: - Helper Functions
    
    private func formatRelativeTime(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.dateTimeStyle = .numeric
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Filter Sheet

struct FilterSheetView: View {
    @Binding var filter: EventFeedFilter
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var localFilter: EventFeedFilter
    
    init(filter: Binding<EventFeedFilter>, onApply: @escaping () -> Void) {
        self._filter = filter
        self.onApply = onApply
        self._localFilter = State(initialValue: filter.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            List {
                // Time range
                Section("When") {
                    ForEach(EventFeedFilter.TimeRange.allCases, id: \.self) { timeRange in
                        HStack {
                            Text(timeRange.displayName)
                            Spacer()
                            if localFilter.timeRange == timeRange {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            localFilter.timeRange = timeRange
                        }
                    }
                }
                
                // Price range
                Section("Price") {
                    ForEach(EventFeedFilter.PriceRange.allCases, id: \.self) { priceRange in
                        HStack {
                            Text(priceRange.displayName)
                            Spacer()
                            if localFilter.priceRange == priceRange {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            localFilter.priceRange = priceRange
                        }
                    }
                    
                    Toggle("Free events only", isOn: $localFilter.freeOnly)
                }
                
                // Event size
                Section("Event Size") {
                    ForEach(EventFeedFilter.AttendeeRange.allCases, id: \.self) { attendeeRange in
                        HStack {
                            Text(attendeeRange.displayName)
                            Spacer()
                            if localFilter.attendeeRange == attendeeRange {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            localFilter.attendeeRange = attendeeRange
                        }
                    }
                }
                
                // Social filters
                Section("Social") {
                    Toggle("Friends only", isOn: $localFilter.friendsOnly)
                }
                
                // Distance
                Section("Distance") {
                    VStack(alignment: .leading) {
                        Text("Within \(Int(localFilter.locationRadius / 1000)) km")
                            .font(.subheadline)
                        
                        Slider(
                            value: Binding(
                                get: { localFilter.locationRadius / 1000 },
                                set: { localFilter.locationRadius = $0 * 1000 }
                            ),
                            in: 1...100,
                            step: 1
                        )
                    }
                }
            }
            .navigationTitle("Filter Events")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        filter = localFilter
                        onApply()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Sort Sheet

struct SortSheetView: View {
    @Binding var sortOption: EventFeedSortOption
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                ForEach(EventFeedSortOption.allCases, id: \.self) { option in
                    HStack {
                        Image(systemName: option.systemImage)
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text(option.displayName)
                        
                        Spacer()
                        
                        if sortOption == option {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        sortOption = option
                        onApply()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Sort By")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Event Detail View (Epic D)

struct EventDetailView: View {
    let feedItem: EventFeedItem
    @Environment(\.dismiss) private var dismiss
    @State private var isRSVPed = false
    @State private var showingRSVPAlert = false
    @State private var showingShareSheet = false
    @StateObject private var checkoutService = StripeCheckoutService.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero Image Section
                    heroImageSection
                    
                    // Event Details Section
                    eventDetailsSection
                    
                    // RSVP Section
                    rsvpSection
                    
                    // Media Preview Section
                    mediaPreviewSection
                    
                    // Location Section
                    locationSection
                    
                    // Host Section
                    hostSection
                    
                    // Similar Events Section
                    similarEventsSection
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                            .foregroundColor(.white)
                            .frame(width: 32, height: 32)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .alert("RSVP Confirmed!", isPresented: $showingRSVPAlert) {
            Button("OK") { }
        } message: {
            Text("You're now RSVPed for this event. We'll send you a reminder!")
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(activityItems: [feedItem.event.title, "Check out this event on Up2!"])
        }
        .sheet(isPresented: $checkoutService.isCheckoutPresented) {
            StripeCheckoutModal(checkoutService: checkoutService)
        }
        .sheet(isPresented: $checkoutService.isPaymentSuccessful) {
            if let event = checkoutService.currentEvent {
                PaymentConfirmationView(event: event, checkoutService: checkoutService)
            }
        }
    }
    
    // MARK: - Hero Image Section
    private var heroImageSection: some View {
        ZStack(alignment: .bottomLeading) {
            // Event Image
            AsyncImage(url: URL(string: feedItem.event.mediaRefs.first ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [Color(red: 0.0, green: 0.48, blue: 1.0), Color(red: 0.0, green: 0.32, blue: 0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
            }
            .frame(height: 300)
            .clipped()
            
            // Gradient Overlay
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 300)
            
            // Event Info Overlay
            VStack(alignment: .leading, spacing: 8) {
                // Date and Time
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.white)
                    Text(formatEventDate(feedItem.event.date))
                        .foregroundColor(.white)
                        .font(.subheadline)
                    
                    Spacer()
                    
                    // Price Badge
                    Text(feedItem.event.formattedPrice)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(red: 0.0, green: 0.48, blue: 1.0))
                        .clipShape(Capsule())
                }
                
                // Title
                Text(feedItem.event.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                // Location
                HStack {
                    Image(systemName: "location")
                        .foregroundColor(.white)
                    Text(feedItem.event.location.name)
                        .foregroundColor(.white)
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Event Details Section
    private var eventDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Description
            VStack(alignment: .leading, spacing: 8) {
                Text("About This Event")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(feedItem.event.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineLimit(nil)
            }
            
            // Event Stats
            HStack(spacing: 24) {
                VStack {
                    Text("\(feedItem.attendeeCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Attending")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Text("5")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Friends")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let distance = feedItem.distanceFromUser {
                    VStack {
                        Text(String(format: "%.1f", distance))
                            .font(.title2)
                            .fontWeight(.bold)
                        Text("Miles")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
    }
    
    // MARK: - RSVP Section
    private var rsvpSection: some View {
        VStack(spacing: 16) {
            // Action Button - Buy Tickets for paid events, RSVP for free events
            Button(action: {
                if feedItem.event.isFree {
                    // Free event - RSVP
                    isRSVPed.toggle()
                    showingRSVPAlert = true
                } else {
                    // Paid event - Initiate Stripe checkout
                    checkoutService.initiateCheckout(for: feedItem.event)
                }
            }) {
                HStack {
                    Image(systemName: feedItem.event.isFree ? 
                          (isRSVPed ? "checkmark.circle.fill" : "calendar.badge.plus") :
                          "ticket.fill")
                        .font(.title3)
                    
                    Text(feedItem.event.isFree ? 
                         (isRSVPed ? "RSVP Confirmed" : "RSVP Now") :
                         "Buy Tickets")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    feedItem.event.isFree ? 
                    (isRSVPed ? Color.green : Color(red: 0.0, green: 0.48, blue: 1.0)) :
                    Color(red: 0.0, green: 0.48, blue: 1.0)
                )
                .cornerRadius(16)
            }
            .disabled(feedItem.event.isFree && isRSVPed)
            
            // Quick Actions
            HStack(spacing: 12) {
                Button(action: { showingShareSheet = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.1))
                    .cornerRadius(12)
                }
                
                Button(action: {}) {
                    HStack {
                        Image(systemName: "heart")
                        Text("Save")
                    }
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Media Preview Section
    private var mediaPreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Photos & Videos")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<5, id: \.self) { index in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(
                                colors: [Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.3), Color(red: 0.0, green: 0.32, blue: 0.8).opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 120, height: 120)
                            .overlay(
                                Image(systemName: index == 0 ? "video" : "photo")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Location")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
            
            HStack(spacing: 16) {
                // Map Preview
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "map")
                            .font(.title)
                            .foregroundColor(.secondary)
                    )
                
                // Location Details
                VStack(alignment: .leading, spacing: 8) {
                    Text(feedItem.event.location.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Get Directions")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                    
                    Spacer()
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Host Section
    private var hostSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Hosted by")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
            
            HStack(spacing: 16) {
                // Host Avatar
                Circle()
                    .fill(LinearGradient(
                        colors: [Color(red: 0.0, green: 0.48, blue: 1.0), Color(red: 0.0, green: 0.32, blue: 0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(String(feedItem.host.name.prefix(1)))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    )
                
                // Host Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(feedItem.host.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if feedItem.host.isVerified {
                        Text("Verified Host")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    
                    Text("Follow")
                        .font(.caption)
                        .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Similar Events Section
    private var similarEventsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Similar Events")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(0..<3, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 8) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(LinearGradient(
                                    colors: [Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.3), Color(red: 0.0, green: 0.32, blue: 0.8).opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 160, height: 100)
                                .overlay(
                                    Image(systemName: "calendar")
                                        .font(.title2)
                                        .foregroundColor(.white)
                                )
                            
                            Text("Similar Event \(index + 1)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .lineLimit(2)
                            
                            Text("Tomorrow")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 160)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
    }
    
    private func formatEventDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct EventDetailRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    ForYouFeedView()
} 