import Foundation
import CoreLocation
import Combine

/// Service for tax calculation and reporting
@MainActor
class TaxCalculationService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var taxRates: [TaxRate] = []
    @Published var taxReports: [TaxReport] = []
    @Published var isLoading = false
    @Published var taxStats: TaxStatistics = TaxStatistics()
    
    // MARK: - Private Properties
    
    private let analyticsService: AnalyticsService
    private let errorHandlingService: ErrorHandlingService
    private let locationService: LocationService
    private let hapticService: HapticService
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        analyticsService: AnalyticsService = .shared,
        errorHandlingService: ErrorHandlingService = .shared,
        locationService: LocationService = .shared,
        hapticService: HapticService = .shared
    ) {
        self.analyticsService = analyticsService
        self.errorHandlingService = errorHandlingService
        self.locationService = locationService
        self.hapticService = hapticService
        
        setupTaxRates()
    }
    
    // MARK: - Tax Calculation
    
    /// Calculate tax for a transaction
    func calculateTax(
        for transaction: PaymentTransaction,
        location: CLLocation? = nil
    ) async throws -> TaxCalculation {
        
        isLoading = true
        
        do {
            // Get location for tax calculation
            let transactionLocation = location ?? await locationService.getCurrentLocation()
            
            // Determine tax jurisdiction
            let jurisdiction = try await determineTaxJurisdiction(for: transactionLocation)
            
            // Get applicable tax rates
            let applicableRates = getApplicableTaxRates(
                for: jurisdiction,
                transactionType: transaction.metadata["event_type"] ?? "ticket_sale"
            )
            
            // Calculate taxes
            let taxBreakdown = calculateTaxBreakdown(
                amount: transaction.amount,
                rates: applicableRates,
                jurisdiction: jurisdiction
            )
            
            // Create tax calculation
            let taxCalculation = TaxCalculation(
                id: UUID().uuidString,
                transactionId: transaction.transactionId,
                amount: transaction.amount,
                currency: transaction.currency,
                jurisdiction: jurisdiction,
                taxRates: applicableRates,
                taxBreakdown: taxBreakdown,
                totalTax: taxBreakdown.totalTax,
                calculatedAt: Date(),
                metadata: [
                    "payment_method": transaction.paymentMethod.rawValue,
                    "event_type": transaction.metadata["event_type"] ?? "ticket_sale"
                ]
            )
            
            // Update statistics
            await updateTaxStatistics()
            
            hapticService.trigger(.light)
            
            analyticsService.trackEvent("tax_calculated", properties: [
                "transaction_id": transaction.transactionId,
                "amount": transaction.amount,
                "total_tax": taxBreakdown.totalTax,
                "jurisdiction": jurisdiction.country
            ])
            
            return taxCalculation
            
        } catch {
            errorHandlingService.handleError(error, context: "TaxCalculationService.calculateTax")
            throw error
        } finally {
            isLoading = false
        }
    }
    
    /// Calculate tax breakdown
    func calculateTaxBreakdown(
        amount: Double,
        rates: [TaxRate],
        jurisdiction: TaxJurisdiction
    ) -> TaxBreakdown {
        
        var breakdown = TaxBreakdown(
            subtotal: amount,
            totalTax: 0,
            taxDetails: [],
            currency: "USD"
        )
        
        // Calculate each tax type
        for rate in rates {
            let taxAmount = amount * rate.rate
            breakdown.totalTax += taxAmount
            
            let taxDetail = TaxDetail(
                type: rate.type,
                rate: rate.rate,
                amount: taxAmount,
                description: rate.description
            )
            
            breakdown.taxDetails.append(taxDetail)
        }
        
        breakdown.totalAmount = amount + breakdown.totalTax
        
        return breakdown
    }
    
    /// Get applicable tax rates for jurisdiction
    func getApplicableTaxRates(
        for jurisdiction: TaxJurisdiction,
        transactionType: String
    ) -> [TaxRate] {
        
        return taxRates.filter { rate in
            rate.jurisdiction.country == jurisdiction.country &&
            (rate.jurisdiction.state == jurisdiction.state || rate.jurisdiction.state == nil) &&
            (rate.jurisdiction.city == jurisdiction.city || rate.jurisdiction.city == nil) &&
            rate.isActive &&
            (rate.applicableTypes.contains(transactionType) || rate.applicableTypes.isEmpty)
        }
    }
    
    /// Determine tax jurisdiction from location
    func determineTaxJurisdiction(for location: CLLocation) async throws -> TaxJurisdiction {
        
        // In a real implementation, this would use a geocoding service
        // For demo purposes, we'll use mock data based on coordinates
        
        let jurisdiction = TaxJurisdiction(
            country: "US",
            state: "CA",
            city: "San Francisco",
            postalCode: "94102",
            coordinates: location.coordinate
        )
        
        return jurisdiction
    }
    
    // MARK: - Tax Reporting
    
    /// Generate tax report
    func generateTaxReport(
        for hostEmail: String,
        timeRange: DateInterval,
        jurisdiction: TaxJurisdiction
    ) async throws -> TaxReport {
        
        isLoading = true
        
        do {
            // Get transactions for the time period
            let transactions = try await getTransactionsForPeriod(
                hostEmail: hostEmail,
                timeRange: timeRange
            )
            
            // Calculate taxes for all transactions
            var totalRevenue: Double = 0
            var totalTax: Double = 0
            var taxCalculations: [TaxCalculation] = []
            
            for transaction in transactions {
                let taxCalculation = try await calculateTax(for: transaction)
                taxCalculations.append(taxCalculation)
                
                totalRevenue += transaction.amount
                totalTax += taxCalculation.totalTax
            }
            
            // Create tax report
            let taxReport = TaxReport(
                id: UUID().uuidString,
                hostEmail: hostEmail,
                timeRange: timeRange,
                jurisdiction: jurisdiction,
                totalRevenue: totalRevenue,
                totalTax: totalTax,
                taxCalculations: taxCalculations,
                reportType: .quarterly,
                status: .generated,
                generatedAt: Date(),
                dueDate: calculateTaxDueDate(for: timeRange),
                metadata: [
                    "transaction_count": String(transactions.count),
                    "jurisdiction": jurisdiction.country
                ]
            )
            
            // Add to reports
            taxReports.append(taxReport)
            
            hapticService.trigger(.success)
            
            analyticsService.trackEvent("tax_report_generated", properties: [
                "host_email": hostEmail,
                "total_revenue": totalRevenue,
                "total_tax": totalTax,
                "jurisdiction": jurisdiction.country
            ])
            
            return taxReport
            
        } catch {
            errorHandlingService.handleError(error, context: "TaxCalculationService.generateTaxReport")
            throw error
        } finally {
            isLoading = false
        }
    }
    
    /// Generate tax documents
    func generateTaxDocuments(for report: TaxReport) async throws -> TaxDocuments {
        
        // Generate various tax documents
        let documents = TaxDocuments(
            reportId: report.id,
            hostEmail: report.hostEmail,
            timeRange: report.timeRange,
            documents: [
                TaxDocument(
                    type: .summary,
                    title: "Tax Summary Report",
                    content: generateTaxSummaryContent(report),
                    format: .pdf
                ),
                TaxDocument(
                    type: .detailed,
                    title: "Detailed Tax Breakdown",
                    content: generateDetailedTaxContent(report),
                    format: .pdf
                ),
                TaxDocument(
                    type: .csv,
                    title: "Transaction Data",
                    content: generateCSVContent(report),
                    format: .csv
                )
            ],
            generatedAt: Date()
        )
        
        analyticsService.trackEvent("tax_documents_generated", properties: [
            "report_id": report.id,
            "document_count": documents.documents.count
        ])
        
        return documents
    }
    
    /// Get tax analytics
    func getTaxAnalytics(timeRange: DateInterval) async throws -> TaxAnalytics {
        
        let reportsInRange = taxReports.filter { report in
            timeRange.contains(report.generatedAt)
        }
        
        let analytics = TaxAnalytics(
            timeRange: timeRange,
            totalReports: reportsInRange.count,
            totalRevenue: reportsInRange.reduce(0) { $0 + $1.totalRevenue },
            totalTax: reportsInRange.reduce(0) { $0 + $1.totalTax },
            averageTaxRate: calculateAverageTaxRate(reportsInRange),
            topJurisdictions: getTopJurisdictions(reportsInRange),
            taxByMonth: groupTaxByMonth(reportsInRange),
            complianceRate: calculateComplianceRate(reportsInRange),
            generatedAt: Date()
        )
        
        analyticsService.trackEvent("tax_analytics_generated", properties: [
            "time_range_start": timeRange.start.timeIntervalSince1970,
            "time_range_end": timeRange.end.timeIntervalSince1970,
            "total_reports": analytics.totalReports
        ])
        
        return analytics
    }
    
    // MARK: - Tax Compliance
    
    /// Check tax compliance
    func checkTaxCompliance(for hostEmail: String) async throws -> TaxComplianceStatus {
        
        let currentYear = Calendar.current.component(.year, from: Date())
        let requiredReports = getRequiredReports(for: hostEmail, year: currentYear)
        let submittedReports = getSubmittedReports(for: hostEmail, year: currentYear)
        
        let complianceStatus = TaxComplianceStatus(
            hostEmail: hostEmail,
            year: currentYear,
            requiredReports: requiredReports,
            submittedReports: submittedReports,
            isCompliant: submittedReports.count >= requiredReports.count,
            missingReports: requiredReports.filter { required in
                !submittedReports.contains { $0.reportType == required.reportType }
            },
            lastUpdated: Date()
        )
        
        analyticsService.trackEvent("tax_compliance_checked", properties: [
            "host_email": hostEmail,
            "year": currentYear,
            "is_compliant": complianceStatus.isCompliant
        ])
        
        return complianceStatus
    }
    
    /// Get tax due dates
    func getTaxDueDates(for jurisdiction: TaxJurisdiction, year: Int) -> [TaxDueDate] {
        
        var dueDates: [TaxDueDate] = []
        
        // Quarterly reports
        for quarter in 1...4 {
            let dueDate = calculateQuarterlyDueDate(quarter: quarter, year: year, jurisdiction: jurisdiction)
            dueDates.append(TaxDueDate(
                reportType: .quarterly,
                period: "Q\(quarter)",
                dueDate: dueDate,
                isOverdue: dueDate < Date()
            ))
        }
        
        // Annual report
        let annualDueDate = calculateAnnualDueDate(year: year, jurisdiction: jurisdiction)
        dueDates.append(TaxDueDate(
            reportType: .annual,
            period: "Annual",
            dueDate: annualDueDate,
            isOverdue: annualDueDate < Date()
        ))
        
        return dueDates
    }
    
    // MARK: - Private Methods
    
    private func setupTaxRates() {
        taxRates = [
            // US Federal Tax
            TaxRate(
                id: "us_federal",
                jurisdiction: TaxJurisdiction(country: "US", state: nil, city: nil, postalCode: nil, coordinates: nil),
                type: .federal,
                rate: 0.0, // No federal tax on services
                description: "US Federal Tax",
                isActive: true,
                applicableTypes: ["ticket_sale", "subscription"]
            ),
            
            // California State Tax
            TaxRate(
                id: "ca_state",
                jurisdiction: TaxJurisdiction(country: "US", state: "CA", city: nil, postalCode: nil, coordinates: nil),
                type: .state,
                rate: 0.075, // 7.5%
                description: "California State Sales Tax",
                isActive: true,
                applicableTypes: ["ticket_sale"]
            ),
            
            // San Francisco City Tax
            TaxRate(
                id: "sf_city",
                jurisdiction: TaxJurisdiction(country: "US", state: "CA", city: "San Francisco", postalCode: nil, coordinates: nil),
                type: .city,
                rate: 0.0085, // 0.85%
                description: "San Francisco City Tax",
                isActive: true,
                applicableTypes: ["ticket_sale"]
            ),
            
            // New York State Tax
            TaxRate(
                id: "ny_state",
                jurisdiction: TaxJurisdiction(country: "US", state: "NY", city: nil, postalCode: nil, coordinates: nil),
                type: .state,
                rate: 0.04, // 4%
                description: "New York State Sales Tax",
                isActive: true,
                applicableTypes: ["ticket_sale"]
            ),
            
            // New York City Tax
            TaxRate(
                id: "nyc_city",
                jurisdiction: TaxJurisdiction(country: "US", state: "NY", city: "New York", postalCode: nil, coordinates: nil),
                type: .city,
                rate: 0.045, // 4.5%
                description: "New York City Sales Tax",
                isActive: true,
                applicableTypes: ["ticket_sale"]
            )
        ]
    }
    
    private func getTransactionsForPeriod(
        hostEmail: String,
        timeRange: DateInterval
    ) async throws -> [PaymentTransaction] {
        
        // In a real implementation, this would fetch from the database
        // For demo purposes, return mock data
        return [
            PaymentTransaction(
                transactionId: "txn_1",
                amount: 100.0,
                currency: "USD",
                paymentMethod: .creditCard,
                status: .completed,
                timestamp: Date(),
                customerEmail: "customer@example.com",
                customerName: "John Doe",
                location: nil,
                country: "US",
                metadata: [
                    "host_email": hostEmail,
                    "event_type": "ticket_sale"
                ]
            )
        ]
    }
    
    private func calculateTaxDueDate(for timeRange: DateInterval) -> Date {
        // Calculate due date based on jurisdiction and report type
        // For demo purposes, return 30 days after the end of the period
        return timeRange.end.addingTimeInterval(30 * 24 * 60 * 60)
    }
    
    private func generateTaxSummaryContent(_ report: TaxReport) -> String {
        return """
        Tax Summary Report
        Host: \(report.hostEmail)
        Period: \(report.timeRange.start) to \(report.timeRange.end)
        Total Revenue: $\(report.totalRevenue, specifier: "%.2f")
        Total Tax: $\(report.totalTax, specifier: "%.2f")
        Jurisdiction: \(report.jurisdiction.country), \(report.jurisdiction.state ?? "")
        """
    }
    
    private func generateDetailedTaxContent(_ report: TaxReport) -> String {
        var content = "Detailed Tax Breakdown\n\n"
        
        for calculation in report.taxCalculations {
            content += "Transaction: \(calculation.transactionId)\n"
            content += "Amount: $\(calculation.amount, specifier: "%.2f")\n"
            content += "Tax: $\(calculation.totalTax, specifier: "%.2f")\n\n"
        }
        
        return content
    }
    
    private func generateCSVContent(_ report: TaxReport) -> String {
        var csv = "Transaction ID,Amount,Tax,Jurisdiction\n"
        
        for calculation in report.taxCalculations {
            csv += "\(calculation.transactionId),\(calculation.amount),\(calculation.totalTax),\(calculation.jurisdiction.country)\n"
        }
        
        return csv
    }
    
    private func updateTaxStatistics() async {
        let totalTax = taxReports.reduce(0) { $0 + $1.totalTax }
        let totalRevenue = taxReports.reduce(0) { $0 + $1.totalRevenue }
        
        taxStats = TaxStatistics(
            totalTax: totalTax,
            totalRevenue: totalRevenue,
            averageTaxRate: totalRevenue > 0 ? totalTax / totalRevenue : 0,
            totalReports: taxReports.count,
            lastUpdated: Date()
        )
    }
    
    private func calculateAverageTaxRate(_ reports: [TaxReport]) -> Double {
        guard !reports.isEmpty else { return 0 }
        
        let totalTax = reports.reduce(0) { $0 + $1.totalTax }
        let totalRevenue = reports.reduce(0) { $0 + $1.totalRevenue }
        
        return totalRevenue > 0 ? totalTax / totalRevenue : 0
    }
    
    private func getTopJurisdictions(_ reports: [TaxReport]) -> [TaxJurisdiction] {
        var jurisdictionTax: [String: Double] = [:]
        
        for report in reports {
            let key = "\(report.jurisdiction.country)_\(report.jurisdiction.state ?? "")"
            jurisdictionTax[key, default: 0] += report.totalTax
        }
        
        return jurisdictionTax.sorted { $0.value > $1.value }
            .prefix(5)
            .compactMap { key, _ in
                let components = key.split(separator: "_")
                return TaxJurisdiction(
                    country: String(components[0]),
                    state: components.count > 1 ? String(components[1]) : nil,
                    city: nil,
                    postalCode: nil,
                    coordinates: nil
                )
            }
    }
    
    private func groupTaxByMonth(_ reports: [TaxReport]) -> [String: Double] {
        var grouped: [String: Double] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        
        for report in reports {
            let monthKey = formatter.string(from: report.generatedAt)
            grouped[monthKey, default: 0] += report.totalTax
        }
        
        return grouped
    }
    
    private func calculateComplianceRate(_ reports: [TaxReport]) -> Double {
        let totalReports = reports.count
        guard totalReports > 0 else { return 0 }
        
        let compliantReports = reports.filter { $0.status == .submitted }.count
        return Double(compliantReports) / Double(totalReports)
    }
    
    private func getRequiredReports(for hostEmail: String, year: Int) -> [TaxReportType] {
        return [.quarterly, .quarterly, .quarterly, .quarterly, .annual]
    }
    
    private func getSubmittedReports(for hostEmail: String, year: Int) -> [TaxReport] {
        return taxReports.filter { report in
            report.hostEmail == hostEmail &&
            Calendar.current.component(.year, from: report.generatedAt) == year
        }
    }
    
    private func calculateQuarterlyDueDate(quarter: Int, year: Int, jurisdiction: TaxJurisdiction) -> Date {
        // Calculate quarterly due dates (simplified)
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year
        components.month = quarter * 3
        components.day = 15
        
        return calendar.date(from: components) ?? Date()
    }
    
    private func calculateAnnualDueDate(year: Int, jurisdiction: TaxJurisdiction) -> Date {
        // Calculate annual due date (simplified)
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = year + 1
        components.month = 4
        components.day = 15
        
        return calendar.date(from: components) ?? Date()
    }
}

