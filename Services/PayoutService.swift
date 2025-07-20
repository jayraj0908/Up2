import Foundation
import Combine

/// Service for managing automated payouts and payout scheduling
@MainActor
class PayoutService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var scheduledPayouts: [ScheduledPayout] = []
    @Published var payoutHistory: [PayoutRecord] = []
    @Published var payoutSettings: [PayoutSetting] = []
    @Published var isLoading = false
    @Published var payoutStats: PayoutStatistics = PayoutStatistics()
    
    // MARK: - Private Properties
    
    private let analyticsService: AnalyticsService
    private let errorHandlingService: ErrorHandlingService
    private let revenueService: RevenueTrackingService
    private let hapticService: HapticService
    
    private var cancellables = Set<AnyCancellable>()
    private var payoutTimer: Timer?
    
    // MARK: - Initialization
    
    init(
        analyticsService: AnalyticsService = .shared,
        errorHandlingService: ErrorHandlingService = .shared,
        revenueService: RevenueTrackingService = .shared,
        hapticService: HapticService = .shared
    ) {
        self.analyticsService = analyticsService
        self.errorHandlingService = errorHandlingService
        self.revenueService = revenueService
        self.hapticService = hapticService
        
        setupPayoutSettings()
        startPayoutMonitoring()
    }
    
    // MARK: - Payout Scheduling
    
    /// Schedule automatic payout
    func schedulePayout(
        for hostEmail: String,
        schedule: PayoutSchedule,
        minimumAmount: Double,
        payoutMethod: PayoutMethod
    ) async throws -> ScheduledPayout {
        
        isLoading = true
        
        do {
            // Validate payout method
            try validatePayoutMethod(payoutMethod)
            
            // Create scheduled payout
            let scheduledPayout = ScheduledPayout(
                id: UUID().uuidString,
                hostEmail: hostEmail,
                schedule: schedule,
                minimumAmount: minimumAmount,
                payoutMethod: payoutMethod,
                status: .active,
                nextPayoutDate: calculateNextPayoutDate(schedule: schedule),
                lastPayoutDate: nil,
                totalPayouts: 0,
                totalAmount: 0,
                createdAt: Date(),
                metadata: [
                    "payout_method": payoutMethod.rawValue,
                    "schedule_type": schedule.type.rawValue
                ]
            )
            
            // Add to scheduled payouts
            scheduledPayouts.append(scheduledPayout)
            
            // Save scheduled payout
            try await saveScheduledPayout(scheduledPayout)
            
            hapticService.trigger(.success)
            
            analyticsService.trackEvent("payout_scheduled", properties: [
                "host_email": hostEmail,
                "schedule_type": schedule.type.rawValue,
                "minimum_amount": minimumAmount,
                "payout_method": payoutMethod.rawValue
            ])
            
            return scheduledPayout
            
        } catch {
            errorHandlingService.handleError(error, context: "PayoutService.schedulePayout")
            throw error
        } finally {
            isLoading = false
        }
    }
    
    /// Update payout schedule
    func updatePayoutSchedule(
        _ scheduledPayoutId: String,
        schedule: PayoutSchedule,
        minimumAmount: Double
    ) async throws -> ScheduledPayout {
        
        guard let index = scheduledPayouts.firstIndex(where: { $0.id == scheduledPayoutId }) else {
            throw PayoutError.scheduledPayoutNotFound
        }
        
        var scheduledPayout = scheduledPayouts[index]
        
        // Update schedule
        scheduledPayout.schedule = schedule
        scheduledPayout.minimumAmount = minimumAmount
        scheduledPayout.nextPayoutDate = calculateNextPayoutDate(schedule: schedule)
        
        // Update in array
        scheduledPayouts[index] = scheduledPayout
        
        // Save updated schedule
        try await saveScheduledPayout(scheduledPayout)
        
        hapticService.trigger(.light)
        
        analyticsService.trackEvent("payout_schedule_updated", properties: [
            "scheduled_payout_id": scheduledPayoutId,
            "schedule_type": schedule.type.rawValue,
            "minimum_amount": minimumAmount
        ])
        
        return scheduledPayout
    }
    
    /// Cancel payout schedule
    func cancelPayoutSchedule(_ scheduledPayoutId: String) async throws -> ScheduledPayout {
        
        guard let index = scheduledPayouts.firstIndex(where: { $0.id == scheduledPayoutId }) else {
            throw PayoutError.scheduledPayoutNotFound
        }
        
        var scheduledPayout = scheduledPayouts[index]
        
        // Update status
        scheduledPayout.status = .cancelled
        scheduledPayout.cancelledAt = Date()
        
        // Update in array
        scheduledPayouts[index] = scheduledPayout
        
        // Save updated schedule
        try await saveScheduledPayout(scheduledPayout)
        
        hapticService.trigger(.light)
        
        analyticsService.trackEvent("payout_schedule_cancelled", properties: [
            "scheduled_payout_id": scheduledPayoutId
        ])
        
        return scheduledPayout
    }
    
    // MARK: - Automated Payout Processing
    
    /// Process scheduled payouts
    func processScheduledPayouts() async throws -> [PayoutRecord] {
        
        let duePayouts = scheduledPayouts.filter { scheduledPayout in
            scheduledPayout.status == .active &&
            scheduledPayout.nextPayoutDate <= Date()
        }
        
        var processedPayouts: [PayoutRecord] = []
        
        for scheduledPayout in duePayouts {
            do {
                let payoutRecord = try await processScheduledPayout(scheduledPayout)
                processedPayouts.append(payoutRecord)
            } catch {
                errorHandlingService.handleError(error, context: "PayoutService.processScheduledPayouts")
            }
        }
        
        return processedPayouts
    }
    
    /// Process individual scheduled payout
    private func processScheduledPayout(_ scheduledPayout: ScheduledPayout) async throws -> PayoutRecord {
        
        // Get pending revenue for host
        let pendingRevenue = revenueService.getPendingRevenue(for: scheduledPayout.hostEmail)
        
        // Check if minimum amount is met
        guard pendingRevenue >= scheduledPayout.minimumAmount else {
            // Reschedule for next period
            try await reschedulePayout(scheduledPayout)
            throw PayoutError.insufficientAmount
        }
        
        // Create payout record
        let payoutRecord = PayoutRecord(
            id: UUID().uuidString,
            scheduledPayoutId: scheduledPayout.id,
            hostEmail: scheduledPayout.hostEmail,
            amount: pendingRevenue,
            currency: "USD",
            payoutMethod: scheduledPayout.payoutMethod,
            status: .processing,
            scheduledAt: Date(),
            processedAt: nil,
            estimatedDelivery: calculateEstimatedDelivery(scheduledPayout.payoutMethod),
            fees: calculatePayoutFees(amount: pendingRevenue, method: scheduledPayout.payoutMethod),
            metadata: [
                "schedule_type": scheduledPayout.schedule.type.rawValue,
                "automated": "true"
            ]
        )
        
        // Add to payout history
        payoutHistory.append(payoutRecord)
        
        // Update scheduled payout
        try await updateScheduledPayoutAfterProcessing(scheduledPayout, payoutRecord: payoutRecord)
        
        // Process the actual payout
        let processedPayout = try await processPayout(payoutRecord)
        
        analyticsService.trackEvent("scheduled_payout_processed", properties: [
            "scheduled_payout_id": scheduledPayout.id,
            "amount": pendingRevenue,
            "payout_method": scheduledPayout.payoutMethod.rawValue
        ])
        
        return processedPayout
    }
    
    /// Reschedule payout for next period
    private func reschedulePayout(_ scheduledPayout: ScheduledPayout) async throws {
        
        guard let index = scheduledPayouts.firstIndex(where: { $0.id == scheduledPayout.id }) else {
            return
        }
        
        var updatedPayout = scheduledPayout
        updatedPayout.nextPayoutDate = calculateNextPayoutDate(schedule: scheduledPayout.schedule)
        
        scheduledPayouts[index] = updatedPayout
        
        try await saveScheduledPayout(updatedPayout)
    }
    
    /// Update scheduled payout after processing
    private func updateScheduledPayoutAfterProcessing(
        _ scheduledPayout: ScheduledPayout,
        payoutRecord: PayoutRecord
    ) async throws {
        
        guard let index = scheduledPayouts.firstIndex(where: { $0.id == scheduledPayout.id }) else {
            return
        }
        
        var updatedPayout = scheduledPayout
        updatedPayout.lastPayoutDate = Date()
        updatedPayout.nextPayoutDate = calculateNextPayoutDate(schedule: scheduledPayout.schedule)
        updatedPayout.totalPayouts += 1
        updatedPayout.totalAmount += payoutRecord.amount
        
        scheduledPayouts[index] = updatedPayout
        
        try await saveScheduledPayout(updatedPayout)
    }
    
    // MARK: - Manual Payout Processing
    
    /// Process manual payout
    func processManualPayout(
        for hostEmail: String,
        amount: Double,
        payoutMethod: PayoutMethod
    ) async throws -> PayoutRecord {
        
        isLoading = true
        
        do {
            // Validate payout method
            try validatePayoutMethod(payoutMethod)
            
            // Check available balance
            let availableBalance = revenueService.getPendingRevenue(for: hostEmail)
            guard availableBalance >= amount else {
                throw PayoutError.insufficientBalance
            }
            
            // Create payout record
            let payoutRecord = PayoutRecord(
                id: UUID().uuidString,
                scheduledPayoutId: nil,
                hostEmail: hostEmail,
                amount: amount,
                currency: "USD",
                payoutMethod: payoutMethod,
                status: .processing,
                scheduledAt: Date(),
                processedAt: nil,
                estimatedDelivery: calculateEstimatedDelivery(payoutMethod),
                fees: calculatePayoutFees(amount: amount, method: payoutMethod),
                metadata: [
                    "manual": "true",
                    "payout_method": payoutMethod.rawValue
                ]
            )
            
            // Add to payout history
            payoutHistory.append(payoutRecord)
            
            // Process the payout
            let processedPayout = try await processPayout(payoutRecord)
            
            hapticService.trigger(.success)
            
            analyticsService.trackEvent("manual_payout_processed", properties: [
                "host_email": hostEmail,
                "amount": amount,
                "payout_method": payoutMethod.rawValue
            ])
            
            return processedPayout
            
        } catch {
            errorHandlingService.handleError(error, context: "PayoutService.processManualPayout")
            throw error
        } finally {
            isLoading = false
        }
    }
    
    // MARK: - Payout Management
    
    /// Get payout by ID
    func getPayout(by id: String) -> PayoutRecord? {
        return payoutHistory.first { $0.id == id }
    }
    
    /// Get payouts for host
    func getPayouts(for hostEmail: String) -> [PayoutRecord] {
        return payoutHistory.filter { $0.hostEmail == hostEmail }
    }
    
    /// Get scheduled payouts for host
    func getScheduledPayouts(for hostEmail: String) -> [ScheduledPayout] {
        return scheduledPayouts.filter { $0.hostEmail == hostEmail }
    }
    
    /// Get payout analytics
    func getPayoutAnalytics(timeRange: DateInterval) async throws -> PayoutAnalytics {
        
        let payoutsInRange = payoutHistory.filter { payout in
            timeRange.contains(payout.scheduledAt)
        }
        
        let analytics = PayoutAnalytics(
            timeRange: timeRange,
            totalPayouts: payoutsInRange.count,
            totalAmount: payoutsInRange.reduce(0) { $0 + $1.amount },
            averagePayoutAmount: calculateAveragePayoutAmount(payoutsInRange),
            successRate: calculatePayoutSuccessRate(payoutsInRange),
            payoutsByMethod: groupPayoutsByMethod(payoutsInRange),
            payoutsByMonth: groupPayoutsByMonth(payoutsInRange),
            topRecipients: getTopRecipients(payoutsInRange),
            generatedAt: Date()
        )
        
        analyticsService.trackEvent("payout_analytics_generated", properties: [
            "time_range_start": timeRange.start.timeIntervalSince1970,
            "time_range_end": timeRange.end.timeIntervalSince1970,
            "total_payouts": analytics.totalPayouts
        ])
        
        return analytics
    }
    
    // MARK: - Payout Settings
    
    /// Update payout settings
    func updatePayoutSettings(
        for hostEmail: String,
        settings: [PayoutSetting]
    ) async throws {
        
        // Remove existing settings
        payoutSettings.removeAll { $0.hostEmail == hostEmail }
        
        // Add new settings
        payoutSettings.append(contentsOf: settings)
        
        // Save settings
        try await savePayoutSettings(settings)
        
        hapticService.trigger(.light)
        
        analyticsService.trackEvent("payout_settings_updated", properties: [
            "host_email": hostEmail,
            "settings_count": settings.count
        ])
    }
    
    /// Get payout settings for host
    func getPayoutSettings(for hostEmail: String) -> [PayoutSetting] {
        return payoutSettings.filter { $0.hostEmail == hostEmail }
    }
    
    // MARK: - Private Methods
    
    private func setupPayoutSettings() {
        // Default payout settings
        payoutSettings = [
            PayoutSetting(
                id: "default_weekly",
                hostEmail: "default",
                scheduleType: .weekly,
                minimumAmount: 50.0,
                isEnabled: true,
                description: "Weekly payouts with $50 minimum"
            ),
            PayoutSetting(
                id: "default_monthly",
                hostEmail: "default",
                scheduleType: .monthly,
                minimumAmount: 100.0,
                isEnabled: true,
                description: "Monthly payouts with $100 minimum"
            )
        ]
    }
    
    private func startPayoutMonitoring() {
        // Check for scheduled payouts every hour
        payoutTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task {
                try? await self?.processScheduledPayouts()
            }
        }
    }
    
    private func validatePayoutMethod(_ payoutMethod: PayoutMethod) throws {
        // Validate payout method details
        switch payoutMethod.type {
        case .bankTransfer:
            guard !payoutMethod.accountDetails["account_number"].isNilOrEmpty else {
                throw PayoutError.invalidPayoutMethod
            }
        case .paypal:
            guard !payoutMethod.accountDetails["paypal_email"].isNilOrEmpty else {
                throw PayoutError.invalidPayoutMethod
            }
        case .stripe:
            guard !payoutMethod.accountDetails["stripe_account"].isNilOrEmpty else {
                throw PayoutError.invalidPayoutMethod
            }
        }
    }
    
    private func calculateNextPayoutDate(schedule: PayoutSchedule) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        switch schedule.type {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: now) ?? now
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: now) ?? now
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: now) ?? now
        case .quarterly:
            return calendar.date(byAdding: .month, value: 3, to: now) ?? now
        }
    }
    
    private func calculateEstimatedDelivery(_ payoutMethod: PayoutMethod) -> Date {
        let calendar = Calendar.current
        
        switch payoutMethod.type {
        case .bankTransfer:
            return calendar.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        case .paypal:
            return calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        case .stripe:
            return calendar.date(byAdding: .day, value: 2, to: Date()) ?? Date()
        }
    }
    
    private func calculatePayoutFees(amount: Double, method: PayoutMethod) -> Double {
        switch method.type {
        case .bankTransfer:
            return 0.25 // $0.25 flat fee
        case .paypal:
            return amount * 0.025 // 2.5%
        case .stripe:
            return 0.25 // $0.25 flat fee
        }
    }
    
    private func processPayout(_ payoutRecord: PayoutRecord) async throws -> PayoutRecord {
        // Simulate payout processing
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        var processedPayout = payoutRecord
        processedPayout.status = .completed
        processedPayout.processedAt = Date()
        
        // Update in payout history
        if let index = payoutHistory.firstIndex(where: { $0.id == payoutRecord.id }) {
            payoutHistory[index] = processedPayout
        }
        
        // Update statistics
        await updatePayoutStatistics()
        
        analyticsService.trackEvent("payout_completed", properties: [
            "payout_id": payoutRecord.id,
            "amount": payoutRecord.amount,
            "payout_method": payoutRecord.payoutMethod.rawValue
        ])
        
        return processedPayout
    }
    
    private func updatePayoutStatistics() async {
        let totalPayouts = payoutHistory.count
        let completedPayouts = payoutHistory.filter { $0.status == .completed }.count
        let totalAmount = payoutHistory.reduce(0) { $0 + $1.amount }
        
        payoutStats = PayoutStatistics(
            totalPayouts: totalPayouts,
            completedPayouts: completedPayouts,
            totalAmount: totalAmount,
            averagePayoutAmount: totalPayouts > 0 ? totalAmount / Double(totalPayouts) : 0,
            successRate: totalPayouts > 0 ? Double(completedPayouts) / Double(totalPayouts) : 0,
            lastUpdated: Date()
        )
    }
    
    private func calculateAveragePayoutAmount(_ payouts: [PayoutRecord]) -> Double {
        guard !payouts.isEmpty else { return 0 }
        
        let totalAmount = payouts.reduce(0) { $0 + $1.amount }
        return totalAmount / Double(payouts.count)
    }
    
    private func calculatePayoutSuccessRate(_ payouts: [PayoutRecord]) -> Double {
        guard !payouts.isEmpty else { return 0 }
        
        let successfulPayouts = payouts.filter { $0.status == .completed }.count
        return Double(successfulPayouts) / Double(payouts.count)
    }
    
    private func groupPayoutsByMethod(_ payouts: [PayoutRecord]) -> [String: Int] {
        var grouped: [String: Int] = [:]
        
        for payout in payouts {
            grouped[payout.payoutMethod.rawValue, default: 0] += 1
        }
        
        return grouped
    }
    
    private func groupPayoutsByMonth(_ payouts: [PayoutRecord]) -> [String: Double] {
        var grouped: [String: Double] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        
        for payout in payouts {
            let monthKey = formatter.string(from: payout.scheduledAt)
            grouped[monthKey, default: 0] += payout.amount
        }
        
        return grouped
    }
    
    private func getTopRecipients(_ payouts: [PayoutRecord]) -> [PayoutRecipient] {
        var recipientAmounts: [String: Double] = [:]
        
        for payout in payouts {
            recipientAmounts[payout.hostEmail, default: 0] += payout.amount
        }
        
        return recipientAmounts.map { PayoutRecipient(hostEmail: $0.key, totalAmount: $0.value) }
            .sorted { $0.totalAmount > $1.totalAmount }
            .prefix(10)
            .map { $0 }
    }
    
    // MARK: - Storage Methods (Mock Implementation)
    
    private func saveScheduledPayout(_ scheduledPayout: ScheduledPayout) async throws {
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // In a real implementation, this would save to secure storage
    }
    
    private func savePayoutSettings(_ settings: [PayoutSetting]) async throws {
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // In a real implementation, this would save to secure storage
    }
}

