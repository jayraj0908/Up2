import Foundation
import SwiftUI
import CoreLocation
import Combine

@MainActor
class EventFeedViewModel: NSObject, ObservableObject {
    @Published var feedState: EventFeedState = .idle
    @Published var currentFilter: EventFeedFilter = .default
    @Published var currentSortOption: EventFeedSortOption = .relevance
    @Published var isLocationEnabled = false
    @Published var locationDescription = "Location off"
    @Published var lastUpdated: Date?
    @Published var hasMoreEvents = true
    
    private let eventService = EventService.shared
    private let authService = SupabaseAuthService.shared
    private let profileService = ProfileService.shared
    
    private var locationManager: CLLocationManager?
    private var currentLocation: CLLocation?
    private var currentPage = 0
    private var cancellables = Set<AnyCancellable>()
    
    // User profile data
    private var userProfile: ProfileData?
    private var friendIds: [UUID] = []
    
    override init() {
        super.init()
        setupLocationManager()
        loadUserData()
    }
    
    // MARK: - Public Interface
    
    func loadInitialFeed() async {
        guard case .idle = feedState else { return }
        
        feedState = .loading
        
        do {
            print("🔄 Loading initial feed...")
            
            // Fetch real events from Supabase
            var events = try await eventService.fetchPublicEvents(location: "Los Angeles")
            print("📅 Fetched \(events.count) events from Supabase")
            
            // If no events found, create sample events
            if events.isEmpty {
                print("⚠️ No events found in database, creating sample events...")
                try await createSampleEvents()
                events = try await eventService.fetchPublicEvents(location: "Los Angeles")
                print("📅 After creating samples: \(events.count) events")
            }
            
            // Fetch host profiles for all events
            let hostIds = Array(Set(events.map { $0.hostId }))
            print("👥 Fetching profiles for \(hostIds.count) hosts")
            let hostProfiles = try await fetchHostProfiles(hostIds: hostIds)
            print("✅ Fetched \(hostProfiles.count) host profiles")
            
            // Convert events to feed items with real host data
            let feedItems = events.compactMap { event -> EventFeedItem? in
                guard let hostProfile = hostProfiles.first(where: { $0.id == event.hostId }) else {
                    print("⚠️ No host profile found for event: \(event.title)")
                    // Create a fallback host profile
                    let fallbackHost = EventHost(
                        id: event.hostId,
                        name: "Unknown Host",
                        handle: "@unknown",
                        avatarUrl: nil,
                        vibeTags: [],
                        isVerified: false
                    )
                    
                    return EventFeedItem(
                        id: event.id,
                        event: event,
                        host: fallbackHost,
                        score: 0.5,
                        attendeeCount: 0,
                        friendsAttending: [],
                        isBookmarked: false,
                        distanceFromUser: calculateDistanceFromUser(event: event)
                    )
                }
                
                return EventFeedItem(
                    id: event.id,
                    event: event,
                    host: EventHost(
                        id: event.hostId,
                        name: hostProfile.name,
                        handle: hostProfile.handle,
                        avatarUrl: hostProfile.avatar,
                        vibeTags: hostProfile.vibeTags,
                        isVerified: hostProfile.isCurator
                    ),
                    score: calculateEventScore(event: event, hostProfile: hostProfile),
                    attendeeCount: 0, // Will be implemented with RSVP service
                    friendsAttending: [],
                    isBookmarked: false,
                    distanceFromUser: calculateDistanceFromUser(event: event)
                )
            }
            
            print("✅ Created \(feedItems.count) feed items")
            feedState = .loaded(feedItems)
            hasMoreEvents = false // For now, load all events at once
            lastUpdated = Date()
            currentPage = 0
            
        } catch {
            print("❌ Error loading feed: \(error)")
            print("🔍 Error details: \(error.localizedDescription)")
            
            // Provide a more user-friendly error message
            let errorMessage = getErrorMessage(for: error)
            feedState = .error(errorMessage)
        }
    }
    
    func refreshFeed() async {
        let currentItems = feedState.items
        feedState = currentItems.isEmpty ? .loading : .refreshing(currentItems)
        
        do {
            // Fetch real events from Supabase
            let events = try await eventService.fetchPublicEvents(location: "Los Angeles")
            
            // Fetch host profiles for all events
            let hostIds = Array(Set(events.map { $0.hostId }))
            let hostProfiles = try await fetchHostProfiles(hostIds: hostIds)
            
            // Convert events to feed items with real host data
            let feedItems = events.compactMap { event -> EventFeedItem? in
                guard let hostProfile = hostProfiles.first(where: { $0.id == event.hostId }) else {
                    return nil
                }
                
                return EventFeedItem(
                    id: event.id,
                    event: event,
                    host: EventHost(
                        id: event.hostId,
                        name: hostProfile.name,
                        handle: hostProfile.handle,
                        avatarUrl: hostProfile.avatar,
                        vibeTags: hostProfile.vibeTags,
                        isVerified: hostProfile.isCurator
                    ),
                    score: calculateEventScore(event: event, hostProfile: hostProfile),
                    attendeeCount: 0, // Will be implemented with RSVP service
                    friendsAttending: [],
                    isBookmarked: false,
                    distanceFromUser: calculateDistanceFromUser(event: event)
                )
            }
            
            feedState = .loaded(feedItems)
            lastUpdated = Date()
            
        } catch {
            feedState = .error(error.localizedDescription)
        }
    }
    
