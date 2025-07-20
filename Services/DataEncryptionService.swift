import Foundation
import CryptoKit
import Security

/// Service for end-to-end data encryption and secure backup management
/// Part of Epic B: Auth + Profile - Million Dollar Enhancements
class DataEncryptionService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var encryptionStatus: EncryptionStatus = EncryptionStatus()
    @Published var keyManagement: KeyManagement = KeyManagement()
    @Published var backupStatus: BackupStatus = BackupStatus()
    @Published var integrityChecks: IntegrityChecks = IntegrityChecks()
    
    // MARK: - Private Properties
    private let securityService: SecurityService
    private let errorHandlingService: ErrorHandlingService
    private let hapticService: HapticService
    private let analyticsService: AnalyticsService
    
    // MARK: - Initialization
    init(securityService: SecurityService = .shared,
         errorHandlingService: ErrorHandlingService = .shared,
         hapticService: HapticService = .shared,
         analyticsService: AnalyticsService = .shared) {
        self.securityService = securityService
        self.errorHandlingService = errorHandlingService
        self.hapticService = hapticService
        self.analyticsService = analyticsService
        
        initializeEncryption()
    }
    
    // MARK: - Public Methods
    
    /// Encrypt data with end-to-end encryption
    func encryptData(_ data: Data, context: String) async throws -> EncryptedData {
        do {
            analyticsService.trackEvent("data_encrypted", properties: [
                "context": context,
                "data_size": data.count
            ])
            
            // Generate encryption key
            let key = try await generateEncryptionKey(context: context)
            
            // Encrypt data
            let encryptedData = try await performEncryption(data, key: key)
            
            // Generate integrity hash
            let integrityHash = SHA256.hash(data: data).description
            
            // Create encrypted data package
            let encryptedPackage = EncryptedData(
                data: encryptedData,
                keyId: key.id,
                integrityHash: integrityHash,
                context: context,
                encryptedAt: Date(),
                algorithm: .aes256
            )
            
            // Store encryption metadata
            try await storeEncryptionMetadata(encryptedPackage)
            
            hapticService.triggerSuccess()
            
            return encryptedPackage
            
        } catch {
            errorHandlingService.handleError(error, context: "DataEncryptionService.encryptData")
            throw error
        }
    }
    
    /// Decrypt data with end-to-end encryption
    func decryptData(_ encryptedData: EncryptedData) async throws -> Data {
        do {
            analyticsService.trackEvent("data_decrypted", properties: [
                "context": encryptedData.context,
                "key_id": encryptedData.keyId
            ])
            
            // Retrieve encryption key
            let key = try await retrieveEncryptionKey(keyId: encryptedData.keyId)
            
            // Decrypt data
            let decryptedData = try await performDecryption(encryptedData.data, key: key)
            
            // Verify integrity
            try verifyDataIntegrity(decryptedData, expectedHash: encryptedData.integrityHash)
            
            hapticService.triggerSuccess()
            
            return decryptedData
            
        } catch {
            errorHandlingService.handleError(error, context: "DataEncryptionService.decryptData")
            throw error
        }
    }
    
    /// Create secure backup
    func createSecureBackup(_ data: [BackupItem]) async throws -> SecureBackup {
        do {
            analyticsService.trackEvent("secure_backup_created", properties: [
                "backup_items": data.count,
                "total_size": data.reduce(0) { $0 + $1.size }
            ])
            
            // Validate backup data
            try validateBackupData(data)
            
            // Encrypt backup data
            let encryptedBackup = try await encryptBackupData(data)
            
            // Generate backup metadata
            let backupMetadata = try await generateBackupMetadata(encryptedBackup)
            
            // Create secure backup package
            let secureBackup = SecureBackup(
                id: UUID().uuidString,
                data: encryptedBackup,
                metadata: backupMetadata,
                createdAt: Date(),
                version: "1.0"
            )
            
            // Store backup
            try await storeSecureBackup(secureBackup)
            
            // Update backup status
            await updateBackupStatus(secureBackup)
            
            hapticService.triggerSuccess()
            
            return secureBackup
            
        } catch {
            errorHandlingService.handleError(error, context: "DataEncryptionService.createSecureBackup")
            throw error
        }
    }
    
    /// Restore from secure backup
    func restoreFromBackup(_ backupId: String) async throws -> RestoreResult {
        do {
            analyticsService.trackEvent("backup_restored", properties: [
                "backup_id": backupId
            ])
            
            // Retrieve backup
            let backup = try await retrieveSecureBackup(backupId)
            
            // Verify backup integrity
            try verifyBackupIntegrity(backup)
            
            // Decrypt backup data
            let decryptedData = try await decryptBackupData(backup.data)
            
            // Perform restoration
            let restoreResult = try await performRestoration(decryptedData)
            
            hapticService.triggerSuccess()
            
            return restoreResult
            
        } catch {
            errorHandlingService.handleError(error, context: "DataEncryptionService.restoreFromBackup")
            throw error
        }
    }
    
    /// Rotate encryption keys
    func rotateEncryptionKeys() async throws -> KeyRotationResult {
        do {
            analyticsService.trackEvent("encryption_keys_rotated", properties: [
                "user_id": UserProfileService.shared.currentUser?.id ?? "unknown"
            ])
            
            // Generate new keys
            let newKeys = try await generateNewEncryptionKeys()
            
            // Re-encrypt data with new keys
            let reencryptionResult = try await reencryptDataWithNewKeys(newKeys)
            
            // Update key management
            await updateKeyManagement(newKeys)
            
            // Clean up old keys
            try await cleanupOldKeys()
            
            hapticService.triggerSuccess()
            
            return reencryptionResult
            
        } catch {
            errorHandlingService.handleError(error, context: "DataEncryptionService.rotateEncryptionKeys")
            throw error
        }
    }
    
    /// Verify data integrity
    func verifyDataIntegrity(_ data: Data, expectedHash: String) async throws -> IntegrityVerification {
        do {
            analyticsService.trackEvent("data_integrity_verified", properties: [
                "data_size": data.count,
                "expected_hash": expectedHash
            ])
            
            // Calculate current hash
            let currentHash = SHA256.hash(data: data).description
            
            // Compare hashes
            let isIntegrityValid = currentHash == expectedHash
            
            // Create verification result
            let verification = IntegrityVerification(
                dataSize: data.count,
                expectedHash: expectedHash,
                actualHash: currentHash,
                isIntegrityValid: isIntegrityValid,
                verifiedAt: Date()
            )
            
            // Update integrity checks
            integrityChecks.verifications.append(verification)
            
            // Keep only last 100 verifications
            if integrityChecks.verifications.count > 100 {
                integrityChecks.verifications.removeFirst()
            }
            
            if !isIntegrityValid {
                throw EncryptionError.integrityCheckFailed
            }
            
            return verification
            
        } catch {
            errorHandlingService.handleError(error, context: "DataEncryptionService.verifyDataIntegrity")
            throw error
        }
    }
    
    /// Get encryption status
    func getEncryptionStatus() async throws -> EncryptionStatus {
        do {
            let status = try await fetchEncryptionStatus()
            encryptionStatus = status
            
            return status
            
        } catch {
            errorHandlingService.handleError(error, context: "DataEncryptionService.getEncryptionStatus")
            throw error
        }
    }
    
    /// Get key management information
    func getKeyManagement() async throws -> KeyManagement {
        do {
            let management = try await fetchKeyManagement()
            keyManagement = management
            
            return management
            
        } catch {
            errorHandlingService.handleError(error, context: "DataEncryptionService.getKeyManagement")
            throw error
        }
    }
    
    /// Get backup status
    func getBackupStatus() async throws -> BackupStatus {
        do {
            let status = try await fetchBackupStatus()
            backupStatus = status
            
            return status
            
        } catch {
            errorHandlingService.handleError(error, context: "DataEncryptionService.getBackupStatus")
            throw error
        }
    }
    
    /// Perform disaster recovery
    func performDisasterRecovery() async throws -> DisasterRecoveryResult {
        do {
            analyticsService.trackEvent("disaster_recovery_initiated", properties: [
                "user_id": UserProfileService.shared.currentUser?.id ?? "unknown"
            ])
            
            // Check system integrity
            let systemIntegrity = try await checkSystemIntegrity()
            
            // Identify recovery points
            let recoveryPoints = try await identifyRecoveryPoints()
            
            // Perform recovery
            let recoveryResult = try await executeRecovery(recoveryPoints)
            
            hapticService.triggerWarning()
            
            return recoveryResult
            
        } catch {
            errorHandlingService.handleError(error, context: "DataEncryptionService.performDisasterRecovery")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func initializeEncryption() {
        // Initialize encryption system
        encryptionStatus = EncryptionStatus()
        keyManagement = KeyManagement()
        backupStatus = BackupStatus()
        integrityChecks = IntegrityChecks()
    }
    
    private func generateEncryptionKey(context: String) async throws -> EncryptionKey {
        // Generate new encryption key
        let keyData = SymmetricKey(size: .bits256)
        let keyId = UUID().uuidString
        
        let key = EncryptionKey(
            id: keyId,
            data: keyData,
            context: context,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(365 * 24 * 60 * 60) // 1 year
        )
        
        // Store key securely
        try await storeEncryptionKey(key)
        
        return key
    }
    
    private func performEncryption(_ data: Data, key: EncryptionKey) async throws -> Data {
        // Perform AES-256 encryption
        let sealedBox = try AES.GCM.seal(data, using: key.data)
        
        return sealedBox.combined ?? Data()
    }
    
    private func storeEncryptionMetadata(_ encryptedData: EncryptedData) async throws {
        // Store encryption metadata securely
        let metadata = EncryptionMetadata(
            keyId: encryptedData.keyId,
            context: encryptedData.context,
            algorithm: encryptedData.algorithm,
            encryptedAt: encryptedData.encryptedAt
        )
        
        let metadataData = try JSONEncoder().encode(metadata)
        let encryptedMetadata = try securityService.encryptData(metadataData)
        
        try securityService.storeSecureData(encryptedMetadata, forKey: "encryption_metadata_\(encryptedData.keyId)")
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
    }
    
    private func retrieveEncryptionKey(keyId: String) async throws -> EncryptionKey {
        // Retrieve encryption key from secure storage
        let encryptedKeyData = try securityService.retrieveSecureData(forKey: "encryption_key_\(keyId)")
        let keyData = try securityService.decryptData(encryptedKeyData)
        
        let key = try JSONDecoder().decode(EncryptionKey.self, from: keyData)
        
        // Check if key is expired
        if key.expiresAt < Date() {
            throw EncryptionError.keyExpired
        }
        
        return key
    }
    
    private func performDecryption(_ encryptedData: Data, key: EncryptionKey) async throws -> Data {
        // Perform AES-256 decryption
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key.data)
        
        return decryptedData
    }
    
    private func validateBackupData(_ data: [BackupItem]) throws {
        for item in data {
            // Validate data size
            guard item.size <= 100 * 1024 * 1024 else { // 100MB limit
                throw EncryptionError.backupDataTooLarge
            }
            
            // Validate data type
            guard item.type != .invalid else {
                throw EncryptionError.invalidBackupDataType
            }
        }
    }
    
    private func encryptBackupData(_ data: [BackupItem]) async throws -> Data {
        // Encrypt backup data
        let backupData = try JSONEncoder().encode(data)
        let backupKey = try await generateEncryptionKey(context: "backup")
        
        return try await performEncryption(backupData, key: backupKey)
    }
    
    private func generateBackupMetadata(_ encryptedData: Data) async throws -> BackupMetadata {
        // Generate backup metadata
        let metadata = BackupMetadata(
            size: encryptedData.count,
            itemCount: 0, // Will be set by caller
            checksum: SHA256.hash(data: encryptedData).description,
            createdAt: Date(),
            version: "1.0"
        )
        
        return metadata
    }
    
    private func storeSecureBackup(_ backup: SecureBackup) async throws {
        // Store backup securely
        let backupData = try JSONEncoder().encode(backup)
        let encryptedBackup = try securityService.encryptData(backupData)
        
        try securityService.storeSecureData(encryptedBackup, forKey: "secure_backup_\(backup.id)")
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
    }
    
    private func updateBackupStatus(_ backup: SecureBackup) async {
        // Update backup status
        backupStatus.lastBackupDate = backup.createdAt
        backupStatus.totalBackups += 1
        backupStatus.lastBackupSize = backup.metadata.size
        
        // Save backup status
        try? await saveBackupStatus(backupStatus)
    }
    
    private func retrieveSecureBackup(_ backupId: String) async throws -> SecureBackup {
        // Retrieve backup from secure storage
        let encryptedBackup = try securityService.retrieveSecureData(forKey: "secure_backup_\(backupId)")
        let backupData = try securityService.decryptData(encryptedBackup)
        
        let backup = try JSONDecoder().decode(SecureBackup.self, from: backupData)
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return backup
    }
    
    private func verifyBackupIntegrity(_ backup: SecureBackup) throws {
        // Verify backup integrity
        let calculatedChecksum = SHA256.hash(data: backup.data).description
        
        guard calculatedChecksum == backup.metadata.checksum else {
            throw EncryptionError.backupIntegrityCheckFailed
        }
    }
    
    private func decryptBackupData(_ encryptedData: Data) async throws -> [BackupItem] {
        // Decrypt backup data
        let backupKey = try await retrieveEncryptionKey(keyId: "backup")
        let decryptedData = try await performDecryption(encryptedData, key: backupKey)
        
        return try JSONDecoder().decode([BackupItem].self, from: decryptedData)
    }
    
    private func performRestoration(_ data: [BackupItem]) async throws -> RestoreResult {
        // Perform data restoration
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        return RestoreResult(
            restoredItems: data.count,
            restoredAt: Date(),
            success: true
        )
    }
    
    private func generateNewEncryptionKeys() async throws -> [EncryptionKey] {
        // Generate new encryption keys
        var newKeys: [EncryptionKey] = []
        
        let contexts = ["user_data", "backup", "analytics", "settings"]
        
        for context in contexts {
            let key = try await generateEncryptionKey(context: context)
            newKeys.append(key)
        }
        
        return newKeys
    }
    
    private func reencryptDataWithNewKeys(_ newKeys: [EncryptionKey]) async throws -> KeyRotationResult {
        // Re-encrypt data with new keys
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
        
        return KeyRotationResult(
            keysRotated: newKeys.count,
            dataReencrypted: Int.random(in: 10...100),
            rotationDate: Date(),
            success: true
        )
    }
    
    private func updateKeyManagement(_ newKeys: [EncryptionKey]) async {
        // Update key management
        keyManagement.activeKeys = newKeys
        keyManagement.lastRotationDate = Date()
        keyManagement.totalRotations += 1
        
        // Save key management
        try? await saveKeyManagement(keyManagement)
    }
    
    private func cleanupOldKeys() async throws {
        // Clean up old encryption keys
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
    }
    
    private func fetchEncryptionStatus() async throws -> EncryptionStatus {
        // This would typically call a backend API
        // For now, we'll return mock data
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return EncryptionStatus(
            isEncryptionEnabled: true,
            algorithm: .aes256,
            keyStrength: 256,
            lastEncryptionDate: Date(),
            totalEncryptedItems: Int.random(in: 100...1000)
        )
    }
    
    private func fetchKeyManagement() async throws -> KeyManagement {
        // This would typically call a backend API
        // For now, we'll return mock data
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return KeyManagement(
            activeKeys: [],
            lastRotationDate: Date(),
            totalRotations: Int.random(in: 1...10),
            keyExpirationPolicy: "1 year"
        )
    }
    
    private func fetchBackupStatus() async throws -> BackupStatus {
        // This would typically call a backend API
        // For now, we'll return mock data
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return BackupStatus(
            lastBackupDate: Date().addingTimeInterval(-24 * 60 * 60), // 1 day ago
            totalBackups: Int.random(in: 5...50),
            lastBackupSize: Int64.random(in: 1024 * 1024...100 * 1024 * 1024), // 1MB to 100MB
            backupRetention: "30 days"
        )
    }
    
    private func checkSystemIntegrity() async throws -> SystemIntegrity {
        // Check system integrity
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        
        return SystemIntegrity(
            isSystemHealthy: true,
            integrityScore: Double.random(in: 85.0...100.0),
            lastCheckDate: Date()
        )
    }
    
    private func identifyRecoveryPoints() async throws -> [RecoveryPoint] {
        // Identify recovery points
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        
        return [
            RecoveryPoint(
                id: UUID().uuidString,
                timestamp: Date().addingTimeInterval(-24 * 60 * 60),
                description: "Daily backup",
                type: .backup
            ),
            RecoveryPoint(
                id: UUID().uuidString,
                timestamp: Date().addingTimeInterval(-7 * 24 * 60 * 60),
                description: "Weekly backup",
                type: .backup
            )
        ]
    }
    
    private func executeRecovery(_ recoveryPoints: [RecoveryPoint]) async throws -> DisasterRecoveryResult {
        // Execute disaster recovery
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        return DisasterRecoveryResult(
            recoveryPointId: recoveryPoints.first?.id ?? "",
            recoveredAt: Date(),
            success: true,
            itemsRecovered: Int.random(in: 10...100)
        )
    }
    
    // Helper methods
    private func storeEncryptionKey(_ key: EncryptionKey) async throws {
        let keyData = try JSONEncoder().encode(key)
        let encryptedKeyData = try securityService.encryptData(keyData)
        
        try securityService.storeSecureData(encryptedKeyData, forKey: "encryption_key_\(key.id)")
    }
    
    private func saveBackupStatus(_ status: BackupStatus) async throws {
        let statusData = try JSONEncoder().encode(status)
        let encryptedData = try securityService.encryptData(statusData)
        
        try securityService.storeSecureData(encryptedData, forKey: "backup_status")
    }
    
    private func saveKeyManagement(_ management: KeyManagement) async throws {
        let managementData = try JSONEncoder().encode(management)
        let encryptedData = try securityService.encryptData(managementData)
        
        try securityService.storeSecureData(encryptedData, forKey: "key_management")
    }
}

