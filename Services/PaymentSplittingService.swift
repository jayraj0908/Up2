import Foundation
import Combine

/// Service for managing payment splitting and group payments
@MainActor
class PaymentSplittingService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var activeGroupPayments: [GroupPayment] = []
    @Published var userGroupPayments: [GroupPayment] = []
    @Published var isLoading = false
    @Published var splittingStats: PaymentSplittingStatistics = PaymentSplittingStatistics()
    
    // MARK: - Private Properties
    
    private let analyticsService: AnalyticsService
    private let errorHandlingService: ErrorHandlingService
    private let paymentService: PaymentMethodService
    private let hapticService: HapticService
    
    private var cancellables = Set<AnyCancellable>()
    private var groupPaymentTimer: Timer?
    
    // MARK: - Initialization
    
    init(
        analyticsService: AnalyticsService = .shared,
        errorHandlingService: ErrorHandlingService = .shared,
        paymentService: PaymentMethodService = .shared,
        hapticService: HapticService = .shared
    ) {
        self.analyticsService = analyticsService
        self.errorHandlingService = errorHandlingService
        self.paymentService = paymentService
        self.hapticService = hapticService
        
        startGroupPaymentMonitoring()
    }
    
    // MARK: - Group Payment Management
    
    /// Create a new group payment
    func createGroupPayment(
        eventId: String,
        totalAmount: Double,
        currency: String = "USD",
        splitType: PaymentSplitType,
        participants: [GroupPaymentParticipant],
        organizerEmail: String
    ) async throws -> GroupPayment {
        
        isLoading = true
        
        do {
            // Validate participants
            try validateParticipants(participants, totalAmount: totalAmount, splitType: splitType)
            
            // Create group payment
            let groupPayment = GroupPayment(
                id: UUID().uuidString,
                eventId: eventId,
                totalAmount: totalAmount,
                currency: currency,
                splitType: splitType,
                status: .pending,
                organizerEmail: organizerEmail,
                participants: participants,
                createdAt: Date(),
                expiresAt: Date().addingTimeInterval(24 * 60 * 60), // 24 hours
                metadata: [
                    "event_id": eventId,
                    "participants_count": String(participants.count)
                ]
            )
            
            // Add to active group payments
            activeGroupPayments.append(groupPayment)
            
            // Save group payment
            try await saveGroupPayment(groupPayment)
            
            // Send invitations to participants
            try await sendGroupPaymentInvitations(groupPayment)
            
            // Update statistics
            await updateSplittingStatistics()
            
            hapticService.trigger(.success)
            
            analyticsService.trackEvent("group_payment_created", properties: [
                "group_payment_id": groupPayment.id,
                "event_id": eventId,
                "total_amount": totalAmount,
                "participants_count": participants.count,
                "split_type": splitType.rawValue
            ])
            
            return groupPayment
            
        } catch {
            errorHandlingService.handleError(error, context: "PaymentSplittingService.createGroupPayment")
            throw error
        } finally {
            isLoading = false
        }
    }
    
    /// Join a group payment
    func joinGroupPayment(
        _ groupPaymentId: String,
        participantEmail: String,
        paymentMethodId: String
    ) async throws -> GroupPaymentParticipant {
        
        guard let index = activeGroupPayments.firstIndex(where: { $0.id == groupPaymentId }) else {
            throw PaymentSplittingError.groupPaymentNotFound
        }
        
        var groupPayment = activeGroupPayments[index]
        
        // Check if participant already exists
        guard let participantIndex = groupPayment.participants.firstIndex(where: { $0.email == participantEmail }) else {
            throw PaymentSplittingError.participantNotFound
        }
        
        var participant = groupPayment.participants[participantIndex]
        
        // Update participant
        participant.paymentMethodId = paymentMethodId
        participant.status = .joined
        participant.joinedAt = Date()
        
        // Update in group payment
        groupPayment.participants[participantIndex] = participant
        
        // Check if all participants have joined
        let allJoined = groupPayment.participants.allSatisfy { $0.status == .joined }
        if allJoined {
            groupPayment.status = .ready
        }
        
        // Update active group payments
        activeGroupPayments[index] = groupPayment
        
        // Save group payment
        try await saveGroupPayment(groupPayment)
        
        hapticService.trigger(.light)
        
        analyticsService.trackEvent("group_payment_joined", properties: [
            "group_payment_id": groupPaymentId,
            "participant_email": participantEmail
        ])
        
        return participant
    }
    
    /// Process group payment
    func processGroupPayment(_ groupPaymentId: String) async throws -> GroupPaymentResult {
        
        guard let index = activeGroupPayments.firstIndex(where: { $0.id == groupPaymentId }) else {
            throw PaymentSplittingError.groupPaymentNotFound
        }
        
        var groupPayment = activeGroupPayments[index]
        
        // Validate all participants are ready
        guard groupPayment.participants.allSatisfy({ $0.status == .joined }) else {
            throw PaymentSplittingError.notAllParticipantsJoined
        }
        
        // Update status to processing
        groupPayment.status = .processing
        activeGroupPayments[index] = groupPayment
        
        var successfulPayments: [PaymentTransaction] = []
        var failedPayments: [FailedPayment] = []
        
        // Process payments for each participant
        for participant in groupPayment.participants {
            do {
                let transaction = try await processParticipantPayment(groupPayment, participant)
                successfulPayments.append(transaction)
                
                // Update participant status
                if let participantIndex = groupPayment.participants.firstIndex(where: { $0.id == participant.id }) {
                    groupPayment.participants[participantIndex].status = .paid
                    groupPayment.participants[participantIndex].transactionId = transaction.transactionId
                }
                
            } catch {
                let failedPayment = FailedPayment(
                    participantId: participant.id,
                    participantEmail: participant.email,
                    amount: participant.amount,
                    error: error.localizedDescription
                )
                failedPayments.append(failedPayment)
                
                // Update participant status
                if let participantIndex = groupPayment.participants.firstIndex(where: { $0.id == participant.id }) {
                    groupPayment.participants[participantIndex].status = .failed
                }
            }
        }
        
        // Determine final status
        if failedPayments.isEmpty {
            groupPayment.status = .completed
            groupPayment.completedAt = Date()
        } else if successfulPayments.isEmpty {
            groupPayment.status = .failed
        } else {
            groupPayment.status = .partial
        }
        
        // Update active group payments
        activeGroupPayments[index] = groupPayment
        
        // Save group payment
        try await saveGroupPayment(groupPayment)
        
        // Update statistics
        await updateSplittingStatistics()
        
        let result = GroupPaymentResult(
            groupPayment: groupPayment,
            successfulPayments: successfulPayments,
            failedPayments: failedPayments,
            totalCollected: successfulPayments.reduce(0) { $0 + $1.amount }
        )
        
        hapticService.trigger(result.failedPayments.isEmpty ? .success : .warning)
        
        analyticsService.trackEvent("group_payment_processed", properties: [
            "group_payment_id": groupPaymentId,
            "successful_payments": successfulPayments.count,
            "failed_payments": failedPayments.count,
            "total_collected": result.totalCollected
        ])
        
        return result
    }
    
    /// Cancel group payment
    func cancelGroupPayment(_ groupPaymentId: String, reason: String? = nil) async throws -> GroupPayment {
        
        guard let index = activeGroupPayments.firstIndex(where: { $0.id == groupPaymentId }) else {
            throw PaymentSplittingError.groupPaymentNotFound
        }
        
        var groupPayment = activeGroupPayments[index]
        
        // Update status
        groupPayment.status = .cancelled
        groupPayment.cancelledAt = Date()
        groupPayment.cancellationReason = reason
        
        // Update active group payments
        activeGroupPayments[index] = groupPayment
        
        // Save group payment
        try await saveGroupPayment(groupPayment)
        
        // Send cancellation notifications
        try await sendCancellationNotifications(groupPayment)
        
        hapticService.trigger(.light)
        
        analyticsService.trackEvent("group_payment_cancelled", properties: [
            "group_payment_id": groupPaymentId,
            "reason": reason ?? "user_requested"
        ])
        
        return groupPayment
    }
    
    /// Get group payment by ID
    func getGroupPayment(by id: String) -> GroupPayment? {
        return activeGroupPayments.first { $0.id == id }
    }
    
    /// Get group payments for user
    func getGroupPayments(for userEmail: String) -> [GroupPayment] {
        return activeGroupPayments.filter { groupPayment in
            groupPayment.organizerEmail == userEmail ||
            groupPayment.participants.contains { $0.email == userEmail }
        }
    }
    
    /// Get group payment analytics
    func getGroupPaymentAnalytics(timeRange: DateInterval) async throws -> GroupPaymentAnalytics {
        
        let groupPaymentsInRange = activeGroupPayments.filter { groupPayment in
            timeRange.contains(groupPayment.createdAt)
        }
        
        let analytics = GroupPaymentAnalytics(
            timeRange: timeRange,
            totalGroupPayments: groupPaymentsInRange.count,
            completedGroupPayments: groupPaymentsInRange.filter { $0.status == .completed }.count,
            failedGroupPayments: groupPaymentsInRange.filter { $0.status == .failed }.count,
            cancelledGroupPayments: groupPaymentsInRange.filter { $0.status == .cancelled }.count,
            totalAmount: groupPaymentsInRange.reduce(0) { $0 + $1.totalAmount },
            averageGroupSize: calculateAverageGroupSize(groupPaymentsInRange),
            successRate: calculateSuccessRate(groupPaymentsInRange),
            groupPaymentsBySplitType: groupGroupPaymentsBySplitType(groupPaymentsInRange),
            generatedAt: Date()
        )
        
        analyticsService.trackEvent("group_payment_analytics_generated", properties: [
            "time_range_start": timeRange.start.timeIntervalSince1970,
            "time_range_end": timeRange.end.timeIntervalSince1970,
            "total_group_payments": analytics.totalGroupPayments
        ])
        
        return analytics
    }
    
    // MARK: - Payment Splitting Methods
    
    /// Calculate payment splits
    func calculatePaymentSplits(
        totalAmount: Double,
        participants: [GroupPaymentParticipant],
        splitType: PaymentSplitType
    ) -> [GroupPaymentParticipant] {
        
        var updatedParticipants = participants
        
        switch splitType {
        case .equal:
            let splitAmount = totalAmount / Double(participants.count)
            for i in 0..<updatedParticipants.count {
                updatedParticipants[i].amount = splitAmount
            }
            
        case .percentage:
            let totalPercentage = participants.reduce(0) { $0 + $1.percentage }
            for i in 0..<updatedParticipants.count {
                let percentage = participants[i].percentage / totalPercentage
                updatedParticipants[i].amount = totalAmount * percentage
            }
            
        case .custom:
            // Custom amounts are already set
            break
        }
        
        return updatedParticipants
    }
    
    /// Validate payment splits
    func validatePaymentSplits(
        participants: [GroupPaymentParticipant],
        totalAmount: Double,
        splitType: PaymentSplitType
    ) -> Bool {
        
        let calculatedParticipants = calculatePaymentSplits(
            totalAmount: totalAmount,
            participants: participants,
            splitType: splitType
        )
        
        let calculatedTotal = calculatedParticipants.reduce(0) { $0 + $1.amount }
        let difference = abs(calculatedTotal - totalAmount)
        
        // Allow for small rounding differences
        return difference < 0.01
    }
    
    // MARK: - Private Methods
    
    private func startGroupPaymentMonitoring() {
        // Check for expired group payments every 30 minutes
        groupPaymentTimer = Timer.scheduledTimer(withTimeInterval: 1800, repeats: true) { [weak self] _ in
            Task {
                await self?.checkExpiredGroupPayments()
            }
        }
    }
    
    private func checkExpiredGroupPayments() async {
        let now = Date()
        let expiredPayments = activeGroupPayments.filter { $0.expiresAt <= now && $0.status == .pending }
        
        for payment in expiredPayments {
            do {
                try await cancelGroupPayment(payment.id, reason: "Expired")
            } catch {
                errorHandlingService.handleError(error, context: "PaymentSplittingService.checkExpiredGroupPayments")
            }
        }
    }
    
    private func validateParticipants(
        _ participants: [GroupPaymentParticipant],
        totalAmount: Double,
        splitType: PaymentSplitType
    ) throws {
        
        guard !participants.isEmpty else {
            throw PaymentSplittingError.noParticipants
        }
        
        guard participants.count <= 20 else {
            throw PaymentSplittingError.tooManyParticipants
        }
        
        // Validate email addresses
        for participant in participants {
            guard isValidEmail(participant.email) else {
                throw PaymentSplittingError.invalidEmail
            }
        }
        
        // Validate payment splits
        guard validatePaymentSplits(participants: participants, totalAmount: totalAmount, splitType: splitType) else {
            throw PaymentSplittingError.invalidPaymentSplits
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func sendGroupPaymentInvitations(_ groupPayment: GroupPayment) async throws {
        // In a real implementation, this would send email/SMS invitations
        // For demo purposes, we'll just log the invitations
        
        for participant in groupPayment.participants {
            analyticsService.trackEvent("group_payment_invitation_sent", properties: [
                "group_payment_id": groupPayment.id,
                "participant_email": participant.email,
                "amount": participant.amount
            ])
        }
    }
    
    private func sendCancellationNotifications(_ groupPayment: GroupPayment) async throws {
        // In a real implementation, this would send cancellation notifications
        // For demo purposes, we'll just log the notifications
        
        for participant in groupPayment.participants {
            analyticsService.trackEvent("group_payment_cancellation_notification_sent", properties: [
                "group_payment_id": groupPayment.id,
                "participant_email": participant.email
            ])
        }
    }
    
    private func processParticipantPayment(
        _ groupPayment: GroupPayment,
        _ participant: GroupPaymentParticipant
    ) async throws -> PaymentTransaction {
        
        // Get payment method
        guard let paymentMethod = paymentService.getPaymentMethod(by: participant.paymentMethodId) else {
            throw PaymentSplittingError.paymentMethodNotFound
        }
        
        // Create payment transaction
        let transaction = PaymentTransaction(
            transactionId: UUID().uuidString,
            amount: participant.amount,
            currency: groupPayment.currency,
            paymentMethod: paymentMethod.type,
            status: .processing,
            timestamp: Date(),
            customerEmail: participant.email,
            customerName: participant.name,
            location: nil,
            country: "US",
            metadata: [
                "group_payment_id": groupPayment.id,
                "participant_id": participant.id,
                "payment_method_type": paymentMethod.type.rawValue
            ]
        )
        
        // Process payment
        let processedTransaction = try await processPaymentTransaction(transaction)
        
        return processedTransaction
    }
    
    private func updateSplittingStatistics() async {
        let totalGroupPayments = activeGroupPayments.count
        let completedGroupPayments = activeGroupPayments.filter { $0.status == .completed }.count
        let totalAmount = activeGroupPayments.reduce(0) { $0 + $1.totalAmount }
        
        splittingStats = PaymentSplittingStatistics(
            totalGroupPayments: totalGroupPayments,
            completedGroupPayments: completedGroupPayments,
            failedGroupPayments: activeGroupPayments.filter { $0.status == .failed }.count,
            cancelledGroupPayments: activeGroupPayments.filter { $0.status == .cancelled }.count,
            totalAmount: totalAmount,
            averageGroupSize: calculateAverageGroupSize(activeGroupPayments),
            successRate: totalGroupPayments > 0 ? Double(completedGroupPayments) / Double(totalGroupPayments) : 0,
            lastUpdated: Date()
        )
    }
    
    private func calculateAverageGroupSize(_ groupPayments: [GroupPayment]) -> Double {
        guard !groupPayments.isEmpty else { return 0 }
        let totalParticipants = groupPayments.reduce(0) { $0 + $1.participants.count }
        return Double(totalParticipants) / Double(groupPayments.count)
    }
    
    private func calculateSuccessRate(_ groupPayments: [GroupPayment]) -> Double {
        let completed = groupPayments.filter { $0.status == .completed }.count
        guard !groupPayments.isEmpty else { return 0 }
        return Double(completed) / Double(groupPayments.count)
    }
    
    private func groupGroupPaymentsBySplitType(_ groupPayments: [GroupPayment]) -> [PaymentSplitType: Int] {
        var grouped: [PaymentSplitType: Int] = [:]
        
        for groupPayment in groupPayments {
            grouped[groupPayment.splitType, default: 0] += 1
        }
        
        return grouped
    }
    
    // MARK: - Storage Methods (Mock Implementation)
    
    private func saveGroupPayment(_ groupPayment: GroupPayment) async throws {
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // In a real implementation, this would save to secure storage
    }
    
    private func processPaymentTransaction(_ transaction: PaymentTransaction) async throws -> PaymentTransaction {
        // Simulate payment processing delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Return successful transaction
        var processedTransaction = transaction
        processedTransaction.status = .completed
        
        return processedTransaction
    }
}

// MARK: - Payment Splitting Models

/// Group payment model
struct GroupPayment: Codable, Identifiable {
    let id: String
    let eventId: String
    let totalAmount: Double
    let currency: String
    let splitType: PaymentSplitType
    var status: GroupPaymentStatus
    let organizerEmail: String
    var participants: [GroupPaymentParticipant]
    let createdAt: Date
    let expiresAt: Date
    var completedAt: Date?
    var cancelledAt: Date?
    var cancellationReason: String?
    var metadata: [String: String]
}

enum GroupPaymentStatus: String, Codable {
    case pending = "pending"
    case ready = "ready"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case partial = "partial"
    case cancelled = "cancelled"
}

enum PaymentSplitType: String, Codable, CaseIterable {
    case equal = "equal"
    case percentage = "percentage"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .equal:
            return "Split Equally"
        case .percentage:
            return "Split by Percentage"
        case .custom:
            return "Custom Amounts"
        }
    }
}

