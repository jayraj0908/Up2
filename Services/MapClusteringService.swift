import Foundation
import CoreLocation
import MapKit
import Combine

@MainActor
class MapClusteringService: ObservableObject {
    static let shared = MapClusteringService()
    
    // MARK: - Dependencies
    private let analyticsService = AnalyticsService.shared
    private let performanceService = AppPerformanceService.shared
    private let errorService = ErrorHandlingService.shared
    private let hapticService = HapticService.shared
    
    // MARK: - Configuration
    private let maxClusterRadius: Double = 1000 // meters
    private let minClusterSize = 2
    private let maxClusterSize = 50
    private let clusteringAlgorithm: ClusteringAlgorithm = .gridBased
    
    // MARK: - Published Properties
    @Published var isClusteringEnabled = true
    @Published var clusterCount: Int = 0
    @Published var lastClusteringTime: Date?
    
    // MARK: - Private Properties
    private var clusterCache: [String: [MapCluster]] = [:]
    private var clusteringStats = ClusteringStatistics()
    
    private init() {
        loadClusteringStatistics()
    }
    
    // MARK: - Public Interface
    
    /// Generate clusters for map events
    func generateClusters(
        events: [MapEvent],
        region: MKCoordinateRegion,
        zoomLevel: Double
    ) async throws -> [MapCluster] {
        
        let startTime = Date()
        
        do {
            // Track performance
            let result = try await performanceService.trackAPICall {
                try await performClustering(
                    events: events,
                    region: region,
                    zoomLevel: zoomLevel
                )
            }
            
            // Update statistics
            updateClusteringStatistics(
                eventCount: events.count,
                clusterCount: result.count,
                processingTime: Date().timeIntervalSince(startTime)
            )
            
            // Track analytics
            analyticsService.trackUserAction("map_clusters_generated", properties: [
                "event_count": events.count,
                "cluster_count": result.count,
                "processing_time": Date().timeIntervalSince(startTime),
                "zoom_level": zoomLevel,
                "algorithm": clusteringAlgorithm.rawValue
            ])
            
            return result
            
        } catch {
            errorService.handleSystemError(error, context: "MapClusteringService.generateClusters")
            throw error
        }
    }
    
    /// Get cached clusters for region
    func getCachedClusters(for region: MKCoordinateRegion) -> [MapCluster]? {
        let cacheKey = generateCacheKey(for: region)
        return clusterCache[cacheKey]
    }
    
    /// Clear cluster cache
    func clearClusterCache() {
        clusterCache.removeAll()
        analyticsService.trackUserAction("cluster_cache_cleared")
    }
    
    /// Get clustering statistics
    func getClusteringStatistics() -> ClusteringStatistics {
        return clusteringStats
    }
    
    /// Optimize clustering for performance
    func optimizeClustering(for devicePerformance: DevicePerformance) {
        switch devicePerformance {
        case .high:
            // Use more sophisticated algorithms
            break
        case .medium:
            // Use balanced algorithms
            break
        case .low:
            // Use simplified algorithms
            break
        }
        
        analyticsService.trackUserAction("clustering_optimized", properties: [
            "device_performance": devicePerformance.rawValue
        ])
    }
    
    // MARK: - Private Methods
    
    private func performClustering(
        events: [MapEvent],
        region: MKCoordinateRegion,
        zoomLevel: Double
    ) async throws -> [MapCluster] {
        
        // Filter events in region
        let eventsInRegion = filterEventsInRegion(events, region: region)
        
        // Apply clustering algorithm
        let clusters: [MapCluster]
        
        switch clusteringAlgorithm {
        case .gridBased:
            clusters = performGridBasedClustering(events: eventsInRegion, zoomLevel: zoomLevel)
        case .hierarchical:
            clusters = performHierarchicalClustering(events: eventsInRegion, zoomLevel: zoomLevel)
        case .densityBased:
            clusters = performDensityBasedClustering(events: eventsInRegion, zoomLevel: zoomLevel)
        }
        
        // Post-process clusters
        let processedClusters = postProcessClusters(clusters, zoomLevel: zoomLevel)
        
        // Cache results
        let cacheKey = generateCacheKey(for: region)
        clusterCache[cacheKey] = processedClusters
        
        clusterCount = processedClusters.count
        lastClusteringTime = Date()
        
        return processedClusters
    }
    
    private func filterEventsInRegion(_ events: [MapEvent], region: MKCoordinateRegion) -> [MapEvent] {
        return events.filter { event in
            let eventLocation = CLLocationCoordinate2D(
                latitude: event.coordinate.latitude,
                longitude: event.coordinate.longitude
            )
            
            return region.contains(eventLocation)
        }
    }
    
