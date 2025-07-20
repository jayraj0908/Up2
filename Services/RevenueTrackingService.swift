import Foundation
import Combine

/// Service for tracking revenue, commissions, and payouts
@MainActor
class RevenueTrackingService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var revenueStats: RevenueStatistics = RevenueStatistics()
    @Published var activePayouts: [Payout] = []
    @Published var commissionRates: [CommissionRate] = []
    @Published var revenueShares: [RevenueShare] = []
    @Published var isLoading = false
    
    // MARK: - Private Properties
    
    private let analyticsService: AnalyticsService
    private let errorHandlingService: ErrorHandlingService
    private let paymentService: PaymentProcessingService
    private let hapticService: HapticService
    
    private var cancellables = Set<AnyCancellable>()
    private var payoutTimer: Timer?
    
    // MARK: - Initialization
    
    init(
        analyticsService: AnalyticsService = .shared,
        errorHandlingService: ErrorHandlingService = .shared,
        paymentService: PaymentProcessingService = .shared,
        hapticService: HapticService = .shared
    ) {
        self.analyticsService = analyticsService
        self.errorHandlingService = errorHandlingService
        self.paymentService = paymentService
        self.hapticService = hapticService
        
        setupCommissionRates()
        startPayoutMonitoring()
    }
    
    // MARK: - Revenue Tracking
    
    /// Track revenue from a successful payment
    func trackRevenue(from transaction: PaymentTransaction) async throws -> RevenueRecord {
        
        isLoading = true
        
        do {
            // Calculate revenue breakdown
            let breakdown = try await calculateRevenueBreakdown(for: transaction)
            
            // Create revenue record
            let revenueRecord = RevenueRecord(
                id: UUID().uuidString,
                transactionId: transaction.transactionId,
                eventId: transaction.metadata["event_id"] ?? "",
                hostEmail: transaction.metadata["host_email"] ?? "",
                customerEmail: transaction.customerEmail,
                grossAmount: transaction.amount,
                netAmount: breakdown.netAmount,
                platformFee: breakdown.platformFee,
                processingFee: breakdown.processingFee,
                hostRevenue: breakdown.hostRevenue,
                currency: transaction.currency,
                status: .completed,
                createdAt: Date(),
                metadata: [
                    "payment_method": transaction.paymentMethod.rawValue,
                    "event_type": transaction.metadata["event_type"] ?? "ticket_sale"
                ]
            )
            
            // Add to revenue shares
            let revenueShare = RevenueShare(
                id: UUID().uuidString,
                revenueRecordId: revenueRecord.id,
                hostEmail: revenueRecord.hostEmail,
                amount: revenueRecord.hostRevenue,
                currency: revenueRecord.currency,
                status: .pending,
                createdAt: Date(),
                payoutId: nil
            )
            
            revenueShares.append(revenueShare)
            
            // Update statistics
            await updateRevenueStatistics()
            
            hapticService.trigger(.success)
            
            analyticsService.trackEvent("revenue_tracked", properties: [
                "transaction_id": transaction.transactionId,
                "gross_amount": transaction.amount,
                "net_amount": breakdown.netAmount,
                "platform_fee": breakdown.platformFee,
                "host_revenue": breakdown.hostRevenue
            ])
            
            return revenueRecord
            
        } catch {
            errorHandlingService.handleError(error, context: "RevenueTrackingService.trackRevenue")
            throw error
        } finally {
            isLoading = false
        }
    }
    
    /// Calculate revenue breakdown for a transaction
    func calculateRevenueBreakdown(for transaction: PaymentTransaction) async throws -> RevenueBreakdown {
        
        // Get commission rate based on transaction type
        let commissionRate = getCommissionRate(for: transaction)
        
        // Calculate fees
        let processingFee = calculateProcessingFee(amount: transaction.amount, paymentMethod: transaction.paymentMethod)
        let platformFee = transaction.amount * commissionRate.rate
        
        // Calculate net amounts
        let totalFees = processingFee + platformFee
        let netAmount = transaction.amount - totalFees
        let hostRevenue = netAmount
        
        return RevenueBreakdown(
            grossAmount: transaction.amount,
            netAmount: netAmount,
            platformFee: platformFee,
            processingFee: processingFee,
            hostRevenue: hostRevenue,
            commissionRate: commissionRate
        )
    }
    
    /// Get commission rate for transaction
    func getCommissionRate(for transaction: PaymentTransaction) -> CommissionRate {
        // Determine commission rate based on transaction type and amount
        let eventType = transaction.metadata["event_type"] ?? "ticket_sale"
        let amount = transaction.amount
        
        // Find applicable commission rate
        if let rate = commissionRates.first(where: { rate in
            rate.eventType == eventType &&
            amount >= rate.minAmount &&
            (rate.maxAmount == nil || amount <= rate.maxAmount!)
        }) {
            return rate
        }
        
        // Return default rate
        return CommissionRate(
            id: "default",
            eventType: "ticket_sale",
            rate: 0.10, // 10% default
            minAmount: 0,
            maxAmount: nil,
            description: "Default commission rate"
        )
    }
    
    /// Calculate processing fee
    private func calculateProcessingFee(amount: Double, paymentMethod: PaymentMethodType) -> Double {
        // Standard processing fees (simplified for demo)
        let baseRate: Double
        let fixedFee: Double
        
        switch paymentMethod {
        case .creditCard:
            baseRate = 0.029 // 2.9%
            fixedFee = 0.30 // $0.30
        case .applePay, .googlePay:
            baseRate = 0.025 // 2.5%
            fixedFee = 0.25 // $0.25
        case .paypal:
            baseRate = 0.029 // 2.9%
            fixedFee = 0.30 // $0.30
        case .bankTransfer:
            baseRate = 0.008 // 0.8%
            fixedFee = 0.25 // $0.25
        case .invalid:
            baseRate = 0.029 // 2.9%
            fixedFee = 0.30 // $0.30
        }
        
        return (amount * baseRate) + fixedFee
    }
    
    // MARK: - Payout Management
    
    /// Create payout for host
    func createPayout(
        for hostEmail: String,
        amount: Double,
        currency: String = "USD",
        payoutMethod: PayoutMethod
    ) async throws -> Payout {
        
        isLoading = true
        
        do {
            // Validate payout amount
            guard amount >= getMinimumPayoutAmount(currency: currency) else {
                throw RevenueTrackingError.insufficientPayoutAmount
            }
            
            // Create payout
            let payout = Payout(
                id: UUID().uuidString,
                hostEmail: hostEmail,
                amount: amount,
                currency: currency,
                payoutMethod: payoutMethod,
                status: .pending,
                requestedAt: Date(),
                processedAt: nil,
                estimatedDelivery: calculateEstimatedDelivery(payoutMethod),
                fees: calculatePayoutFees(amount: amount, method: payoutMethod),
                metadata: [
                    "payout_method": payoutMethod.rawValue
                ]
            )
            
            // Add to active payouts
            activePayouts.append(payout)
            
            // Update revenue shares
            updateRevenueSharesForPayout(payout)
            
            // Save payout
            try await savePayout(payout)
            
            hapticService.trigger(.success)
            
            analyticsService.trackEvent("payout_created", properties: [
                "payout_id": payout.id,
                "host_email": hostEmail,
                "amount": amount,
                "payout_method": payoutMethod.rawValue
            ])
            
            return payout
            
        } catch {
            errorHandlingService.handleError(error, context: "RevenueTrackingService.createPayout")
            throw error
        } finally {
            isLoading = false
        }
    }
    
    /// Process pending payouts
    func processPendingPayouts() async throws -> [Payout] {
        
        let pendingPayouts = activePayouts.filter { $0.status == .pending }
        var processedPayouts: [Payout] = []
        
        for payout in pendingPayouts {
            do {
                let processedPayout = try await processPayout(payout)
                processedPayouts.append(processedPayout)
            } catch {
                errorHandlingService.handleError(error, context: "RevenueTrackingService.processPendingPayouts")
            }
        }
        
        return processedPayouts
    }
    
    /// Get payout by ID
    func getPayout(by id: String) -> Payout? {
        return activePayouts.first { $0.id == id }
    }
    
    /// Get payouts for host
    func getPayouts(for hostEmail: String) -> [Payout] {
        return activePayouts.filter { $0.payoutMethod.hostEmail == hostEmail }
    }
    
    /// Get pending revenue for host
    func getPendingRevenue(for hostEmail: String) -> Double {
        let pendingShares = revenueShares.filter { 
            $0.hostEmail == hostEmail && $0.status == .pending 
        }
        return pendingShares.reduce(0) { $0 + $1.amount }
    }
    
    // MARK: - Analytics and Reporting
    
    /// Get revenue analytics
    func getRevenueAnalytics(timeRange: DateInterval) async throws -> RevenueAnalytics {
        
        let revenueInRange = revenueShares.filter { share in
            timeRange.contains(share.createdAt)
        }
        
        let analytics = RevenueAnalytics(
            timeRange: timeRange,
            totalRevenue: revenueInRange.reduce(0) { $0 + $1.amount },
            totalPayouts: activePayouts.filter { timeRange.contains($0.requestedAt) }.count,
            averageRevenuePerEvent: calculateAverageRevenuePerEvent(revenueInRange),
            topHosts: getTopHosts(revenueInRange),
            revenueByEventType: groupRevenueByEventType(revenueInRange),
            payoutSuccessRate: calculatePayoutSuccessRate(),
            generatedAt: Date()
        )
        
        analyticsService.trackEvent("revenue_analytics_generated", properties: [
            "time_range_start": timeRange.start.timeIntervalSince1970,
            "time_range_end": timeRange.end.timeIntervalSince1970,
            "total_revenue": analytics.totalRevenue
        ])
        
        return analytics
    }
    
    /// Generate revenue report
    func generateRevenueReport(
        for hostEmail: String,
        timeRange: DateInterval
    ) async throws -> HostRevenueReport {
        
        let hostRevenue = revenueShares.filter { share in
            share.hostEmail == hostEmail && timeRange.contains(share.createdAt)
        }
        
        let hostPayouts = activePayouts.filter { payout in
            payout.payoutMethod.hostEmail == hostEmail && timeRange.contains(payout.requestedAt)
        }
        
        let report = HostRevenueReport(
            hostEmail: hostEmail,
            timeRange: timeRange,
            totalRevenue: hostRevenue.reduce(0) { $0 + $1.amount },
            totalPayouts: hostPayouts.reduce(0) { $0 + $1.amount },
            pendingRevenue: getPendingRevenue(for: hostEmail),
            revenueByMonth: groupRevenueByMonth(hostRevenue),
            payoutHistory: hostPayouts,
            averageRevenuePerEvent: calculateAverageRevenuePerEvent(hostRevenue),
            generatedAt: Date()
        )
        
        analyticsService.trackEvent("host_revenue_report_generated", properties: [
            "host_email": hostEmail,
            "total_revenue": report.totalRevenue,
            "total_payouts": report.totalPayouts
        ])
        
        return report
    }
    
    // MARK: - Private Methods
    
    private func setupCommissionRates() {
        commissionRates = [
            CommissionRate(
                id: "ticket_sale_standard",
                eventType: "ticket_sale",
                rate: 0.10, // 10%
                minAmount: 0,
                maxAmount: 1000,
                description: "Standard ticket sales"
            ),
            CommissionRate(
                id: "ticket_sale_premium",
                eventType: "ticket_sale",
                rate: 0.08, // 8%
                minAmount: 1000,
                maxAmount: nil,
                description: "Premium ticket sales"
            ),
            CommissionRate(
                id: "subscription_monthly",
                eventType: "subscription",
                rate: 0.15, // 15%
                minAmount: 0,
                maxAmount: nil,
                description: "Monthly subscriptions"
            ),
            CommissionRate(
                id: "subscription_yearly",
                eventType: "subscription",
                rate: 0.12, // 12%
                minAmount: 0,
                maxAmount: nil,
                description: "Yearly subscriptions"
            ),
            CommissionRate(
                id: "group_payment",
                eventType: "group_payment",
                rate: 0.05, // 5%
                minAmount: 0,
                maxAmount: nil,
                description: "Group payments"
            )
        ]
    }
    
    private func startPayoutMonitoring() {
        // Check for pending payouts every 6 hours
        payoutTimer = Timer.scheduledTimer(withTimeInterval: 21600, repeats: true) { [weak self] _ in
            Task {
                try? await self?.processPendingPayouts()
            }
        }
    }
    
    private func getMinimumPayoutAmount(currency: String) -> Double {
        switch currency {
        case "USD":
            return 25.0 // $25 minimum
        case "EUR":
            return 20.0 // €20 minimum
        case "GBP":
            return 15.0 // £15 minimum
        default:
            return 25.0 // Default $25
        }
    }
    
    private func calculateEstimatedDelivery(_ method: PayoutMethod) -> Date {
        let calendar = Calendar.current
        
        switch method {
        case .bankTransfer:
            return calendar.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        case .paypal:
            return calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        case .stripe:
            return calendar.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        }
    }
    
    private func calculatePayoutFees(amount: Double, method: PayoutMethod) -> Double {
        switch method {
        case .bankTransfer:
            return 0.25 // $0.25 flat fee
        case .paypal:
            return amount * 0.025 // 2.5%
        case .stripe:
            return 0.25 // $0.25 flat fee
        }
    }
    
    private func updateRevenueSharesForPayout(_ payout: Payout) {
        // Update revenue shares to mark them as paid
        for i in 0..<revenueShares.count {
            if revenueShares[i].hostEmail == payout.payoutMethod.hostEmail && 
               revenueShares[i].status == .pending {
                revenueShares[i].status = .paid
                revenueShares[i].payoutId = payout.id
            }
        }
    }
    
    private func processPayout(_ payout: Payout) async throws -> Payout {
        // Simulate payout processing
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        var processedPayout = payout
        processedPayout.status = .completed
        processedPayout.processedAt = Date()
        
        // Update in active payouts
        if let index = activePayouts.firstIndex(where: { $0.id == payout.id }) {
            activePayouts[index] = processedPayout
        }
        
        analyticsService.trackEvent("payout_processed", properties: [
            "payout_id": payout.id,
            "amount": payout.amount,
            "payout_method": payout.payoutMethod.rawValue
        ])
        
        return processedPayout
    }
    
    private func updateRevenueStatistics() async {
        let totalRevenue = revenueShares.reduce(0) { $0 + $1.amount }
        let pendingRevenue = revenueShares.filter { $0.status == .pending }.reduce(0) { $0 + $1.amount }
        let paidRevenue = revenueShares.filter { $0.status == .paid }.reduce(0) { $0 + $1.amount }
        
        revenueStats = RevenueStatistics(
            totalRevenue: totalRevenue,
            pendingRevenue: pendingRevenue,
            paidRevenue: paidRevenue,
            totalPayouts: activePayouts.count,
            completedPayouts: activePayouts.filter { $0.status == .completed }.count,
            averagePayoutAmount: calculateAveragePayoutAmount(),
            lastUpdated: Date()
        )
    }
    
    private func calculateAveragePayoutAmount() -> Double {
        let completedPayouts = activePayouts.filter { $0.status == .completed }
        guard !completedPayouts.isEmpty else { return 0 }
        
        let totalAmount = completedPayouts.reduce(0) { $0 + $1.amount }
        return totalAmount / Double(completedPayouts.count)
    }
    
    private func calculateAverageRevenuePerEvent(_ revenue: [RevenueShare]) -> Double {
        guard !revenue.isEmpty else { return 0 }
        
        let totalRevenue = revenue.reduce(0) { $0 + $1.amount }
        return totalRevenue / Double(revenue.count)
    }
    
    private func getTopHosts(_ revenue: [RevenueShare]) -> [HostRevenue] {
        var hostRevenue: [String: Double] = [:]
        
        for share in revenue {
            hostRevenue[share.hostEmail, default: 0] += share.amount
        }
        
        return hostRevenue.map { HostRevenue(hostEmail: $0.key, revenue: $0.value) }
            .sorted { $0.revenue > $1.revenue }
            .prefix(10)
            .map { $0 }
    }
    
    private func groupRevenueByEventType(_ revenue: [RevenueShare]) -> [String: Double] {
        var grouped: [String: Double] = [:]
        
        for share in revenue {
            grouped["ticket_sale", default: 0] += share.amount
        }
        
        return grouped
    }
    
    private func calculatePayoutSuccessRate() -> Double {
        let totalPayouts = activePayouts.count
        guard totalPayouts > 0 else { return 0 }
        
        let successfulPayouts = activePayouts.filter { $0.status == .completed }.count
        return Double(successfulPayouts) / Double(totalPayouts)
    }
    
    private func groupRevenueByMonth(_ revenue: [RevenueShare]) -> [String: Double] {
        var grouped: [String: Double] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        
        for share in revenue {
            let monthKey = formatter.string(from: share.createdAt)
            grouped[monthKey, default: 0] += share.amount
        }
        
        return grouped
    }
    
    // MARK: - Storage Methods (Mock Implementation)
    
    private func savePayout(_ payout: Payout) async throws {
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // In a real implementation, this would save to secure storage
    }
}