// MARK: - Payout Models

/// Scheduled payout
struct ScheduledPayout: Codable, Identifiable {
    let id: String
    let hostEmail: String
    var schedule: PayoutSchedule
    var minimumAmount: Double
    let payoutMethod: PayoutMethod
    var status: ScheduledPayoutStatus
    var nextPayoutDate: Date
    var lastPayoutDate: Date?
    var totalPayouts: Int
    var totalAmount: Double
    let createdAt: Date
    var cancelledAt: Date?
    let metadata: [String: String]
}

/// Payout schedule
struct PayoutSchedule: Codable {
    let type: PayoutScheduleType
    let dayOfWeek: Int? // 1 = Sunday, 7 = Saturday
    let dayOfMonth: Int? // 1-31
    let time: Date // Time of day for payout
    
    var description: String {
        switch type {
        case .daily:
            return "Daily at \(time, formatter: timeFormatter)"
        case .weekly:
            let dayName = dayOfWeek.map { Calendar.current.weekdaySymbols[$0 - 1] } ?? "Sunday"
            return "Weekly on \(dayName) at \(time, formatter: timeFormatter)"
        case .monthly:
            return "Monthly on day \(dayOfMonth ?? 1) at \(time, formatter: timeFormatter)"
        case .quarterly:
            return "Quarterly at \(time, formatter: timeFormatter)"
        }
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
}

enum PayoutScheduleType: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case quarterly = "quarterly"
    
