import Foundation
import Combine

/// Service for managing subscriptions
class SubscriptionService: ObservableObject {
    @Published var currentSubscription: Subscription?
    @Published var availablePlans: [SubscriptionPlan] = []
    @Published var activeSubscriptions: [Subscription] = []
    @Published var subscriptionStats: SubscriptionStats = SubscriptionStats(
        totalRevenue: 0.0,
        activeSubscriptions: 0,
        monthlyGrowth: 0.0,
        churnRate: 0.0
    )
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadAvailablePlans()
        loadCurrentSubscription()
        loadActiveSubscriptions()
        loadSubscriptionStats()
    }
    
    /// Load available subscription plans
    private func loadAvailablePlans() {
        availablePlans = [
            SubscriptionPlan(
                id: "basic",
                name: "Basic",
                description: "Essential features for event hosts",
                price: 9.99,
                currency: "USD",
                interval: "month",
                features: ["Basic analytics", "Standard support"],
                isPopular: false
            ),
            SubscriptionPlan(
                id: "pro",
                name: "Pro",
                description: "Advanced features for growing hosts",
                price: 24.99,
                currency: "USD",
                interval: "month",
                features: ["Advanced analytics", "Priority support", "Custom branding"],
                isPopular: true
            ),
            SubscriptionPlan(
                id: "enterprise",
                name: "Enterprise",
                description: "Full suite for large organizations",
                price: 99.99,
                currency: "USD",
                interval: "month",
                features: ["Enterprise analytics", "24/7 support", "Custom integrations"],
                isPopular: false
            )
        ]
    }
    
    /// Load current subscription
    private func loadCurrentSubscription() {
        // Mock data for now
        currentSubscription = nil
    }
    
    /// Load active subscriptions
    private func loadActiveSubscriptions() {
        // Mock data for now
        activeSubscriptions = []
    }
    
    /// Load subscription statistics
    private func loadSubscriptionStats() {
        subscriptionStats = SubscriptionStats(
            totalRevenue: 1250.0,
            activeSubscriptions: 0,
            monthlyGrowth: 15.5,
            churnRate: 2.1
        )
    }
    
    /// Subscribe to a plan
    func subscribe(to plan: SubscriptionPlan) async throws -> Subscription {
        // Simulate subscription process
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        let subscription = Subscription(
            id: UUID().uuidString,
            planId: plan.id,
            status: .active,
            startDate: Date(),
            endDate: Date().addingTimeInterval(30 * 24 * 60 * 60), // 30 days
            amount: plan.price,
            currency: plan.currency,
            metadata: ["plan_name": plan.name]
        )
        
        await MainActor.run {
            currentSubscription = subscription
            activeSubscriptions.append(subscription)
        }
        
        return subscription
    }
    
    /// Cancel subscription
    func cancelSubscription(_ subscription: Subscription) async throws {
        // Simulate cancellation
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        await MainActor.run {
            if let index = activeSubscriptions.firstIndex(where: { $0.id == subscription.id }) {
                activeSubscriptions[index].status = .cancelled
            }
            if currentSubscription?.id == subscription.id {
                currentSubscription?.status = .cancelled
            }
        }
    }
}

// MARK: - Supporting Types

struct SubscriptionStats {
    let totalRevenue: Double
    let activeSubscriptions: Int
    let monthlyGrowth: Double
    let churnRate: Double
}

enum SubscriptionStatus: String, Codable {
    case active = "active"
    case cancelled = "cancelled"
    case paused = "paused"
    case expired = "expired"
    case pending = "pending"
}

struct Subscription: Identifiable, Codable {
    let id: String
    let planId: String
    var status: SubscriptionStatus
    let startDate: Date
    let endDate: Date
    let amount: Double
    let currency: String
    let metadata: [String: String]
}

struct SubscriptionPlan: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let price: Double
    let currency: String
    let interval: String
    let features: [String]
    let isPopular: Bool
} 