// MARK: - Revenue Tracking Models

/// Revenue record
struct RevenueRecord: Codable, Identifiable {
    let id: String
    let transactionId: String
    let eventId: String
    let hostEmail: String
    let customerEmail: String
    let grossAmount: Double
    let netAmount: Double
    let platformFee: Double
    let processingFee: Double
    let hostRevenue: Double
    let currency: String
    let status: RevenueStatus
    let createdAt: Date
    let metadata: [String: String]
}

enum RevenueStatus: String, Codable {
    case pending = "pending"
    case completed = "completed"
    case failed = "failed"
    case refunded = "refunded"
}

/// Revenue breakdown
struct RevenueBreakdown: Codable {
    let grossAmount: Double
    let netAmount: Double
    let platformFee: Double
    let processingFee: Double
    let hostRevenue: Double
    let commissionRate: CommissionRate
}

/// Commission rate
struct CommissionRate: Codable, Identifiable {
    let id: String
    let eventType: String
    let rate: Double
    let minAmount: Double
    let maxAmount: Double?
    let description: String
    
    var percentage: String {
        return "\(Int(rate * 100))%"
    }
}

/// Revenue share
struct RevenueShare: Codable, Identifiable {
    let id: String
    let revenueRecordId: String
    let hostEmail: String
    let amount: Double
    let currency: String
    var status: ShareStatus
    let createdAt: Date
    var payoutId: String?
}

