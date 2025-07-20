import Foundation
import CoreLocation
import Network

/// Service for detecting and preventing payment fraud
@MainActor
class FraudDetectionService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var isMonitoring = false
    @Published var lastRiskAssessment: Date?
    @Published var fraudAlerts: [FraudAlert] = []
    @Published var riskScore: Double = 0.0
    
    // MARK: - Private Properties
    
    private let analyticsService: AnalyticsService
    private let errorHandlingService: ErrorHandlingService
    private let locationService: LocationService
    
    private var transactionHistory: [TransactionRecord] = []
    private var riskRules: [FraudRiskRule] = []
    private var monitoringTimer: Timer?
    
    // MARK: - Configuration
    
    private let maxRiskScore: Double = 100.0
    private let highRiskThreshold: Double = 75.0
    private let mediumRiskThreshold: Double = 50.0
    private let lowRiskThreshold: Double = 25.0
    
    // MARK: - Initialization
    
    init(
        analyticsService: AnalyticsService = .shared,
        errorHandlingService: ErrorHandlingService = .shared,
        locationService: LocationService = .shared
    ) {
        self.analyticsService = analyticsService
        self.errorHandlingService = errorHandlingService
        self.locationService = locationService
        
        setupRiskRules()
        startMonitoring()
    }
    
    // MARK: - Fraud Detection
    
    /// Assess fraud risk for a payment transaction
    func assessFraudRisk(for transaction: PaymentTransaction) async -> FraudRiskAssessment {
        var riskFactors: [RiskFactor] = []
        var totalRiskScore: Double = 0.0
        
        // Factor 1: Transaction Amount
        let amountRisk = assessAmountRisk(transaction.amount)
        riskFactors.append(amountRisk)
        totalRiskScore += amountRisk.score
        
        // Factor 2: Location Risk
        let locationRisk = await assessLocationRisk(transaction)
        riskFactors.append(locationRisk)
        totalRiskScore += locationRisk.score
        
        // Factor 3: Time Risk
        let timeRisk = assessTimeRisk(transaction)
        riskFactors.append(timeRisk)
        totalRiskScore += timeRisk.score
        
        // Factor 4: Device Risk
        let deviceRisk = await assessDeviceRisk(transaction)
        riskFactors.append(deviceRisk)
        totalRiskScore += deviceRisk.score
        
        // Factor 5: Behavioral Risk
        let behavioralRisk = assessBehavioralRisk(transaction)
        riskFactors.append(behavioralRisk)
        totalRiskScore += behavioralRisk.score
        
        // Factor 6: Payment Method Risk
        let paymentMethodRisk = assessPaymentMethodRisk(transaction)
        riskFactors.append(paymentMethodRisk)
        totalRiskScore += paymentMethodRisk.score
        
        // Normalize risk score
        let normalizedScore = min(totalRiskScore, maxRiskScore)
        
        // Determine risk level
        let riskLevel = determineRiskLevel(normalizedScore)
        
        // Create assessment
        let assessment = FraudRiskAssessment(
            transactionId: transaction.transactionId,
            riskScore: normalizedScore,
            riskLevel: riskLevel,
            riskFactors: riskFactors,
            recommendations: generateRecommendations(riskLevel, riskFactors),
            assessedAt: Date()
        )
        
        // Update service state
        riskScore = normalizedScore
        lastRiskAssessment = assessment.assessedAt
        
        // Log assessment
        analyticsService.trackEvent("fraud_risk_assessed", properties: [
            "transaction_id": transaction.transactionId,
            "risk_score": normalizedScore,
            "risk_level": riskLevel.rawValue,
            "risk_factors_count": riskFactors.count
        ])
        
        // Check for fraud alerts
        if riskLevel == .high {
            await createFraudAlert(for: assessment)
        }
        
        return assessment
    }
    
    /// Monitor transaction for suspicious activity
    func monitorTransaction(_ transaction: PaymentTransaction) async -> MonitoringResult {
        let assessment = await assessFraudRisk(for: transaction)
        
        // Apply automated rules
        let shouldBlock = await applyAutomatedRules(assessment)
        
        // Create monitoring result
        let result = MonitoringResult(
            transactionId: transaction.transactionId,
            assessment: assessment,
            shouldBlock: shouldBlock,
            shouldReview: assessment.riskLevel == .medium,
            monitoringNotes: generateMonitoringNotes(assessment)
        )
        
        // Log monitoring result
        analyticsService.trackEvent("transaction_monitored", properties: [
            "transaction_id": transaction.transactionId,
            "should_block": shouldBlock,
            "should_review": result.shouldReview,
            "risk_level": assessment.riskLevel.rawValue
        ])
        
        return result
    }
    
    /// Apply automated fraud prevention rules
    func applyAutomatedRules(_ assessment: FraudRiskAssessment) async -> Bool {
        var shouldBlock = false
        
        // Rule 1: High risk score
        if assessment.riskScore >= highRiskThreshold {
            shouldBlock = true
        }
        
        // Rule 2: Multiple high-risk factors
        let highRiskFactors = assessment.riskFactors.filter { $0.score >= 20.0 }
        if highRiskFactors.count >= 3 {
            shouldBlock = true
        }
        
        // Rule 3: Suspicious location pattern
        if let locationRisk = assessment.riskFactors.first(where: { $0.type == .location }) {
            if locationRisk.score >= 30.0 {
                shouldBlock = true
            }
        }
        
        // Rule 4: Unusual transaction time
        if let timeRisk = assessment.riskFactors.first(where: { $0.type == .time }) {
            if timeRisk.score >= 25.0 {
                shouldBlock = true
            }
        }
        
        // Rule 5: Device fingerprint mismatch
        if let deviceRisk = assessment.riskFactors.first(where: { $0.type == .device }) {
            if deviceRisk.score >= 35.0 {
                shouldBlock = true
            }
        }
        
        if shouldBlock {
            analyticsService.trackEvent("transaction_blocked", properties: [
                "transaction_id": assessment.transactionId,
                "risk_score": assessment.riskScore,
                "risk_level": assessment.riskLevel.rawValue
            ])
        }
        
        return shouldBlock
    }
    
    // MARK: - Risk Assessment Methods
    
    private func assessAmountRisk(_ amount: Double) -> RiskFactor {
        var score: Double = 0.0
        var details = ""
        
        // High amount risk
        if amount > 1000.0 {
            score = 30.0
            details = "Transaction amount exceeds $1000"
        } else if amount > 500.0 {
            score = 20.0
            details = "Transaction amount exceeds $500"
        } else if amount > 100.0 {
            score = 10.0
            details = "Transaction amount exceeds $100"
        } else {
            score = 5.0
            details = "Normal transaction amount"
        }
        
        // Check for unusual amounts
        if isUnusualAmount(amount) {
            score += 15.0
            details += " - Unusual amount pattern"
        }
        
        return RiskFactor(
            type: .amount,
            score: score,
            details: details,
            severity: score > 20.0 ? .high : score > 10.0 ? .medium : .low
        )
    }
    
    private func assessLocationRisk(_ transaction: PaymentTransaction) async -> RiskFactor {
        var score: Double = 0.0
        var details = ""
        
        // Get current location
        let currentLocation = await locationService.getCurrentLocation()
        
        // Check for location mismatch
        if let transactionLocation = transaction.location {
            let distance = calculateDistance(from: currentLocation, to: transactionLocation)
            
            if distance > 1000.0 { // 1000 km
                score = 40.0
                details = "Transaction location is \(Int(distance))km from current location"
            } else if distance > 500.0 {
                score = 25.0
                details = "Transaction location is \(Int(distance))km from current location"
            } else if distance > 100.0 {
                score = 15.0
                details = "Transaction location is \(Int(distance))km from current location"
            } else {
                score = 5.0
                details = "Transaction location is within normal range"
            }
        }
        
        // Check for high-risk countries
        if let country = transaction.country, isHighRiskCountry(country) {
            score += 20.0
            details += " - High-risk country detected"
        }
        
        return RiskFactor(
            type: .location,
            score: score,
            details: details,
            severity: score > 30.0 ? .high : score > 15.0 ? .medium : .low
        )
    }
    
    private func assessTimeRisk(_ transaction: PaymentTransaction) -> RiskFactor {
        var score: Double = 0.0
        var details = ""
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: transaction.timestamp)
        
        // Unusual time risk
        if hour >= 23 || hour <= 5 {
            score = 25.0
            details = "Transaction during unusual hours (\(hour):00)"
        } else if hour >= 22 || hour <= 6 {
            score = 15.0
            details = "Transaction during late hours (\(hour):00)"
        } else {
            score = 5.0
            details = "Transaction during normal hours (\(hour):00)"
        }
        
        // Check for rapid transactions
        if isRapidTransaction(transaction) {
            score += 20.0
            details += " - Rapid transaction detected"
        }
        
        return RiskFactor(
            type: .time,
            score: score,
            details: details,
            severity: score > 20.0 ? .high : score > 10.0 ? .medium : .low
        )
    }
    
    private func assessDeviceRisk(_ transaction: PaymentTransaction) async -> RiskFactor {
        var score: Double = 0.0
        var details = ""
        
        // Check device fingerprint
        let deviceFingerprint = await getDeviceFingerprint()
        
        if !isKnownDevice(deviceFingerprint) {
            score = 30.0
            details = "Unknown device detected"
        } else if isSuspiciousDevice(deviceFingerprint) {
            score = 20.0
            details = "Suspicious device characteristics"
        } else {
            score = 5.0
            details = "Known device"
        }
        
        // Check for VPN usage
        if await isUsingVPN() {
            score += 15.0
            details += " - VPN detected"
        }
        
        return RiskFactor(
            type: .device,
            score: score,
            details: details,
            severity: score > 25.0 ? .high : score > 15.0 ? .medium : .low
        )
    }
    
    private func assessBehavioralRisk(_ transaction: PaymentTransaction) -> RiskFactor {
        var score: Double = 0.0
        var details = ""
        
        // Check transaction history
        let userHistory = getTransactionHistory(for: transaction.customerEmail)
        
        if userHistory.count == 0 {
            score = 20.0
            details = "New customer - no transaction history"
        } else {
            // Check for unusual patterns
            if isUnusualPattern(transaction, in: userHistory) {
                score = 25.0
                details = "Unusual transaction pattern detected"
            } else {
                score = 5.0
                details = "Normal transaction pattern"
            }
        }
        
        // Check for multiple failed attempts
        let failedAttempts = getFailedAttempts(for: transaction.customerEmail)
        if failedAttempts > 3 {
            score += 20.0
            details += " - Multiple failed attempts (\(failedAttempts))"
        }
        
        return RiskFactor(
            type: .behavioral,
            score: score,
            details: details,
            severity: score > 20.0 ? .high : score > 10.0 ? .medium : .low
        )
    }
    
    private func assessPaymentMethodRisk(_ transaction: PaymentTransaction) -> RiskFactor {
        var score: Double = 0.0
        var details = ""
        
        switch transaction.paymentMethod {
        case .creditCard:
            score = 10.0
            details = "Credit card payment"
        case .applePay:
            score = 5.0
            details = "Apple Pay - low risk"
        case .googlePay:
            score = 5.0
            details = "Google Pay - low risk"
        case .paypal:
            score = 8.0
            details = "PayPal payment"
        case .bankTransfer:
            score = 15.0
            details = "Bank transfer - higher risk"
        case .invalid:
            score = 50.0
            details = "Invalid payment method"
        }
        
        // Check for new payment method
        if isNewPaymentMethod(transaction) {
            score += 15.0
            details += " - New payment method"
        }
        
        return RiskFactor(
            type: .paymentMethod,
            score: score,
            details: details,
            severity: score > 20.0 ? .high : score > 10.0 ? .medium : .low
        )
    }
    
    // MARK: - Utility Methods
    
    private func determineRiskLevel(_ score: Double) -> RiskLevel {
        if score >= highRiskThreshold {
            return .high
        } else if score >= mediumRiskThreshold {
            return .medium
        } else if score >= lowRiskThreshold {
            return .low
        } else {
            return .minimal
        }
    }
    
    private func generateRecommendations(_ riskLevel: RiskLevel, _ factors: [RiskFactor]) -> [String] {
        var recommendations: [String] = []
        
        switch riskLevel {
        case .high:
            recommendations.append("Transaction blocked due to high fraud risk")
            recommendations.append("Manual review required")
            recommendations.append("Contact customer for verification")
        case .medium:
            recommendations.append("Additional verification recommended")
            recommendations.append("Monitor transaction closely")
        case .low:
            recommendations.append("Proceed with normal processing")
        case .minimal:
            recommendations.append("Low risk transaction")
        }
        
        // Add specific recommendations based on risk factors
        for factor in factors where factor.severity == .high {
            recommendations.append("Review \(factor.type.rawValue) risk: \(factor.details)")
        }
        
        return recommendations
    }
    
    private func generateMonitoringNotes(_ assessment: FraudRiskAssessment) -> String {
        let highRiskFactors = assessment.riskFactors.filter { $0.severity == .high }
        let mediumRiskFactors = assessment.riskFactors.filter { $0.severity == .medium }
        
        var notes = "Risk Score: \(assessment.riskScore)/\(maxRiskScore)\n"
        notes += "Risk Level: \(assessment.riskLevel.rawValue)\n"
        
        if !highRiskFactors.isEmpty {
            notes += "\nHigh Risk Factors:\n"
            for factor in highRiskFactors {
                notes += "• \(factor.details)\n"
            }
        }
        
        if !mediumRiskFactors.isEmpty {
            notes += "\nMedium Risk Factors:\n"
            for factor in mediumRiskFactors {
                notes += "• \(factor.details)\n"
            }
        }
        
        return notes
    }
    
    private func createFraudAlert(for assessment: FraudRiskAssessment) async {
        let alert = FraudAlert(
            id: UUID().uuidString,
            transactionId: assessment.transactionId,
            riskScore: assessment.riskScore,
            riskLevel: assessment.riskLevel,
            description: "High-risk transaction detected",
            createdAt: Date(),
            status: .active
        )
        
        fraudAlerts.append(alert)
        
        analyticsService.trackEvent("fraud_alert_created", properties: [
            "alert_id": alert.id,
            "transaction_id": alert.transactionId,
            "risk_score": alert.riskScore,
            "risk_level": alert.riskLevel.rawValue
        ])
    }
    
    // MARK: - Setup Methods
    
    private func setupRiskRules() {
        riskRules = [
            FraudRiskRule(
                name: "High Amount Rule",
                description: "Block transactions over $1000",
                condition: { transaction in
                    transaction.amount > 1000.0
                },
                action: .block
            ),
            FraudRiskRule(
                name: "Unusual Time Rule",
                description: "Flag transactions between 11 PM and 5 AM",
                condition: { transaction in
                    let hour = Calendar.current.component(.hour, from: transaction.timestamp)
                    return hour >= 23 || hour <= 5
                },
                action: .flag
            ),
            FraudRiskRule(
                name: "New Customer Rule",
                description: "Review transactions from new customers",
                condition: { transaction in
                    // Check if customer is new
                    return true // Simplified for demo
                },
                action: .review
            )
        ]
    }
    
    private func startMonitoring() {
        isMonitoring = true
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task {
                await self?.performPeriodicMonitoring()
            }
        }
    }
    
    private func performPeriodicMonitoring() async {
        // Perform periodic fraud monitoring checks
        analyticsService.trackEvent("periodic_fraud_monitoring", properties: [
            "active_alerts": fraudAlerts.count,
            "current_risk_score": riskScore
        ])
    }
    
    // MARK: - Helper Methods (Simplified for demo)
    
    private func isUnusualAmount(_ amount: Double) -> Bool {
        // Simplified logic for demo
        return amount.truncatingRemainder(dividingBy: 100) == 0
    }
    
    private func calculateDistance(from: CLLocation, to: CLLocation) -> Double {
        return from.distance(from: to) / 1000.0 // Convert to km
    }
    
    private func isHighRiskCountry(_ country: String) -> Bool {
        let highRiskCountries = ["XX", "YY", "ZZ"] // Simplified for demo
        return highRiskCountries.contains(country)
    }
    
    private func isRapidTransaction(_ transaction: PaymentTransaction) -> Bool {
        // Simplified logic for demo
        return false
    }
    
    private func getDeviceFingerprint() async -> String {
        // Simplified for demo
        return "device_fingerprint_\(UUID().uuidString)"
    }
    
    private func isKnownDevice(_ fingerprint: String) -> Bool {
        // Simplified for demo
        return true
    }
    
    private func isSuspiciousDevice(_ fingerprint: String) -> Bool {
        // Simplified for demo
        return false
    }
    
    private func isUsingVPN() async -> Bool {
        // Simplified for demo
        return false
    }
    
    private func getTransactionHistory(for email: String) -> [TransactionRecord] {
        // Simplified for demo
        return []
    }
    
    private func isUnusualPattern(_ transaction: PaymentTransaction, in history: [TransactionRecord]) -> Bool {
        // Simplified for demo
        return false
    }
    
    private func getFailedAttempts(for email: String) -> Int {
        // Simplified for demo
        return 0
    }
    
    private func isNewPaymentMethod(_ transaction: PaymentTransaction) -> Bool {
        // Simplified for demo
        return false
    }
}

