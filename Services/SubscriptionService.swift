import Foundation
import Combine

/// Service for managing subscriptions and recurring payments
@MainActor
class SubscriptionService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var activeSubscriptions: [Subscription] = []
    @Published var subscriptionPlans: [SubscriptionPlan] = []
    @Published var isLoading = false
    @Published var subscriptionStats: SubscriptionStatistics = SubscriptionStatistics()
    
    // MARK: - Private Properties
    
    private let analyticsService: AnalyticsService
    private let errorHandlingService: ErrorHandlingService
    private let paymentService: PaymentMethodService
    private let hapticService: HapticService
    
    private var cancellables = Set<AnyCancellable>()
    private var subscriptionTimer: Timer?
    
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
        
        setupSubscriptionPlans()
        startSubscriptionMonitoring()
    }
    
    // MARK: - Subscription Management
    
    /// Create a new subscription
    func createSubscription(
        planId: String,
        customerEmail: String,
        paymentMethodId: String,
        startDate: Date = Date()
    ) async throws -> Subscription {
        
        isLoading = true
        
        do {
            // Validate plan
            guard let plan = subscriptionPlans.first(where: { $0.id == planId }) else {
                throw SubscriptionError.planNotFound
            }
            
            // Validate payment method
            guard let paymentMethod = paymentService.getPaymentMethod(by: paymentMethodId) else {
                throw SubscriptionError.paymentMethodNotFound
            }
            
            // Create subscription
            let subscription = Subscription(
                id: UUID().uuidString,
                planId: planId,
                customerEmail: customerEmail,
                paymentMethodId: paymentMethodId,
                status: .active,
                startDate: startDate,
                nextBillingDate: calculateNextBillingDate(startDate: startDate, interval: plan.billingInterval),
                endDate: nil,
                amount: plan.price,
                currency: plan.currency,
                billingInterval: plan.billingInterval,
                totalBilled: plan.price,
                billingCycles: 1,
                metadata: [
                    "plan_name": plan.name,
                    "payment_method_type": paymentMethod.type.rawValue
                ]
            )
            
            // Process initial payment
            let transaction = try await processSubscriptionPayment(subscription)
            
            // Update subscription with transaction
            var updatedSubscription = subscription
            updatedSubscription.lastTransactionId = transaction.transactionId
            
            // Add to active subscriptions
            activeSubscriptions.append(updatedSubscription)
            
            // Save subscription
            try await saveSubscription(updatedSubscription)
            
            // Update statistics
            await updateSubscriptionStatistics()
            
            hapticService.trigger(.success)
            
            analyticsService.trackEvent("subscription_created", properties: [
                "subscription_id": updatedSubscription.id,
                "plan_id": planId,
                "amount": plan.price,
                "billing_interval": plan.billingInterval.rawValue
            ])
            
            return updatedSubscription
            
        } catch {
            errorHandlingService.handleError(error, context: "SubscriptionService.createSubscription")
            throw error
        } finally {
            isLoading = false
        }
    }
    
    /// Cancel subscription
    func cancelSubscription(_ subscriptionId: String, reason: String? = nil) async throws -> Subscription {
        
        guard let index = activeSubscriptions.firstIndex(where: { $0.id == subscriptionId }) else {
            throw SubscriptionError.subscriptionNotFound
        }
        
        var subscription = activeSubscriptions[index]
        
        // Update subscription status
        subscription.status = .cancelled
        subscription.endDate = Date()
        subscription.cancellationReason = reason
        
        // Update in array
        activeSubscriptions[index] = subscription
        
        // Save to storage
        try await saveSubscription(subscription)
        
        // Update statistics
        await updateSubscriptionStatistics()
        
        hapticService.trigger(.light)
        
        analyticsService.trackEvent("subscription_cancelled", properties: [
            "subscription_id": subscriptionId,
            "reason": reason ?? "user_requested"
        ])
        
        return subscription
    }
    
    /// Pause subscription
    func pauseSubscription(_ subscriptionId: String, reason: String? = nil) async throws -> Subscription {
        
        guard let index = activeSubscriptions.firstIndex(where: { $0.id == subscriptionId }) else {
            throw SubscriptionError.subscriptionNotFound
        }
        
        var subscription = activeSubscriptions[index]
        
        // Update subscription status
        subscription.status = .paused
        subscription.pauseReason = reason
        subscription.pausedAt = Date()
        
        // Update in array
        activeSubscriptions[index] = subscription
        
        // Save to storage
        try await saveSubscription(subscription)
        
        hapticService.trigger(.light)
        
        analyticsService.trackEvent("subscription_paused", properties: [
            "subscription_id": subscriptionId,
            "reason": reason ?? "user_requested"
        ])
        
        return subscription
    }
    
    /// Resume subscription
    func resumeSubscription(_ subscriptionId: String) async throws -> Subscription {
        
        guard let index = activeSubscriptions.firstIndex(where: { $0.id == subscriptionId }) else {
            throw SubscriptionError.subscriptionNotFound
        }
        
        var subscription = activeSubscriptions[index]
        
        // Update subscription status
        subscription.status = .active
        subscription.pauseReason = nil
        subscription.pausedAt = nil
        
        // Recalculate next billing date
        subscription.nextBillingDate = calculateNextBillingDate(
            startDate: subscription.startDate,
            interval: subscription.billingInterval,
            cycles: subscription.billingCycles
        )
        
        // Update in array
        activeSubscriptions[index] = subscription
        
        // Save to storage
        try await saveSubscription(subscription)
        
        hapticService.trigger(.success)
        
        analyticsService.trackEvent("subscription_resumed", properties: [
            "subscription_id": subscriptionId
        ])
        
        return subscription
    }
    
    /// Update subscription payment method
    func updateSubscriptionPaymentMethod(
        _ subscriptionId: String,
        newPaymentMethodId: String
    ) async throws -> Subscription {
        
        guard let index = activeSubscriptions.firstIndex(where: { $0.id == subscriptionId }) else {
            throw SubscriptionError.subscriptionNotFound
        }
        
        // Validate new payment method
        guard let paymentMethod = paymentService.getPaymentMethod(by: newPaymentMethodId) else {
            throw SubscriptionError.paymentMethodNotFound
        }
        
        var subscription = activeSubscriptions[index]
        
        // Update payment method
        subscription.paymentMethodId = newPaymentMethodId
        subscription.metadata["payment_method_type"] = paymentMethod.type.rawValue
        
        // Update in array
        activeSubscriptions[index] = subscription
        
        // Save to storage
        try await saveSubscription(subscription)
        
        hapticService.trigger(.light)
        
        analyticsService.trackEvent("subscription_payment_method_updated", properties: [
            "subscription_id": subscriptionId,
            "new_payment_method_type": paymentMethod.type.rawValue
        ])
        
        return subscription
    }
    
    /// Process subscription billing
    func processSubscriptionBilling() async {
        let dueSubscriptions = activeSubscriptions.filter { subscription in
            subscription.status == .active &&
            subscription.nextBillingDate <= Date()
        }
        
        for subscription in dueSubscriptions {
            do {
                try await processBillingCycle(subscription)
            } catch {
                errorHandlingService.handleError(error, context: "SubscriptionService.processSubscriptionBilling")
            }
        }
    }
    
    /// Get subscription by ID
    func getSubscription(by id: String) -> Subscription? {
        return activeSubscriptions.first { $0.id == id }
    }
    
    /// Get subscriptions for customer
    func getSubscriptions(for customerEmail: String) -> [Subscription] {
        return activeSubscriptions.filter { $0.customerEmail == customerEmail }
    }
    
    /// Get subscription analytics
    func getSubscriptionAnalytics(timeRange: DateInterval) async throws -> SubscriptionAnalytics {
        
        let subscriptionsInRange = activeSubscriptions.filter { subscription in
            timeRange.contains(subscription.startDate)
        }
        
        let analytics = SubscriptionAnalytics(
            timeRange: timeRange,
            totalSubscriptions: subscriptionsInRange.count,
            activeSubscriptions: subscriptionsInRange.filter { $0.status == .active }.count,
            cancelledSubscriptions: subscriptionsInRange.filter { $0.status == .cancelled }.count,
            pausedSubscriptions: subscriptionsInRange.filter { $0.status == .paused }.count,
            totalRevenue: subscriptionsInRange.reduce(0) { $0 + $1.totalBilled },
            averageSubscriptionValue: calculateAverageSubscriptionValue(subscriptionsInRange),
            churnRate: calculateChurnRate(subscriptionsInRange),
            retentionRate: calculateRetentionRate(subscriptionsInRange),
            subscriptionsByPlan: groupSubscriptionsByPlan(subscriptionsInRange),
            generatedAt: Date()
        )
        
        analyticsService.trackEvent("subscription_analytics_generated", properties: [
            "time_range_start": timeRange.start.timeIntervalSince1970,
            "time_range_end": timeRange.end.timeIntervalSince1970,
            "total_subscriptions": analytics.totalSubscriptions
        ])
        
        return analytics
    }
    
    // MARK: - Private Methods
    
    private func setupSubscriptionPlans() {
        subscriptionPlans = [
            SubscriptionPlan(
                id: "basic_monthly",
                name: "Basic Monthly",
                description: "Access to basic features",
                price: 9.99,
                currency: "USD",
                billingInterval: .monthly,
                features: ["Event Creation", "Basic Analytics", "Email Support"],
                isPopular: false
            ),
            SubscriptionPlan(
                id: "pro_monthly",
                name: "Pro Monthly",
                description: "Professional features for hosts",
                price: 19.99,
                currency: "USD",
                billingInterval: .monthly,
                features: ["Event Creation", "Advanced Analytics", "Priority Support", "Custom Branding"],
                isPopular: true
            ),
            SubscriptionPlan(
                id: "pro_yearly",
                name: "Pro Yearly",
                description: "Professional features with annual discount",
                price: 199.99,
                currency: "USD",
                billingInterval: .yearly,
                features: ["Event Creation", "Advanced Analytics", "Priority Support", "Custom Branding"],
                isPopular: false
            ),
            SubscriptionPlan(
                id: "enterprise",
                name: "Enterprise",
                description: "Enterprise features for large organizations",
                price: 99.99,
                currency: "USD",
                billingInterval: .monthly,
                features: ["Event Creation", "Advanced Analytics", "Priority Support", "Custom Branding", "API Access", "Dedicated Manager"],
                isPopular: false
            )
        ]
    }
    
    private func startSubscriptionMonitoring() {
        // Check for due subscriptions every hour
        subscriptionTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task {
                await self?.processSubscriptionBilling()
            }
        }
    }
    
    private func calculateNextBillingDate(
        startDate: Date,
        interval: BillingInterval,
        cycles: Int = 1
    ) -> Date {
        let calendar = Calendar.current
        
        switch interval {
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: cycles, to: startDate) ?? startDate
        case .monthly:
            return calendar.date(byAdding: .month, value: cycles, to: startDate) ?? startDate
        case .yearly:
            return calendar.date(byAdding: .year, value: cycles, to: startDate) ?? startDate
        }
    }
    
    private func processSubscriptionPayment(_ subscription: Subscription) async throws -> PaymentTransaction {
        
        // Get payment method
        guard let paymentMethod = paymentService.getPaymentMethod(by: subscription.paymentMethodId) else {
            throw SubscriptionError.paymentMethodNotFound
        }
        
        // Create payment transaction
        let transaction = PaymentTransaction(
            transactionId: UUID().uuidString,
            amount: subscription.amount,
            currency: subscription.currency,
            paymentMethod: paymentMethod.type,
            status: .processing,
            timestamp: Date(),
            customerEmail: subscription.customerEmail,
            customerName: nil,
            location: nil,
            country: "US",
            metadata: [
                "subscription_id": subscription.id,
                "billing_cycle": String(subscription.billingCycles),
                "payment_method_type": paymentMethod.type.rawValue
            ]
        )
        
        // Process payment
        let processedTransaction = try await processPaymentTransaction(transaction)
        
        return processedTransaction
    }
    
    private func processBillingCycle(_ subscription: Subscription) async throws {
        
        // Process payment
        let transaction = try await processSubscriptionPayment(subscription)
        
        // Update subscription
        var updatedSubscription = subscription
        updatedSubscription.billingCycles += 1
        updatedSubscription.totalBilled += subscription.amount
        updatedSubscription.nextBillingDate = calculateNextBillingDate(
            startDate: subscription.startDate,
            interval: subscription.billingInterval,
            cycles: updatedSubscription.billingCycles
        )
        updatedSubscription.lastTransactionId = transaction.transactionId
        
        // Update in array
        if let index = activeSubscriptions.firstIndex(where: { $0.id == subscription.id }) {
            activeSubscriptions[index] = updatedSubscription
        }
        
        // Save to storage
        try await saveSubscription(updatedSubscription)
        
        analyticsService.trackEvent("subscription_billing_processed", properties: [
            "subscription_id": subscription.id,
            "billing_cycle": updatedSubscription.billingCycles,
            "amount": subscription.amount,
            "transaction_id": transaction.transactionId
        ])
    }
    
    private func updateSubscriptionStatistics() async {
        let totalSubscriptions = activeSubscriptions.count
        let activeSubscriptions = activeSubscriptions.filter { $0.status == .active }.count
        let totalRevenue = activeSubscriptions.reduce(0) { $0 + $1.totalBilled }
        
        subscriptionStats = SubscriptionStatistics(
            totalSubscriptions: totalSubscriptions,
            activeSubscriptions: activeSubscriptions,
            cancelledSubscriptions: activeSubscriptions.filter { $0.status == .cancelled }.count,
            pausedSubscriptions: activeSubscriptions.filter { $0.status == .paused }.count,
            totalRevenue: totalRevenue,
            averageSubscriptionValue: totalSubscriptions > 0 ? totalRevenue / Double(totalSubscriptions) : 0,
            lastUpdated: Date()
        )
    }
    
    private func calculateAverageSubscriptionValue(_ subscriptions: [Subscription]) -> Double {
        guard !subscriptions.isEmpty else { return 0 }
        let totalValue = subscriptions.reduce(0) { $0 + $1.totalBilled }
        return totalValue / Double(subscriptions.count)
    }
    
    private func calculateChurnRate(_ subscriptions: [Subscription]) -> Double {
        let cancelled = subscriptions.filter { $0.status == .cancelled }.count
        guard !subscriptions.isEmpty else { return 0 }
        return Double(cancelled) / Double(subscriptions.count)
    }
    
    private func calculateRetentionRate(_ subscriptions: [Subscription]) -> Double {
        let active = subscriptions.filter { $0.status == .active }.count
        guard !subscriptions.isEmpty else { return 0 }
        return Double(active) / Double(subscriptions.count)
    }
    
    private func groupSubscriptionsByPlan(_ subscriptions: [Subscription]) -> [String: Int] {
        var grouped: [String: Int] = [:]
        
        for subscription in subscriptions {
            grouped[subscription.planId, default: 0] += 1
        }
        
        return grouped
    }
    
    // MARK: - Storage Methods (Mock Implementation)
    
    private func saveSubscription(_ subscription: Subscription) async throws {
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

// MARK: - Subscription Models

/// Subscription model
struct Subscription: Codable, Identifiable {
    let id: String
    let planId: String
    let customerEmail: String
    var paymentMethodId: String
    var status: SubscriptionStatus
    let startDate: Date
    var nextBillingDate: Date
    var endDate: Date?
    let amount: Double
    let currency: String
    let billingInterval: BillingInterval
    var totalBilled: Double
    var billingCycles: Int
    var lastTransactionId: String?
    var cancellationReason: String?
    var pauseReason: String?
    var pausedAt: Date?
    var metadata: [String: String]
}

enum SubscriptionStatus: String, Codable {
    case active = "active"
    case cancelled = "cancelled"
    case paused = "paused"
    case expired = "expired"
}

enum BillingInterval: String, Codable {
    case weekly = "weekly"
    case monthly = "monthly"
    case yearly = "yearly"
}

/// Subscription plan
struct SubscriptionPlan: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let currency: String
    let billingInterval: BillingInterval
    let features: [String]
    let isPopular: Bool
    
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: price)) ?? "$\(price)"
    }
    
    var intervalDisplay: String {
        switch billingInterval {
        case .weekly:
            return "week"
        case .monthly:
            return "month"
        case .yearly:
            return "year"
        }
    }
}

