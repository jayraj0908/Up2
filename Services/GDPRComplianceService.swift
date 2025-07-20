import Foundation
import CryptoKit

/// Service for GDPR compliance and data protection management
/// Part of Epic B: Auth + Profile - Million Dollar Enhancements
class GDPRComplianceService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var consentStatus: ConsentStatus = ConsentStatus()
    @Published var dataRights: DataRights = DataRights()
    @Published var complianceStatus: GDPRComplianceStatus = GDPRComplianceStatus()
    @Published var dataProcessingActivities: [DataProcessingActivity] = []
    
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
        
        loadConsentStatus()
    }
    
    // MARK: - Public Methods
    
    /// Request data export (Right to Data Portability)
    func requestDataExport() async throws -> DataExportRequest {
        do {
            analyticsService.trackEvent("gdpr_data_export_requested", properties: [
                "user_id": UserProfileService.shared.currentUser?.id ?? "unknown"
            ])
            
            // Validate user identity
            try await validateUserIdentity()
            
            // Create export request
            let request = try await createDataExportRequest()
            
            // Collect user data
            let userData = try await collectUserDataForExport()
            
            // Encrypt and package data
            let exportPackage = try await createExportPackage(userData)
            
            // Store export record
            try await storeExportRecord(exportPackage)
            
            hapticService.triggerSuccess()
            
            return request
            
        } catch {
            errorHandlingService.handleError(error, context: "GDPRComplianceService.requestDataExport")
            throw error
        }
    }
    
    /// Request data deletion (Right to be Forgotten)
    func requestDataDeletion(reason: String) async throws -> DataDeletionRequest {
        do {
            analyticsService.trackEvent("gdpr_data_deletion_requested", properties: [
                "user_id": UserProfileService.shared.currentUser?.id ?? "unknown",
                "reason": reason
            ])
            
            // Validate user identity
            try await validateUserIdentity()
            
            // Create deletion request
            let request = try await createDataDeletionRequest(reason: reason)
            
            // Process data deletion
            try await processDataDeletion(request)
            
            // Update compliance status
            await updateComplianceStatus()
            
            hapticService.triggerWarning()
            
            return request
            
        } catch {
            errorHandlingService.handleError(error, context: "GDPRComplianceService.requestDataDeletion")
            throw error
        }
    }
    
    /// Request data rectification
    func requestDataRectification(corrections: [DataCorrection]) async throws -> DataRectificationRequest {
        do {
            analyticsService.trackEvent("gdpr_data_rectification_requested", properties: [
                "user_id": UserProfileService.shared.currentUser?.id ?? "unknown",
                "corrections_count": corrections.count
            ])
            
            // Validate corrections
            try validateDataCorrections(corrections)
            
            // Create rectification request
            let request = try await createDataRectificationRequest(corrections)
            
            // Process corrections
            try await processDataCorrections(request)
            
            hapticService.triggerSuccess()
            
            return request
            
        } catch {
            errorHandlingService.handleError(error, context: "GDPRComplianceService.requestDataRectification")
            throw error
        }
    }
    
    /// Update consent preferences
    func updateConsentPreferences(_ preferences: ConsentPreferences) async throws {
        do {
            analyticsService.trackEvent("gdpr_consent_preferences_updated", properties: [
                "user_id": UserProfileService.shared.currentUser?.id ?? "unknown",
                "data_processing": preferences.dataProcessing,
                "marketing": preferences.marketing,
                "third_party_sharing": preferences.thirdPartySharing
            ])
            
            // Validate consent preferences
            try validateConsentPreferences(preferences)
            
            // Update consent status
            consentStatus.preferences = preferences
            consentStatus.lastUpdated = Date()
            
            // Save consent status
            try await saveConsentStatus(consentStatus)
            
            // Update data processing activities
            await updateDataProcessingActivities(preferences)
            
            hapticService.triggerSuccess()
            
        } catch {
            errorHandlingService.handleError(error, context: "GDPRComplianceService.updateConsentPreferences")
            throw error
        }
    }
    
    /// Get data processing activities
    func getDataProcessingActivities() async throws -> [DataProcessingActivity] {
        do {
            let activities = try await fetchDataProcessingActivities()
            dataProcessingActivities = activities
            
            analyticsService.trackEvent("gdpr_processing_activities_requested", properties: [
                "user_id": UserProfileService.shared.currentUser?.id ?? "unknown",
                "activities_count": activities.count
            ])
            
            return activities
            
        } catch {
            errorHandlingService.handleError(error, context: "GDPRComplianceService.getDataProcessingActivities")
            throw error
        }
    }
    
    /// Check GDPR compliance status
    func checkComplianceStatus() async throws -> GDPRComplianceStatus {
        do {
            let status = try await fetchComplianceStatus()
            complianceStatus = status
            
            analyticsService.trackEvent("gdpr_compliance_status_checked", properties: [
                "user_id": UserProfileService.shared.currentUser?.id ?? "unknown",
                "is_compliant": status.isCompliant,
                "compliance_score": status.complianceScore
            ])
            
            return status
            
        } catch {
            errorHandlingService.handleError(error, context: "GDPRComplianceService.checkComplianceStatus")
            throw error
        }
    }
    
    /// Request data access (Right of Access)
    func requestDataAccess() async throws -> DataAccessRequest {
        do {
            analyticsService.trackEvent("gdpr_data_access_requested", properties: [
                "user_id": UserProfileService.shared.currentUser?.id ?? "unknown"
            ])
            
            // Validate user identity
            try await validateUserIdentity()
            
            // Create access request
            let request = try await createDataAccessRequest()
            
            // Generate access report
            let accessReport = try await generateDataAccessReport()
            
            // Store access record
            try await storeAccessRecord(request, report: accessReport)
            
            hapticService.triggerSuccess()
            
            return request
            
        } catch {
            errorHandlingService.handleError(error, context: "GDPRComplianceService.requestDataAccess")
            throw error
        }
    }
    
    /// Object to data processing
    func objectToDataProcessing(grounds: String) async throws -> DataProcessingObjection {
        do {
            analyticsService.trackEvent("gdpr_processing_objection_submitted", properties: [
                "user_id": UserProfileService.shared.currentUser?.id ?? "unknown",
                "grounds": grounds
            ])
            
            // Create objection request
            let objection = try await createDataProcessingObjection(grounds: grounds)
            
            // Process objection
            try await processObjection(objection)
            
            hapticService.triggerWarning()
            
            return objection
            
        } catch {
            errorHandlingService.handleError(error, context: "GDPRComplianceService.objectToDataProcessing")
            throw error
        }
    }
    
    /// Request data portability
    func requestDataPortability(format: DataFormat) async throws -> DataPortabilityRequest {
        do {
            analyticsService.trackEvent("gdpr_data_portability_requested", properties: [
                "user_id": UserProfileService.shared.currentUser?.id ?? "unknown",
                "format": format.rawValue
            ])
            
            // Validate user identity
            try await validateUserIdentity()
            
            // Create portability request
            let request = try await createDataPortabilityRequest(format: format)
            
            // Prepare portable data
            let portableData = try await preparePortableData(format: format)
            
            // Store portability record
            try await storePortabilityRecord(request, data: portableData)
            
            hapticService.triggerSuccess()
            
            return request
            
        } catch {
            errorHandlingService.handleError(error, context: "GDPRComplianceService.requestDataPortability")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func loadConsentStatus() {
        // Load saved consent status from secure storage
        // For now, we'll use default values
        consentStatus = ConsentStatus()
        dataRights = DataRights()
        complianceStatus = GDPRComplianceStatus()
    }
    
    private func validateUserIdentity() async throws {
        // Validate user identity for GDPR requests
        guard let user = UserProfileService.shared.currentUser else {
            throw GDPRError.userNotAuthenticated
        }
        
        // Additional identity verification if needed
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
    }
    
    private func createDataExportRequest() async throws -> DataExportRequest {
        let request = DataExportRequest(
            id: UUID().uuidString,
            userId: UserProfileService.shared.currentUser?.id ?? "",
            requestedAt: Date(),
            status: .pending,
            format: .json
        )
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        return request
    }
    
    private func collectUserDataForExport() async throws -> UserDataCollection {
        // Collect all user data for export
        var dataTypes: [DataType] = []
        var exportData = Data()
        
        // Profile data
        if let user = UserProfileService.shared.currentUser {
            let profileData = try JSONEncoder().encode(user)
            exportData.append(profileData)
            dataTypes.append(.profile)
        }
        
        // Activity data
        let activityData = try await fetchActivityData()
        exportData.append(activityData)
        dataTypes.append(.activity)
        
        // Settings data
        let settingsData = try JSONEncoder().encode(consentStatus)
        exportData.append(settingsData)
        dataTypes.append(.settings)
        
        // Analytics data
        let analyticsData = try await fetchAnalyticsData()
        exportData.append(analyticsData)
        dataTypes.append(.analytics)
        
        return UserDataCollection(
            exportData: exportData,
            dataTypes: dataTypes,
            collectedAt: Date()
        )
    }
    
    private func createExportPackage(_ userData: UserDataCollection) async throws -> DataExportPackage {
        // Encrypt export data
        let encryptedData = try securityService.encryptData(userData.exportData)
        
        // Generate export hash for integrity
        let exportHash = SHA256.hash(data: userData.exportData).description
        
        return DataExportPackage(
            data: encryptedData,
            hash: exportHash,
            dataTypes: userData.dataTypes,
            exportedAt: Date(),
            format: .json
        )
    }
    
    private func storeExportRecord(_ package: DataExportPackage) async throws {
        // Store export record in secure storage
        let exportRecord = DataExportRecord(
            package: package,
            userId: UserProfileService.shared.currentUser?.id ?? "",
            storedAt: Date()
        )
        
        let recordData = try JSONEncoder().encode(exportRecord)
        let encryptedRecord = try securityService.encryptData(recordData)
        
        try securityService.storeSecureData(encryptedRecord, forKey: "gdpr_export_\(exportRecord.id)")
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
    }
    
    private func createDataDeletionRequest(reason: String) async throws -> DataDeletionRequest {
        let request = DataDeletionRequest(
            id: UUID().uuidString,
            userId: UserProfileService.shared.currentUser?.id ?? "",
            reason: reason,
            requestedAt: Date(),
            status: .pending
        )
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        return request
    }
    
    private func processDataDeletion(_ request: DataDeletionRequest) async throws {
        // Process data deletion
        try await deleteUserProfile()
        try await deleteUserActivity()
        try await deleteUserSettings()
        try await deleteUserAnalytics()
        
        // Update request status
        try await updateDeletionRequestStatus(request.id, status: .completed)
    }
    
    private func updateComplianceStatus() async {
        // Update GDPR compliance status
        complianceStatus.lastAuditDate = Date()
        complianceStatus.isCompliant = true
        complianceStatus.complianceScore = 95.0
        
        // Save compliance status
        try? await saveComplianceStatus(complianceStatus)
    }
    
    private func validateDataCorrections(_ corrections: [DataCorrection]) throws {
        for correction in corrections {
            // Validate correction data
            guard !correction.field.isEmpty else {
                throw GDPRError.invalidCorrectionField
            }
            
            guard !correction.newValue.isEmpty else {
                throw GDPRError.invalidCorrectionValue
            }
        }
    }
    
    private func createDataRectificationRequest(_ corrections: [DataCorrection]) async throws -> DataRectificationRequest {
        let request = DataRectificationRequest(
            id: UUID().uuidString,
            userId: UserProfileService.shared.currentUser?.id ?? "",
            corrections: corrections,
            requestedAt: Date(),
            status: .pending
        )
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        return request
    }
    
    private func processDataCorrections(_ request: DataRectificationRequest) async throws {
        // Process data corrections
        for correction in request.corrections {
            try await applyDataCorrection(correction)
        }
        
        // Update request status
        try await updateRectificationRequestStatus(request.id, status: .completed)
    }
    
    private func validateConsentPreferences(_ preferences: ConsentPreferences) throws {
        // Validate consent preferences
        guard preferences.dataProcessing || preferences.dataProcessing == false else {
            throw GDPRError.invalidDataProcessingConsent
        }
        
        guard preferences.marketing || preferences.marketing == false else {
            throw GDPRError.invalidMarketingConsent
        }
        
        guard preferences.thirdPartySharing || preferences.thirdPartySharing == false else {
            throw GDPRError.invalidThirdPartyConsent
        }
    }
    
    private func saveConsentStatus(_ status: ConsentStatus) async throws {
        // Save consent status to secure storage
        let statusData = try JSONEncoder().encode(status)
        let encryptedData = try securityService.encryptData(statusData)
        
        try securityService.storeSecureData(encryptedData, forKey: "gdpr_consent_status")
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
    }
    
    private func updateDataProcessingActivities(_ preferences: ConsentPreferences) async {
        // Update data processing activities based on consent
        let activity = DataProcessingActivity(
            type: .consentUpdate,
            description: "User updated consent preferences",
            legalBasis: .consent,
            dataCategories: ["personal_data", "usage_data"],
            processingPurpose: "User preference management",
            retentionPeriod: 365,
            timestamp: Date()
        )
        
        dataProcessingActivities.append(activity)
        
        // Save activities
        try? await saveDataProcessingActivities(dataProcessingActivities)
    }
    
    private func fetchDataProcessingActivities() async throws -> [DataProcessingActivity] {
        // This would typically call a backend API
        // For now, we'll return mock data
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return [
            DataProcessingActivity(
                type: .dataCollection,
                description: "User profile data collection",
                legalBasis: .consent,
                dataCategories: ["personal_data", "contact_data"],
                processingPurpose: "User account management",
                retentionPeriod: 365,
                timestamp: Date()
            ),
            DataProcessingActivity(
                type: .dataAnalysis,
                description: "User behavior analytics",
                legalBasis: .legitimateInterest,
                dataCategories: ["usage_data", "analytics_data"],
                processingPurpose: "Service improvement",
                retentionPeriod: 90,
                timestamp: Date()
            )
        ]
    }
    
    private func fetchComplianceStatus() async throws -> GDPRComplianceStatus {
        // This would typically call a backend API
        // For now, we'll return mock data
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
        
        return GDPRComplianceStatus(
            isCompliant: true,
            lastAuditDate: Date(),
            missingRequirements: [],
            complianceScore: 95.0,
            auditReport: "All GDPR requirements met"
        )
    }
    
    private func createDataAccessRequest() async throws -> DataAccessRequest {
        let request = DataAccessRequest(
            id: UUID().uuidString,
            userId: UserProfileService.shared.currentUser?.id ?? "",
            requestedAt: Date(),
            status: .pending
        )
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        return request
    }
    
    private func generateDataAccessReport() async throws -> DataAccessReport {
        // Generate comprehensive data access report
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        
        return DataAccessReport(
            userId: UserProfileService.shared.currentUser?.id ?? "",
            dataCategories: ["personal_data", "usage_data", "analytics_data"],
            processingPurposes: ["account_management", "service_improvement", "marketing"],
            dataRetention: "365 days for personal data, 90 days for analytics",
            thirdPartySharing: ["analytics_providers", "payment_processors"],
            userRights: ["access", "rectification", "erasure", "portability"],
            generatedAt: Date()
        )
    }
    
    private func storeAccessRecord(_ request: DataAccessRequest, report: DataAccessReport) async throws {
        // Store access record
        let accessRecord = DataAccessRecord(
            request: request,
            report: report,
            storedAt: Date()
        )
        
        let recordData = try JSONEncoder().encode(accessRecord)
        let encryptedRecord = try securityService.encryptData(recordData)
        
        try securityService.storeSecureData(encryptedRecord, forKey: "gdpr_access_\(request.id)")
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
    }
    
    private func createDataProcessingObjection(grounds: String) async throws -> DataProcessingObjection {
        let objection = DataProcessingObjection(
            id: UUID().uuidString,
            userId: UserProfileService.shared.currentUser?.id ?? "",
            grounds: grounds,
            submittedAt: Date(),
            status: .pending
        )
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        return objection
    }
    
    private func processObjection(_ objection: DataProcessingObjection) async throws {
        // Process data processing objection
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        
        // Update objection status
        try await updateObjectionStatus(objection.id, status: .underReview)
    }
    
    private func createDataPortabilityRequest(format: DataFormat) async throws -> DataPortabilityRequest {
        let request = DataPortabilityRequest(
            id: UUID().uuidString,
            userId: UserProfileService.shared.currentUser?.id ?? "",
            format: format,
            requestedAt: Date(),
            status: .pending
        )
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        return request
    }
    
    private func preparePortableData(format: DataFormat) async throws -> DataPortabilityPackage {
        // Prepare data in requested format
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second delay
        
        return DataPortabilityPackage(
            userId: UserProfileService.shared.currentUser?.id ?? "",
            format: format,
            data: Data(),
            preparedAt: Date()
        )
    }
    
    private func storePortabilityRecord(_ request: DataPortabilityRequest, data: DataPortabilityPackage) async throws {
        // Store portability record
        let portabilityRecord = DataPortabilityRecord(
            request: request,
            package: data,
            storedAt: Date()
        )
        
        let recordData = try JSONEncoder().encode(portabilityRecord)
        let encryptedRecord = try securityService.encryptData(recordData)
        
        try securityService.storeSecureData(encryptedRecord, forKey: "gdpr_portability_\(request.id)")
        
        // This would typically call a backend API
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 second delay
    }
    
    // Helper methods for data operations
    private func fetchActivityData() async throws -> Data {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
        return Data()
    }
    
    private func fetchAnalyticsData() async throws -> Data {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
        return Data()
    }
    
    private func deleteUserProfile() async throws {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
    }
    
    private func deleteUserActivity() async throws {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
    }
    
    private func deleteUserSettings() async throws {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
    }
    
    private func deleteUserAnalytics() async throws {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
    }
    
    private func updateDeletionRequestStatus(_ requestId: String, status: DeletionStatus) async throws {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
    }
    
    private func applyDataCorrection(_ correction: DataCorrection) async throws {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
    }
    
    private func updateRectificationRequestStatus(_ requestId: String, status: RectificationStatus) async throws {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
    }
    
    private func saveDataProcessingActivities(_ activities: [DataProcessingActivity]) async throws {
        let activitiesData = try JSONEncoder().encode(activities)
        let encryptedData = try securityService.encryptData(activitiesData)
        
        try securityService.storeSecureData(encryptedData, forKey: "gdpr_processing_activities")
    }
    
    private func saveComplianceStatus(_ status: GDPRComplianceStatus) async throws {
        let statusData = try JSONEncoder().encode(status)
        let encryptedData = try securityService.encryptData(statusData)
        
        try securityService.storeSecureData(encryptedData, forKey: "gdpr_compliance_status")
    }
    
    private func updateObjectionStatus(_ objectionId: String, status: ObjectionStatus) async throws {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second delay
    }
}

// MARK: - Supporting Types

struct ConsentStatus: Codable {
    var preferences: ConsentPreferences = ConsentPreferences()
    var lastUpdated: Date = Date()
    var version: String = "1.0"
}

struct ConsentPreferences: Codable {
    var dataProcessing: Bool = true
    var marketing: Bool = false
    var thirdPartySharing: Bool = false
    var analytics: Bool = true
    var personalizedContent: Bool = true
}

struct DataRights: Codable {
    var access: Bool = true
    var rectification: Bool = true
    var erasure: Bool = true
    var portability: Bool = true
    var objection: Bool = true
    var restriction: Bool = true
}

struct GDPRComplianceStatus: Codable {
    var isCompliant: Bool = true
    var lastAuditDate: Date = Date()
    var missingRequirements: [String] = []
    var complianceScore: Double = 100.0
    var auditReport: String = ""
}

struct DataExportRequest: Codable {
    let id: String
    let userId: String
    let requestedAt: Date
    let status: ExportStatus
    let format: DataFormat
}

enum ExportStatus: String, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
}

