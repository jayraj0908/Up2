import SwiftUI

/// Dashboard view for payment security monitoring and management
struct PaymentSecurityDashboardView: View {
    
    // MARK: - Environment
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appStateManager: AppStateManager
    
    // MARK: - View Models
    
    @StateObject private var securityService = PaymentSecurityService()
    @StateObject private var fraudService = FraudDetectionService()
    @StateObject private var disputeService = DisputeResolutionService()
    
    // MARK: - State
    
    @State private var selectedTab = 0
    @State private var showingComplianceDetails = false
    @State private var showingFraudAlerts = false
    @State private var showingDisputeDetails = false
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
                        // Compliance Tab
                        complianceTabView
                            .tag(0)
                        
                        // Fraud Detection Tab
                        fraudDetectionTabView
                            .tag(1)
                        
                        // Dispute Management Tab
                        disputeManagementTabView
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
                
                Text("Security Dashboard")
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
            
            // Security Status Overview
            securityStatusOverview
        }
    }
    
    // MARK: - Security Status Overview
    
    private var securityStatusOverview: some View {
        HStack(spacing: 16) {
            // PCI DSS Compliance
            SecurityStatusCard(
                title: "PCI DSS",
                status: securityService.securityStatus,
                value: securityService.isCompliant ? "Compliant" : "Non-Compliant",
                icon: "shield.checkered",
                color: securityService.isCompliant ? .green : .red
            )
            
            // Fraud Detection
            SecurityStatusCard(
                title: "Fraud Detection",
                status: .compliant,
                value: "\(fraudService.fraudAlerts.count) Alerts",
                icon: "exclamationmark.triangle",
                color: fraudService.fraudAlerts.isEmpty ? .green : .orange
            )
            
            // Disputes
            SecurityStatusCard(
                title: "Disputes",
                status: .compliant,
                value: "\(disputeService.activeDisputes.count) Active",
                icon: "doc.text",
                color: disputeService.activeDisputes.isEmpty ? .green : .blue
            )
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Tab Selector
    
    private var tabSelectorSection: some View {
        HStack(spacing: 0) {
            ForEach(["Compliance", "Fraud", "Disputes"], id: \.self) { tab in
                Button(action: {
                    withAnimation {
                        selectedTab = ["Compliance", "Fraud", "Disputes"].firstIndex(of: tab) ?? 0
                    }
                }) {
                    Text(tab)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(selectedTab == ["Compliance", "Fraud", "Disputes"].firstIndex(of: tab) ? .white : .white.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            selectedTab == ["Compliance", "Fraud", "Disputes"].firstIndex(of: tab) ?
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
    
    // MARK: - Compliance Tab
    
    private var complianceTabView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Compliance Status
                complianceStatusSection
                
                // Security Audit
                securityAuditSection
                
                // Encryption Status
                encryptionStatusSection
                
                // Key Management
                keyManagementSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }
    
    private var complianceStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PCI DSS Compliance")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: securityService.isCompliant ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(securityService.isCompliant ? .green : .red)
                        .font(.title2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(securityService.isCompliant ? "Compliant" : "Non-Compliant")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                        
                        Text("Payment Card Industry Data Security Standard")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Button("Details") {
                        showingComplianceDetails = true
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
                
                if let lastAudit = securityService.lastSecurityAudit {
                    HStack {
                        Text("Last Audit:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(lastAudit, style: .date)
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Spacer()
                    }
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var securityAuditSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Security Audit")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Button(action: {
                Task {
                    await performSecurityAudit()
                }
            }) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                    
                    Text("Run Security Audit")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
    }
    
    private var encryptionStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Data Encryption")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                SecurityFeatureRow(
                    title: "AES-256-GCM Encryption",
                    description: "All sensitive payment data is encrypted",
                    status: .active
                )
                
                SecurityFeatureRow(
                    title: "Secure Tokenization",
                    description: "Payment data is tokenized for storage",
                    status: .active
                )
                
                SecurityFeatureRow(
                    title: "Key Management",
                    description: "Encryption keys are securely managed",
                    status: .active
                )
            }
        }
    }
    
    private var keyManagementSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Key Management")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                SecurityFeatureRow(
                    title: "Key Rotation",
                    description: "Encryption keys are rotated regularly",
                    status: .active
                )
                
                SecurityFeatureRow(
                    title: "Secure Storage",
                    description: "Keys stored in iOS Keychain",
                    status: .active
                )
                
                SecurityFeatureRow(
                    title: "Access Control",
                    description: "Strict access controls implemented",
                    status: .active
                )
            }
        }
    }
    
    // MARK: - Fraud Detection Tab
    
    private var fraudDetectionTabView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Risk Score
                riskScoreSection
                
                // Fraud Alerts
                fraudAlertsSection
                
                // Risk Factors
                riskFactorsSection
                
                // Monitoring Status
                monitoringStatusSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }
    
    private var riskScoreSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Risk Score")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(Int(fraudService.riskScore))/100")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(riskScoreColor)
                    
                    Text(riskScoreDescription)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Risk gauge
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: fraudService.riskScore / 100)
                        .stroke(riskScoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1), value: fraudService.riskScore)
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var fraudAlertsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Fraud Alerts")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    showingFraudAlerts = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if fraudService.fraudAlerts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.shield")
                        .font(.title)
                        .foregroundColor(.green)
                    
                    Text("No Active Alerts")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("All transactions are within normal risk parameters")
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
                    ForEach(fraudService.fraudAlerts.prefix(3)) { alert in
                        FraudAlertRow(alert: alert)
                    }
                }
            }
        }
    }
    
    private var riskFactorsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Risk Factors")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                RiskFactorRow(
                    title: "Amount Risk",
                    description: "Transaction amount analysis",
                    riskLevel: .low
                )
                
                RiskFactorRow(
                    title: "Location Risk",
                    description: "Geographic location analysis",
                    riskLevel: .low
                )
                
                RiskFactorRow(
                    title: "Time Risk",
                    description: "Transaction timing analysis",
                    riskLevel: .low
                )
                
                RiskFactorRow(
                    title: "Device Risk",
                    description: "Device fingerprint analysis",
                    riskLevel: .low
                )
                
                RiskFactorRow(
                    title: "Behavioral Risk",
                    description: "User behavior analysis",
                    riskLevel: .low
                )
            }
        }
    }
    
    private var monitoringStatusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Monitoring Status")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(fraudService.isMonitoring ? "Active" : "Inactive")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(fraudService.isMonitoring ? .green : .red)
                    
                    Text("Real-time fraud monitoring")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Circle()
                    .fill(fraudService.isMonitoring ? .green : .red)
                    .frame(width: 12, height: 12)
            }
            .padding(16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Dispute Management Tab
    
    private var disputeManagementTabView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Dispute Statistics
                disputeStatisticsSection
                
                // Active Disputes
                activeDisputesSection
                
                // Resolution Performance
                resolutionPerformanceSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
    }
    
    private var disputeStatisticsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Dispute Statistics")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Total",
                    value: "\(disputeService.disputeStats.totalDisputes)",
                    color: .blue
                )
                
                StatCard(
                    title: "Active",
                    value: "\(disputeService.disputeStats.activeDisputes)",
                    color: .orange
                )
                
                StatCard(
                    title: "Resolved",
                    value: "\(disputeService.disputeStats.resolvedDisputes)",
                    color: .green
                )
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Win Rate")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(Int(disputeService.disputeStats.winRate * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Avg Resolution")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("\(Int(disputeService.disputeStats.averageResolutionTime / 86400)) days")
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
    
    private var activeDisputesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Active Disputes")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("View All") {
                    showingDisputeDetails = true
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            
            if disputeService.activeDisputes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.doc")
                        .font(.title)
                        .foregroundColor(.green)
                    
                    Text("No Active Disputes")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("All disputes have been resolved")
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
                    ForEach(disputeService.activeDisputes.prefix(3)) { dispute in
                        DisputeRow(dispute: dispute)
                    }
                }
            }
        }
    }
    
    private var resolutionPerformanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Resolution Performance")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 12) {
                PerformanceRow(
                    title: "Response Time",
                    value: "< 24 hours",
                    status: .good
                )
                
                PerformanceRow(
                    title: "Evidence Quality",
                    value: "High",
                    status: .good
                )
                
                PerformanceRow(
                    title: "Customer Satisfaction",
                    value: "95%",
                    status: .good
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func refreshData() {
        isRefreshing = true
        
        // Simulate data refresh
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isRefreshing = false
        }
    }
    
    private func performSecurityAudit() async {
        // Perform security audit
        let _ = await securityService.performPCIDSSComplianceCheck()
    }
    
    private var riskScoreColor: Color {
        if fraudService.riskScore >= 75 {
            return .red
        } else if fraudService.riskScore >= 50 {
            return .orange
        } else if fraudService.riskScore >= 25 {
            return .yellow
        } else {
            return .green
        }
    }
    
    private var riskScoreDescription: String {
        if fraudService.riskScore >= 75 {
            return "High Risk"
        } else if fraudService.riskScore >= 50 {
            return "Medium Risk"
        } else if fraudService.riskScore >= 25 {
            return "Low Risk"
        } else {
            return "Minimal Risk"
        }
    }
}

