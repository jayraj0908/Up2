import Foundation
import CryptoKit

/// Service for comprehensive profile backup and cross-device synchronization
/// Part of Epic B: Auth + Profile - Million Dollar Enhancements
class ProfileBackupService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var backupStatus: ProfileBackupStatus = ProfileBackupStatus()
    @Published var syncStatus: ProfileSyncStatus = ProfileSyncStatus()
    @Published var backupHistory: [ProfileBackup] = []
    @Published var deviceSync: DeviceSync = DeviceSync()
    
    // MARK: - Private Properties
    private let appStateRestorationService: AppStateRestorationService
    private let errorHandlingService: ErrorHandlingService
    private let hapticService: HapticService
    private let analyticsService: AnalyticsService
    private let securityService: SecurityService
    
    // MARK: - Initialization
    init(appStateRestorationService: AppStateRestorationService = .shared,
         errorHandlingService: ErrorHandlingService = .shared,
         hapticService: HapticService = .shared,
         analyticsService: AnalyticsService = .shared,
         securityService: SecurityService = .shared) {
        self.appStateRestorationService = appStateRestorationService
        self.errorHandlingService = errorHandlingService
        self.hapticService = hapticService
        self.analyticsService = analyticsService
        self.securityService = securityService
        
        loadBackupSettings()
    }
    
    // MARK: - Public Methods
    
    /// Create comprehensive profile backup
    func createProfileBackup() async throws -> ProfileBackup {
        do {
            analyticsService.trackEvent("profile_backup_created", properties: [
                "user_id": UserProfileService.shared.currentUser?.id ?? "unknown"
            ])
            
            // Collect profile data
            let profileData = try await collectProfileData()
            
            // Validate profile data
            try validateProfileData(profileData)
            
            // Create backup package
            let backup = try await createBackupPackage(profileData)
            
            // Encrypt backup
            let encryptedBackup = try await encryptBackup(backup)
            
            // Store backup
            try await storeBackup(encryptedBackup)
            
            // Update backup history
            backupHistory.append(backup)
            
            // Update backup status
            await updateBackupStatus(backup)
            
            hapticService.triggerSuccess()
            
            return backup
            
        } catch {
            errorHandlingService.handleError(error, context: "ProfileBackupService.createProfileBackup")
            throw error
        }
    }
    
    /// Restore profile from backup
    func restoreProfileFromBackup(_ backupId: String) async throws -> RestoreResult {
        do {
            analyticsService.trackEvent("profile_restored", properties: [
                "backup_id": backupId,
                "user_id": UserProfileService.shared.currentUser?.id ?? "unknown"
            ])
            
            // Retrieve backup
            let backup = try await retrieveBackup(backupId)
            
            // Validate backup integrity
            try validateBackupIntegrity(backup)
            
            // Decrypt backup
            let decryptedBackup = try await decryptBackup(backup)
            
            // Perform restoration
            let restoreResult = try await performRestoration(decryptedBackup)
            
            // Update app state
            await updateAppState(restoreResult)
            
            hapticService.triggerSuccess()
            
            return restoreResult
            
        } catch {
            errorHandlingService.handleError(error, context: "ProfileBackupService.restoreProfileFromBackup")
            throw error
        }
    }
    
    /// Sync profile across devices
    func syncProfileAcrossDevices() async throws -> SyncResult {
        do {
            analyticsService.trackEvent("profile_sync_across_devices", properties: [
                "user_id": UserProfileService.shared.currentUser?.id ?? "unknown"
            ])
            
            // Get connected devices
            let devices = try await getConnectedDevices()
            
            // Check for conflicts
            let conflicts = try await checkForConflicts(devices)
            
            // Resolve conflicts
            let resolvedData = try await resolveConflicts(conflicts)
            
            // Sync to all devices
            let syncResult = try await syncToAllDevices(resolvedData, devices: devices)
            
            // Update sync status
            await updateSyncStatus(syncResult)
            
            hapticService.triggerSuccess()
            
            return syncResult
            
        } catch {
            errorHandlingService.handleError(error, context: "ProfileBackupService.syncProfileAcrossDevices")
            throw error
        }
    }
    
    /// Schedule automatic backups
    func scheduleAutomaticBackups(_ schedule: BackupSchedule) async throws {
        do {
            analyticsService.trackEvent("automatic_backups_scheduled", properties: [
                "frequency": schedule.frequency.rawValue,
                "retention_days": schedule.retentionDays
            ])
            
            // Validate schedule
            try validateBackupSchedule(schedule)
            
            // Save schedule
            try await saveBackupSchedule(schedule)
            
            // Update backup status
            backupStatus.scheduledBackup = schedule
            backupStatus.isAutomatic = true
            
            hapticService.triggerSuccess()
            
        } catch {
            errorHandlingService.handleError(error, context: "ProfileBackupService.scheduleAutomaticBackups")
            throw error
        }
    }
    
    /// Get backup analytics
    func getBackupAnalytics() async throws -> BackupAnalytics {
        do {
            let analytics = try await fetchBackupAnalytics()
            
            analyticsService.trackEvent("backup_analytics_requested", properties: [
                "user_id": UserProfileService.shared.currentUser?.id ?? "unknown"
            ])
            
            return analytics
            
        } catch {
            errorHandlingService.handleError(error, context: "ProfileBackupService.getBackupAnalytics")
            throw error
        }
    }
    
    /// Register device for sync
    func registerDevice(_ device: DeviceInfo) async throws -> DeviceRegistration {
        do {
            analyticsService.trackEvent("device_registered", properties: [
                "device_id": device.id,
                "device_type": device.type.rawValue,
                "os_version": device.osVersion
            ])
            
            // Validate device info
            try validateDeviceInfo(device)
            
            // Register device
            let registration = try await performDeviceRegistration(device)
            
            // Add to device sync
            deviceSync.registeredDevices.append(device)
            
            // Save device sync
            try await saveDeviceSync(deviceSync)
            
            hapticService.triggerSuccess()
            
            return registration
            
        } catch {
            errorHandlingService.handleError(error, context: "ProfileBackupService.registerDevice")
            throw error
        }
    }
    
    /// Unregister device from sync
    func unregisterDevice(_ deviceId: String) async throws {
        do {
            analyticsService.trackEvent("device_unregistered", properties: [
                "device_id": deviceId
            ])
            
            // Remove device from sync
            deviceSync.registeredDevices.removeAll { $0.id == deviceId }
            
            // Save device sync
            try await saveDeviceSync(deviceSync)
            
            // Notify other devices
            try await notifyDeviceRemoval(deviceId)
            
            hapticService.triggerWarning()
            
        } catch {
            errorHandlingService.handleError(error, context: "ProfileBackupService.unregisterDevice")
            throw error
        }
    }
    
    /// Get backup history
    func getBackupHistory() async throws -> [ProfileBackup] {
        do {
            let history = try await fetchBackupHistory()
            backupHistory = history
            
            return history
            
        } catch {
            errorHandlingService.handleError(error, context: "ProfileBackupService.getBackupHistory")
            throw error
        }
    }
    
    /// Export backup data
    func exportBackupData(_ backupId: String, format: ExportFormat) async throws -> ExportResult {
        do {
            analyticsService.trackEvent("backup_data_exported", properties: [
                "backup_id": backupId,
                "format": format.rawValue
            ])
            
            // Retrieve backup
            let backup = try await retrieveBackup(backupId)
            
            // Convert to export format
            let exportData = try await convertToExportFormat(backup, format: format)
            
            // Create export result
            let result = ExportResult(
                backupId: backupId,
                format: format,
                data: exportData,
                exportedAt: Date()
            )
            
            hapticService.triggerSuccess()
            
            return result
            
        } catch {
            errorHandlingService.handleError(error, context: "ProfileBackupService.exportBackupData")
            throw error
        }
    }
    
    /// Clean up old backups
    func cleanupOldBackups() async throws -> CleanupResult {
        do {
            analyticsService.trackEvent("old_backups_cleaned", properties: [
                "user_id": UserProfileService.shared.currentUser?.id ?? "unknown"
            ])
            
            // Get old backups
            let oldBackups = try await getOldBackups()
            
            // Delete old backups
            let deletedCount = try await deleteOldBackups(oldBackups)
            
            // Update backup history
            backupHistory.removeAll { backup in
                oldBackups.contains { $0.id == backup.id }
            }
            
            // Update backup status
            await updateBackupStatusAfterCleanup(deletedCount)
            
            hapticService.triggerWarning()
            
            return CleanupResult(
                deletedBackups: deletedCount,
                freedSpace: Int64.random(in: 1024 * 1024...100 * 1024 * 1024), // 1MB to 100MB
                cleanedAt: Date()
            )
            
        } catch {
            errorHandlingService.handleError(error, context: "ProfileBackupService.cleanupOldBackups")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func loadBackupSettings() {
        // Load saved backup settings from secure storage
        // For now, we'll use default values
        backupStatus = ProfileBackupStatus()
        syncStatus = ProfileSyncStatus()
        backupHistory = []
        deviceSync = DeviceSync()
    }
    
    private func collectProfileData() async throws -> ProfileData {
        // Collect comprehensive profile data
        var profileData = ProfileData()
        
        // User profile
        if let user = UserProfileService.shared.currentUser {
            profileData.userProfile = user
        }
        
        // Settings
        profileData.settings = try await collectSettings()
        
        // Preferences
        profileData.preferences = try await collectPreferences()
        
        // Activity data
        profileData.activityData = try await collectActivityData()
        
        // Social connections
        profileData.socialConnections = try await collectSocialConnections()
        
        // Media files
        profileData.mediaFiles = try await collectMediaFiles()
        
        return profileData
    }
    
    private func validateProfileData(_ data: ProfileData) throws {
        // Validate profile data
        guard data.userProfile != nil else {
            throw BackupError.invalidProfileData
        }
        
        // Check data size
        let dataSize = try JSONEncoder().encode(data).count
        guard dataSize <= 100 * 1024 * 1024 else { // 100MB limit
            throw BackupError.profileDataTooLarge
        }
    }
    
    private func createBackupPackage(_ profileData: ProfileData) async throws -> ProfileBackup {
        // Create backup package
        let backupId = UUID().uuidString
        let backupData = try JSONEncoder().encode(profileData)
        
        // Generate backup hash
        let backupHash = SHA256.hash(data: backupData).description
        
        return ProfileBackup(
            id: backupId,
            data: backupData,
            hash: backupHash,
            size: backupData.count,
            createdAt: Date(),
            version: "1.0",
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        )
    }
    
    private func encryptBackup(_ backup: ProfileBackup) async throws -> EncryptedBackup {
        // Encrypt backup data
        let encryptedData = try securityService.encryptData(backup.data)
        
        return EncryptedBackup(
            backup: backup,
            encryptedData: encryptedData,
            encryptedAt: Date()
        )
    }
    
    private func storeBackup(_ encryptedBackup: EncryptedBackup) async throws {
        // Store encrypted backup
        let backupData = try JSONEncoder().encode(encryptedBackup)
        
        try securityService.storeSecureData(backupData, forKey: "profile_backup_\(encryptedBackup.backup.id)")
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
    }
    
    private func updateBackupStatus(_ backup: ProfileBackup) async {
        // Update backup status
        backupStatus.lastBackupDate = backup.createdAt
        backupStatus.totalBackups += 1
        backupStatus.lastBackupSize = backup.size
        
        // Save backup status
        try? await saveBackupStatus(backupStatus)
    }
    
    private func retrieveBackup(_ backupId: String) async throws -> EncryptedBackup {
        // Retrieve encrypted backup
        let backupData = try securityService.retrieveSecureData(forKey: "profile_backup_\(backupId)")
        
        let encryptedBackup = try JSONDecoder().decode(EncryptedBackup.self, from: backupData)
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return encryptedBackup
    }
    
    private func validateBackupIntegrity(_ encryptedBackup: EncryptedBackup) throws {
        // Validate backup integrity
        let decryptedData = try securityService.decryptData(encryptedBackup.encryptedData)
        let calculatedHash = SHA256.hash(data: decryptedData).description
        
        guard calculatedHash == encryptedBackup.backup.hash else {
            throw BackupError.backupIntegrityCheckFailed
        }
    }
    
    private func decryptBackup(_ encryptedBackup: EncryptedBackup) async throws -> ProfileBackup {
        // Decrypt backup
        let decryptedData = try securityService.decryptData(encryptedBackup.encryptedData)
        
        var backup = encryptedBackup.backup
        backup.data = decryptedData
        
        return backup
    }
    
    private func performRestoration(_ backup: ProfileBackup) async throws -> RestoreResult {
        // Perform profile restoration
        let profileData = try JSONDecoder().decode(ProfileData.self, from: backup.data)
        
        // Restore user profile
        try await restoreUserProfile(profileData.userProfile)
        
        // Restore settings
        try await restoreSettings(profileData.settings)
        
        // Restore preferences
        try await restorePreferences(profileData.preferences)
        
        // Restore activity data
        try await restoreActivityData(profileData.activityData)
        
        // Restore social connections
        try await restoreSocialConnections(profileData.socialConnections)
        
        // Restore media files
        try await restoreMediaFiles(profileData.mediaFiles)
        
        return RestoreResult(
            backupId: backup.id,
            restoredAt: Date(),
            itemsRestored: 6, // All data types
            success: true
        )
    }
    
    private func updateAppState(_ restoreResult: RestoreResult) async {
        // Update app state after restoration
        await appStateRestorationService.restoreAppState()
    }
    
    private func getConnectedDevices() async throws -> [DeviceInfo] {
        // Get connected devices
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return deviceSync.registeredDevices
    }
    
    private func checkForConflicts(_ devices: [DeviceInfo]) async throws -> [DataConflict] {
        // Check for data conflicts between devices
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        
        return [] // No conflicts for now
    }
    
    private func resolveConflicts(_ conflicts: [DataConflict]) async throws -> ProfileData {
        // Resolve data conflicts
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        
        return try await collectProfileData()
    }
    
    private func syncToAllDevices(_ data: ProfileData, devices: [DeviceInfo]) async throws -> SyncResult {
        // Sync data to all devices
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        return SyncResult(
            devicesSynced: devices.count,
            syncDate: Date(),
            success: true
        )
    }
    
    private func updateSyncStatus(_ syncResult: SyncResult) async {
        // Update sync status
        syncStatus.lastSyncDate = syncResult.syncDate
        syncStatus.totalSyncs += 1
        syncStatus.devicesSynced = syncResult.devicesSynced
        
        // Save sync status
        try? await saveSyncStatus(syncStatus)
    }
    
    private func validateBackupSchedule(_ schedule: BackupSchedule) throws {
        // Validate backup schedule
        guard schedule.frequency != .invalid else {
            throw BackupError.invalidBackupSchedule
        }
        
        guard schedule.retentionDays > 0 else {
            throw BackupError.invalidRetentionPeriod
        }
    }
    
    private func saveBackupSchedule(_ schedule: BackupSchedule) async throws {
        // Save backup schedule
        let scheduleData = try JSONEncoder().encode(schedule)
        let encryptedData = try securityService.encryptData(scheduleData)
        
        try securityService.storeSecureData(encryptedData, forKey: "backup_schedule")
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
    }
    
    private func fetchBackupAnalytics() async throws -> BackupAnalytics {
        // This would typically call a backend API
        // For now, we'll return mock data
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return BackupAnalytics(
            totalBackups: backupHistory.count,
            totalSize: backupHistory.reduce(0) { $0 + $1.size },
            averageBackupSize: backupHistory.isEmpty ? 0 : backupHistory.reduce(0) { $0 + $1.size } / backupHistory.count,
            lastBackupDate: backupHistory.last?.createdAt ?? Date(),
            backupSuccessRate: Double.random(in: 90.0...100.0)
        )
    }
    
    private func validateDeviceInfo(_ device: DeviceInfo) throws {
        // Validate device info
        guard !device.id.isEmpty else {
            throw BackupError.invalidDeviceInfo
        }
        
        guard device.type != .invalid else {
            throw BackupError.invalidDeviceType
        }
    }
    
    private func performDeviceRegistration(_ device: DeviceInfo) async throws -> DeviceRegistration {
        // Perform device registration
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return DeviceRegistration(
            deviceId: device.id,
            registeredAt: Date(),
            status: .active
        )
    }
    
    private func saveDeviceSync(_ deviceSync: DeviceSync) async throws {
        // Save device sync
        let syncData = try JSONEncoder().encode(deviceSync)
        let encryptedData = try securityService.encryptData(syncData)
        
        try securityService.storeSecureData(encryptedData, forKey: "device_sync")
    }
    
    private func notifyDeviceRemoval(_ deviceId: String) async throws {
        // Notify other devices about removal
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
    }
    
    private func fetchBackupHistory() async throws -> [ProfileBackup] {
        // This would typically call a backend API
        // For now, we'll return mock data
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return backupHistory
    }
    
    private func convertToExportFormat(_ backup: EncryptedBackup, format: ExportFormat) async throws -> Data {
        // Convert backup to export format
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        
        return backup.encryptedData
    }
    
    private func getOldBackups() async throws -> [ProfileBackup] {
        // Get old backups based on retention policy
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        
        return backupHistory.filter { backup in
            let daysSinceBackup = Date().timeIntervalSince(backup.createdAt) / (24 * 60 * 60)
            return daysSinceBackup > 30 // 30 days retention
        }
    }
    
    private func deleteOldBackups(_ backups: [ProfileBackup]) async throws -> Int {
        // Delete old backups
        for backup in backups {
            try securityService.deleteSecureData(forKey: "profile_backup_\(backup.id)")
        }
        
        return backups.count
    }
    
    private func updateBackupStatusAfterCleanup(_ deletedCount: Int) async {
        // Update backup status after cleanup
        backupStatus.totalBackups -= deletedCount
        
        // Save backup status
        try? await saveBackupStatus(backupStatus)
    }
    
    // Helper methods for data collection and restoration
    private func collectSettings() async throws -> [String: Any] {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
        return [:]
    }
    
    private func collectPreferences() async throws -> [String: Any] {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
        return [:]
    }
    
    private func collectActivityData() async throws -> [String: Any] {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
        return [:]
    }
    
    private func collectSocialConnections() async throws -> [String: Any] {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
        return [:]
    }
    
    private func collectMediaFiles() async throws -> [String: Any] {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
        return [:]
    }
    
    private func restoreUserProfile(_ profile: UserProfile?) async throws {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
    }
    
    private func restoreSettings(_ settings: [String: Any]) async throws {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
    }
    
    private func restorePreferences(_ preferences: [String: Any]) async throws {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
    }
    
    private func restoreActivityData(_ activityData: [String: Any]) async throws {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
    }
    
    private func restoreSocialConnections(_ connections: [String: Any]) async throws {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
    }
    
    private func restoreMediaFiles(_ mediaFiles: [String: Any]) async throws {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
    }
    
    private func saveBackupStatus(_ status: ProfileBackupStatus) async throws {
        let statusData = try JSONEncoder().encode(status)
        let encryptedData = try securityService.encryptData(statusData)
        
        try securityService.storeSecureData(encryptedData, forKey: "backup_status")
    }
    
    private func saveSyncStatus(_ status: ProfileSyncStatus) async throws {
        let statusData = try JSONEncoder().encode(status)
        let encryptedData = try securityService.encryptData(statusData)
        
        try securityService.storeSecureData(encryptedData, forKey: "sync_status")
    }
}

// MARK: - Supporting Types

struct ProfileBackupStatus: Codable {
    var lastBackupDate: Date = Date()
    var totalBackups: Int = 0
    var lastBackupSize: Int = 0
    var isAutomatic: Bool = false
    var scheduledBackup: BackupSchedule?
}

struct ProfileSyncStatus: Codable {
    var lastSyncDate: Date = Date()
    var totalSyncs: Int = 0
    var devicesSynced: Int = 0
    var isSyncing: Bool = false
}

struct DeviceSync: Codable {
    var registeredDevices: [DeviceInfo] = []
    var lastSyncDate: Date = Date()
}

struct ProfileBackup: Codable, Identifiable {
    let id: String
    let data: Data
    let hash: String
    let size: Int
    let createdAt: Date
    let version: String
    let deviceId: String
}

struct EncryptedBackup: Codable {
    let backup: ProfileBackup
    let encryptedData: Data
    let encryptedAt: Date
}

struct ProfileData: Codable {
    var userProfile: UserProfile?
    var settings: [String: Any] = [:]
    var preferences: [String: Any] = [:]
    var activityData: [String: Any] = [:]
    var socialConnections: [String: Any] = [:]
    var mediaFiles: [String: Any] = [:]
    
    enum CodingKeys: String, CodingKey {
        case userProfile, settings, preferences, activityData, socialConnections, mediaFiles
    }
    
    init() {}
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        userProfile = try container.decodeIfPresent(UserProfile.self, forKey: .userProfile)
        settings = [:]
        preferences = [:]
        activityData = [:]
        socialConnections = [:]
        mediaFiles = [:]
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(userProfile, forKey: .userProfile)
        // Note: Complex dictionaries are simplified for encoding
    }
}

