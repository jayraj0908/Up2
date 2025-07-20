import SwiftUI

/// Dashboard view for financial management
struct FinancialManagementDashboardView: View {
    
    // MARK: - Environment
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appStateManager: AppStateManager
    
    // MARK: - View Models
    
    @StateObject private var revenueService = RevenueTrackingService()
    @StateObject private var taxService = TaxCalculationService()
    @StateObject private var payoutService = PayoutService()
    
    // MARK: - State
    
    @State private var selectedTab = 0
    @State private var showingRevenueReport = false
    @State private var showingTaxReport = false
    @State private var showingPayoutSchedule = false
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
                        // Revenue Tab
                        revenueTabView
                            .tag(0)
                        
                        // Tax Tab
                        taxTabView
                            .tag(1)
                        
                        // Payouts Tab
                        payoutsTabView
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
                
                Text("Financial Management")
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
            
            // Financial Overview
            financialOverview
        }
    }
    
    // MARK: - Financial Overview
    
    private var financialOverview: some View {
        HStack(spacing: 16) {
            // Revenue
            FinancialStatusCard(
                title: "Total Revenue",
                value: "$\(revenueService.revenueStats.totalRevenue, specifier: "%.2f")",
                subtitle: "All Time",
                icon: "dollarsign.circle",
                color: .green
            )
            
            // Tax
            FinancialStatusCard(
                title: "Total Tax",
                value: "$\(taxService.taxStats.totalTax, specifier: "%.2f")",
                subtitle: "Calculated",
                icon: "doc.text",
                color: .orange
            )
            
            // Payouts
            FinancialStatusCard(
                title: "Total Payouts",
                value: "$\(payoutService.payoutStats.totalAmount, specifier: "%.2f")",
                subtitle: "Processed",
                icon: "arrow.up.circle",
                color: .blue
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Tab Selector
    
    private var tabSelectorSection: some View {
        HStack(spacing: 0) {
            ForEach(["Revenue", "Tax", "Payouts"], id: \.self) { tab in
                Button(action: {
                    withAnimation {
                        selectedTab = ["Revenue", "Tax", "Payouts"].firstIndex(of: tab) ?? 0
                    }
                }) {
                    Text(tab)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTab == ["Revenue", "Tax", "Payouts"].firstIndex(of: tab) ? .white : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            selectedTab == ["Revenue", "Tax", "Payouts"].firstIndex(of: tab) ?
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
    
    // MARK: - Revenue Tab
    
    private var revenueTabView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Revenue Statistics
                revenueStatisticsSection
                
                // Commission Rates
                commissionRatesSection
                
                // Revenue Shares
                revenueSharesSection
                
                // Pending Payouts
                pendingPayoutsSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }
    
    private var revenueStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Revenue Statistics")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Generate Report") {
                    showingRevenueReport = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            HStack(spacing: 16) {
                RevenueStatCard(
                    title: "Total Revenue",
                    value: "$\(revenueService.revenueStats.totalRevenue, specifier: "%.2f")",
                    color: .green
                )
                
                RevenueStatCard(
                    title: "Pending Revenue",
                    value: "$\(revenueService.revenueStats.pendingRevenue, specifier: "%.2f")",
                    color: .orange
                )
            }
            
            HStack(spacing: 16) {
                RevenueStatCard(
                    title: "Paid Revenue",
                    value: "$\(revenueService.revenueStats.paidRevenue, specifier: "%.2f")",
                    color: .blue
                )
                
                RevenueStatCard(
                    title: "Total Payouts",
                    value: "\(revenueService.revenueStats.totalPayouts)",
                    color: .purple
                )
            }
        }
    }
    
    private var commissionRatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Commission Rates")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVStack(spacing: 12) {
                ForEach(revenueService.commissionRates) { rate in
                    CommissionRateRow(rate: rate)
                }
            }
        }
    }
    
    private var revenueSharesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Revenue Shares")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if revenueService.revenueShares.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.title)
                        .foregroundColor(.green)
                    
                    Text("No Revenue Shares")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("Revenue shares will appear here after transactions")
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
                    ForEach(revenueService.revenueShares.prefix(5)) { share in
                        RevenueShareRow(share: share)
                    }
                }
            }
        }
    }
    
    private var pendingPayoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pending Payouts")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if revenueService.activePayouts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.up.circle")
                        .font(.title)
                        .foregroundColor(.blue)
                    
                    Text("No Pending Payouts")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("Payouts will appear here when scheduled")
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
                    ForEach(revenueService.activePayouts.prefix(5)) { payout in
                        PendingPayoutRow(payout: payout)
                    }
                }
            }
        }
    }
    
    // MARK: - Tax Tab
    
    private var taxTabView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Tax Statistics
                taxStatisticsSection
                
                // Tax Rates
                taxRatesSection
                
                // Tax Reports
                taxReportsSection
                
                // Tax Compliance
                taxComplianceSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }
    
    private var taxStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tax Statistics")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Generate Report") {
                    showingTaxReport = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            HStack(spacing: 16) {
                TaxStatCard(
                    title: "Total Tax",
                    value: "$\(taxService.taxStats.totalTax, specifier: "%.2f")",
                    color: .orange
                )
                
                TaxStatCard(
                    title: "Total Revenue",
                    value: "$\(taxService.taxStats.totalRevenue, specifier: "%.2f")",
                    color: .green
                )
            }
            
            HStack(spacing: 16) {
                TaxStatCard(
                    title: "Avg Tax Rate",
                    value: "\(Int(taxService.taxStats.averageTaxRate * 100))%",
                    color: .red
                )
                
                TaxStatCard(
                    title: "Reports",
                    value: "\(taxService.taxStats.totalReports)",
                    color: .blue
                )
            }
        }
    }
    
    private var taxRatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tax Rates by Jurisdiction")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVStack(spacing: 12) {
                ForEach(taxService.taxRates) { rate in
                    TaxRateRow(rate: rate)
                }
            }
        }
    }
    
    private var taxReportsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tax Reports")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if taxService.taxReports.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text")
                        .font(.title)
                        .foregroundColor(.orange)
                    
                    Text("No Tax Reports")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("Tax reports will appear here when generated")
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
                    ForEach(taxService.taxReports.prefix(5)) { report in
                        TaxReportRow(report: report)
                    }
                }
            }
        }
    }
    
    private var taxComplianceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Tax Compliance")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                ComplianceStatusRow(
                    title: "Quarterly Reports",
                    status: .compliant,
                    description: "All quarterly reports submitted"
                )
                
                ComplianceStatusRow(
                    title: "Annual Reports",
                    status: .pending,
                    description: "Annual report due in 30 days"
                )
                
                ComplianceStatusRow(
                    title: "Tax Payments",
                    status: .compliant,
                    description: "All tax payments up to date"
                )
            }
        }
    }
    
    // MARK: - Payouts Tab
    
    private var payoutsTabView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Payout Statistics
                payoutStatisticsSection
                
                // Scheduled Payouts
                scheduledPayoutsSection
                
                // Payout History
                payoutHistorySection
                
                // Payout Settings
                payoutSettingsSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }
    
    private var payoutStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Payout Statistics")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Schedule Payout") {
                    showingPayoutSchedule = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            HStack(spacing: 16) {
                PayoutStatCard(
                    title: "Total Payouts",
                    value: "\(payoutService.payoutStats.totalPayouts)",
                    color: .blue
                )
                
                PayoutStatCard(
                    title: "Completed",
                    value: "\(payoutService.payoutStats.completedPayouts)",
                    color: .green
                )
            }
            
            HStack(spacing: 16) {
                PayoutStatCard(
                    title: "Total Amount",
                    value: "$\(payoutService.payoutStats.totalAmount, specifier: "%.2f")",
                    color: .purple
                )
                
                PayoutStatCard(
                    title: "Success Rate",
                    value: "\(Int(payoutService.payoutStats.successRate * 100))%",
                    color: .orange
                )
            }
        }
    }
    
    private var scheduledPayoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Scheduled Payouts")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if payoutService.scheduledPayouts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title)
                        .foregroundColor(.blue)
                    
                    Text("No Scheduled Payouts")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("Schedule automatic payouts to receive funds regularly")
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
                    ForEach(payoutService.scheduledPayouts.prefix(5)) { scheduledPayout in
                        ScheduledPayoutRow(scheduledPayout: scheduledPayout)
                    }
                }
            }
        }
    }
    
    private var payoutHistorySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payout History")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if payoutService.payoutHistory.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "arrow.up.circle")
                        .font(.title)
                        .foregroundColor(.blue)
                    
                    Text("No Payout History")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("Payout history will appear here after processing")
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
                    ForEach(payoutService.payoutHistory.prefix(5)) { payout in
                        PayoutHistoryRow(payout: payout)
                    }
                }
            }
        }
    }
    
    private var payoutSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payout Settings")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            LazyVStack(spacing: 12) {
                ForEach(payoutService.payoutSettings) { setting in
                    PayoutSettingRow(setting: setting)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func refreshData() {
        isRefreshing = true
        
        Task {
            // Refresh data from services
            await revenueService.updateRevenueStatistics()
            await taxService.updateTaxStatistics()
            await payoutService.updatePayoutStatistics()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                isRefreshing = false
            }
        }
    }
}

