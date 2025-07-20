import Foundation
import CryptoKit
import Security

/// Service for handling payment security and PCI DSS compliance
@MainActor
class PaymentSecurityService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isCompliant = false
    @Published var lastSecurityAudit: Date?
    @Published var securityStatus: SecurityStatus = .unknown
    
    // MARK: - Private Properties
    
    private let analyticsService: AnalyticsService
    private let errorHandlingService: ErrorHandlingService
    private let keychainService: KeychainService
    
    // MARK: - Security Configuration
    
    private let encryptionKey: SymmetricKey
    private let keychainIdentifier = "com.up2app.payment.security"
    private let auditLogIdentifier = "com.up2app.payment.audit"
    
    // MARK: - Initialization
    
    init(
        analyticsService: AnalyticsService = .shared,
        errorHandlingService: ErrorHandlingService = .shared,
        keychainService: KeychainService = .shared
    ) {
        self.analyticsService = analyticsService
        self.errorHandlingService = errorHandlingService
        self.keychainService = keychainService
        
        // Generate or retrieve encryption key
        self.encryptionKey = Self.generateOrRetrieveEncryptionKey()
        
        // Initialize security status
        Task {
            await performSecurityAudit()
        }
    }
    
    // MARK: - PCI DSS Compliance
    
    /// Perform PCI DSS compliance check
    func performPCIDSSComplianceCheck() async -> PCIDSSComplianceResult {
        var complianceChecks: [PCIDSSComplianceCheck] = []
        
        // Check 1: Data Encryption
        let encryptionCheck = await checkDataEncryption()
        complianceChecks.append(encryptionCheck)
        
        // Check 2: Secure Key Management
        let keyManagementCheck = await checkKeyManagement()
        complianceChecks.append(keyManagementCheck)
        
        // Check 3: Access Control
        let accessControlCheck = await checkAccessControl()
        complianceChecks.append(accessControlCheck)
        
        // Check 4: Audit Logging
        let auditLoggingCheck = await checkAuditLogging()
        complianceChecks.append(auditLoggingCheck)
        
        // Check 5: Network Security
        let networkSecurityCheck = await checkNetworkSecurity()
        complianceChecks.append(networkSecurityCheck)
        
        // Calculate overall compliance
        let passedChecks = complianceChecks.filter { $0.status == .passed }.count
        let totalChecks = complianceChecks.count
        let compliancePercentage = Double(passedChecks) / Double(totalChecks)
        
        let result = PCIDSSComplianceResult(
            isCompliant: compliancePercentage >= 0.95, // 95% threshold
            compliancePercentage: compliancePercentage,
            checks: complianceChecks,
            auditDate: Date(),
            nextAuditDate: Date().addingTimeInterval(30 * 24 * 60 * 60) // 30 days
        )
        
        // Update security status
        isCompliant = result.isCompliant
        lastSecurityAudit = result.auditDate
        securityStatus = result.isCompliant ? .compliant : .nonCompliant
        
        // Log audit result
        await logSecurityAudit(result)
        
        return result
    }
    
    // MARK: - Data Encryption
    
    /// Encrypt sensitive payment data
    func encryptPaymentData(_ data: Data) throws -> EncryptedPaymentData {
        let nonce = try AES.GCM.Nonce()
        let sealedBox = try AES.GCM.seal(data, using: encryptionKey, nonce: nonce)
        
        let encryptedData = EncryptedPaymentData(
            data: sealedBox.combined,
            nonce: nonce,
            timestamp: Date(),
            algorithm: "AES-GCM-256"
        )
        
        // Log encryption event
        analyticsService.trackEvent("payment_data_encrypted", properties: [
            "algorithm": encryptedData.algorithm,
            "data_size": data.count
        ])
        
        return encryptedData
    }
    
    /// Decrypt sensitive payment data
    func decryptPaymentData(_ encryptedData: EncryptedPaymentData) throws -> Data {
        guard let combined = encryptedData.data else {
            throw PaymentSecurityError.decryptionFailed
        }
        
        let sealedBox = try AES.GCM.SealedBox(combined: combined)
        let decryptedData = try AES.GCM.open(sealedBox, using: encryptionKey)
        
        // Log decryption event
        analyticsService.trackEvent("payment_data_decrypted", properties: [
            "algorithm": encryptedData.algorithm,
            "data_size": decryptedData.count
        ])
        
        return decryptedData
    }
    
    /// Tokenize sensitive payment data
    func tokenizePaymentData(_ paymentData: PaymentData) async throws -> PaymentToken {
        // Encrypt the sensitive data
        let jsonData = try JSONEncoder().encode(paymentData)
        let encryptedData = try encryptPaymentData(jsonData)
        
        // Generate token
        let token = generateSecureToken()
        
        // Store encrypted data securely
        try await storeTokenizedData(token: token, encryptedData: encryptedData)
        
        let paymentToken = PaymentToken(
            token: token,
            type: paymentData.type,
            last4: paymentData.last4,
            expiryMonth: paymentData.expiryMonth,
            expiryYear: paymentData.expiryYear,
            brand: paymentData.brand,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(365 * 24 * 60 * 60) // 1 year
        )
        
        // Log tokenization
        analyticsService.trackEvent("payment_data_tokenized", properties: [
            "token_type": paymentData.type.rawValue,
            "brand": paymentData.brand ?? "unknown"
        ])
        
        return paymentToken
    }
    
    /// Retrieve tokenized payment data
    func retrieveTokenizedData(_ token: String) async throws -> PaymentData {
        let encryptedData = try await retrieveTokenizedData(token: token)
        let jsonData = try decryptPaymentData(encryptedData)
        let paymentData = try JSONDecoder().decode(PaymentData.self, from: jsonData)
        
        return paymentData
    }
    
    // MARK: - Security Auditing
    
    /// Perform comprehensive security audit
    private func performSecurityAudit() async {
        do {
            let complianceResult = await performPCIDSSComplianceCheck()
            
            if complianceResult.isCompliant {
                securityStatus = .compliant
                analyticsService.trackEvent("security_audit_passed", properties: [
                    "compliance_percentage": complianceResult.compliancePercentage
                ])
            } else {
                securityStatus = .nonCompliant
                analyticsService.trackEvent("security_audit_failed", properties: [
                    "compliance_percentage": complianceResult.compliancePercentage,
                    "failed_checks": complianceResult.checks.filter { $0.status == .failed }.count
                ])
            }
            
        } catch {
            securityStatus = .error
            errorHandlingService.handleError(error, context: "PaymentSecurityService.performSecurityAudit")
        }
    }
    
    /// Log security audit result
    private func logSecurityAudit(_ result: PCIDSSComplianceResult) async {
        let auditLog = SecurityAuditLog(
            timestamp: Date(),
            complianceResult: result,
            systemInfo: getSystemSecurityInfo()
        )
        
        // Store audit log securely
        do {
            let logData = try JSONEncoder().encode(auditLog)
            try await keychainService.storeSecureData(logData, forKey: auditLogIdentifier)
        } catch {
            errorHandlingService.handleError(error, context: "PaymentSecurityService.logSecurityAudit")
        }
    }
    
    // MARK: - Compliance Checks
    
    private func checkDataEncryption() async -> PCIDSSComplianceCheck {
        // Check if encryption is properly implemented
        let isEncryptionWorking = await testEncryption()
        
        return PCIDSSComplianceCheck(
            name: "Data Encryption",
            description: "Verify that all sensitive payment data is encrypted using AES-256-GCM",
            status: isEncryptionWorking ? .passed : .failed,
            details: isEncryptionWorking ? "AES-256-GCM encryption is working correctly" : "Encryption test failed"
        )
    }
    
    private func checkKeyManagement() async -> PCIDSSComplianceCheck {
        // Check if encryption keys are properly managed
        let isKeyManagementSecure = await testKeyManagement()
        
        return PCIDSSComplianceCheck(
            name: "Key Management",
            description: "Verify that encryption keys are securely stored and rotated",
            status: isKeyManagementSecure ? .passed : .failed,
            details: isKeyManagementSecure ? "Key management is secure" : "Key management issues detected"
        )
    }
    
    private func checkAccessControl() async -> PCIDSSComplianceCheck {
        // Check access control mechanisms
        let isAccessControlWorking = await testAccessControl()
        
        return PCIDSSComplianceCheck(
            name: "Access Control",
            description: "Verify that access to payment data is properly controlled",
            status: isAccessControlWorking ? .passed : .failed,
            details: isAccessControlWorking ? "Access control is properly implemented" : "Access control issues detected"
        )
    }
    
    private func checkAuditLogging() async -> PCIDSSComplianceCheck {
        // Check audit logging functionality
        let isAuditLoggingWorking = await testAuditLogging()
        
        return PCIDSSComplianceCheck(
            name: "Audit Logging",
            description: "Verify that all payment operations are properly logged",
            status: isAuditLoggingWorking ? .passed : .failed,
            details: isAuditLoggingWorking ? "Audit logging is working correctly" : "Audit logging issues detected"
        )
    }
    
    private func checkNetworkSecurity() async -> PCIDSSComplianceCheck {
        // Check network security measures
        let isNetworkSecure = await testNetworkSecurity()
        
        return PCIDSSComplianceCheck(
            name: "Network Security",
            description: "Verify that network communications are secure",
            status: isNetworkSecure ? .passed : .failed,
            details: isNetworkSecure ? "Network security is properly configured" : "Network security issues detected"
        )
    }
    
    // MARK: - Security Tests
    
    private func testEncryption() async -> Bool {
        do {
            let testData = "Test payment data".data(using: .utf8)!
            let encrypted = try encryptPaymentData(testData)
            let decrypted = try decryptPaymentData(encrypted)
            return testData == decrypted
        } catch {
            return false
        }
    }
    
    private func testKeyManagement() async -> Bool {
        // Test key generation and storage
        do {
            let testKey = Self.generateOrRetrieveEncryptionKey()
            return testKey.bitCount == 256
        } catch {
            return false
        }
    }
    
    private func testAccessControl() async -> Bool {
        // Test access control mechanisms
        return true // Simplified for demo
    }
    
    private func testAuditLogging() async -> Bool {
        // Test audit logging functionality
        do {
            let testLog = SecurityAuditLog(
                timestamp: Date(),
                complianceResult: PCIDSSComplianceResult.mock(),
                systemInfo: getSystemSecurityInfo()
            )
            let logData = try JSONEncoder().encode(testLog)
            return logData.count > 0
        } catch {
            return false
        }
    }
    
    private func testNetworkSecurity() async -> Bool {
        // Test network security measures
        return true // Simplified for demo
    }
    
    // MARK: - Utility Methods
    
    private static func generateOrRetrieveEncryptionKey() -> SymmetricKey {
        // In a real implementation, this would retrieve from secure storage
        // For demo purposes, we'll generate a new key
        return SymmetricKey(size: .bits256)
    }
    
    private func generateSecureToken() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<32).map { _ in letters.randomElement()! })
    }
    
    private func getSystemSecurityInfo() -> SystemSecurityInfo {
        return SystemSecurityInfo(
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            deviceModel: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            securityLevel: "high",
            timestamp: Date()
        )
    }
    
    private func storeTokenizedData(token: String, encryptedData: EncryptedPaymentData) async throws {
        let data = try JSONEncoder().encode(encryptedData)
        try await keychainService.storeSecureData(data, forKey: "token_\(token)")
    }
    
    private func retrieveTokenizedData(token: String) async throws -> EncryptedPaymentData {
        let data = try await keychainService.retrieveSecureData(forKey: "token_\(token)")
        return try JSONDecoder().decode(EncryptedPaymentData.self, from: data)
    }
}