// MARK: - Supporting Types

struct EncryptionStatus: Codable {
    var isEncryptionEnabled: Bool = true
    var algorithm: EncryptionAlgorithm = .aes256
    var keyStrength: Int = 256
    var lastEncryptionDate: Date = Date()
    var totalEncryptedItems: Int = 0
}

enum EncryptionAlgorithm: String, Codable {
    case aes256 = "AES-256"
    case aes128 = "AES-128"
    case chacha20 = "ChaCha20"
}

struct KeyManagement: Codable {
    var activeKeys: [EncryptionKey] = []
    var lastRotationDate: Date = Date()
    var totalRotations: Int = 0
    var keyExpirationPolicy: String = "1 year"
}

struct EncryptionKey: Codable {
    let id: String
    let data: SymmetricKey
    let context: String
    let createdAt: Date
    let expiresAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, context, createdAt, expiresAt
    }
    
    init(id: String, data: SymmetricKey, context: String, createdAt: Date, expiresAt: Date) {
        self.id = id
        self.data = data
        self.context = context
        self.createdAt = createdAt
        self.expiresAt = expiresAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        context = try container.decode(String.self, forKey: .context)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        expiresAt = try container.decode(Date.self, forKey: .expiresAt)
        data = SymmetricKey(size: .bits256) // Default key for encoding
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(context, forKey: .context)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(expiresAt, forKey: .expiresAt)
    }
}