// MARK: - Supporting Views

/// Financial status card
struct FinancialStatusCard: View {
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

/// Revenue stat card
struct RevenueStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

/// Commission rate row
struct CommissionRateRow: View {
    let rate: CommissionRate
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(rate.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("\(rate.eventType) • \(rate.percentage)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text(rate.percentage)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.green.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

/// Revenue share row
struct RevenueShareRow: View {
    let share: RevenueShare
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(share.hostEmail)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("$\(share.amount, specifier: "%.2f") • \(share.status.rawValue.capitalized)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text("$\(share.amount, specifier: "%.2f")")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.green)
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

/// Pending payout row
struct PendingPayoutRow: View {
    let payout: Payout
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(payout.payoutMethod.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("$\(payout.amount, specifier: "%.2f") • \(payout.status.rawValue.capitalized)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text("$\(payout.amount, specifier: "%.2f")")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

/// Tax stat card
struct TaxStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

/// Tax rate row
struct TaxRateRow: View {
    let rate: TaxRate
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(rate.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("\(rate.jurisdiction.country) • \(rate.type.rawValue.capitalized)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text(rate.percentage)
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.orange)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

/// Tax report row
struct TaxReportRow: View {
    let report: TaxReport
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(report.reportType.rawValue.capitalized) Report")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("$\(report.totalTax, specifier: "%.2f") • \(report.status.rawValue.capitalized)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text("$\(report.totalTax, specifier: "%.2f")")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.orange)
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

/// Compliance status row
struct ComplianceStatusRow: View {
    let title: String
    let status: ComplianceStatus
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
        case .compliant:
            return .green
        case .pending:
            return .orange
        case .nonCompliant:
            return .red
        }
    }
}

enum ComplianceStatus {
    case compliant
    case pending
    case nonCompliant
}

/// Payout stat card
struct PayoutStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

/// Scheduled payout row
struct ScheduledPayoutRow: View {
    let scheduledPayout: ScheduledPayout
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(scheduledPayout.schedule.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("$\(scheduledPayout.minimumAmount, specifier: "%.2f") min • \(scheduledPayout.status.rawValue.capitalized)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text("$\(scheduledPayout.totalAmount, specifier: "%.2f")")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

/// Payout history row
struct PayoutHistoryRow: View {
    let payout: PayoutRecord
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(payout.payoutMethod.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("$\(payout.amount, specifier: "%.2f") • \(payout.status.rawValue.capitalized)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text("$\(payout.amount, specifier: "%.2f")")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundColor(.blue)
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

/// Payout setting row
struct PayoutSettingRow: View {
    let setting: PayoutSetting
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(setting.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("\(setting.scheduleType.displayName) • $\(setting.minimumAmount, specifier: "%.2f") min")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text(setting.isEnabled ? "Enabled" : "Disabled")
                .font(.caption)
                .foregroundColor(setting.isEnabled ? .green : .red)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background((setting.isEnabled ? Color.green : Color.red).opacity(0.2))
                .cornerRadius(4)
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#Preview {
    FinancialManagementDashboardView()
        .environmentObject(AppStateManager.shared)
} 