    var displayName: String {
        switch self {
        case .daily:
            return "Daily"
        case .weekly:
            return "Weekly"
        case .monthly:
            return "Monthly"
        case .quarterly:
            return "Quarterly"
        }
    }
}

enum ScheduledPayoutStatus: String, Codable {
    case active = "active"
    case paused = "paused"
    case cancelled = "cancelled"
}

/// Payout record
struct PayoutRecord: Codable, Identifiable {
    let id: String
    let scheduledPayoutId: String?
    let hostEmail: String
    let amount: Double
    let currency: String
    let payoutMethod: PayoutMethod
    var status: PayoutRecordStatus
    let scheduledAt: Date
    var processedAt: Date?
    let estimatedDelivery: Date
    let fees: Double
    let metadata: [String: String]
    
    var netAmount: Double {
        return amount - fees
    }
}

enum PayoutRecordStatus: String, Codable {
    case scheduled = "scheduled"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
}

/// Payout setting
struct PayoutSetting: Codable, Identifiable {
    let id: String
    let hostEmail: String
    let scheduleType: PayoutScheduleType
    let minimumAmount: Double
    var isEnabled: Bool
    let description: String
}

/// Payout analytics
struct PayoutAnalytics: Codable {
    let timeRange: DateInterval
    let totalPayouts: Int
    let totalAmount: Double
    let averagePayoutAmount: Double
    let successRate: Double
    let payoutsByMethod: [String: Int]
    let payoutsByMonth: [String: Double]
    let topRecipients: [PayoutRecipient]
    let generatedAt: Date
}

