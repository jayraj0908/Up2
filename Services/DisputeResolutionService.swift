import Foundation
import UIKit

/// Service for handling payment disputes and chargeback resolution
@MainActor
class DisputeResolutionService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var activeDisputes: [PaymentDispute] = []
    @Published var disputeStats: DisputeStatistics = DisputeStatistics()
    @Published var isProcessing = false
    
    // MARK: - Private Properties
    
    private let analyticsService: AnalyticsService
    private let errorHandlingService: ErrorHandlingService
    private let paymentService: PaymentProcessingService
    
    private var disputeHistory: [PaymentDispute] = []
    private var evidenceTemplates: [EvidenceTemplate] = []
    
    // MARK: - Initialization
    
    init(
        analyticsService: AnalyticsService = .shared,
        errorHandlingService: ErrorHandlingService = .shared,
        paymentService: PaymentProcessingService = .shared
    ) {
        self.analyticsService = analyticsService
        self.errorHandlingService = errorHandlingService
        self.paymentService = paymentService
        
        setupEvidenceTemplates()
        loadDisputeHistory()
    }
    
    // MARK: - Dispute Management
    
    /// Create a new payment dispute
    func createDispute(
        transactionId: String,
        reason: DisputeReason,
        description: String,
        customerEmail: String,
        amount: Double
    ) async throws -> PaymentDispute {
        
        isProcessing = true
        
        do {
            // Validate transaction
            try await validateTransaction(transactionId)
            
            // Create dispute
            let dispute = PaymentDispute(
                id: UUID().uuidString,
                transactionId: transactionId,
                customerEmail: customerEmail,
                amount: amount,
                reason: reason,
                description: description,
                status: .pending,
                createdAt: Date(),
                evidence: [],
                resolution: nil
            )
            
            // Add to active disputes
            activeDisputes.append(dispute)
            
            // Update statistics
            await updateDisputeStatistics()
            
            // Log dispute creation
            analyticsService.trackEvent("payment_dispute_created", properties: [
                "dispute_id": dispute.id,
                "transaction_id": transactionId,
                "reason": reason.rawValue,
                "amount": amount
            ])
            
            return dispute
            
        } catch {
            errorHandlingService.handleError(error, context: "DisputeResolutionService.createDispute")
            throw error
        } finally {
            isProcessing = false
        }
    }
    
    /// Add evidence to a dispute
    func addEvidence(
        to disputeId: String,
        type: EvidenceType,
        title: String,
        description: String,
        data: Data? = nil,
        url: URL? = nil
    ) async throws -> DisputeEvidence {
        
        guard let dispute = activeDisputes.first(where: { $0.id == disputeId }) else {
            throw DisputeResolutionError.disputeNotFound
        }
        
        // Create evidence
        let evidence = DisputeEvidence(
            id: UUID().uuidString,
            disputeId: disputeId,
            type: type,
            title: title,
            description: description,
            data: data,
            url: url,
            uploadedAt: Date()
        )
        
        // Add evidence to dispute
        var updatedDispute = dispute
        updatedDispute.evidence.append(evidence)
        
        // Update dispute status
        updatedDispute.status = .evidenceSubmitted
        
        // Update active disputes
        if let index = activeDisputes.firstIndex(where: { $0.id == disputeId }) {
            activeDisputes[index] = updatedDispute
        }
        
        // Log evidence addition
        analyticsService.trackEvent("dispute_evidence_added", properties: [
            "dispute_id": disputeId,
            "evidence_type": type.rawValue,
            "evidence_title": title
        ])
        
        return evidence
    }
    
    /// Submit dispute for review
    func submitDisputeForReview(_ disputeId: String) async throws -> DisputeReview {
        
        guard let dispute = activeDisputes.first(where: { $0.id == disputeId }) else {
            throw DisputeResolutionError.disputeNotFound
        }
        
        // Validate dispute is ready for review
        try validateDisputeForReview(dispute)
        
        // Create review
        let review = DisputeReview(
            id: UUID().uuidString,
            disputeId: disputeId,
            reviewerId: "system_reviewer",
            status: .underReview,
            assignedAt: Date(),
            estimatedResolutionDate: Date().addingTimeInterval(7 * 24 * 60 * 60), // 7 days
            notes: []
        )
        
        // Update dispute status
        var updatedDispute = dispute
        updatedDispute.status = .underReview
        updatedDispute.review = review
        
        // Update active disputes
        if let index = activeDisputes.firstIndex(where: { $0.id == disputeId }) {
            activeDisputes[index] = updatedDispute
        }
        
        // Log review submission
        analyticsService.trackEvent("dispute_submitted_for_review", properties: [
            "dispute_id": disputeId,
            "reviewer_id": review.reviewerId
        ])
        
        return review
    }
    
    /// Resolve dispute with decision
    func resolveDispute(
        _ disputeId: String,
        decision: DisputeDecision,
        notes: String
    ) async throws -> DisputeResolution {
        
        guard let dispute = activeDisputes.first(where: { $0.id == disputeId }) else {
            throw DisputeResolutionError.disputeNotFound
        }
        
        // Create resolution
        let resolution = DisputeResolution(
            id: UUID().uuidString,
            disputeId: disputeId,
            decision: decision,
            notes: notes,
            resolvedAt: Date(),
            resolvedBy: "system_resolver"
        )
        
        // Update dispute
        var updatedDispute = dispute
        updatedDispute.status = .resolved
        updatedDispute.resolution = resolution
        
        // Move to history
        disputeHistory.append(updatedDispute)
        activeDisputes.removeAll { $0.id == disputeId }
        
        // Update statistics
        await updateDisputeStatistics()
        
        // Handle resolution based on decision
        try await handleDisputeResolution(dispute: updatedDispute, resolution: resolution)
        
        // Log resolution
        analyticsService.trackEvent("dispute_resolved", properties: [
            "dispute_id": disputeId,
            "decision": decision.rawValue,
            "amount": dispute.amount
        ])
        
        return resolution
    }
    
    // MARK: - Chargeback Protection
    
    /// Implement chargeback protection measures
    func implementChargebackProtection(for transactionId: String) async throws -> ChargebackProtection {
        
        // Get transaction details
        guard let transaction = await getTransactionDetails(transactionId) else {
            throw DisputeResolutionError.transactionNotFound
        }
        
        // Create protection measures
        let protection = ChargebackProtection(
            transactionId: transactionId,
            measures: [
                .enhancedDocumentation,
                .customerCommunication,
                .deliveryConfirmation,
                .fraudDetection
            ],
            implementedAt: Date(),
            status: .active
        )
        
        // Apply protection measures
        try await applyProtectionMeasures(protection)
        
        // Log protection implementation
        analyticsService.trackEvent("chargeback_protection_implemented", properties: [
            "transaction_id": transactionId,
            "measures_count": protection.measures.count
        ])
        
        return protection
    }
    
    /// Generate chargeback response
    func generateChargebackResponse(for disputeId: String) async throws -> ChargebackResponse {
        
        guard let dispute = activeDisputes.first(where: { $0.id == disputeId }) else {
            throw DisputeResolutionError.disputeNotFound
        }
        
        // Generate response based on dispute type
        let response = ChargebackResponse(
            disputeId: disputeId,
            responseType: determineResponseType(for: dispute),
            evidence: dispute.evidence,
            arguments: generateArguments(for: dispute),
            submittedAt: Date()
        )
        
        // Log response generation
        analyticsService.trackEvent("chargeback_response_generated", properties: [
            "dispute_id": disputeId,
            "response_type": response.responseType.rawValue
        ])
        
        return response
    }
    
    // MARK: - Evidence Management
    
    /// Get evidence templates for dispute type
    func getEvidenceTemplates(for reason: DisputeReason) -> [EvidenceTemplate] {
        return evidenceTemplates.filter { $0.applicableReasons.contains(reason) }
    }
    
    /// Upload evidence file
    func uploadEvidenceFile(
        for disputeId: String,
        fileData: Data,
        fileName: String,
        fileType: String
    ) async throws -> DisputeEvidence {
        
        // Validate file
        try validateEvidenceFile(fileData, fileName, fileType)
        
        // Store file securely
        let fileUrl = try await storeEvidenceFile(fileData, fileName, disputeId)
        
        // Create evidence record
        let evidence = try await addEvidence(
            to: disputeId,
            type: .document,
            title: fileName,
            description: "Uploaded evidence file: \(fileName)",
            data: fileData,
            url: fileUrl
        )
        
        return evidence
    }
    
    // MARK: - Analytics and Reporting
    
    /// Get dispute statistics
    func getDisputeStatistics() -> DisputeStatistics {
        return disputeStats
    }
    
    /// Generate dispute report
    func generateDisputeReport(timeRange: DateInterval) async throws -> DisputeReport {
        
        let disputesInRange = disputeHistory.filter { dispute in
            timeRange.contains(dispute.createdAt)
        }
        
        let report = DisputeReport(
            timeRange: timeRange,
            totalDisputes: disputesInRange.count,
            resolvedDisputes: disputesInRange.filter { $0.status == .resolved }.count,
            pendingDisputes: disputesInRange.filter { $0.status == .pending }.count,
            underReviewDisputes: disputesInRange.filter { $0.status == .underReview }.count,
            winRate: calculateWinRate(disputesInRange),
            averageResolutionTime: calculateAverageResolutionTime(disputesInRange),
            totalAmount: disputesInRange.reduce(0) { $0 + $1.amount },
            disputesByReason: groupDisputesByReason(disputesInRange),
            generatedAt: Date()
        )
        
        // Log report generation
        analyticsService.trackEvent("dispute_report_generated", properties: [
            "time_range_start": timeRange.start.timeIntervalSince1970,
            "time_range_end": timeRange.end.timeIntervalSince1970,
            "total_disputes": report.totalDisputes
        ])
        
        return report
    }
    
    // MARK: - Private Methods
    
    private func setupEvidenceTemplates() {
        evidenceTemplates = [
            EvidenceTemplate(
                id: "receipt",
                title: "Transaction Receipt",
                description: "Proof of purchase and payment",
                applicableReasons: [.fraudulent, .duplicate, .incorrectAmount],
                required: true
            ),
            EvidenceTemplate(
                id: "delivery_confirmation",
                title: "Delivery Confirmation",
                description: "Proof that goods/services were delivered",
                applicableReasons: [.goodsNotReceived, .servicesNotRendered],
                required: true
            ),
            EvidenceTemplate(
                id: "communication",
                title: "Customer Communication",
                description: "Emails, messages, or call records",
                applicableReasons: [.goodsNotReceived, .servicesNotRendered, .incorrectAmount],
                required: false
            ),
            EvidenceTemplate(
                id: "terms_conditions",
                title: "Terms and Conditions",
                description: "Agreed terms and conditions",
                applicableReasons: [.fraudulent, .duplicate],
                required: false
            )
        ]
    }
    
    private func loadDisputeHistory() {
        // Load dispute history from storage
        // Simplified for demo
    }
    
    private func validateTransaction(_ transactionId: String) async throws {
        // Validate transaction exists and is eligible for dispute
        // Simplified for demo
    }
    
    private func updateDisputeStatistics() async {
        let totalDisputes = activeDisputes.count + disputeHistory.count
        let resolvedDisputes = disputeHistory.filter { $0.status == .resolved }.count
        let pendingDisputes = activeDisputes.filter { $0.status == .pending }.count
        let underReviewDisputes = activeDisputes.filter { $0.status == .underReview }.count
        
        disputeStats = DisputeStatistics(
            totalDisputes: totalDisputes,
            activeDisputes: activeDisputes.count,
            resolvedDisputes: resolvedDisputes,
            pendingDisputes: pendingDisputes,
            underReviewDisputes: underReviewDisputes,
            winRate: totalDisputes > 0 ? Double(resolvedDisputes) / Double(totalDisputes) : 0.0,
            averageResolutionTime: calculateAverageResolutionTime(disputeHistory),
            lastUpdated: Date()
        )
    }
    
    private func validateDisputeForReview(_ dispute: PaymentDispute) throws {
        // Validate dispute has sufficient evidence
        guard !dispute.evidence.isEmpty else {
            throw DisputeResolutionError.insufficientEvidence
        }
        
        // Validate dispute is in correct status
        guard dispute.status == .evidenceSubmitted else {
            throw DisputeResolutionError.invalidStatus
        }
    }
    
    private func handleDisputeResolution(dispute: PaymentDispute, resolution: DisputeResolution) async throws {
        switch resolution.decision {
        case .won:
            // Dispute won - no action needed
            break
        case .lost:
            // Dispute lost - process refund
            try await processRefund(for: dispute)
        case .partial:
            // Partial win - process partial refund
            try await processPartialRefund(for: dispute, resolution: resolution)
        }
    }
    
    private func processRefund(for dispute: PaymentDispute) async throws {
        // Process full refund
        // Simplified for demo
    }
    
    private func processPartialRefund(for dispute: PaymentDispute, resolution: DisputeResolution) async throws {
        // Process partial refund based on resolution
        // Simplified for demo
    }
    
    private func getTransactionDetails(_ transactionId: String) async -> PaymentTransaction? {
        // Get transaction details
        // Simplified for demo
        return nil
    }
    
    private func applyProtectionMeasures(_ protection: ChargebackProtection) async throws {
        // Apply protection measures
        // Simplified for demo
    }
    
    private func determineResponseType(for dispute: PaymentDispute) -> ChargebackResponseType {
        switch dispute.reason {
        case .fraudulent:
            return .representment
        case .goodsNotReceived, .servicesNotRendered:
            return .acceptance
        case .duplicate, .incorrectAmount:
            return .representment
        }
    }
    
    private func generateArguments(for dispute: PaymentDispute) -> [String] {
        var arguments: [String] = []
        
        switch dispute.reason {
        case .fraudulent:
            arguments.append("Transaction was legitimate and authorized")
            arguments.append("Customer received goods/services as described")
        case .goodsNotReceived:
            arguments.append("Delivery confirmation provided")
            arguments.append("Tracking information shows successful delivery")
        case .servicesNotRendered:
            arguments.append("Service was provided as agreed")
            arguments.append("Customer communication confirms service completion")
        case .duplicate:
            arguments.append("Transaction was not duplicated")
            arguments.append("Each charge represents a separate purchase")
        case .incorrectAmount:
            arguments.append("Amount charged was correct")
            arguments.append("Pricing was clearly communicated")
        }
        
        return arguments
    }
    
    private func validateEvidenceFile(_ fileData: Data, _ fileName: String, _ fileType: String) throws {
        // Validate file size
        guard fileData.count <= 10 * 1024 * 1024 else { // 10MB limit
            throw DisputeResolutionError.fileTooLarge
        }
        
        // Validate file type
        let allowedTypes = ["pdf", "jpg", "jpeg", "png", "doc", "docx"]
        guard allowedTypes.contains(fileType.lowercased()) else {
            throw DisputeResolutionError.invalidFileType
        }
    }
    
    private func storeEvidenceFile(_ fileData: Data, _ fileName: String, _ disputeId: String) async throws -> URL {
        // Store file securely
        // Simplified for demo
        return URL(string: "file://evidence/\(disputeId)/\(fileName)")!
    }
    
    private func calculateWinRate(_ disputes: [PaymentDispute]) -> Double {
        let resolvedDisputes = disputes.filter { $0.status == .resolved }
        guard !resolvedDisputes.isEmpty else { return 0.0 }
        
        let wonDisputes = resolvedDisputes.filter { $0.resolution?.decision == .won }.count
        return Double(wonDisputes) / Double(resolvedDisputes.count)
    }
    
    private func calculateAverageResolutionTime(_ disputes: [PaymentDispute]) -> TimeInterval {
        let resolvedDisputes = disputes.filter { $0.status == .resolved && $0.resolution != nil }
        guard !resolvedDisputes.isEmpty else { return 0.0 }
        
        let totalTime = resolvedDisputes.reduce(0.0) { total, dispute in
            total + dispute.resolution!.resolvedAt.timeIntervalSince(dispute.createdAt)
        }
        
        return totalTime / Double(resolvedDisputes.count)
    }
    
    private func groupDisputesByReason(_ disputes: [PaymentDispute]) -> [DisputeReason: Int] {
        var grouped: [DisputeReason: Int] = [:]
        
        for dispute in disputes {
            grouped[dispute.reason, default: 0] += 1
        }
        
        return grouped
    }
}

