import Foundation
import Combine

/// Service for detecting and managing fraud alerts
class FraudDetectionService: ObservableObject {
    @Published var fraudAlerts: [FraudAlert] = []
    @Published var riskLevel: RiskLevel = .low
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadFraudData()
    }
    
    /// Load fraud detection data
    private func loadFraudData() {
        // Mock data for now
        riskLevel = .low
        
        fraudAlerts = [
            FraudAlert(
                id: UUID(),
                type: .suspiciousTransaction,
                description: "Unusual payment pattern detected",
                riskLevel: .medium,
                date: Date().addingTimeInterval(-3600),
                status: .investigating
            ),
            FraudAlert(
                id: UUID(),
                type: .multipleAccounts,
                description: "Multiple accounts from same IP",
                riskLevel: .high,
                date: Date().addingTimeInterval(-7200),
                status: .resolved
            )
        ]
    }
    
    /// Analyze transaction for fraud
    func analyzeTransaction(_ transaction: PaymentTransaction) async throws -> FraudAnalysis {
        // Mock implementation
        let riskScore = Double.random(in: 0...100)
        let riskLevel: RiskLevel = riskScore > 80 ? .high : riskScore > 50 ? .medium : .low
        
        return FraudAnalysis(
            transactionId: transaction.id,
            riskScore: riskScore,
            riskLevel: riskLevel,
            flagged: riskScore > 70,
            reasons: riskScore > 70 ? ["Unusual amount", "New location"] : []
        )
    }
}

// MARK: - Supporting Types

struct FraudAlert: Identifiable, Codable {
    let id: UUID
    let type: FraudAlertType
    let description: String
    let riskLevel: RiskLevel
    let date: Date
    let status: FraudAlertStatus
}

enum FraudAlertType: String, Codable, CaseIterable {
    case suspiciousTransaction = "suspicious_transaction"
    case multipleAccounts = "multiple_accounts"
    case unusualLocation = "unusual_location"
    case rapidTransactions = "rapid_transactions"
}

enum FraudAlertStatus: String, Codable, CaseIterable {
    case new = "new"
    case investigating = "investigating"
    case resolved = "resolved"
    case falsePositive = "false_positive"
}

enum RiskLevel: String, Codable, CaseIterable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case critical = "critical"
    
    var displayName: String {
        switch self {
        case .low:
            return "Low Risk"
        case .medium:
            return "Medium Risk"
        case .high:
            return "High Risk"
        case .critical:
            return "Critical Risk"
        }
    }
    
    var color: String {
        switch self {
        case .low:
            return "green"
        case .medium:
            return "yellow"
        case .high:
            return "orange"
        case .critical:
            return "red"
        }
    }
}

struct FraudAnalysis: Codable {
    let transactionId: String
    let riskScore: Double
    let riskLevel: RiskLevel
    let flagged: Bool
    let reasons: [String]
}

struct PaymentTransaction: Codable {
    let id: String
    let amount: Double
    let currency: String
    let timestamp: Date
    let location: String?
} 