/// Subscription statistics
struct SubscriptionStatistics: Codable {
    let totalSubscriptions: Int
    let activeSubscriptions: Int
    let cancelledSubscriptions: Int
    let pausedSubscriptions: Int
    let totalRevenue: Double
    let averageSubscriptionValue: Double
    let lastUpdated: Date
}

/// Subscription analytics
struct SubscriptionAnalytics: Codable {
    let timeRange: DateInterval
    let totalSubscriptions: Int
    let activeSubscriptions: Int
    let cancelledSubscriptions: Int
    let pausedSubscriptions: Int
    let totalRevenue: Double
    let averageSubscriptionValue: Double
    let churnRate: Double
    let retentionRate: Double
    let subscriptionsByPlan: [String: Int]
    let generatedAt: Date
}

/// Subscription errors
enum SubscriptionError: Error, LocalizedError {
    case subscriptionNotFound
    case planNotFound
    case paymentMethodNotFound
    case invalidSubscriptionData
    case billingFailed
    case subscriptionAlreadyCancelled
    
    var errorDescription: String? {
        switch self {
        case .subscriptionNotFound:
            return "Subscription not found"
        case .planNotFound:
            return "Subscription plan not found"
        case .paymentMethodNotFound:
            return "Payment method not found"
        case .invalidSubscriptionData:
            return "Invalid subscription data"
        case .billingFailed:
            return "Subscription billing failed"
        case .subscriptionAlreadyCancelled:
            return "Subscription is already cancelled"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .subscriptionNotFound:
            return "Please check the subscription ID"
        case .planNotFound:
            return "Please select a valid subscription plan"
        case .paymentMethodNotFound:
            return "Please add a valid payment method"
        case .invalidSubscriptionData:
            return "Please check your subscription information"
        case .billingFailed:
            return "Please try again or contact support"
        case .subscriptionAlreadyCancelled:
            return "This subscription has already been cancelled"
        }
    }
}

// MARK: - Extensions

extension SubscriptionService {
    /// Create a mock instance for testing
    static func mock() -> SubscriptionService {
        SubscriptionService(
            analyticsService: .shared,
            errorHandlingService: .shared,
            paymentService: .shared,
            hapticService: .shared
        )
    }
} 