// MARK: - Dispute Resolution Models

/// Payment dispute
struct PaymentDispute: Codable, Identifiable {
    let id: String
    let transactionId: String
    let customerEmail: String
    let amount: Double
    let reason: DisputeReason
    let description: String
    var status: DisputeStatus
    let createdAt: Date
    var evidence: [DisputeEvidence]
    var review: DisputeReview?
    var resolution: DisputeResolution?
}

enum DisputeReason: String, Codable, CaseIterable {
    case fraudulent = "fraudulent"
    case goodsNotReceived = "goods_not_received"
    case servicesNotRendered = "services_not_rendered"
    case duplicate = "duplicate"
    case incorrectAmount = "incorrect_amount"
}

enum DisputeStatus: String, Codable {
    case pending = "pending"
    case evidenceSubmitted = "evidence_submitted"
    case underReview = "under_review"
    case resolved = "resolved"
}

/// Dispute evidence
struct DisputeEvidence: Codable, Identifiable {
    let id: String
    let disputeId: String
    let type: EvidenceType
    let title: String
    let description: String
    let data: Data?
    let url: URL?
    let uploadedAt: Date
}

enum EvidenceType: String, Codable {
    case document = "document"
    case image = "image"
    case communication = "communication"
    case receipt = "receipt"
    case other = "other"
}