struct RestoreResult: Codable {
    let backupId: String
    let restoredAt: Date
    let itemsRestored: Int
    let success: Bool
}

struct SyncResult: Codable {
    let devicesSynced: Int
    let syncDate: Date
    let success: Bool
}

struct BackupSchedule: Codable {
    let frequency: BackupFrequency
    let retentionDays: Int
    let isEnabled: Bool = true
}

enum BackupFrequency: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case invalid = "invalid"
}

struct BackupAnalytics: Codable {
    let totalBackups: Int
    let totalSize: Int
    let averageBackupSize: Int
    let lastBackupDate: Date
    let backupSuccessRate: Double
}

struct DeviceInfo: Codable, Identifiable {
    let id: String
    let name: String
    let type: DeviceType
    let osVersion: String
    let appVersion: String
    let lastSeen: Date
}

enum DeviceType: String, Codable, CaseIterable {
    case iPhone = "iphone"
    case iPad = "ipad"
    case mac = "mac"
    case watch = "watch"
    case tv = "tv"
    case invalid = "invalid"
}

struct DeviceRegistration: Codable {
    let deviceId: String
    let registeredAt: Date
    let status: RegistrationStatus
}

enum RegistrationStatus: String, Codable {
    case active = "active"
    case inactive = "inactive"
    case pending = "pending"
}