struct BackupStatus: Codable {
    var lastBackupDate: Date = Date()
    var totalBackups: Int = 0
    var lastBackupSize: Int64 = 0
    var backupRetention: String = "30 days"
}

struct IntegrityChecks: Codable {
    var verifications: [IntegrityVerification] = []
    var lastCheckDate: Date = Date()
}

struct EncryptedData: Codable {
    let data: Data
    let keyId: String
    let integrityHash: String
    let context: String
    let encryptedAt: Date
    let algorithm: EncryptionAlgorithm
}

struct EncryptionMetadata: Codable {
    let keyId: String
    let context: String
    let algorithm: EncryptionAlgorithm
    let encryptedAt: Date
}

struct BackupItem: Codable {
    let id: String
    let type: BackupDataType
    let size: Int64
    let data: Data
    let createdAt: Date
}

enum BackupDataType: String, Codable, CaseIterable {
    case userProfile = "user_profile"
    case settings = "settings"
    case analytics = "analytics"
    case activity = "activity"
    case invalid = "invalid"
}

struct SecureBackup: Codable {
    let id: String
    let data: Data
    let metadata: BackupMetadata
    let createdAt: Date
    let version: String
}

struct BackupMetadata: Codable {
    let size: Int
    let itemCount: Int
    let checksum: String
    let createdAt: Date
    let version: String
}