    func loadMoreEvents() async {
        guard hasMoreEvents && feedState.isLoaded else { return }
        
        // For now, we load all events at once, so no pagination needed
        hasMoreEvents = false
    }
    
    func applyFilter() async {
        // Apply current filter to events
        // This would filter the existing events based on currentFilter
        // For now, just refresh the feed
        await refreshFeed()
    }
    
    func applySorting() async {
        // Apply current sort option to events
        // This would sort the existing events based on currentSortOption
        // For now, just refresh the feed
        await refreshFeed()
    }
    
    func clearFilters() {
        currentFilter = .default
        currentSortOption = .relevance
    }
    
    func toggleBookmark(for item: EventFeedItem) async {
        // Update the item locally first for immediate UI feedback
        updateItemBookmarkStatus(item.id, isBookmarked: !item.isBookmarked)
        
        // TODO: Implement bookmark API call
        // This would typically call a bookmark service
        print("Bookmark toggled for event: \(item.event.title)")
    }
    
    func createSampleEvents() async {
        do {
            print("🔄 Creating sample events...")
            try await eventService.createSampleEvents()
            print("✅ Sample events created successfully")
            
            // Reload the feed to show the new events
            await loadInitialFeed()
        } catch {
            print("❌ Failed to create sample events: \(error)")
            // Don't update feedState here, just log the error
        }
    }
    
    // MARK: - Computed Properties
    
    var hasActiveFilters: Bool {
        return currentFilter != .default
    }
    
    // MARK: - Private Methods
    
    private func loadUserData() {
        Task {
            if let currentUser = authService.currentUser {
                userProfile = try? await profileService.getProfile(for: currentUser.id)
                // Load friend IDs if needed
                friendIds = []
            }
        }
    }
    
    private func fetchHostProfiles(hostIds: [UUID]) async throws -> [ProfileData] {
        var profiles: [ProfileData] = []
        
        for hostId in hostIds {
            if let profile = try? await profileService.getProfile(for: hostId) {
                profiles.append(profile)
            }
        }
        
        return profiles
    }
    
    private func calculateEventScore(event: Event, hostProfile: ProfileData) -> Double {
        var score: Double = 0.0
        
        // Base score from event properties
        score += 0.3 // Base score
        
        // Time relevance (closer events get higher scores)
        let timeUntilEvent = event.startTime.timeIntervalSinceNow
        if timeUntilEvent > 0 {
            let daysUntilEvent = timeUntilEvent / (24 * 60 * 60)
            let timeScore = max(0, 1.0 - (daysUntilEvent / 30)) // 30 days max
            score += timeScore * 0.2
        }
        
        // Host verification bonus
        if hostProfile.isCurator {
            score += 0.1
        }
        
        // Vibe tag matching (if user has profile)
        if let userProfile = userProfile {
            let userTags = Set(userProfile.vibeTags.map { $0.rawValue })
            let eventTags = Set(event.tags)
            let matchingTags = userTags.intersection(eventTags)
            let tagScore = Double(matchingTags.count) / Double(max(userTags.count, 1))
            score += tagScore * 0.2
        }
        
        // Price consideration (free events get slight boost)
        if event.price == nil || event.price == 0 {
            score += 0.05
        }
        
        return min(1.0, score)
    }
    
    private func calculateDistanceFromUser(event: Event) -> Double? {
        guard let userLocation = currentLocation else { return nil }
        
        // For now, we'll use a default location for the event
        // In a real implementation, this would use the event's actual coordinates
        let eventLocation = CLLocation(latitude: 37.7749, longitude: -122.4194) // Default to SF
        return userLocation.distance(from: eventLocation)
    }
    
