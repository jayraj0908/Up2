import Foundation
import CryptoKit

/// Service for automated data retention policies and lifecycle management
/// Part of Epic B: Auth + Profile - Million Dollar Enhancements
class DataRetentionService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var retentionPolicies: [DataRetentionPolicy] = []
    @Published var dataLifecycle: DataLifecycle = DataLifecycle()
    @Published var cleanupStatus: CleanupStatus = CleanupStatus()
    @Published var complianceMetrics: RetentionComplianceMetrics = RetentionComplianceMetrics()
    
    // MARK: - Private Properties
    private let appPerformanceService: AppPerformanceService
    private let errorHandlingService: ErrorHandlingService
    private let hapticService: HapticService
    private let analyticsService: AnalyticsService
    private let securityService: SecurityService
    
    // MARK: - Initialization
    init(appPerformanceService: AppPerformanceService = .shared,
         errorHandlingService: ErrorHandlingService = .shared,
         hapticService: HapticService = .shared,
         analyticsService: AnalyticsService = .shared,
         securityService: SecurityService = .shared) {
        self.appPerformanceService = appPerformanceService
        self.errorHandlingService = errorHandlingService
        self.hapticService = hapticService
        self.analyticsService = analyticsService
        self.securityService = securityService
        
        loadRetentionPolicies()
    }
    
    // MARK: - Public Methods
    
    /// Create data retention policy
    func createRetentionPolicy(_ policy: DataRetentionPolicy) async throws {
        do {
            analyticsService.trackEvent("retention_policy_created", properties: [
                "data_type": policy.dataType.rawValue,
                "retention_period": policy.retentionPeriod,
                "legal_basis": policy.legalBasis.rawValue
            ])
            
            // Validate policy
            try validateRetentionPolicy(policy)
            
            // Save policy
            try await saveRetentionPolicy(policy)
            
            // Update policies list
            retentionPolicies.append(policy)
            
            // Update compliance metrics
            await updateComplianceMetrics()
            
            hapticService.triggerSuccess()
            
        } catch {
            errorHandlingService.handleError(error, context: "DataRetentionService.createRetentionPolicy")
            throw error
        }
    }
    
    /// Update data retention policy
    func updateRetentionPolicy(_ policy: DataRetentionPolicy) async throws {
        do {
            analyticsService.trackEvent("retention_policy_updated", properties: [
                "policy_id": policy.id,
                "data_type": policy.dataType.rawValue,
                "retention_period": policy.retentionPeriod
            ])
            
            // Validate policy
            try validateRetentionPolicy(policy)
            
            // Update policy
            try await updateRetentionPolicyInStorage(policy)
            
            // Update local policies
            if let index = retentionPolicies.firstIndex(where: { $0.id == policy.id }) {
                retentionPolicies[index] = policy
            }
            
            // Update compliance metrics
            await updateComplianceMetrics()
            
            hapticService.triggerSuccess()
            
        } catch {
            errorHandlingService.handleError(error, context: "DataRetentionService.updateRetentionPolicy")
            throw error
        }
    }
    
    /// Delete data retention policy
    func deleteRetentionPolicy(policyId: String) async throws {
        do {
            analyticsService.trackEvent("retention_policy_deleted", properties: [
                "policy_id": policyId
            ])
            
            // Delete policy from storage
            try await deleteRetentionPolicyFromStorage(policyId)
            
            // Remove from local policies
            retentionPolicies.removeAll { $0.id == policyId }
            
            // Update compliance metrics
            await updateComplianceMetrics()
            
            hapticService.triggerWarning()
            
        } catch {
            errorHandlingService.handleError(error, context: "DataRetentionService.deleteRetentionPolicy")
            throw error
        }
    }
    
    /// Execute data cleanup based on retention policies
    func executeDataCleanup() async throws -> CleanupReport {
        do {
            analyticsService.trackEvent("data_cleanup_executed", properties: [
                "user_id": UserProfileService.shared.currentUser?.id ?? "unknown"
            ])
            
            // Get expired data
            let expiredData = try await getExpiredData()
            
            // Execute cleanup
            let cleanupResult = try await performCleanup(expiredData)
            
            // Update cleanup status
            cleanupStatus.lastCleanupDate = Date()
            cleanupStatus.cleanedDataCount += cleanupResult.cleanedItems.count
            cleanupStatus.totalStorageFreed += cleanupResult.storageFreed
            
            // Save cleanup status
            try await saveCleanupStatus(cleanupStatus)
            
            // Update compliance metrics
            await updateComplianceMetrics()
            
            hapticService.triggerSuccess()
            
            return cleanupResult
            
        } catch {
            errorHandlingService.handleError(error, context: "DataRetentionService.executeDataCleanup")
            throw error
        }
    }
    
    /// Archive data for long-term storage
    func archiveData(_ data: [DataItem]) async throws -> ArchiveReport {
        do {
            analyticsService.trackEvent("data_archived", properties: [
                "data_count": data.count,
                "total_size": data.reduce(0) { $0 + $1.size }
            ])
            
            // Validate data for archiving
            try validateDataForArchiving(data)
            
            // Create archive
            let archive = try await createArchive(data)
            
            // Store archive
            try await storeArchive(archive)
            
            // Update data lifecycle
            await updateDataLifecycle(data, action: .archived)
            
            hapticService.triggerSuccess()
            
            return archive
            
        } catch {
            errorHandlingService.handleError(error, context: "DataRetentionService.archiveData")
            throw error
        }
    }
    
    /// Restore data from archive
    func restoreData(archiveId: String) async throws -> RestoreReport {
        do {
            analyticsService.trackEvent("data_restored", properties: [
                "archive_id": archiveId
            ])
            
            // Retrieve archive
            let archive = try await retrieveArchive(archiveId)
            
            // Validate archive integrity
            try validateArchiveIntegrity(archive)
            
            // Restore data
            let restoreResult = try await performRestore(archive)
            
            // Update data lifecycle
            await updateDataLifecycle(restoreResult.restoredData, action: .restored)
            
            hapticService.triggerSuccess()
            
            return restoreResult
            
        } catch {
            errorHandlingService.handleError(error, context: "DataRetentionService.restoreData")
            throw error
        }
    }
    
    /// Get data lifecycle information
    func getDataLifecycle(dataType: DataType) async throws -> DataLifecycleInfo {
        do {
            let lifecycle = try await fetchDataLifecycle(dataType: dataType)
            
            analyticsService.trackEvent("data_lifecycle_requested", properties: [
                "data_type": dataType.rawValue
            ])
            
            return lifecycle
            
        } catch {
            errorHandlingService.handleError(error, context: "DataRetentionService.getDataLifecycle")
            throw error
        }
    }
    
    /// Get compliance metrics
    func getComplianceMetrics() async throws -> RetentionComplianceMetrics {
        do {
            let metrics = try await fetchComplianceMetrics()
            complianceMetrics = metrics
            
            return metrics
            
        } catch {
            errorHandlingService.handleError(error, context: "DataRetentionService.getComplianceMetrics")
            throw error
        }
    }
    
    /// Schedule automated cleanup
    func scheduleAutomatedCleanup(schedule: CleanupSchedule) async throws {
        do {
            analyticsService.trackEvent("automated_cleanup_scheduled", properties: [
                "frequency": schedule.frequency.rawValue,
                "time": schedule.time
            ])
            
            // Validate schedule
            try validateCleanupSchedule(schedule)
            
            // Save schedule
            try await saveCleanupSchedule(schedule)
            
            // Update cleanup status
            cleanupStatus.scheduledCleanup = schedule
            cleanupStatus.isAutomated = true
            
            hapticService.triggerSuccess()
            
        } catch {
            errorHandlingService.handleError(error, context: "DataRetentionService.scheduleAutomatedCleanup")
            throw error
        }
    }
    
    /// Get data retention analytics
    func getRetentionAnalytics() async throws -> RetentionAnalytics {
        do {
            let analytics = try await fetchRetentionAnalytics()
            
            analyticsService.trackEvent("retention_analytics_requested", properties: [
                "user_id": UserProfileService.shared.currentUser?.id ?? "unknown"
            ])
            
            return analytics
            
        } catch {
            errorHandlingService.handleError(error, context: "DataRetentionService.getRetentionAnalytics")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func loadRetentionPolicies() {
        // Load saved retention policies from secure storage
        // For now, we'll use default policies
        retentionPolicies = [
            DataRetentionPolicy(
                dataType: .userProfile,
                retentionPeriod: 365,
                legalBasis: .consent,
                description: "User profile data retention"
            ),
            DataRetentionPolicy(
                dataType: .activity,
                retentionPeriod: 90,
                legalBasis: .legitimateInterest,
                description: "User activity data retention"
            ),
            DataRetentionPolicy(
                dataType: .analytics,
                retentionPeriod: 30,
                legalBasis: .legitimateInterest,
                description: "Analytics data retention"
            )
        ]
    }
    
    private func validateRetentionPolicy(_ policy: DataRetentionPolicy) throws {
        // Validate retention period
        guard policy.retentionPeriod > 0 else {
            throw RetentionError.invalidRetentionPeriod
        }
        
        // Validate legal basis
        guard policy.legalBasis != .invalid else {
            throw RetentionError.invalidLegalBasis
        }
        
        // Validate data type
        guard policy.dataType != .invalid else {
            throw RetentionError.invalidDataType
        }
    }
    
    private func saveRetentionPolicy(_ policy: DataRetentionPolicy) async throws {
        // Save policy to secure storage
        let policyData = try JSONEncoder().encode(policy)
        let encryptedData = try securityService.encryptData(policyData)
        
        try securityService.storeSecureData(encryptedData, forKey: "retention_policy_\(policy.id)")
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
    }
    
    private func updateRetentionPolicyInStorage(_ policy: DataRetentionPolicy) async throws {
        // Update policy in secure storage
        let policyData = try JSONEncoder().encode(policy)
        let encryptedData = try securityService.encryptData(policyData)
        
        try securityService.storeSecureData(encryptedData, forKey: "retention_policy_\(policy.id)")
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
    }
    
    private func deleteRetentionPolicyFromStorage(_ policyId: String) async throws {
        // Delete policy from secure storage
        try securityService.deleteSecureData(forKey: "retention_policy_\(policyId)")
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
    }
    
    private func updateComplianceMetrics() async {
        // Update compliance metrics based on current policies
        complianceMetrics.totalPolicies = retentionPolicies.count
        complianceMetrics.compliantPolicies = retentionPolicies.filter { $0.isCompliant }.count
        complianceMetrics.lastUpdated = Date()
        
        // Calculate compliance score
        if complianceMetrics.totalPolicies > 0 {
            complianceMetrics.complianceScore = Double(complianceMetrics.compliantPolicies) / Double(complianceMetrics.totalPolicies) * 100.0
        }
        
        // Save compliance metrics
        try? await saveComplianceMetrics(complianceMetrics)
    }
    
    private func getExpiredData() async throws -> [ExpiredDataItem] {
        // Get data that has exceeded retention period
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        return [
            ExpiredDataItem(
                id: UUID().uuidString,
                dataType: .analytics,
                size: 1024 * 1024, // 1MB
                createdAt: Date().addingTimeInterval(-31 * 24 * 60 * 60), // 31 days ago
                retentionPolicy: retentionPolicies.first { $0.dataType == .analytics }
            ),
            ExpiredDataItem(
                id: UUID().uuidString,
                dataType: .activity,
                size: 512 * 1024, // 512KB
                createdAt: Date().addingTimeInterval(-91 * 24 * 60 * 60), // 91 days ago
                retentionPolicy: retentionPolicies.first { $0.dataType == .activity }
            )
        ]
    }
    
    private func performCleanup(_ expiredData: [ExpiredDataItem]) async throws -> CleanupReport {
        var cleanedItems: [String] = []
        var storageFreed: Int64 = 0
        
        for item in expiredData {
            // Delete expired data
            try await deleteDataItem(item)
            
            cleanedItems.append(item.id)
            storageFreed += item.size
        }
        
        return CleanupReport(
            cleanedItems: cleanedItems,
            storageFreed: storageFreed,
            cleanupDate: Date(),
            itemsProcessed: expiredData.count
        )
    }
    
    private func saveCleanupStatus(_ status: CleanupStatus) async throws {
        // Save cleanup status to secure storage
        let statusData = try JSONEncoder().encode(status)
        let encryptedData = try securityService.encryptData(statusData)
        
        try securityService.storeSecureData(encryptedData, forKey: "cleanup_status")
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
    }
    
    private func validateDataForArchiving(_ data: [DataItem]) throws {
        for item in data {
            // Validate data size
            guard item.size <= 100 * 1024 * 1024 else { // 100MB limit
                throw RetentionError.dataTooLargeForArchiving
            }
            
            // Validate data type
            guard item.type != .invalid else {
                throw RetentionError.invalidDataType
            }
        }
    }
    
    private func createArchive(_ data: [DataItem]) async throws -> ArchiveReport {
        // Create archive package
        let archiveId = UUID().uuidString
        let archiveData = try JSONEncoder().encode(data)
        let compressedData = try await compressData(archiveData)
        let encryptedData = try securityService.encryptData(compressedData)
        
        // Generate archive hash
        let archiveHash = SHA256.hash(data: compressedData).description
        
        return ArchiveReport(
            id: archiveId,
            data: encryptedData,
            hash: archiveHash,
            originalSize: data.reduce(0) { $0 + $1.size },
            compressedSize: compressedData.count,
            archivedAt: Date(),
            dataCount: data.count
        )
    }
    
    private func storeArchive(_ archive: ArchiveReport) async throws {
        // Store archive in secure storage
        let archiveData = try JSONEncoder().encode(archive)
        let encryptedArchive = try securityService.encryptData(archiveData)
        
        try securityService.storeSecureData(encryptedArchive, forKey: "archive_\(archive.id)")
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
    }
    
    private func updateDataLifecycle(_ data: [DataItem], action: LifecycleAction) async {
        // Update data lifecycle tracking
        for item in data {
            let lifecycleEvent = LifecycleEvent(
                dataId: item.id,
                action: action,
                timestamp: Date(),
                metadata: ["size": item.size, "type": item.type.rawValue]
            )
            
            dataLifecycle.events.append(lifecycleEvent)
        }
        
        // Keep only last 1000 events
        if dataLifecycle.events.count > 1000 {
            dataLifecycle.events.removeFirst(dataLifecycle.events.count - 1000)
        }
        
        // Save lifecycle
        try? await saveDataLifecycle(dataLifecycle)
    }
    
    private func retrieveArchive(_ archiveId: String) async throws -> ArchiveReport {
        // Retrieve archive from secure storage
        let encryptedArchive = try securityService.retrieveSecureData(forKey: "archive_\(archiveId)")
        let archiveData = try securityService.decryptData(encryptedArchive)
        
        let archive = try JSONDecoder().decode(ArchiveReport.self, from: archiveData)
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return archive
    }
    
    private func validateArchiveIntegrity(_ archive: ArchiveReport) throws {
        // Validate archive integrity
        let archiveData = try securityService.decryptData(archive.data)
        let calculatedHash = SHA256.hash(data: archiveData).description
        
        guard calculatedHash == archive.hash else {
            throw RetentionError.archiveIntegrityCheckFailed
        }
    }
    
    private func performRestore(_ archive: ArchiveReport) async throws -> RestoreReport {
        // Restore data from archive
        let archiveData = try securityService.decryptData(archive.data)
        let decompressedData = try await decompressData(archiveData)
        let restoredData = try JSONDecoder().decode([DataItem].self, from: decompressedData)
        
        return RestoreReport(
            archiveId: archive.id,
            restoredData: restoredData,
            restoredAt: Date(),
            itemsRestored: restoredData.count
        )
    }
    
    private func fetchDataLifecycle(dataType: DataType) async throws -> DataLifecycleInfo {
        // This would typically call a backend API
        // For now, we'll return mock data
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return DataLifecycleInfo(
            dataType: dataType,
            totalItems: Int.random(in: 100...1000),
            totalSize: Int64.random(in: 1024 * 1024...100 * 1024 * 1024), // 1MB to 100MB
            averageAge: Double.random(in: 1...365),
            retentionCompliance: Double.random(in: 80.0...100.0)
        )
    }
    
    private func fetchComplianceMetrics() async throws -> RetentionComplianceMetrics {
        // This would typically call a backend API
        // For now, we'll return mock data
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return RetentionComplianceMetrics(
            totalPolicies: retentionPolicies.count,
            compliantPolicies: retentionPolicies.filter { $0.isCompliant }.count,
            complianceScore: Double.random(in: 85.0...100.0),
            lastUpdated: Date(),
            auditDate: Date().addingTimeInterval(-7 * 24 * 60 * 60) // 7 days ago
        )
    }
    
    private func validateCleanupSchedule(_ schedule: CleanupSchedule) throws {
        // Validate cleanup schedule
        guard schedule.frequency != .invalid else {
            throw RetentionError.invalidCleanupFrequency
        }
        
        guard !schedule.time.isEmpty else {
            throw RetentionError.invalidCleanupTime
        }
    }
    
    private func saveCleanupSchedule(_ schedule: CleanupSchedule) async throws {
        // Save cleanup schedule to secure storage
        let scheduleData = try JSONEncoder().encode(schedule)
        let encryptedData = try securityService.encryptData(scheduleData)
        
        try securityService.storeSecureData(encryptedData, forKey: "cleanup_schedule")
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
    }
    
    private func fetchRetentionAnalytics() async throws -> RetentionAnalytics {
        // This would typically call a backend API
        // For now, we'll return mock data
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return RetentionAnalytics(
            totalDataStored: Int64.random(in: 1024 * 1024 * 1024...10 * 1024 * 1024 * 1024), // 1GB to 10GB
            dataByType: [
                .userProfile: Int64.random(in: 100 * 1024 * 1024...1 * 1024 * 1024 * 1024),
                .activity: Int64.random(in: 500 * 1024 * 1024...5 * 1024 * 1024 * 1024),
                .analytics: Int64.random(in: 50 * 1024 * 1024...500 * 1024 * 1024)
            ],
            retentionEfficiency: Double.random(in: 70.0...95.0),
            cleanupFrequency: Double.random(in: 1...30),
            lastCleanupDate: Date().addingTimeInterval(-Double.random(in: 1...7) * 24 * 60 * 60)
        )
    }
    
    // Helper methods
    private func deleteDataItem(_ item: ExpiredDataItem) async throws {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
    }
    
    private func compressData(_ data: Data) async throws -> Data {
        // Simple compression simulation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
        return data
    }
    
    private func decompressData(_ data: Data) async throws -> Data {
        // Simple decompression simulation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
        return data
    }
    
    private func saveDataLifecycle(_ lifecycle: DataLifecycle) async throws {
        let lifecycleData = try JSONEncoder().encode(lifecycle)
        let encryptedData = try securityService.encryptData(lifecycleData)
        
        try securityService.storeSecureData(encryptedData, forKey: "data_lifecycle")
    }
    
    private func saveComplianceMetrics(_ metrics: RetentionComplianceMetrics) async throws {
        let metricsData = try JSONEncoder().encode(metrics)
        let encryptedData = try securityService.encryptData(metricsData)
        
        try securityService.storeSecureData(encryptedData, forKey: "retention_compliance_metrics")
    }
}

// MARK: - Supporting Types

struct DataRetentionPolicy: Codable, Identifiable {
    let id: String = UUID().uuidString
    let dataType: DataType
    let retentionPeriod: Int // in days
    let legalBasis: LegalBasis
    let description: String
    var isCompliant: Bool = true
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
}

enum DataType: String, Codable, CaseIterable {
    case userProfile = "user_profile"
    case activity = "activity"
    case analytics = "analytics"
    case messages = "messages"
    case events = "events"
    case settings = "settings"
    case invalid = "invalid"
}

enum LegalBasis: String, Codable, CaseIterable {
    case consent = "consent"
    case contract = "contract"
    case legitimateInterest = "legitimate_interest"
    case legalObligation = "legal_obligation"
    case vitalInterests = "vital_interests"
    case publicTask = "public_task"
    case invalid = "invalid"
}

struct DataLifecycle: Codable {
    var events: [LifecycleEvent] = []
    var lastUpdated: Date = Date()
}

struct LifecycleEvent: Codable {
    let dataId: String
    let action: LifecycleAction
    let timestamp: Date
    let metadata: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case dataId, action, timestamp, metadata
    }
    
    init(dataId: String, action: LifecycleAction, timestamp: Date, metadata: [String: Any]) {
        self.dataId = dataId
        self.action = action
        self.timestamp = timestamp
        self.metadata = metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        dataId = try container.decode(String.self, forKey: .dataId)
        action = try container.decode(LifecycleAction.self, forKey: .action)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        metadata = [:] // Simplified for encoding
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(dataId, forKey: .dataId)
        try container.encode(action, forKey: .action)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(metadata, forKey: .metadata)
    }
}