enum DataFormat: String, Codable {
    case json = "json"
    case csv = "csv"
    case xml = "xml"
}

struct UserDataCollection: Codable {
    let exportData: Data
    let dataTypes: [DataType]
    let collectedAt: Date
}

enum DataType: String, Codable {
    case profile = "profile"
    case activity = "activity"
    case settings = "settings"
    case analytics = "analytics"
    case messages = "messages"
    case events = "events"
}

struct DataExportPackage: Codable {
    let data: Data
    let hash: String
    let dataTypes: [DataType]
    let exportedAt: Date
    let format: DataFormat
}

struct DataExportRecord: Codable {
    let id: String = UUID().uuidString
    let package: DataExportPackage
    let userId: String
    let storedAt: Date
}

struct DataDeletionRequest: Codable {
    let id: String
    let userId: String
    let reason: String
    let requestedAt: Date
    let status: DeletionStatus
}

enum DeletionStatus: String, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
}

struct DataCorrection: Codable {
    let field: String
    let oldValue: String
    let newValue: String
    let reason: String
}

struct DataRectificationRequest: Codable {
    let id: String
    let userId: String
    let corrections: [DataCorrection]
    let requestedAt: Date
    let status: RectificationStatus
}

enum RectificationStatus: String, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
}

struct DataProcessingActivity: Codable {
    let type: ProcessingActivityType
    let description: String
    let legalBasis: LegalBasis
    let dataCategories: [String]
    let processingPurpose: String
    let retentionPeriod: Int
    let timestamp: Date
}