    private func updateItemBookmarkStatus(_ itemId: UUID, isBookmarked: Bool) {
        switch feedState {
        case .loaded(var items), .refreshing(var items), .loadingMore(var items):
            if let index = items.firstIndex(where: { $0.id == itemId }) {
                let updatedItem = EventFeedItem(
                    id: items[index].id,
                    event: items[index].event,
                    host: items[index].host,
                    score: items[index].score,
                    attendeeCount: items[index].attendeeCount,
                    friendsAttending: items[index].friendsAttending,
                    isBookmarked: isBookmarked,
                    distanceFromUser: items[index].distanceFromUser
                )
                items[index] = updatedItem
                
                switch feedState {
                case .loaded:
                    feedState = .loaded(items)
                case .refreshing:
                    feedState = .refreshing(items)
                case .loadingMore:
                    feedState = .loadingMore(items)
                case .idle, .loading, .error:
                    break
                }
            }
        default:
            break
        }
    }
    
    private func getErrorMessage(for error: Error) -> String {
        if let eventError = error as? EventError {
            return eventError.localizedDescription
        } else if let profileError = error as? ProfileError {
            return profileError.localizedDescription
        } else {
            // Check for specific decoding errors
            let errorString = error.localizedDescription
            if errorString.contains("data couldn't be read") {
                return "Unable to load events. Please try again later."
            } else if errorString.contains("network") {
                return "Network connection issue. Please check your internet connection."
            } else {
                return "Something went wrong. Please try again."
            }
        }
    }
    
    // MARK: - Location Services
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationPermissionPublic() {
        requestLocationPermission()
    }
    
    private func requestLocationPermission() {
        locationManager?.requestWhenInUseAuthorization()
    }
    
    private func startLocationUpdates() {
        locationManager?.startUpdatingLocation()
            }
    
    private func stopLocationUpdates() {
        locationManager?.stopUpdatingLocation()
    }
    
    private func updateLocationDescription() {
        if let location = currentLocation {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let placemark = placemarks?.first {
                    let city = placemark.locality ?? "Unknown"
                    let state = placemark.administrativeArea ?? ""
                    self.locationDescription = "\(city), \(state)"
            } else {
                    self.locationDescription = "Location on"
                }
            }
        } else {
            locationDescription = "Location off"
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension EventFeedViewModel: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            currentLocation = location
            updateLocationDescription()
            
            // Update location-based filtering if needed
            if isLocationEnabled {
                // Could update feed based on new location
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
        Task { @MainActor in
            locationDescription = "Location error"
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                isLocationEnabled = true
                startLocationUpdates()
            case .denied, .restricted:
                isLocationEnabled = false
                stopLocationUpdates()
            case .notDetermined:
                isLocationEnabled = false
                requestLocationPermission()
            @unknown default:
                isLocationEnabled = false
            }
        }
    }
}

// MARK: - EventFeedState

enum EventFeedState {
    case idle
    case loading
    case refreshing([EventFeedItem])
    case loadingMore([EventFeedItem])
    case loaded([EventFeedItem])
    case error(String)
    
    var items: [EventFeedItem] {
        switch self {
        case .idle, .loading, .error:
            return []
        case .refreshing(let items), .loadingMore(let items), .loaded(let items):
            return items
        }
    }
    
    var isLoading: Bool {
        switch self {
        case .loading, .refreshing, .loadingMore:
            return true
        default:
            return false
        }
    }
    
    var isLoaded: Bool {
        switch self {
        case .loaded:
            return true
        default:
            return false
        }
    }
    
    var isEmpty: Bool {
        switch self {
        case .loaded(let items):
            return items.isEmpty
        default:
            return false
        }
    }
}

// MARK: - EventFeedFilter

enum EventFeedFilter {
    case all
    case today
    case thisWeek
    case thisMonth
    case free
    case paid
    
    static var `default`: EventFeedFilter { .all }
    
    var displayName: String {
        switch self {
        case .all: return "All Events"
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .free: return "Free"
        case .paid: return "Paid"
        }
    }
}

// MARK: - EventFeedSortOption

enum EventFeedSortOption: CaseIterable {
    case relevance
    case date
    case distance
    case popularity
    
    static var allCases: [EventFeedSortOption] {
        return [.relevance, .date, .distance, .popularity]
    }
    
    var displayName: String {
        switch self {
        case .relevance: return "Relevance"
        case .date: return "Date"
        case .distance: return "Distance"
        case .popularity: return "Popularity"
        }
    }
    
    var systemImage: String {
        switch self {
        case .relevance: return "star"
        case .date: return "calendar"
        case .distance: return "location"
        case .popularity: return "flame"
        }
    }
}

// MARK: - EventFeedItem

struct EventFeedItem: Identifiable {
    let id: UUID
    let event: Event
    let host: EventHost
    let score: Double
    let attendeeCount: Int
    let friendsAttending: [UUID]
    let isBookmarked: Bool
    let distanceFromUser: Double?
}

// MARK: - EventHost

struct EventHost: Identifiable {
    let id: UUID
    let name: String
    let handle: String
    let avatarUrl: String?
    let vibeTags: [VibeTag]
    let isVerified: Bool
} 