enum LifecycleAction: String, Codable {
    case created = "created"
    case accessed = "accessed"
    case modified = "modified"
    case archived = "archived"
    case restored = "restored"
    case deleted = "deleted"
}

struct CleanupStatus: Codable {
    var lastCleanupDate: Date = Date()
    var cleanedDataCount: Int = 0
    var totalStorageFreed: Int64 = 0
    var isAutomated: Bool = false
    var scheduledCleanup: CleanupSchedule?
}

struct CleanupSchedule: Codable {
    let frequency: CleanupFrequency
    let time: String // HH:mm format
    let isEnabled: Bool = true
}

enum CleanupFrequency: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case invalid = "invalid"
}

struct RetentionComplianceMetrics: Codable {
    var totalPolicies: Int = 0
    var compliantPolicies: Int = 0
    var complianceScore: Double = 100.0
    var lastUpdated: Date = Date()
    var auditDate: Date = Date()
}

struct ExpiredDataItem: Codable {
    let id: String
    let dataType: DataType
    let size: Int64
    let createdAt: Date
    let retentionPolicy: DataRetentionPolicy?
}

struct DataItem: Codable {
    let id: String
    let type: DataType
    let size: Int64
    let createdAt: Date
    let data: Data
}

struct CleanupReport: Codable {
    let cleanedItems: [String]
    let storageFreed: Int64
    let cleanupDate: Date
    let itemsProcessed: Int
}