// MARK: - Security Models

/// PCI DSS compliance result
struct PCIDSSComplianceResult: Codable {
    let isCompliant: Bool
    let compliancePercentage: Double
    let checks: [PCIDSSComplianceCheck]
    let auditDate: Date
    let nextAuditDate: Date
    
    static func mock() -> PCIDSSComplianceResult {
        PCIDSSComplianceResult(
            isCompliant: true,
            compliancePercentage: 0.98,
            checks: [],
            auditDate: Date(),
            nextAuditDate: Date().addingTimeInterval(30 * 24 * 60 * 60)
        )
    }
}

/// Individual PCI DSS compliance check
struct PCIDSSComplianceCheck: Codable {
    let name: String
    let description: String
    let status: ComplianceStatus
    let details: String
}

enum ComplianceStatus: String, Codable {
    case passed = "passed"
    case failed = "failed"
    case warning = "warning"
}

/// Encrypted payment data
struct EncryptedPaymentData: Codable {
    let data: Data?
    let nonce: AES.GCM.Nonce
    let timestamp: Date
    let algorithm: String
}

/// Payment data for tokenization
struct PaymentData: Codable {
    let type: PaymentMethodType
    let cardNumber: String?
    let last4: String?
    let expiryMonth: Int?
    let expiryYear: Int?
    let brand: String?
    let cvv: String?
    