// MARK: - Tax Calculation Models

/// Tax calculation
struct TaxCalculation: Codable, Identifiable {
    let id: String
    let transactionId: String
    let amount: Double
    let currency: String
    let jurisdiction: TaxJurisdiction
    let taxRates: [TaxRate]
    let taxBreakdown: TaxBreakdown
    let totalTax: Double
    let calculatedAt: Date
    let metadata: [String: String]
}

/// Tax jurisdiction
struct TaxJurisdiction: Codable, Equatable {
    let country: String
    let state: String?
    let city: String?
    let postalCode: String?
    let coordinates: CLLocationCoordinate2D?
}

/// Tax rate
struct TaxRate: Codable, Identifiable {
    let id: String
    let jurisdiction: TaxJurisdiction
    let type: TaxType
    let rate: Double
    let description: String
    let isActive: Bool
    let applicableTypes: [String]
    
    var percentage: String {
        return "\(Int(rate * 100))%"
    }
}

enum TaxType: String, Codable {
    case federal = "federal"
    case state = "state"
    case city = "city"
    case county = "county"
    case special = "special"
}

/// Tax breakdown
struct TaxBreakdown: Codable {
    let subtotal: Double
    var totalTax: Double
    let taxDetails: [TaxDetail]
    let currency: String
    var totalAmount: Double = 0
}