// MARK: - Supporting Views

/// Security status card
struct SecurityStatusCard: View {
    let title: String
    let status: SecurityStatus
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

/// Security feature row
struct SecurityFeatureRow: View {
    let title: String
    let description: String
    let status: FeatureStatus
    
    var body: some View {
        HStack {
            Image(systemName: status == .active ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(status == .active ? .green : .red)
                .font(.title3)
            
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
}

enum FeatureStatus {
    case active
    case inactive
}

/// Fraud alert row
struct FraudAlertRow: View {
    let alert: FraudAlert
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("High Risk Transaction")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("Risk Score: \(Int(alert.riskScore))")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            Text(alert.createdAt, style: .time)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

/// Risk factor row
struct RiskFactorRow: View {
    let title: String
    let description: String
    let riskLevel: RiskLevel
    
    var body: some View {
        HStack {
            Circle()
                .fill(riskLevelColor)
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
            
            Text(riskLevel.rawValue.capitalized)
                .font(.caption)
                .foregroundColor(riskLevelColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(riskLevelColor.opacity(0.2))
                .cornerRadius(4)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var riskLevelColor: Color {
        switch riskLevel {
        case .minimal, .low:
            return .green
        case .medium:
            return .yellow
        case .high:
            return .red
        }
    }
}

/// Stat card
struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
}

/// Dispute row
struct DisputeRow: View {
    let dispute: PaymentDispute
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(dispute.reason.rawValue.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text("$\(dispute.amount, specifier: "%.2f")")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(dispute.status.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(statusColor.opacity(0.2))
                    .cornerRadius(4)
                
                Text(dispute.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch dispute.status {
        case .pending:
            return .orange
        case .evidenceSubmitted:
            return .blue
        case .underReview:
            return .yellow
        case .resolved:
            return .green
        }
    }
}

/// Performance row
struct PerformanceRow: View {
    let title: String
    let value: String
    let status: PerformanceStatus
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(statusColor)
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(8)
    }
    
    private var statusColor: Color {
        switch status {
        case .good:
            return .green
        case .warning:
            return .yellow
        case .poor:
            return .red
        }
    }
}

enum PerformanceStatus {
    case good
    case warning
    case poor
}

// MARK: - Preview

#Preview {
    PaymentSecurityDashboardView()
        .environmentObject(AppStateManager.shared)
} 