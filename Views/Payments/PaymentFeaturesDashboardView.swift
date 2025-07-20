import SwiftUI

/// Dashboard view for payment features management
struct PaymentFeaturesDashboardView: View {
    
    // MARK: - Environment
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appStateManager: AppStateManager
    
    // MARK: - View Models
    
    @StateObject private var paymentMethodService = PaymentMethodService()
    @StateObject private var subscriptionService = SubscriptionService()
    @StateObject private var splittingService = PaymentSplittingService()
    
    // MARK: - State
    
    @State private var selectedTab = 0
    @State private var showingAddPaymentMethod = false
    @State private var showingCreateSubscription = false
    @State private var showingCreateGroupPayment = false
    @State private var isRefreshing = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundView
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Tab Selector
                    tabSelectorSection
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        // Payment Methods Tab
                        paymentMethodsTabView
                            .tag(0)
                        
                        // Subscriptions Tab
                        subscriptionsTabView
                            .tag(1)
                        
                        // Group Payments Tab
                        groupPaymentsTabView
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                refreshData()
            }
        }
    }
    
    // MARK: - Background View
    
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black,
                Color(red: 0.1, green: 0.0, blue: 0.3),
                Color(red: 0.3, green: 0.0, blue: 0.4)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Navigation bar
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text("Payment Features")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button(action: {
                    refreshData()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                        .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                        .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Features Overview
            featuresOverview
        }
    }
    
    // MARK: - Features Overview
    
    private var featuresOverview: some View {
        HStack(spacing: 16) {
            // Payment Methods
            FeatureStatusCard(
                title: "Payment Methods",
                value: "\(paymentMethodService.userPaymentMethods.count)",
                subtitle: "Saved Methods",
                icon: "creditcard",
                color: .blue
            )
            
            // Subscriptions
            FeatureStatusCard(
                title: "Subscriptions",
                value: "\(subscriptionService.activeSubscriptions.count)",
                subtitle: "Active Plans",
                icon: "repeat",
                color: .green
            )
            
            // Group Payments
            FeatureStatusCard(
                title: "Group Payments",
                value: "\(splittingService.activeGroupPayments.count)",
                subtitle: "Active Groups",
                icon: "person.3",
                color: .orange
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Tab Selector
    
    private var tabSelectorSection: some View {
        HStack(spacing: 0) {
            ForEach(["Methods", "Subscriptions", "Group Payments"], id: \.self) { tab in
                Button(action: {
                    withAnimation {
                        selectedTab = ["Methods", "Subscriptions", "Group Payments"].firstIndex(of: tab) ?? 0
                    }
                }) {
                    Text(tab)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTab == ["Methods", "Subscriptions", "Group Payments"].firstIndex(of: tab) ? .white : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            selectedTab == ["Methods", "Subscriptions", "Group Payments"].firstIndex(of: tab) ?
                            Color.white.opacity(0.2) : Color.clear
                        )
                }
            }
        }
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    // MARK: - Payment Methods Tab
    
    private var paymentMethodsTabView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Available Payment Methods
                availablePaymentMethodsSection
                
                // Saved Payment Methods
                savedPaymentMethodsSection
                
                // Payment Method Status
                paymentMethodStatusSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }
    
    private var availablePaymentMethodsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Available Payment Methods")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                PaymentMethodCard(
                    type: .applePay,
                    isAvailable: paymentMethodService.isApplePayAvailable,
                    title: "Apple Pay",
                    description: "Quick and secure"
                )
                
                PaymentMethodCard(
                    type: .googlePay,
                    isAvailable: paymentMethodService.isGooglePayAvailable,
                    title: "Google Pay",
                    description: "Fast checkout"
                )
                
                PaymentMethodCard(
                    type: .creditCard,
                    isAvailable: true,
                    title: "Credit Cards",
                    description: "Visa, Mastercard, Amex"
                )
                
                PaymentMethodCard(
                    type: .paypal,
                    isAvailable: true,
                    title: "PayPal",
                    description: "Trusted payment"
                )
            }
        }
    }
    
    private var savedPaymentMethodsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Saved Payment Methods")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Add New") {
                    showingAddPaymentMethod = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if paymentMethodService.userPaymentMethods.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "creditcard.badge.plus")
                        .font(.title)
                        .foregroundColor(.blue)
                    
                    Text("No Payment Methods")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("Add a payment method to get started")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(paymentMethodService.userPaymentMethods) { method in
                        SavedPaymentMethodRow(method: method)
                    }
                }
            }
        }
    }
    
    private var paymentMethodStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Method Status")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                StatusRow(
                    title: "Apple Pay",
                    status: paymentMethodService.isApplePayAvailable ? .available : .unavailable,
                    description: paymentMethodService.isApplePayAvailable ? "Ready to use" : "Not available"
                )
                
                StatusRow(
                    title: "Google Pay",
                    status: paymentMethodService.isGooglePayAvailable ? .available : .unavailable,
                    description: paymentMethodService.isGooglePayAvailable ? "Ready to use" : "Not available"
                )
                
                StatusRow(
                    title: "Credit Cards",
                    status: .available,
                    description: "All major cards supported"
                )
                
                StatusRow(
                    title: "PayPal",
                    status: .available,
                    description: "PayPal account required"
                )
            }
        }
    }
    
    // MARK: - Subscriptions Tab
    
    private var subscriptionsTabView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Subscription Plans
                subscriptionPlansSection
                
                // Active Subscriptions
                activeSubscriptionsSection
                
                // Subscription Statistics
                subscriptionStatisticsSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }
    
    private var subscriptionPlansSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Subscription Plans")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    showingCreateSubscription = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(subscriptionService.subscriptionPlans) { plan in
                        SubscriptionPlanCard(plan: plan)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var activeSubscriptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Active Subscriptions")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if subscriptionService.activeSubscriptions.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "repeat.circle")
                        .font(.title)
                        .foregroundColor(.green)
                    
                    Text("No Active Subscriptions")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("Subscribe to a plan to unlock premium features")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(subscriptionService.activeSubscriptions) { subscription in
                        ActiveSubscriptionRow(subscription: subscription)
                    }
                }
            }
        }
    }
    
    private var subscriptionStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Subscription Statistics")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Total Revenue",
                    value: "$\(subscriptionService.subscriptionStats.totalRevenue, specifier: "%.2f")",
                    color: .green
                )
                
                StatCard(
                    title: "Success Rate",
                    value: "\(Int(subscriptionService.subscriptionStats.winRate * 100))%",
                    color: .blue
                )
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Active Subscriptions")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(subscriptionService.subscriptionStats.activeSubscriptions)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Avg Value")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("$\(subscriptionService.subscriptionStats.averageSubscriptionValue, specifier: "%.2f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Group Payments Tab
    
    private var groupPaymentsTabView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Group Payment Options
                groupPaymentOptionsSection
                
                // Active Group Payments
                activeGroupPaymentsSection
                
                // Group Payment Statistics
                groupPaymentStatisticsSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }
    
    private var groupPaymentOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Group Payment Options")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Create Group") {
                    showingCreateGroupPayment = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                GroupPaymentOptionCard(
                    title: "Split Equally",
                    description: "Divide cost evenly",
                    icon: "equal.circle",
                    color: .blue
                )
                
                GroupPaymentOptionCard(
                    title: "Split by Percentage",
                    description: "Custom percentages",
                    icon: "percent",
                    color: .green
                )
                
                GroupPaymentOptionCard(
                    title: "Custom Amounts",
                    description: "Set specific amounts",
                    icon: "dollarsign.circle",
                    color: .orange
                )
                
                GroupPaymentOptionCard(
                    title: "Group Events",
                    description: "Event ticket splitting",
                    icon: "ticket",
                    color: .purple
                )
            }
        }
    }
    
    private var activeGroupPaymentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Active Group Payments")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if splittingService.activeGroupPayments.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.3.sequence")
                        .font(.title)
                        .foregroundColor(.orange)
                    
                    Text("No Active Group Payments")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("Create a group payment to split costs with friends")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(splittingService.activeGroupPayments) { groupPayment in
                        ActiveGroupPaymentRow(groupPayment: groupPayment)
                    }
                }
            }
        }
    }
    
    private var groupPaymentStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Group Payment Statistics")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Total Amount",
                    value: "$\(splittingService.splittingStats.totalAmount, specifier: "%.2f")",
                    color: .orange
                )
                
                StatCard(
                    title: "Success Rate",
                    value: "\(Int(splittingService.splittingStats.successRate * 100))%",
                    color: .green
                )
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Completed Groups")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(splittingService.splittingStats.completedGroupPayments)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Avg Group Size")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(splittingService.splittingStats.averageGroupSize, specifier: "%.1f")")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Methods
    
    private func refreshData() {
        isRefreshing = true
        
        Task {
            do {
                try await paymentMethodService.loadUserPaymentMethods()
            } catch {
                // Handle error
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isRefreshing = false
            }
        }
    }
}

