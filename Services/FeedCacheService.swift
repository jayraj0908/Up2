import Foundation
import CoreData
import Combine

@MainActor
class FeedCacheService: ObservableObject {
    static let shared = FeedCacheService()
    
    // MARK: - Dependencies
    private let securityService = SecurityService.shared
    private let performanceService = AppPerformanceService.shared
    private let analyticsService = AnalyticsService.shared
    private let errorService = ErrorHandlingService.shared
    
    // MARK: - Core Data Stack
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "FeedCache")
        container.loadPersistentStores { _, error in
            if let error = error {
                self.errorService.handleSystemError(error, context: "FeedCacheService")
            }
        }
        return container
    }()
    
    private var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: - Cache Configuration
    private let maxCacheSize: Int = 1000 // Maximum number of cached items
    private let cacheExpirationTime: TimeInterval = 3600 // 1 hour
    private let backgroundRefreshInterval: TimeInterval = 900 // 15 minutes
    
    // MARK: - Published Properties
    @Published var isOfflineMode = false
    @Published var cacheHitRate: Double = 0.0
    @Published var lastRefreshTime: Date?
    
    // MARK: - Private Properties
    private var backgroundRefreshTimer: Timer?
    private var cacheStats = CacheStatistics()
    
    private init() {
        setupBackgroundRefresh()
        loadCacheStatistics()
    }
    
    // MARK: - Public Interface
    
    /// Cache feed response with encryption
    func cacheFeedResponse(_ response: EventFeedResponse, for request: EventFeedRequest) async throws {
        let startTime = Date()
        
        do {
            // Generate cache key
            let cacheKey = generateCacheKey(for: request)
            
            // Encrypt response data
            let responseData = try JSONEncoder().encode(response)
            let encryptedData = try securityService.encrypt(responseData, withKey: "feed_cache_key")
            
            // Save to Core Data
            try await saveToCoreData(
                key: cacheKey,
                data: encryptedData,
                timestamp: Date(),
                request: request
            )
            
            // Update statistics
            updateCacheStatistics(hit: false, responseTime: Date().timeIntervalSince(startTime))
            
            // Track analytics
            analyticsService.trackUserAction("feed_cached", properties: [
                "cache_key": cacheKey,
                "item_count": response.items.count,
                "response_time": Date().timeIntervalSince(startTime)
            ])
            
            // Performance tracking
            performanceService.trackAPICall {
                // Cache operation completed
            }
            
        } catch {
            errorService.handleSystemError(error, context: "FeedCacheService.cacheFeedResponse")
            throw error
        }
    }
    
    /// Retrieve cached feed response
    func getCachedFeedResponse(for request: EventFeedRequest) async throws -> EventFeedResponse? {
        let startTime = Date()
        
        do {
            let cacheKey = generateCacheKey(for: request)
            
            // Check if cache entry exists and is valid
            guard let cacheEntry = try await getCacheEntry(for: cacheKey),
                  !isCacheExpired(cacheEntry.timestamp) else {
                updateCacheStatistics(hit: false, responseTime: Date().timeIntervalSince(startTime))
                return nil
            }
            
            // Decrypt cached data
            let decryptedData = try securityService.decrypt(cacheEntry.data, withKey: "feed_cache_key")
            let response = try JSONDecoder().decode(EventFeedResponse.self, from: decryptedData)
            
            // Update statistics
            updateCacheStatistics(hit: true, responseTime: Date().timeIntervalSince(startTime))
            
            // Track analytics
            analyticsService.trackUserAction("feed_cache_hit", properties: [
                "cache_key": cacheKey,
                "response_time": Date().timeIntervalSince(startTime),
                "cache_age": Date().timeIntervalSince(cacheEntry.timestamp)
            ])
            
            return response
            
        } catch {
            errorService.handleSystemError(error, context: "FeedCacheService.getCachedFeedResponse")
            return nil
        }
    }
    
    /// Clear cache for specific request or all cache
    func clearCache(for request: EventFeedRequest? = nil) async throws {
        do {
            if let request = request {
                let cacheKey = generateCacheKey(for: request)
                try await deleteCacheEntry(for: cacheKey)
            } else {
                try await clearAllCache()
            }
            
            analyticsService.trackUserAction("feed_cache_cleared", properties: [
                "cache_scope": request != nil ? "specific" : "all"
            ])
            
        } catch {
            errorService.handleSystemError(error, context: "FeedCacheService.clearCache")
            throw error
        }
    }
    
    /// Get offline feed data
    func getOfflineFeedData() async throws -> [EventFeedItem] {
        do {
            let offlineItems = try await getOfflineFeedItems()
            return offlineItems
        } catch {
            errorService.handleSystemError(error, context: "FeedCacheService.getOfflineFeedData")
            throw error
        }
    }
    
    /// Check if offline mode should be enabled
    func checkOfflineMode() async {
        // This would typically check network connectivity
        // For now, we'll use a simple implementation
        isOfflineMode = false // TODO: Implement network detection
    }
    
    // MARK: - Private Methods
    
    private func generateCacheKey(for request: EventFeedRequest) -> String {
        let components = [
            request.userId.uuidString,
            request.userLocation?.coordinate.latitude.description ?? "nil",
            request.userLocation?.coordinate.longitude.description ?? "nil",
            request.userVibeTags.joined(separator: ","),
            request.filter.description,
            request.sortOption.rawValue,
            "\(request.page)",
            "\(request.pageSize)"
        ]
        
        let keyString = components.joined(separator: "|")
        return securityService.generateHash(from: keyString)
    }
    
    private func saveToCoreData(key: String, data: Data, timestamp: Date, request: EventFeedRequest) async throws {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    // Check if entry already exists
                    let fetchRequest: NSFetchRequest<FeedCacheEntry> = FeedCacheEntry.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "cacheKey == %@", key)
                    
                    let existingEntries = try self.context.fetch(fetchRequest)
                    
                    let entry: FeedCacheEntry
                    if let existingEntry = existingEntries.first {
                        entry = existingEntry
                    } else {
                        entry = FeedCacheEntry(context: self.context)
                        entry.cacheKey = key
                    }
                    
                    entry.cachedData = data
                    entry.timestamp = timestamp
                    entry.userId = request.userId
                    entry.page = Int32(request.page)
                    entry.pageSize = Int32(request.pageSize)
                    
                    try self.context.save()
                    continuation.resume()
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func getCacheEntry(for key: String) async throws -> (data: Data, timestamp: Date)? {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<FeedCacheEntry> = FeedCacheEntry.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "cacheKey == %@", key)
                    fetchRequest.fetchLimit = 1
                    
                    let entries = try self.context.fetch(fetchRequest)
                    
                    if let entry = entries.first,
                       let data = entry.cachedData,
                       let timestamp = entry.timestamp {
                        continuation.resume(returning: (data, timestamp))
                    } else {
                        continuation.resume(returning: nil)
                    }
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func deleteCacheEntry(for key: String) async throws {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<FeedCacheEntry> = FeedCacheEntry.fetchRequest()
                    fetchRequest.predicate = NSPredicate(format: "cacheKey == %@", key)
                    
                    let entries = try self.context.fetch(fetchRequest)
                    entries.forEach { self.context.delete($0) }
                    
                    try self.context.save()
                    continuation.resume()
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func clearAllCache() async throws {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<FeedCacheEntry> = FeedCacheEntry.fetchRequest()
                    let entries = try self.context.fetch(fetchRequest)
                    
                    entries.forEach { self.context.delete($0) }
                    try self.context.save()
                    
                    continuation.resume()
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func getOfflineFeedItems() async throws -> [EventFeedItem] {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let fetchRequest: NSFetchRequest<FeedCacheEntry> = FeedCacheEntry.fetchRequest()
                    fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
                    fetchRequest.fetchLimit = 100 // Limit offline items
                    
                    let entries = try self.context.fetch(fetchRequest)
                    var offlineItems: [EventFeedItem] = []
                    
                    for entry in entries {
                        if let data = entry.cachedData {
                            do {
                                let decryptedData = try self.securityService.decrypt(data, withKey: "feed_cache_key")
                                let response = try JSONDecoder().decode(EventFeedResponse.self, from: decryptedData)
                                offlineItems.append(contentsOf: response.items)
                            } catch {
                                // Skip invalid entries
                                continue
                            }
                        }
                    }
                    
                    continuation.resume(returning: offlineItems)
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func isCacheExpired(_ timestamp: Date) -> Bool {
        Date().timeIntervalSince(timestamp) > cacheExpirationTime
    }
    
    private func updateCacheStatistics(hit: Bool, responseTime: TimeInterval) {
        cacheStats.totalRequests += 1
        if hit {
            cacheStats.hits += 1
        }
        cacheStats.totalResponseTime += responseTime
        
        cacheHitRate = Double(cacheStats.hits) / Double(cacheStats.totalRequests)
        
        // Save statistics
        saveCacheStatistics()
    }
    
    private func loadCacheStatistics() {
        // Load from UserDefaults or other persistent storage
        if let data = UserDefaults.standard.data(forKey: "feed_cache_stats"),
           let stats = try? JSONDecoder().decode(CacheStatistics.self, from: data) {
            cacheStats = stats
            cacheHitRate = Double(cacheStats.hits) / Double(cacheStats.totalRequests)
        }
    }
    
    private func saveCacheStatistics() {
        if let data = try? JSONEncoder().encode(cacheStats) {
            UserDefaults.standard.set(data, forKey: "feed_cache_stats")
        }
    }
    
    private func setupBackgroundRefresh() {
        backgroundRefreshTimer = Timer.scheduledTimer(withTimeInterval: backgroundRefreshInterval, repeats: true) { _ in
            Task {
                await self.performBackgroundRefresh()
            }
        }
    }
    
    private func performBackgroundRefresh() async {
        // Implement background refresh logic
        // This would typically refresh popular feeds in the background
        analyticsService.trackUserAction("background_refresh_performed")
    }
}

// MARK: - Cache Statistics

private struct CacheStatistics: Codable {
    var totalRequests: Int = 0
    var hits: Int = 0
    var totalResponseTime: TimeInterval = 0
    
    var averageResponseTime: TimeInterval {
        totalRequests > 0 ? totalResponseTime / Double(totalRequests) : 0
    }
}

// MARK: - Core Data Model

@objc(FeedCacheEntry)
public class FeedCacheEntry: NSManagedObject {
    @NSManaged public var cacheKey: String
    @NSManaged public var cachedData: Data?
    @NSManaged public var timestamp: Date?
    @NSManaged public var userId: UUID
    @NSManaged public var page: Int32
    @NSManaged public var pageSize: Int32
}

extension FeedCacheEntry {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<FeedCacheEntry> {
        return NSFetchRequest<FeedCacheEntry>(entityName: "FeedCacheEntry")
    }
} 