/// Tax detail
struct TaxDetail: Codable {
    let type: TaxType
    let rate: Double
    let amount: Double
    let description: String
}

/// Tax report
struct TaxReport: Codable, Identifiable {
    let id: String
    let hostEmail: String
    let timeRange: DateInterval
    let jurisdiction: TaxJurisdiction
    let totalRevenue: Double
    let totalTax: Double
    let taxCalculations: [TaxCalculation]
    let reportType: TaxReportType
    var status: TaxReportStatus
    let generatedAt: Date
    let dueDate: Date
    let metadata: [String: String]
}

enum TaxReportType: String, Codable {
    case quarterly = "quarterly"
    case annual = "annual"
    case monthly = "monthly"
}

enum TaxReportStatus: String, Codable {
    case generated = "generated"
    case submitted = "submitted"
    case approved = "approved"
    case rejected = "rejected"
}

/// Tax documents
struct TaxDocuments: Codable {
    let reportId: String
    let hostEmail: String
    let timeRange: DateInterval
    let documents: [TaxDocument]
    let generatedAt: Date
}

/// Tax document
struct TaxDocument: Codable {
    let type: TaxDocumentType
    let title: String
    let content: String
    let format: DocumentFormat
}

enum TaxDocumentType: String, Codable {
    case summary = "summary"
    case detailed = "detailed"
    case csv = "csv"
}