// MARK: - Supporting Views

/// Feature status card
struct FeatureStatusCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

/// Payment method card
struct PaymentMethodCard: View {
    let type: PaymentMethodType
    let isAvailable: Bool
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: paymentMethodIcon)
                    .font(.title3)
                    .foregroundColor(isAvailable ? .green : .gray)
                
                Spacer()
                
                if isAvailable {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
        .opacity(isAvailable ? 1.0 : 0.5)
    }
    
    private var paymentMethodIcon: String {
        switch type {
        case .applePay:
            return "applelogo"
        case .googlePay:
            return "g.circle"
        case .creditCard:
            return "creditcard"
        case .paypal:
            return "p.circle"
        case .bankTransfer:
            return "building.columns"
        case .invalid:
            return "questionmark.circle"
        }
    }
}

/// Saved payment method row
struct SavedPaymentMethodRow: View {
    let method: UserPaymentMethod
    
    var body: some View {
        HStack {
            Image(systemName: paymentMethodIcon)
                .font(.title3)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(paymentMethodTitle)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                if let last4 = method.last4 {
                    Text("•••• \(last4)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            Spacer()
            
            if method.isDefault {
                Text("Default")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(4)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var paymentMethodIcon: String {
        switch method.type {
        case .applePay:
            return "applelogo"
        case .googlePay:
            return "g.circle"
        case .creditCard:
            return "creditcard"
        case .paypal:
            return "p.circle"
        case .bankTransfer:
            return "building.columns"
        case .invalid:
            return "questionmark.circle"
        }
    }
    
    private var paymentMethodTitle: String {
        switch method.type {
        case .applePay:
            return "Apple Pay"
        case .googlePay:
            return "Google Pay"
        case .creditCard:
            return method.brand ?? "Credit Card"
        case .paypal:
            return "PayPal"
        case .bankTransfer:
            return "Bank Transfer"
        case .invalid:
            return "Invalid Method"
        }
    }
}

/// Status row
struct StatusRow: View {
    let title: String
    let status: AvailabilityStatus
    let description: String
    
    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch status {
        case .available:
            return .green
        case .unavailable:
            return .red
        case .warning:
            return .orange
        }
    }
}

enum AvailabilityStatus {
    case available
    case unavailable
    case warning
}

/// Subscription plan card
struct SubscriptionPlanCard: View {
    let plan: SubscriptionPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(plan.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                if plan.isPopular {
                    Text("Popular")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .cornerRadius(4)
                }
            }
            
            Text(plan.description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Text(plan.formattedPrice)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.green)
            
            Text("per \(plan.intervalDisplay)")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(plan.features.prefix(3), id: \.self) { feature in
                    HStack {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundColor(.green)
                        
                        Text(feature)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .frame(width: 280)
    }
}

/// Active subscription row
struct ActiveSubscriptionRow: View {
    let subscription: Subscription
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.metadata["plan_name"] ?? "Unknown Plan")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("$\(subscription.amount, specifier: "%.2f") per \(subscription.billingInterval.rawValue)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(subscription.status.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(4)
                
                Text(subscription.nextBillingDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch subscription.status {
        case .active:
            return .green
        case .cancelled:
            return .red
        case .paused:
            return .orange
        case .expired:
            return .gray
        }
    }
}

/// Group payment option card
struct GroupPaymentOptionCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text(description)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
}

/// Active group payment row
struct ActiveGroupPaymentRow: View {
    let groupPayment: GroupPayment
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Group Payment")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("$\(groupPayment.totalAmount, specifier: "%.2f") • \(groupPayment.participants.count) people")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(groupPayment.status.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(4)
                
                Text(groupPayment.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch groupPayment.status {
        case .pending:
            return .orange
        case .ready:
            return .blue
        case .processing:
            return .yellow
        case .completed:
            return .green
        case .failed:
            return .red
        case .partial:
            return .purple
        case .cancelled:
            return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    PaymentFeaturesDashboardView()
        .environmentObject(AppStateManager.shared)
} 