/// Group payment participant
struct GroupPaymentParticipant: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    var amount: Double
    var percentage: Double
    var status: ParticipantStatus
    var paymentMethodId: String?
    var joinedAt: Date?
    var transactionId: String?
    
    init(
        id: String = UUID().uuidString,
        email: String,
        name: String,
        amount: Double = 0,
        percentage: Double = 0,
        status: ParticipantStatus = .invited,
        paymentMethodId: String? = nil
    ) {
        self.id = id
        self.email = email
        self.name = name
        self.amount = amount
        self.percentage = percentage
        self.status = status
        self.paymentMethodId = paymentMethodId
    }
}

enum ParticipantStatus: String, Codable {
    case invited = "invited"
    case joined = "joined"
    case paid = "paid"
    case failed = "failed"
}

/// Group payment result
struct GroupPaymentResult: Codable {
    let groupPayment: GroupPayment
    let successfulPayments: [PaymentTransaction]
    let failedPayments: [FailedPayment]
    let totalCollected: Double
}

/// Failed payment
struct FailedPayment: Codable {
    let participantId: String
    let participantEmail: String
    let amount: Double
    let error: String
}

/// Payment splitting statistics
struct PaymentSplittingStatistics: Codable {
    let totalGroupPayments: Int
    let completedGroupPayments: Int
    let failedGroupPayments: Int
    let cancelledGroupPayments: Int
    let totalAmount: Double
    let averageGroupSize: Double
    let successRate: Double
    let lastUpdated: Date
}