enum DocumentFormat: String, Codable {
    case pdf = "pdf"
    case csv = "csv"
    case json = "json"
}

/// Tax analytics
struct TaxAnalytics: Codable {
    let timeRange: DateInterval
    let totalReports: Int
    let totalRevenue: Double
    let totalTax: Double
    let averageTaxRate: Double
    let topJurisdictions: [TaxJurisdiction]
    let taxByMonth: [String: Double]
    let complianceRate: Double
    let generatedAt: Date
}

/// Tax statistics
struct TaxStatistics: Codable {
    let totalTax: Double
    let totalRevenue: Double
    let averageTaxRate: Double
    let totalReports: Int
    let lastUpdated: Date
}

/// Tax compliance status
struct TaxComplianceStatus: Codable {
    let hostEmail: String
    let year: Int
    let requiredReports: [TaxReportType]
    let submittedReports: [TaxReport]
    let isCompliant: Bool
    let missingReports: [TaxReportType]
    let lastUpdated: Date
}

/// Tax due date
struct TaxDueDate: Codable {
    let reportType: TaxReportType
    let period: String
    let dueDate: Date
    let isOverdue: Bool
}

/// Tax calculation errors
enum TaxCalculationError: Error, LocalizedError {
    case jurisdictionNotFound
    case taxRateNotFound
    case calculationFailed
    case reportGenerationFailed
    
    var errorDescription: String? {
        switch self {
        case .jurisdictionNotFound:
            return "Tax jurisdiction not found"
        case .taxRateNotFound:
            return "Tax rate not found for jurisdiction"
        case .calculationFailed:
            return "Tax calculation failed"
        case .reportGenerationFailed:
            return "Tax report generation failed"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .jurisdictionNotFound:
            return "Please check the location information"
        case .taxRateNotFound:
            return "Please contact support for tax rate information"
        case .calculationFailed:
            return "Please try again or contact support"
        case .reportGenerationFailed:
            return "Please try again or contact support"
        }
    }
}

// MARK: - Extensions

extension TaxCalculationService {
    /// Create a mock instance for testing
    static func mock() -> TaxCalculationService {
        TaxCalculationService(
            analyticsService: .shared,
            errorHandlingService: .shared,
            locationService: .shared,
            hapticService: .shared
        )
    }
} 