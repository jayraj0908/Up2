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
    
    private let discoveryService = EventDiscoveryService.shared
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
        guard feedState == .idle else { return }
        
        feedState = .loading
        
        do {
            let request = createFeedRequest(page: 0)
            let response = try await discoveryService.generatePersonalizedFeed(request: request)
            
            feedState = .loaded(response.items)
            hasMoreEvents = response.hasMore
            lastUpdated = Date()
            currentPage = 0
            
        } catch {
            feedState = .error(error.localizedDescription)
        }
    }
    
    func refreshFeed() async {
        let currentItems = feedState.items
        feedState = currentItems.isEmpty ? .loading : .refreshing(currentItems)
        
        do {
            let request = createFeedRequest(page: 0)
            let response = try await discoveryService.refreshFeed(for: request)
            
            feedState = .loaded(response.items)
            hasMoreEvents = response.hasMore
            lastUpdated = Date()
            currentPage = 0
            
        } catch {
            feedState = .error(error.localizedDescription)
        }
    }
    
    func loadMoreIfNeeded() async {
        guard hasMoreEvents,
              case .loaded(let currentItems) = feedState,
              !currentItems.isEmpty else { return }
        
        feedState = .loadingMore(currentItems)
        
        do {
            let request = createFeedRequest(page: currentPage + 1)
            let response = try await discoveryService.loadMoreEvents(for: request)
            
            let allItems = currentItems + response.items
            feedState = .loaded(allItems)
            hasMoreEvents = response.hasMore
            currentPage += 1
            
        } catch {
            // Revert to previous state on error
            feedState = .loaded(currentItems)
        }
    }
    
    func applyFilter() async {
        await refreshFeed()
    }
    
    func applySorting() async {
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
    
    // MARK: - Computed Properties
    
    var hasActiveFilters: Bool {
        return currentFilter != .default
    }
    
    // MARK: - Private Methods
    
    private func createFeedRequest(page: Int) -> EventFeedRequest {
        // For dummy login, create a fallback user ID if none exists
        let userIdString = authService.currentUser?.id ?? "dummy-user-id"
        guard let userId = UUID(uuidString: userIdString) else {
            // If UUID creation fails, use a fallback UUID
            let fallbackUserId = UUID()
            return EventFeedRequest(
                userId: fallbackUserId,
                userLocation: currentLocation,
                userVibeTags: userProfile?.vibeTags.map { $0.rawValue } ?? [],
                friendIds: friendIds,
                filter: currentFilter,
                sortOption: currentSortOption,
                page: page,
                pageSize: 20
            )
        }
        
        return EventFeedRequest(
            userId: userId,
            userLocation: currentLocation,
            userVibeTags: userProfile?.vibeTags.map { $0.rawValue } ?? [],
            friendIds: friendIds,
            filter: currentFilter,
            sortOption: currentSortOption,
            page: page,
            pageSize: 20
        )
    }
    
    private func loadUserData() {
        // For dummy login, create a fallback user ID if none exists
        let userIdString = authService.currentUser?.id ?? "dummy-user-id"
        guard let userId = UUID(uuidString: userIdString) else { 
            // If UUID creation fails, use a fallback UUID and continue
            let fallbackUserId = UUID()
            Task {
                // Load user profile with fallback user
                do {
                    userProfile = try await profileService.getProfile(for: fallbackUserId)
                } catch {
                    // If profile loading fails, create a dummy profile
                    userProfile = ProfileData(
                        id: fallbackUserId,
                        name: "Demo User",
                        handle: "demo_user",
                        avatar: nil,
                        vibeTags: [.music, .social],
                        bio: "Demo user for testing"
                    )
                }
                friendIds = []
            }
            return 
        }
        
        Task {
            do {
                // Load user profile
                userProfile = try await profileService.getProfile(for: userId)
                
                // Load friend list (placeholder for now)
                // This would typically come from a friends/social service
                friendIds = []
                
            } catch {
                print("Error loading user data: \(error)")
            }
        }
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
                default:
                    break
                }
            }
        default:
            break
        }
    }
    
    // MARK: - Location Services
    
    private func setupLocationManager() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        
        updateLocationStatus()
    }
    
    func requestLocationPermission() {
        guard let locationManager = locationManager else { return }
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // Direct user to settings
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
    private func updateLocationStatus() {
        guard let locationManager = locationManager else { return }
        
        switch locationManager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            isLocationEnabled = true
            locationManager.startUpdatingLocation()
            if currentLocation != nil {
                locationDescription = "Current location"
            } else {
                locationDescription = "Getting location..."
            }
        case .denied, .restricted:
            isLocationEnabled = false
            locationDescription = "Location disabled"
            currentLocation = nil
        case .notDetermined:
            isLocationEnabled = false
            locationDescription = "Location permission needed"
            currentLocation = nil
        @unknown default:
            isLocationEnabled = false
            locationDescription = "Location unavailable"
            currentLocation = nil
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension EventFeedViewModel: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        Task { @MainActor in
            currentLocation = location
            isLocationEnabled = true
            locationDescription = "Current location"
            
            // Stop updating location to save battery
            manager.stopUpdatingLocation()
            
            // Refresh feed with new location
            await refreshFeed()
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
        Task { @MainActor in
            isLocationEnabled = false
            locationDescription = "Location error"
            currentLocation = nil
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task { @MainActor in
            updateLocationStatus()
            
            // Refresh feed when location permission changes
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                await refreshFeed()
            }
        }
    }
}

// MARK: - Feed State Helpers

extension EventFeedViewModel {
    var isLoading: Bool {
        feedState.isLoading
    }
    
    var errorMessage: String? {
        feedState.errorMessage
    }
    
    var isEmpty: Bool {
        switch feedState {
        case .empty:
            return true
        case .loaded(let items):
            return items.isEmpty
        default:
            return false
        }
    }
}

// MARK: - Mock Data for Development

#if DEBUG
extension EventFeedViewModel {
    static func createMockViewModel() -> EventFeedViewModel {
        let viewModel = EventFeedViewModel()
        
        // Create mock feed items
        let mockItems = [
            EventFeedItem(
                id: UUID(),
                event: Event(
                    hostId: UUID(),
                    title: "Beach Volleyball Tournament",
                    description: "Join us for an exciting tournament with great vibes!",
                    vibe: "energetic",
                    date: Date().addingTimeInterval(86400),
                    location: EventLocation(
                        name: "Manhattan Beach",
                        address: "2000 The Strand",
                        city: "Manhattan Beach",
                        state: "CA",
                        country: "USA",
                        zipCode: "90266",
                        latitude: 33.8847,
                        longitude: -118.4109
                    ),
                    capacity: 50,
                    price: 25.0
                ),
                host: EventHost(
                    id: UUID(),
                    name: "Alex Johnson",
                    handle: "alexvolleyball",
                    avatarUrl: nil,
                    vibeTags: ["energetic", "outdoorsy"],
                    isVerified: true
                ),
                score: 0.85,
                attendeeCount: 23,
                friendsAttending: [],
                isBookmarked: false,
                distanceFromUser: 2500.0
            ),
            EventFeedItem(
                id: UUID(),
                event: Event(
                    hostId: UUID(),
                    title: "Coffee & Code Meetup",
                    description: "Weekly gathering for developers to network and share ideas.",
                    vibe: "chill",
                    date: Date().addingTimeInterval(172800),
                    location: EventLocation(
                        name: "Local Coffee Shop",
                        address: "123 Main St",
                        city: "San Francisco",
                        state: "CA",
                        country: "USA",
                        zipCode: "94102",
                        latitude: 37.7749,
                        longitude: -122.4194
                    ),
                    capacity: 30,
                    price: nil
                ),
                host: EventHost(
                    id: UUID(),
                    name: "Sarah Chen",
                    handle: "sarahcodes",
                    avatarUrl: nil,
                    vibeTags: ["chill", "intellectual"],
                    isVerified: false
                ),
                score: 0.72,
                attendeeCount: 15,
                friendsAttending: [],
                isBookmarked: true,
                distanceFromUser: 5000.0
            )
        ]
        
        viewModel.feedState = .loaded(mockItems)
        viewModel.lastUpdated = Date()
        viewModel.isLocationEnabled = true
        viewModel.locationDescription = "Current location"
        
        return viewModel
    }
}
#endif 