struct ArchiveReport: Codable {
    let id: String
    let data: Data
    let hash: String
    let originalSize: Int64
    let compressedSize: Int
    let archivedAt: Date
    let dataCount: Int
}

struct RestoreReport: Codable {
    let archiveId: String
    let restoredData: [DataItem]
    let restoredAt: Date
    let itemsRestored: Int
}

struct DataLifecycleInfo: Codable {
    let dataType: DataType
    let totalItems: Int
    let totalSize: Int64
    let averageAge: Double
    let retentionCompliance: Double
}

struct RetentionAnalytics: Codable {
    let totalDataStored: Int64
    let dataByType: [DataType: Int64]
    let retentionEfficiency: Double
    let cleanupFrequency: Double
    let lastCleanupDate: Date
}

enum RetentionError: Error, LocalizedError {
    case invalidRetentionPeriod
    case invalidLegalBasis
    case invalidDataType
    case dataTooLargeForArchiving
    case archiveIntegrityCheckFailed
    case invalidCleanupFrequency
    case invalidCleanupTime
    case cleanupFailed
    case archivingFailed
    case restorationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidRetentionPeriod:
            return "Invalid retention period"
        case .invalidLegalBasis:
            return "Invalid legal basis"
        case .invalidDataType:
            return "Invalid data type"
        case .dataTooLargeForArchiving:
            return "Data too large for archiving"
        case .archiveIntegrityCheckFailed:
            return "Archive integrity check failed"
        case .invalidCleanupFrequency:
            return "Invalid cleanup frequency"
        case .invalidCleanupTime:
            return "Invalid cleanup time"
        case .cleanupFailed:
            return "Data cleanup failed"
        case .archivingFailed:
            return "Data archiving failed"
        case .restorationFailed:
            return "Data restoration failed"
        }
    }
} 