/// Group payment analytics
struct GroupPaymentAnalytics: Codable {
    let timeRange: DateInterval
    let totalGroupPayments: Int
    let completedGroupPayments: Int
    let failedGroupPayments: Int
    let cancelledGroupPayments: Int
    let totalAmount: Double
    let averageGroupSize: Double
    let successRate: Double
    let groupPaymentsBySplitType: [PaymentSplitType: Int]
    let generatedAt: Date
}

/// Payment splitting errors
enum PaymentSplittingError: Error, LocalizedError {
    case groupPaymentNotFound
    case participantNotFound
    case paymentMethodNotFound
    case noParticipants
    case tooManyParticipants
    case invalidEmail
    case invalidPaymentSplits
    case notAllParticipantsJoined
    case groupPaymentExpired
    
    var errorDescription: String? {
        switch self {
        case .groupPaymentNotFound:
            return "Group payment not found"
        case .participantNotFound:
            return "Participant not found"
        case .paymentMethodNotFound:
            return "Payment method not found"
        case .noParticipants:
            return "No participants specified"
        case .tooManyParticipants:
            return "Too many participants (maximum 20)"
        case .invalidEmail:
            return "Invalid email address"
        case .invalidPaymentSplits:
            return "Invalid payment splits"
        case .notAllParticipantsJoined:
            return "Not all participants have joined"
        case .groupPaymentExpired:
            return "Group payment has expired"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .groupPaymentNotFound:
            return "Please check the group payment ID"
        case .participantNotFound:
            return "Please check the participant email"
        case .paymentMethodNotFound:
            return "Please add a valid payment method"
        case .noParticipants:
            return "Please add at least one participant"
        case .tooManyParticipants:
            return "Please reduce the number of participants"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidPaymentSplits:
            return "Please check the payment amounts"
        case .notAllParticipantsJoined:
            return "Please wait for all participants to join"
        case .groupPaymentExpired:
            return "Please create a new group payment"
        }
    }
}

// MARK: - Extensions

extension PaymentSplittingService {
    /// Create a mock instance for testing
    static func mock() -> PaymentSplittingService {
        PaymentSplittingService(
            analyticsService: .shared,
            errorHandlingService: .shared,
            paymentService: .shared,
            hapticService: .shared
        )
    }
} 