enum ShareStatus: String, Codable {
    case pending = "pending"
    case paid = "paid"
    case failed = "failed"
}

/// Payout
struct Payout: Codable, Identifiable {
    let id: String
    let hostEmail: String
    let amount: Double
    let currency: String
    let payoutMethod: PayoutMethod
    var status: PayoutStatus
    let requestedAt: Date
    var processedAt: Date?
    let estimatedDelivery: Date
    let fees: Double
    let metadata: [String: String]
    
    var netAmount: Double {
        return amount - fees
    }
}

enum PayoutStatus: String, Codable {
    case pending = "pending"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
}

/// Payout method
struct PayoutMethod: Codable {
    let type: PayoutMethodType
    let hostEmail: String
    let accountDetails: [String: String]
    
    var rawValue: String {
        return type.rawValue
    }
}

enum PayoutMethodType: String, Codable {
    case bankTransfer = "bank_transfer"
    case paypal = "paypal"
    case stripe = "stripe"
}

/// Revenue statistics
struct RevenueStatistics: Codable {
    let totalRevenue: Double
    let pendingRevenue: Double
    let paidRevenue: Double
    let totalPayouts: Int
    let completedPayouts: Int
    let averagePayoutAmount: Double
    let lastUpdated: Date
}

/// Revenue analytics
struct RevenueAnalytics: Codable {
    let timeRange: DateInterval
    let totalRevenue: Double
    let totalPayouts: Int
    let averageRevenuePerEvent: Double
    let topHosts: [HostRevenue]
    let revenueByEventType: [String: Double]
    let payoutSuccessRate: Double
    let generatedAt: Date
}

