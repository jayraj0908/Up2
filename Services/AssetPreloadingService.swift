import Foundation
import SwiftUI
import Combine

// MARK: - Asset Preloading Models

struct AssetPreloadRequest {
    let assetId: String
    let assetType: AssetType
    let priority: AssetPriority
    let url: URL?
    let localPath: String?
    let estimatedSize: Int64
    let isRequired: Bool
    let cachePolicy: CachePolicy
    
    enum AssetType {
        case image
        case video
        case audio
        case data
        case font
    }
    
    enum AssetPriority {
        case critical
        case high
        case medium
        case low
    }
    
    enum CachePolicy {
        case memory
        case disk
        case both
        case none
    }
}

struct AssetPreloadResult {
    let assetId: String
    let success: Bool
    let loadTime: TimeInterval
    let size: Int64
    let cacheHit: Bool
    let error: AssetPreloadError?
    
    enum AssetPreloadError: Error {
        case networkError
        case invalidURL
        case fileNotFound
        case insufficientMemory
        case timeout
        case cancelled
    }
}

struct AssetPreloadMetrics {
    let totalAssets: Int
    let loadedAssets: Int
    let failedAssets: Int
    let totalLoadTime: TimeInterval
    let averageLoadTime: TimeInterval
    let cacheHitRate: Double
    let memoryUsage: Int64
    let networkUsage: Int64
}

// MARK: - Asset Preloading Service

@MainActor
class AssetPreloadingService: ObservableObject {
    static let shared = AssetPreloadingService()
    
    // MARK: - Dependencies
    private let performanceService = AppPerformanceService.shared
    private let analyticsService = AnalyticsService.shared
    private let errorService = ErrorHandlingService.shared
    private let hapticService = HapticService.shared
    private let networkService: NetworkConnectivityService
    
    // MARK: - Properties
    @Published var preloadProgress: Double = 0.0
    @Published var isPreloading = false
    @Published var currentMetrics: AssetPreloadMetrics?
    @Published var preloadResults: [AssetPreloadResult] = []
    
    private var preloadQueue: [AssetPreloadRequest] = []
    private var activePreloads: [String: Task<Void, Never>] = [:]
    private var assetCache: NSCache<NSString, AnyObject> = NSCache()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private let maxConcurrentPreloads = 3
    private let preloadTimeout: TimeInterval = 10.0
    private let maxMemoryUsage: Int64 = 50 * 1024 * 1024 // 50MB
    private let cacheSizeLimit: Int64 = 100 * 1024 * 1024 // 100MB
    