// MARK: - Fraud Detection Models

/// Fraud risk assessment result
struct FraudRiskAssessment: Codable {
    let transactionId: String
    let riskScore: Double
    let riskLevel: RiskLevel
    let riskFactors: [RiskFactor]
    let recommendations: [String]
    let assessedAt: Date
}

/// Individual risk factor
struct RiskFactor: Codable {
    let type: RiskFactorType
    let score: Double
    let details: String
    let severity: RiskSeverity
}

enum RiskFactorType: String, Codable {
    case amount = "amount"
    case location = "location"
    case time = "time"
    case device = "device"
    case behavioral = "behavioral"
    case paymentMethod = "payment_method"
}

enum RiskSeverity: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

enum RiskLevel: String, Codable {
    case minimal = "minimal"
    case low = "low"
    case medium = "medium"
    case high = "high"
}

/// Transaction monitoring result
struct MonitoringResult: Codable {
    let transactionId: String
    let assessment: FraudRiskAssessment
    let shouldBlock: Bool
    let shouldReview: Bool
    let monitoringNotes: String
}

/// Fraud alert
struct FraudAlert: Codable, Identifiable {
    let id: String
    let transactionId: String
    let riskScore: Double
    let riskLevel: RiskLevel
    let description: String
    let createdAt: Date
    let status: AlertStatus
}

enum AlertStatus: String, Codable {
    case active = "active"
    case resolved = "resolved"
    case dismissed = "dismissed"
}

/// Fraud risk rule
struct FraudRiskRule: Codable {
    let name: String
    let description: String
    let condition: (PaymentTransaction) -> Bool
    let action: RuleAction
}

enum RuleAction: String, Codable {
    case block = "block"
    case flag = "flag"
    case review = "review"
}

/// Transaction record for history
struct TransactionRecord: Codable {
    let transactionId: String
    let amount: Double
    let timestamp: Date
    let customerEmail: String
    let status: TransactionStatus
}

// MARK: - Extensions

extension FraudDetectionService {
    /// Create a mock instance for testing
    static func mock() -> FraudDetectionService {
        FraudDetectionService(
            analyticsService: .shared,
            errorHandlingService: .shared,
            locationService: .shared
        )
    }
} 