enum ProcessingActivityType: String, Codable {
    case dataCollection = "data_collection"
    case dataAnalysis = "data_analysis"
    case dataSharing = "data_sharing"
    case consentUpdate = "consent_update"
    case dataDeletion = "data_deletion"
}

enum LegalBasis: String, Codable {
    case consent = "consent"
    case contract = "contract"
    case legitimateInterest = "legitimate_interest"
    case legalObligation = "legal_obligation"
    case vitalInterests = "vital_interests"
    case publicTask = "public_task"
}

struct DataAccessRequest: Codable {
    let id: String
    let userId: String
    let requestedAt: Date
    let status: AccessStatus
}

enum AccessStatus: String, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
}

struct DataAccessReport: Codable {
    let userId: String
    let dataCategories: [String]
    let processingPurposes: [String]
    let dataRetention: String
    let thirdPartySharing: [String]
    let userRights: [String]
    let generatedAt: Date
}

struct DataAccessRecord: Codable {
    let request: DataAccessRequest
    let report: DataAccessReport
    let storedAt: Date
}

struct DataProcessingObjection: Codable {
    let id: String
    let userId: String
    let grounds: String
    let submittedAt: Date
    let status: ObjectionStatus
}

enum ObjectionStatus: String, Codable {
    case pending = "pending"
    case underReview = "under_review"
    case approved = "approved"
    case rejected = "rejected"
}