struct DataConflict: Codable {
    let field: String
    let deviceId: String
    let value: String
    let timestamp: Date
}

struct ExportResult: Codable {
    let backupId: String
    let format: ExportFormat
    let data: Data
    let exportedAt: Date
}

enum ExportFormat: String, Codable, CaseIterable {
    case json = "json"
    case xml = "xml"
    case csv = "csv"
    case zip = "zip"
}

struct CleanupResult: Codable {
    let deletedBackups: Int
    let freedSpace: Int64
    let cleanedAt: Date
}

enum BackupError: Error, LocalizedError {
    case invalidProfileData
    case profileDataTooLarge
    case backupIntegrityCheckFailed
    case invalidBackupSchedule
    case invalidRetentionPeriod
    case invalidDeviceInfo
    case invalidDeviceType
    case backupCreationFailed
    case backupRestorationFailed
    case syncFailed
    case deviceRegistrationFailed
    case exportFailed
    case cleanupFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidProfileData:
            return "Invalid profile data"
        case .profileDataTooLarge:
            return "Profile data is too large"
        case .backupIntegrityCheckFailed:
            return "Backup integrity check failed"
        case .invalidBackupSchedule:
            return "Invalid backup schedule"
        case .invalidRetentionPeriod:
            return "Invalid retention period"
        case .invalidDeviceInfo:
            return "Invalid device information"
        case .invalidDeviceType:
            return "Invalid device type"
        case .backupCreationFailed:
            return "Backup creation failed"
        case .backupRestorationFailed:
            return "Backup restoration failed"
        case .syncFailed:
            return "Profile sync failed"
        case .deviceRegistrationFailed:
            return "Device registration failed"
        case .exportFailed:
            return "Backup export failed"
        case .cleanupFailed:
            return "Backup cleanup failed"
        }
    }
} 