    // MARK: - Initialization
    private init() {
        setupAssetCache()
        setupNetworkMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Start asset preloading for splash screen
    func startSplashScreenPreloading() async {
        await MainActor.run {
            isPreloading = true
            preloadProgress = 0.0
            preloadResults.removeAll()
            
            // Create preload queue for splash screen
            createSplashScreenPreloadQueue()
            
            // Start preloading
            Task {
                await performPreloading()
            }
        }
    }
    
    /// Add asset to preload queue
    func addAssetToPreloadQueue(_ request: AssetPreloadRequest) {
        preloadQueue.append(request)
        preloadQueue.sort { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    /// Preload specific asset
    func preloadAsset(_ request: AssetPreloadRequest) async -> AssetPreloadResult {
        let startTime = Date()
        
        do {
            // Check cache first
            if let cachedAsset = getCachedAsset(for: request.assetId) {
                return AssetPreloadResult(
                    assetId: request.assetId,
                    success: true,
                    loadTime: Date().timeIntervalSince(startTime),
                    size: getAssetSize(cachedAsset),
                    cacheHit: true,
                    error: nil
                )
            }
            
            // Load asset based on type
            let asset = try await loadAsset(request)
            
            // Cache asset if needed
            if shouldCacheAsset(request) {
                cacheAsset(asset, for: request.assetId, policy: request.cachePolicy)
            }
            
            let loadTime = Date().timeIntervalSince(startTime)
            
            return AssetPreloadResult(
                assetId: request.assetId,
                success: true,
                loadTime: loadTime,
                size: getAssetSize(asset),
                cacheHit: false,
                error: nil
            )
            
        } catch {
            let loadTime = Date().timeIntervalSince(startTime)
            
            return AssetPreloadResult(
                assetId: request.assetId,
                success: false,
                loadTime: loadTime,
                size: 0,
                cacheHit: false,
                error: mapError(error)
            )
        }
    }
    
    /// Get cached asset
    func getCachedAsset(for assetId: String) -> AnyObject? {
        return assetCache.object(forKey: assetId as NSString)
    }
    
    /// Clear asset cache
    func clearAssetCache() {
        assetCache.removeAllObjects()
        
        analyticsService.trackUserAction("asset_cache_cleared")
    }
    
    /// Get preload metrics
    func getPreloadMetrics() -> AssetPreloadMetrics {
        let totalAssets = preloadResults.count
        let loadedAssets = preloadResults.filter { $0.success }.count
        let failedAssets = totalAssets - loadedAssets
        let totalLoadTime = preloadResults.reduce(0) { $0 + $1.loadTime }
        let averageLoadTime = totalAssets > 0 ? totalLoadTime / Double(totalAssets) : 0
        let cacheHitRate = totalAssets > 0 ? Double(preloadResults.filter { $0.cacheHit }.count) / Double(totalAssets) : 0
        let memoryUsage = getCurrentMemoryUsage()
        let networkUsage = preloadResults.filter { !$0.cacheHit }.reduce(0) { $0 + $1.size }
        
        return AssetPreloadMetrics(
            totalAssets: totalAssets,
            loadedAssets: loadedAssets,
            failedAssets: failedAssets,
            totalLoadTime: totalLoadTime,
            averageLoadTime: averageLoadTime,
            cacheHitRate: cacheHitRate,
            memoryUsage: memoryUsage,
            networkUsage: networkUsage
        )
    }
    
    // MARK: - Private Methods
    
    private func setupAssetCache() {
        assetCache.totalCostLimit = Int(maxMemoryUsage)
        assetCache.countLimit = 100
    }
    
    private func setupNetworkMonitoring() {
        // This would integrate with NetworkConnectivityService
        // For now, we'll handle network conditions in the preloading logic
    }
    
    private func createSplashScreenPreloadQueue() {
        preloadQueue.removeAll()
        
        // Add critical splash screen assets
        preloadQueue.append(AssetPreloadRequest(
            assetId: "splash_logo",
            assetType: .image,
            priority: .critical,
            url: nil,
            localPath: "logo_no_bg",
            estimatedSize: 1024 * 1024, // 1MB
            isRequired: true,
            cachePolicy: .both
        ))
        
        preloadQueue.append(AssetPreloadRequest(
            assetId: "splash_background",
            assetType: .image,
            priority: .high,
            url: nil,
            localPath: "splash_background",
            estimatedSize: 2 * 1024 * 1024, // 2MB
            isRequired: false,
            cachePolicy: .memory
        ))
        
        preloadQueue.append(AssetPreloadRequest(
            assetId: "app_fonts",
            assetType: .font,
            priority: .high,
            url: nil,
            localPath: "fonts",
            estimatedSize: 512 * 1024, // 512KB
            isRequired: true,
            cachePolicy: .both
        ))
        
        // Sort by priority
        preloadQueue.sort { $0.priority.rawValue > $1.priority.rawValue }
    }
    
    private func performPreloading() async {
        let totalAssets = preloadQueue.count
        var loadedAssets = 0
        
        for request in preloadQueue {
            // Check if we should continue based on network conditions
            if !shouldContinuePreloading() {
                break
            }
            
            // Start preloading asset
            let task = Task {
                let result = await preloadAsset(request)
                
                await MainActor.run {
                    preloadResults.append(result)
                    loadedAssets += 1
                    preloadProgress = Double(loadedAssets) / Double(totalAssets)
                    
                    // Track preload result
                    analyticsService.trackUserAction("asset_preloaded", properties: [
                        "asset_id": result.assetId,
                        "success": result.success,
                        "load_time": result.loadTime,
                        "cache_hit": result.cacheHit,
                        "size": result.size
                    ])
                    
                    // Handle errors
                    if !result.success {
                        errorService.handleAssetPreloadError(result.error, assetId: result.assetId)
                    }
                }
            }
            
            activePreloads[request.assetId] = task
            
            // Wait for completion or timeout
            do {
                try await withTimeout(seconds: preloadTimeout) {
                    await task.value
                }
            } catch {
                task.cancel()
            }
            
            // Remove from active preloads
            activePreloads.removeValue(forKey: request.assetId)
        }
        
        await MainActor.run {
            isPreloading = false
            currentMetrics = getPreloadMetrics()
            
            // Track completion
            analyticsService.trackUserAction("asset_preloading_completed", properties: [
                "total_assets": totalAssets,
                "loaded_assets": loadedAssets,
                "success_rate": Double(loadedAssets) / Double(totalAssets)
            ])
            
            hapticService.successNotification()
        }
    }
    
    private func loadAsset(_ request: AssetPreloadRequest) async throws -> AnyObject {
        // Check memory usage before loading
        if getCurrentMemoryUsage() > maxMemoryUsage {
            throw AssetPreloadResult.AssetPreloadError.insufficientMemory
        }
        
        switch request.assetType {
        case .image:
            return try await loadImageAsset(request)
        case .video:
            return try await loadVideoAsset(request)
        case .audio:
            return try await loadAudioAsset(request)
        case .data:
            return try await loadDataAsset(request)
        case .font:
            return try await loadFontAsset(request)
        }
    }
    
    private func loadImageAsset(_ request: AssetPreloadRequest) async throws -> UIImage {
        if let localPath = request.localPath {
            guard let image = UIImage(named: localPath) else {
                throw AssetPreloadResult.AssetPreloadError.fileNotFound
            }
            return image
        } else if let url = request.url {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else {
                throw AssetPreloadResult.AssetPreloadError.networkError
            }
            return image
        } else {
            throw AssetPreloadResult.AssetPreloadError.invalidURL
        }
    }
    
    private func loadVideoAsset(_ request: AssetPreloadRequest) async throws -> Data {
        if let localPath = request.localPath {
            guard let url = Bundle.main.url(forResource: localPath, withExtension: nil) else {
                throw AssetPreloadResult.AssetPreloadError.fileNotFound
            }
            return try Data(contentsOf: url)
        } else if let url = request.url {
            let (data, _) = try await URLSession.shared.data(from: url)
            return data
        } else {
            throw AssetPreloadResult.AssetPreloadError.invalidURL
        }
    }
    
    private func loadAudioAsset(_ request: AssetPreloadRequest) async throws -> Data {
        // Similar to video asset loading
        return try await loadVideoAsset(request)
    }
    
    private func loadDataAsset(_ request: AssetPreloadRequest) async throws -> Data {
        // Similar to video asset loading
        return try await loadVideoAsset(request)
    }
    
    private func loadFontAsset(_ request: AssetPreloadRequest) async throws -> Data {
        // Similar to video asset loading
        return try await loadVideoAsset(request)
    }
    
    private func getCachedAsset(for assetId: String) -> AnyObject? {
        return assetCache.object(forKey: assetId as NSString)
    }
    
    private func cacheAsset(_ asset: AnyObject, for assetId: String, policy: AssetPreloadRequest.CachePolicy) {
        switch policy {
        case .memory, .both:
            let cost = getAssetSize(asset)
            assetCache.setObject(asset, forKey: assetId as NSString, cost: Int(cost))
        case .disk:
            // Implement disk caching
            break
        case .none:
            break
        }
    }
    
    private func shouldCacheAsset(_ request: AssetPreloadRequest) -> Bool {
        return request.cachePolicy != .none
    }
    
    private func getAssetSize(_ asset: AnyObject) -> Int64 {
        if let image = asset as? UIImage {
            return Int64(image.jpegData(compressionQuality: 1.0)?.count ?? 0)
        } else if let data = asset as? Data {
            return Int64(data.count)
        }
        return 0
    }
    
    private func shouldContinuePreloading() -> Bool {
        // Check network conditions, memory usage, etc.
        return getCurrentMemoryUsage() < maxMemoryUsage
    }
    
    private func getCurrentMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        } else {
            return 0
        }
    }
    
    private func mapError(_ error: Error) -> AssetPreloadResult.AssetPreloadError {
        if error is URLError {
            return .networkError
        } else if error is AssetPreloadResult.AssetPreloadError {
            return error as! AssetPreloadResult.AssetPreloadError
        } else {
            return .networkError
        }
    }
    
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw AssetPreloadResult.AssetPreloadError.timeout
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

// MARK: - Supporting Types

extension AssetPreloadRequest.AssetPriority: RawRepresentable {
    typealias RawValue = Int
    
    init?(rawValue: Int) {
        switch rawValue {
        case 0: self = .critical
        case 1: self = .high
        case 2: self = .medium
        case 3: self = .low
        default: return nil
        }
    }
    
    var rawValue: Int {
        switch self {
        case .critical: return 0
        case .high: return 1
        case .medium: return 2
        case .low: return 3
        }
    }
} 