/// Host revenue
struct HostRevenue: Codable {
    let hostEmail: String
    let revenue: Double
}

/// Host revenue report
struct HostRevenueReport: Codable {
    let hostEmail: String
    let timeRange: DateInterval
    let totalRevenue: Double
    let totalPayouts: Double
    let pendingRevenue: Double
    let revenueByMonth: [String: Double]
    let payoutHistory: [Payout]
    let averageRevenuePerEvent: Double
    let generatedAt: Date
}

/// Revenue tracking errors
enum RevenueTrackingError: Error, LocalizedError {
    case insufficientPayoutAmount
    case payoutMethodNotSupported
    case revenueCalculationFailed
    case payoutProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .insufficientPayoutAmount:
            return "Payout amount is below minimum threshold"
        case .payoutMethodNotSupported:
            return "Payout method not supported"
        case .revenueCalculationFailed:
            return "Failed to calculate revenue breakdown"
        case .payoutProcessingFailed:
            return "Failed to process payout"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .insufficientPayoutAmount:
            return "Please wait for more revenue to accumulate"
        case .payoutMethodNotSupported:
            return "Please select a different payout method"
        case .revenueCalculationFailed:
            return "Please try again or contact support"
        case .payoutProcessingFailed:
            return "Please try again or contact support"
        }
    }
}

// MARK: - Extensions

extension RevenueTrackingService {
    /// Create a mock instance for testing
    static func mock() -> RevenueTrackingService {
        RevenueTrackingService(
            analyticsService: .shared,
            errorHandlingService: .shared,
            paymentService: .shared,
            hapticService: .shared
        )
    }
} 