    private func performGridBasedClustering(
        events: [MapEvent],
        zoomLevel: Double
    ) -> [MapCluster] {
        
        var clusters: [MapCluster] = []
        let cellSize = calculateCellSize(for: zoomLevel)
        
        // Create grid cells
        var gridCells: [String: [MapEvent]] = [:]
        
        for event in events {
            let cellKey = getGridCellKey(for: event.coordinate, cellSize: cellSize)
            
            if gridCells[cellKey] == nil {
                gridCells[cellKey] = []
            }
            gridCells[cellKey]?.append(event)
        }
        
        // Create clusters from grid cells
        for (_, cellEvents) in gridCells {
            if cellEvents.count >= minClusterSize {
                let cluster = createCluster(from: cellEvents, algorithm: .gridBased)
                clusters.append(cluster)
            } else {
                // Add individual events as single-event clusters
                for event in cellEvents {
                    let cluster = MapCluster(
                        id: UUID(),
                        events: [event],
                        center: event.coordinate,
                        radius: 50, // Small radius for single events
                        algorithm: .gridBased
                    )
                    clusters.append(cluster)
                }
            }
        }
        
        return clusters
    }
    
    private func performHierarchicalClustering(
        events: [MapEvent],
        zoomLevel: Double
    ) -> [MapCluster] {
        
        var clusters: [MapCluster] = []
        let maxDistance = calculateMaxDistance(for: zoomLevel)
        
        // Start with each event as its own cluster
        var eventClusters = events.map { event in
            MapCluster(
                id: UUID(),
                events: [event],
                center: event.coordinate,
                radius: 50,
                algorithm: .hierarchical
            )
        }
        
        // Merge clusters iteratively
        while eventClusters.count > 1 {
            var merged = false
            
            for i in 0..<eventClusters.count {
                for j in (i+1)..<eventClusters.count {
                    let distance = calculateDistance(
                        eventClusters[i].center,
                        eventClusters[j].center
                    )
                    
                    if distance <= maxDistance {
                        // Merge clusters
                        let mergedCluster = mergeClusters(
                            eventClusters[i],
                            eventClusters[j]
                        )
                        
                        eventClusters.remove(at: j)
                        eventClusters.remove(at: i)
                        eventClusters.append(mergedCluster)
                        
                        merged = true
                        break
                    }
                }
                if merged { break }
            }
            
            if !merged { break }
        }
        
        return eventClusters
    }
    
    private func performDensityBasedClustering(
        events: [MapEvent],
        zoomLevel: Double
    ) -> [MapCluster] {
        
        var clusters: [MapCluster] = []
        let eps = calculateEps(for: zoomLevel)
        let minPts = minClusterSize
        
        var visited: Set<UUID> = []
        
        for event in events {
            if visited.contains(event.id) { continue }
            
            visited.insert(event.id)
            
            // Find neighbors
            let neighbors = findNeighbors(for: event, in: events, eps: eps)
            
            if neighbors.count >= minPts {
                // Start a new cluster
                var clusterEvents = [event] + neighbors
                visited.formUnion(neighbors.map { $0.id })
                
                // Expand cluster
                var i = 0
                while i < clusterEvents.count {
                    let currentEvent = clusterEvents[i]
                    let currentNeighbors = findNeighbors(for: currentEvent, in: events, eps: eps)
                    
                    for neighbor in currentNeighbors {
                        if !visited.contains(neighbor.id) {
                            visited.insert(neighbor.id)
                            clusterEvents.append(neighbor)
                        }
                    }
                    
                    i += 1
                }
                
                let cluster = createCluster(from: clusterEvents, algorithm: .densityBased)
                clusters.append(cluster)
            } else {
                // Single event cluster
                let cluster = MapCluster(
                    id: UUID(),
                    events: [event],
                    center: event.coordinate,
                    radius: 50,
                    algorithm: .densityBased
                )
                clusters.append(cluster)
            }
        }
        
        return clusters
    }
    
    private func createCluster(
        from events: [MapEvent],
        algorithm: ClusteringAlgorithm
    ) -> MapCluster {
        
        // Calculate cluster center
        let center = calculateClusterCenter(events: events)
        
        // Calculate cluster radius
        let radius = calculateClusterRadius(events: events, center: center)
        
        return MapCluster(
            id: UUID(),
            events: events,
            center: center,
            radius: radius,
            algorithm: algorithm
        )
    }
    
    private func mergeClusters(_ cluster1: MapCluster, _ cluster2: MapCluster) -> MapCluster {
        let allEvents = cluster1.events + cluster2.events
        let center = calculateClusterCenter(events: allEvents)
        let radius = calculateClusterRadius(events: allEvents, center: center)
        
        return MapCluster(
            id: UUID(),
            events: allEvents,
            center: center,
            radius: radius,
            algorithm: cluster1.algorithm
        )
    }
    