/// Evidence template
struct EvidenceTemplate: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let applicableReasons: [DisputeReason]
    let required: Bool
}

/// Dispute review
struct DisputeReview: Codable, Identifiable {
    let id: String
    let disputeId: String
    let reviewerId: String
    var status: ReviewStatus
    let assignedAt: Date
    let estimatedResolutionDate: Date
    var notes: [ReviewNote]
}

enum ReviewStatus: String, Codable {
    case underReview = "under_review"
    case completed = "completed"
    case escalated = "escalated"
}

/// Review note
struct ReviewNote: Codable, Identifiable {
    let id = UUID()
    let reviewerId: String
    let note: String
    let timestamp: Date
}

/// Dispute resolution
struct DisputeResolution: Codable, Identifiable {
    let id: String
    let disputeId: String
    let decision: DisputeDecision
    let notes: String
    let resolvedAt: Date
    let resolvedBy: String
}

enum DisputeDecision: String, Codable {
    case won = "won"
    case lost = "lost"
    case partial = "partial"
}

/// Chargeback protection
struct ChargebackProtection: Codable {
    let transactionId: String
    let measures: [ProtectionMeasure]
    let implementedAt: Date
    let status: ProtectionStatus
}

enum ProtectionMeasure: String, Codable {
    case enhancedDocumentation = "enhanced_documentation"
    case customerCommunication = "customer_communication"
    case deliveryConfirmation = "delivery_confirmation"
    case fraudDetection = "fraud_detection"
}

