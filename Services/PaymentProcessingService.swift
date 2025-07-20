import Foundation
import Combine
import SwiftUI

/// Main service for coordinating payment processing
@MainActor
class PaymentProcessingService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentFlowState: PaymentFlowState = .idle
    @Published var currentSession: PaymentSession?
    @Published var selectedPaymentMethod: UserPaymentMethod?
    @Published var paymentConfirmation: PaymentConfirmation?
    @Published var lastError: PaymentError?
    
    // MARK: - Private Properties
    
    private let stripeService: StripeIntegrationService
    private let analyticsService: AnalyticsService
    private let errorHandlingService: ErrorHandlingService
    private let hapticService: HapticService
    private let validationService: ValidationService
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        stripeService: StripeIntegrationService = StripeIntegrationService(),
        analyticsService: AnalyticsService = .shared,
        errorHandlingService: ErrorHandlingService = .shared,
        hapticService: HapticService = .shared,
        validationService: ValidationService = .shared
    ) {
        self.stripeService = stripeService
        self.analyticsService = analyticsService
        self.errorHandlingService = errorHandlingService
        self.hapticService = hapticService
        self.validationService = validationService
        
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Bind Stripe service state
        stripeService.$currentSession
            .assign(to: \.currentSession, on: self)
            .store(in: &cancellables)
        
        stripeService.$lastError
            .assign(to: \.lastError, on: self)
            .store(in: &cancellables)
        
        stripeService.$isProcessing
            .sink { [weak self] isProcessing in
                if isProcessing {
                    self?.currentFlowState = .processingPayment
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Payment Flow Management
    
    /// Start payment flow for ticket purchase
    func startPaymentFlow(
        eventId: String,
        ticketId: String,
        amount: Double,
        currency: String = "USD",
        customerEmail: String,
        customerName: String? = nil
    ) async throws -> PaymentSession {
        
        currentFlowState = .loading
        lastError = nil
        
        do {
            // Validate inputs
            try validatePaymentFlowInputs(
                eventId: eventId,
                ticketId: ticketId,
                amount: amount,
                currency: currency,
                customerEmail: customerEmail
            )
            
            // Create payment session
            let session = try await stripeService.createPaymentSession(
                eventId: eventId,
                ticketId: ticketId,
                amount: amount,
                currency: currency,
                customerEmail: customerEmail,
                customerName: customerName
            )
            
            // Update flow state
            currentFlowState = .selectingPaymentMethod
            
            // Track flow start
            analyticsService.trackEvent("payment_flow_started", properties: [
                "session_id": session.id,
                "event_id": eventId,
                "ticket_id": ticketId,
                "amount": amount,
                "currency": currency
            ])
            
            hapticService.trigger(.light)
            
            return session
            
        } catch {
            currentFlowState = .failed(error as? PaymentError ?? .invalidConfiguration)
            errorHandlingService.handleError(error, context: "PaymentProcessingService.startPaymentFlow")
            throw error
        }
    }
    
    /// Select payment method and proceed to payment
    func selectPaymentMethod(_ paymentMethod: UserPaymentMethod) {
        selectedPaymentMethod = paymentMethod
        currentFlowState = .processingPayment
        
        analyticsService.trackEvent("payment_method_selected", properties: [
            "payment_method": paymentMethod.type.rawValue,
            "session_id": currentSession?.id ?? ""
        ])
        
        hapticService.trigger(.light)
    }
    
    /// Process payment with selected method
    func processPayment() async throws -> PaymentConfirmation {
        
        guard let session = currentSession else {
            throw PaymentError.invalidConfiguration
        }
        
        guard let paymentMethod = selectedPaymentMethod else {
            throw PaymentError.invalidPaymentMethod
        }
        
        currentFlowState = .processingPayment
        
        do {
            // Process payment through Stripe
            let confirmation = try await stripeService.processPayment(
                session: session,
                paymentMethodId: paymentMethod.id
            )
            
            // Update flow state
            currentFlowState = .completed
            paymentConfirmation = confirmation
            
            // Track successful payment
            analyticsService.trackEvent("payment_processing_completed", properties: [
                "session_id": session.id,
                "transaction_id": confirmation.transactionId,
                "amount": session.amount,
                "currency": session.currency,
                "payment_method": paymentMethod.type.rawValue
            ])
            
            hapticService.trigger(.success)
            
            return confirmation
            
        } catch {
            currentFlowState = .failed(error as? PaymentError ?? .serverError)
            errorHandlingService.handleError(error, context: "PaymentProcessingService.processPayment")
            throw error
        }
    }
    
    /// Create checkout session for web-based payment
    func createCheckoutSession(
        successUrl: String,
        cancelUrl: String
    ) async throws -> String {
        
        guard let session = currentSession else {
            throw PaymentError.invalidConfiguration
        }
        
        currentFlowState = .processingPayment
        
        do {
            let checkoutUrl = try await stripeService.createCheckoutSession(
                for: session,
                successUrl: successUrl,
                cancelUrl: cancelUrl
            )
            
            analyticsService.trackEvent("checkout_session_created", properties: [
                "session_id": session.id,
                "amount": session.amount,
                "currency": session.currency
            ])
            
            return checkoutUrl
            
        } catch {
            currentFlowState = .failed(error as? PaymentError ?? .serverError)
            errorHandlingService.handleError(error, context: "PaymentProcessingService.createCheckoutSession")
            throw error
        }
    }
    
    /// Cancel payment flow
    func cancelPayment() {
        currentFlowState = .cancelled
        
        analyticsService.trackEvent("payment_flow_cancelled", properties: [
            "session_id": currentSession?.id ?? "",
            "flow_state": "cancelled"
        ])
        
        hapticService.trigger(.light)
        
        // Clear session after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.clearPaymentFlow()
        }
    }
    
    /// Clear payment flow and reset state
    func clearPaymentFlow() {
        currentFlowState = .idle
        currentSession = nil
        selectedPaymentMethod = nil
        paymentConfirmation = nil
        lastError = nil
        
        stripeService.clearSession()
    }
    
    // MARK: - Payment Validation
    
    /// Validate payment flow inputs
    private func validatePaymentFlowInputs(
        eventId: String,
        ticketId: String,
        amount: Double,
        currency: String,
        customerEmail: String
    ) throws {
        
        // Validate event ID
        guard !eventId.isEmpty else {
            throw PaymentError.invalidConfiguration
        }
        
        // Validate ticket ID
        guard !ticketId.isEmpty else {
            throw PaymentError.invalidConfiguration
        }
        
        // Validate amount
        guard amount > 0 else {
            throw PaymentError.invalidAmount
        }
        
        // Validate currency
        guard !currency.isEmpty else {
            throw PaymentError.invalidConfiguration
        }
        
        // Validate email
        guard validationService.isValidEmail(customerEmail) else {
            throw PaymentError.invalidConfiguration
        }
    }
    
    /// Validate payment method selection
    func validatePaymentMethodSelection() -> Bool {
        guard let paymentMethod = selectedPaymentMethod else {
            return false
        }
        
        return paymentMethod.isEnabled
    }
    
    // MARK: - Payment Method Management
    
    /// Get available payment methods for user
    func getAvailablePaymentMethods() async throws -> [UserPaymentMethod] {
        // In a real implementation, this would fetch from user's saved methods
        return [
            UserPaymentMethod(
                id: "pm_apple_pay",
                type: .applePay,
                last4: nil,
                brand: nil,
                expiryMonth: nil,
                expiryYear: nil,
                isDefault: true,
                isEnabled: stripeService.isApplePayAvailable,
                addedAt: Date()
            ),
            UserPaymentMethod(
                id: "pm_google_pay",
                type: .googlePay,
                last4: nil,
                brand: nil,
                expiryMonth: nil,
                expiryYear: nil,
                isDefault: false,
                isEnabled: stripeService.isGooglePayAvailable,
                addedAt: Date()
            ),
            UserPaymentMethod(
                id: "pm_credit_card",
                type: .creditCard,
                last4: "4242",
                brand: "Visa",
                expiryMonth: 12,
                expiryYear: 2025,
                isDefault: false,
                isEnabled: true,
                addedAt: Date()
            )
        ]
    }
    
    /// Set default payment method
    func setDefaultPaymentMethod(_ paymentMethod: UserPaymentMethod) async throws {
        // In a real implementation, this would update the user's default payment method
        analyticsService.trackEvent("default_payment_method_changed", properties: [
            "payment_method": paymentMethod.type.rawValue
        ])
    }
    
    // MARK: - Payment Analytics
    
    /// Track payment flow step
    func trackPaymentStep(_ step: String, properties: [String: Any] = [:]) {
        var props = properties
        props["step"] = step
        props["session_id"] = currentSession?.id
        
        analyticsService.trackEvent("payment_flow_step", properties: props)
    }
    
    /// Get payment metrics for current session
    func getPaymentMetrics() -> PaymentMetrics? {
        guard let session = currentSession else { return nil }
        
        // In a real implementation, this would calculate actual metrics
        return PaymentMetrics(
            totalTransactions: 1,
            successfulTransactions: 1,
            failedTransactions: 0,
            totalRevenue: session.amount,
            averageTransactionValue: session.amount,
            conversionRate: 1.0,
            averageProcessingTime: 2.5,
            topPaymentMethods: [.creditCard: 1],
            timeRange: DateInterval(start: session.createdAt, duration: 300) // 5 minutes
        )
    }
    
    // MARK: - Error Handling
    
    /// Handle payment error
    func handlePaymentError(_ error: PaymentError) {
        lastError = error
        currentFlowState = .failed(error)
        
        analyticsService.trackEvent("payment_error", properties: [
            "error_type": String(describing: error),
            "session_id": currentSession?.id ?? "",
            "error_description": error.errorDescription ?? ""
        ])
        
        hapticService.trigger(.error)
    }
    
    /// Retry payment after error
    func retryPayment() async throws -> PaymentConfirmation {
        guard let session = currentSession else {
            throw PaymentError.invalidConfiguration
        }
        
        lastError = nil
        currentFlowState = .processingPayment
        
        analyticsService.trackEvent("payment_retry", properties: [
            "session_id": session.id
        ])
        
        return try await processPayment()
    }
    
    // MARK: - Utility Methods
    
    /// Check if payment flow is active
    var isPaymentFlowActive: Bool {
        switch currentFlowState {
        case .idle, .completed, .failed, .cancelled:
            return false
        default:
            return true
        }
    }
    
    /// Check if payment can be processed
    var canProcessPayment: Bool {
        currentSession != nil && 
        selectedPaymentMethod != nil && 
        selectedPaymentMethod?.isEnabled == true &&
        currentFlowState == .selectingPaymentMethod
    }
    
    /// Get formatted amount for display
    var formattedAmount: String {
        guard let session = currentSession else { return "$0.00" }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = session.currency
        return formatter.string(from: NSNumber(value: session.amount)) ?? "$\(session.amount)"
    }
    
    /// Get session time remaining
    var sessionTimeRemaining: TimeInterval {
        currentSession?.timeRemaining ?? 0
    }
    
    /// Check if session is expired
    var isSessionExpired: Bool {
        currentSession?.isExpired ?? false
    }
}

// MARK: - Extensions

extension PaymentProcessingService {
    /// Create a mock instance for testing
    static func mock() -> PaymentProcessingService {
        PaymentProcessingService(
            stripeService: .mock(),
            analyticsService: .shared,
            errorHandlingService: .shared,
            hapticService: .shared,
            validationService: .shared
        )
    }
} 