    private func calculateClusterCenter(events: [MapEvent]) -> CLLocationCoordinate2D {
        let totalLat = events.reduce(0) { $0 + $1.coordinate.latitude }
        let totalLon = events.reduce(0) { $0 + $1.coordinate.longitude }
        
        return CLLocationCoordinate2D(
            latitude: totalLat / Double(events.count),
            longitude: totalLon / Double(events.count)
        )
    }
    
    private func calculateClusterRadius(
        events: [MapEvent],
        center: CLLocationCoordinate2D
    ) -> Double {
        
        let maxDistance = events.map { event in
            calculateDistance(center, event.coordinate)
        }.max() ?? 0
        
        return maxDistance + 50 // Add buffer
    }
    
    private func calculateDistance(_ coord1: CLLocationCoordinate2D, _ coord2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2)
    }
    
    private func findNeighbors(
        for event: MapEvent,
        in events: [MapEvent],
        eps: Double
    ) -> [MapEvent] {
        
        return events.filter { otherEvent in
            otherEvent.id != event.id &&
            calculateDistance(event.coordinate, otherEvent.coordinate) <= eps
        }
    }
    
    private func calculateCellSize(for zoomLevel: Double) -> Double {
        // Cell size decreases with zoom level
        return maxClusterRadius / pow(2, zoomLevel - 10)
    }
    
    private func calculateMaxDistance(for zoomLevel: Double) -> Double {
        // Max distance decreases with zoom level
        return maxClusterRadius / pow(2, zoomLevel - 10)
    }
    
    private func calculateEps(for zoomLevel: Double) -> Double {
        // Eps decreases with zoom level
        return maxClusterRadius / pow(2, zoomLevel - 10)
    }
    
    private func getGridCellKey(
        for coordinate: CLLocationCoordinate2D,
        cellSize: Double
    ) -> String {
        
        let latCell = Int(coordinate.latitude / cellSize)
        let lonCell = Int(coordinate.longitude / cellSize)
        
        return "\(latCell),\(lonCell)"
    }
    
    private func generateCacheKey(for region: MKCoordinateRegion) -> String {
        let components = [
            String(format: "%.4f", region.center.latitude),
            String(format: "%.4f", region.center.longitude),
            String(format: "%.4f", region.span.latitudeDelta),
            String(format: "%.4f", region.span.longitudeDelta)
        ]
        
        return components.joined(separator: "|")
    }
    
    private func postProcessClusters(
        _ clusters: [MapCluster],
        zoomLevel: Double
    ) -> [MapCluster] {
        
        return clusters.map { cluster in
            // Limit cluster size for performance
            let limitedEvents = Array(cluster.events.prefix(maxClusterSize))
            
            return MapCluster(
                id: cluster.id,
                events: limitedEvents,
                center: cluster.center,
                radius: cluster.radius,
                algorithm: cluster.algorithm
            )
        }
    }
    
    private func updateClusteringStatistics(
        eventCount: Int,
        clusterCount: Int,
        processingTime: TimeInterval
    ) {
        clusteringStats.totalEvents += eventCount
        clusteringStats.totalClusters += clusterCount
        clusteringStats.totalProcessingTime += processingTime
        clusteringStats.averageProcessingTime = clusteringStats.totalProcessingTime / Double(clusteringStats.totalOperations)
        
        saveClusteringStatistics()
    }
    
    private func loadClusteringStatistics() {
        // Load from persistent storage
        // For now, start with default statistics
    }
    
    private func saveClusteringStatistics() {
        // Save to persistent storage
        // For now, just track in memory
    }
}

// MARK: - Supporting Types

struct MapCluster: Identifiable {
    let id: UUID
    let events: [MapEvent]
    let center: CLLocationCoordinate2D
    let radius: Double
    let algorithm: ClusteringAlgorithm
    
    var eventCount: Int {
        events.count
    }
    
    var isSingleEvent: Bool {
        events.count == 1
    }
    
    var primaryEvent: MapEvent? {
        events.first
    }
}

enum ClusteringAlgorithm: String, CaseIterable {
    case gridBased = "grid_based"
    case hierarchical = "hierarchical"
    case densityBased = "density_based"
}

enum DevicePerformance: String, CaseIterable {
    case high = "high"
    case medium = "medium"
    case low = "low"
}

struct ClusteringStatistics {
    var totalEvents: Int = 0
    var totalClusters: Int = 0
    var totalOperations: Int = 0
    var totalProcessingTime: TimeInterval = 0
    
    var averageProcessingTime: TimeInterval = 0
    var averageClusterSize: Double {
        totalClusters > 0 ? Double(totalEvents) / Double(totalClusters) : 0
    }
}

// MARK: - MapEvent Extension

extension MapEvent {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
} 