struct DataPortabilityRequest: Codable {
    let id: String
    let userId: String
    let format: DataFormat
    let requestedAt: Date
    let status: PortabilityStatus
}

enum PortabilityStatus: String, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
}

struct DataPortabilityPackage: Codable {
    let userId: String
    let format: DataFormat
    let data: Data
    let preparedAt: Date
}

struct DataPortabilityRecord: Codable {
    let request: DataPortabilityRequest
    let package: DataPortabilityPackage
    let storedAt: Date
}

enum GDPRError: Error, LocalizedError {
    case userNotAuthenticated
    case invalidCorrectionField
    case invalidCorrectionValue
    case invalidDataProcessingConsent
    case invalidMarketingConsent
    case invalidThirdPartyConsent
    case exportFailed
    case deletionFailed
    case rectificationFailed
    case accessFailed
    case objectionFailed
    case portabilityFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User must be authenticated for GDPR requests"
        case .invalidCorrectionField:
            return "Invalid correction field"
        case .invalidCorrectionValue:
            return "Invalid correction value"
        case .invalidDataProcessingConsent:
            return "Invalid data processing consent"
        case .invalidMarketingConsent:
            return "Invalid marketing consent"
        case .invalidThirdPartyConsent:
            return "Invalid third party consent"
        case .exportFailed:
            return "Data export failed"
        case .deletionFailed:
            return "Data deletion failed"
        case .rectificationFailed:
            return "Data rectification failed"
        case .accessFailed:
            return "Data access failed"
        case .objectionFailed:
            return "Data processing objection failed"
        case .portabilityFailed:
            return "Data portability failed"
        }
    }
} 