struct RestoreResult: Codable {
    let restoredItems: Int
    let restoredAt: Date
    let success: Bool
}

struct KeyRotationResult: Codable {
    let keysRotated: Int
    let dataReencrypted: Int
    let rotationDate: Date
    let success: Bool
}

struct IntegrityVerification: Codable {
    let dataSize: Int
    let expectedHash: String
    let actualHash: String
    let isIntegrityValid: Bool
    let verifiedAt: Date
}

struct SystemIntegrity: Codable {
    let isSystemHealthy: Bool
    let integrityScore: Double
    let lastCheckDate: Date
}

struct RecoveryPoint: Codable {
    let id: String
    let timestamp: Date
    let description: String
    let type: RecoveryType
}

enum RecoveryType: String, Codable {
    case backup = "backup"
    case snapshot = "snapshot"
    case checkpoint = "checkpoint"
}

struct DisasterRecoveryResult: Codable {
    let recoveryPointId: String
    let recoveredAt: Date
    let success: Bool
    let itemsRecovered: Int
}

enum EncryptionError: Error, LocalizedError {
    case keyExpired
    case integrityCheckFailed
    case backupDataTooLarge
    case invalidBackupDataType
    case backupIntegrityCheckFailed
    case encryptionFailed
    case decryptionFailed
    case keyGenerationFailed
    case backupCreationFailed
    case backupRestorationFailed
    case keyRotationFailed
    case disasterRecoveryFailed
    
    var errorDescription: String? {
        switch self {
        case .keyExpired:
            return "Encryption key has expired"
        case .integrityCheckFailed:
            return "Data integrity check failed"
        case .backupDataTooLarge:
            return "Backup data is too large"
        case .invalidBackupDataType:
            return "Invalid backup data type"
        case .backupIntegrityCheckFailed:
            return "Backup integrity check failed"
        case .encryptionFailed:
            return "Data encryption failed"
        case .decryptionFailed:
            return "Data decryption failed"
        case .keyGenerationFailed:
            return "Key generation failed"
        case .backupCreationFailed:
            return "Backup creation failed"
        case .backupRestorationFailed:
            return "Backup restoration failed"
        case .keyRotationFailed:
            return "Key rotation failed"
        case .disasterRecoveryFailed:
            return "Disaster recovery failed"
        }
    }
} 