enum ProtectionStatus: String, Codable {
    case active = "active"
    case inactive = "inactive"
}

/// Chargeback response
struct ChargebackResponse: Codable {
    let disputeId: String
    let responseType: ChargebackResponseType
    let evidence: [DisputeEvidence]
    let arguments: [String]
    let submittedAt: Date
}

enum ChargebackResponseType: String, Codable {
    case representment = "representment"
    case acceptance = "acceptance"
    case preArbitration = "pre_arbitration"
}

/// Dispute statistics
struct DisputeStatistics: Codable {
    let totalDisputes: Int
    let activeDisputes: Int
    let resolvedDisputes: Int
    let pendingDisputes: Int
    let underReviewDisputes: Int
    let winRate: Double
    let averageResolutionTime: TimeInterval
    let lastUpdated: Date
}

/// Dispute report
struct DisputeReport: Codable {
    let timeRange: DateInterval
    let totalDisputes: Int
    let resolvedDisputes: Int
    let pendingDisputes: Int
    let underReviewDisputes: Int
    let winRate: Double
    let averageResolutionTime: TimeInterval
    let totalAmount: Double
    let disputesByReason: [DisputeReason: Int]
    let generatedAt: Date
}

/// Dispute resolution errors
enum DisputeResolutionError: Error, LocalizedError {
    case disputeNotFound
    case transactionNotFound
    case insufficientEvidence
    case invalidStatus
    case fileTooLarge
    case invalidFileType
    
    var errorDescription: String? {
        switch self {
        case .disputeNotFound:
            return "Dispute not found"
        case .transactionNotFound:
            return "Transaction not found"
        case .insufficientEvidence:
            return "Insufficient evidence for review"
        case .invalidStatus:
            return "Invalid dispute status"
        case .fileTooLarge:
            return "Evidence file is too large"
        case .invalidFileType:
            return "Invalid file type for evidence"
        }
    }
}

// MARK: - Extensions

extension DisputeResolutionService {
    /// Create a mock instance for testing
    static func mock() -> DisputeResolutionService {
        DisputeResolutionService(
            analyticsService: .shared,
            errorHandlingService: .shared,
            paymentService: .shared
        )
    }
} 