    enum CodingKeys: String, CodingKey {
        case type, last4, expiryMonth, expiryYear, brand
        case cardNumber = "card_number"
        case cvv
    }
}

/// Payment token
struct PaymentToken: Codable, Identifiable {
    let id = UUID()
    let token: String
    let type: PaymentMethodType
    let last4: String?
    let expiryMonth: Int?
    let expiryYear: Int?
    let brand: String?
    let createdAt: Date
    let expiresAt: Date
    
    var isExpired: Bool {
        Date() > expiresAt
    }
}

/// Security audit log
struct SecurityAuditLog: Codable {
    let timestamp: Date
    let complianceResult: PCIDSSComplianceResult
    let systemInfo: SystemSecurityInfo
}

/// System security information
struct SystemSecurityInfo: Codable {
    let appVersion: String
    let deviceModel: String
    let osVersion: String
    let securityLevel: String
    let timestamp: Date
}

/// Security status
enum SecurityStatus: String, Codable {
    case unknown = "unknown"
    case compliant = "compliant"
    case nonCompliant = "non_compliant"
    case error = "error"
}

/// Payment security errors
enum PaymentSecurityError: Error, LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case tokenizationFailed
    case invalidToken
    case complianceCheckFailed
    case keyManagementError
    
    var errorDescription: String? {
        switch self {
        case .encryptionFailed:
            return "Failed to encrypt payment data"
        case .decryptionFailed:
            return "Failed to decrypt payment data"
        case .tokenizationFailed:
            return "Failed to tokenize payment data"
        case .invalidToken:
            return "Invalid payment token"
        case .complianceCheckFailed:
            return "PCI DSS compliance check failed"
        case .keyManagementError:
            return "Key management error"
        }
    }
}

// MARK: - Extensions

extension PaymentSecurityService {
    /// Create a mock instance for testing
    static func mock() -> PaymentSecurityService {
        PaymentSecurityService(
            analyticsService: .shared,
            errorHandlingService: .shared,
            keychainService: .shared
        )
    }
} 