/// Payout recipient
struct PayoutRecipient: Codable {
    let hostEmail: String
    let totalAmount: Double
}

/// Payout statistics
struct PayoutStatistics: Codable {
    let totalPayouts: Int
    let completedPayouts: Int
    let totalAmount: Double
    let averagePayoutAmount: Double
    let successRate: Double
    let lastUpdated: Date
}

/// Payout errors
enum PayoutError: Error, LocalizedError {
    case scheduledPayoutNotFound
    case insufficientAmount
    case insufficientBalance
    case invalidPayoutMethod
    case payoutProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .scheduledPayoutNotFound:
            return "Scheduled payout not found"
        case .insufficientAmount:
            return "Insufficient amount for payout"
        case .insufficientBalance:
            return "Insufficient balance for payout"
        case .invalidPayoutMethod:
            return "Invalid payout method"
        case .payoutProcessingFailed:
            return "Payout processing failed"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .scheduledPayoutNotFound:
            return "Please check the scheduled payout ID"
        case .insufficientAmount:
            return "Please wait for more revenue to accumulate"
        case .insufficientBalance:
            return "Please reduce the payout amount"
        case .invalidPayoutMethod:
            return "Please update your payout method"
        case .payoutProcessingFailed:
            return "Please try again or contact support"
        }
    }
}

// MARK: - Extensions

extension PayoutService {
    /// Create a mock instance for testing
    static func mock() -> PayoutService {
        PayoutService(
            analyticsService: .shared,
            errorHandlingService: .shared,
            revenueService: .shared,
            hapticService: .shared
        )
    }
}

extension String {
    var isNilOrEmpty: Bool {
        return self.isEmpty
    }
} 