import Foundation

// MARK: - Payment Method Types

/// Represents different types of payment methods
enum PaymentMethodType: String, Codable, CaseIterable {
    case creditCard = "credit_card"
    case applePay = "apple_pay"
    case googlePay = "google_pay"
    case paypal = "paypal"
    case bankTransfer = "bank_transfer"
    case invalid = "invalid"
    
    var displayName: String {
        switch self {
        case .creditCard:
            return "Credit Card"
        case .applePay:
            return "Apple Pay"
        case .googlePay:
            return "Google Pay"
        case .paypal:
            return "PayPal"
        case .bankTransfer:
            return "Bank Transfer"
        case .invalid:
            return "Invalid Method"
        }
    }
    
    var iconName: String {
        switch self {
        case .creditCard:
            return "creditcard"
        case .applePay:
            return "applelogo"
        case .googlePay:
            return "g.circle"
        case .paypal:
            return "p.circle"
        case .bankTransfer:
            return "building.columns"
        case .invalid:
            return "exclamationmark.triangle"
        }
    }
}

// MARK: - Core Payment Models

/// Represents a payment session for ticket purchase
struct PaymentSession: Codable, Identifiable {
    let id: String
    let eventId: String
    let ticketId: String
    let amount: Double
    let currency: String
    let customerEmail: String
    let customerName: String?
    let paymentIntentId: String?
    let status: PaymentSessionStatus
    let createdAt: Date
    let expiresAt: Date
    
    var isExpired: Bool {
        Date() > expiresAt
    }
    
    var timeRemaining: TimeInterval {
        max(0, expiresAt.timeIntervalSince(Date()))
    }
}

enum PaymentSessionStatus: String, Codable {
    case created = "created"
    case processing = "processing"
    case completed = "completed"
    case failed = "failed"
    case cancelled = "cancelled"
    case expired = "expired"
}

/// Represents a ticket for purchase
struct Ticket: Codable, Identifiable {
    let id: String
    let eventId: String
    let name: String
    let description: String?
    let price: Double
    let currency: String
    let quantity: Int
    let availableQuantity: Int
    let isRefundable: Bool
    let refundPolicy: String?
    let validFrom: Date
    let validUntil: Date
    
    var isAvailable: Bool {
        availableQuantity > 0 && Date() >= validFrom && Date() <= validUntil
    }
    
    var formattedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: price)) ?? "$\(price)"
    }
}

/// Represents a payment method for the user
struct UserPaymentMethod: Codable, Identifiable {
    let id: String
    let type: PaymentMethodType
    let last4: String?
    let brand: String?
    let expiryMonth: Int?
    let expiryYear: Int?
    var isDefault: Bool
    let isEnabled: Bool
    let addedAt: Date
    
    var displayName: String {
        switch type {
        case .creditCard:
            if let last4 = last4, let brand = brand {
                return "\(brand) •••• \(last4)"
            } else {
                return "Credit Card"
            }
        case .applePay:
            return "Apple Pay"
        case .googlePay:
            return "Google Pay"
        case .paypal:
            return "PayPal"
        case .bankTransfer:
            return "Bank Transfer"
        case .invalid:
            return "Invalid Payment Method"
        }
    }
    
    var expiryDate: String? {
        guard let month = expiryMonth, let year = expiryYear else { return nil }
        return String(format: "%02d/%d", month, year)
    }
}

/// Represents a payment confirmation
struct PaymentConfirmation: Codable {
    let transactionId: String
    let paymentSessionId: String
    let eventId: String
    let ticketId: String
    let amount: Double
    let currency: String
    let paymentMethod: PaymentMethodType
    let customerEmail: String
    let customerName: String?
    let processedAt: Date
    let receiptUrl: String?
    let confirmationCode: String
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        return formatter.string(from: NSNumber(value: amount)) ?? "$\(amount)"
    }
}

/// Represents payment checkout options
struct PaymentCheckoutOptions: Codable {
    let allowApplePay: Bool
    let allowGooglePay: Bool
    let allowCreditCards: Bool
    let allowPayPal: Bool
    let requireBillingAddress: Bool
    let requireShippingAddress: Bool
    let allowPromoCode: Bool
    let autoConfirm: Bool
    
    static let `default` = PaymentCheckoutOptions(
        allowApplePay: true,
        allowGooglePay: true,
        allowCreditCards: true,
        allowPayPal: true,
        requireBillingAddress: false,
        requireShippingAddress: false,
        allowPromoCode: true,
        autoConfirm: false
    )
}

// MARK: - Stripe Integration Models

/// Stripe payment intent configuration
struct StripePaymentIntentConfig: Codable {
    let amount: Int // Amount in cents
    let currency: String
    let customerEmail: String
    let customerName: String?
    let metadata: [String: String]
    let description: String
    let receiptEmail: String?
    let applicationFeeAmount: Int?
    
    init(
        amount: Double,
        currency: String = "usd",
        customerEmail: String,
        customerName: String? = nil,
        metadata: [String: String] = [:],
        description: String,
        receiptEmail: String? = nil,
        applicationFeeAmount: Double? = nil
    ) {
        self.amount = Int(amount * 100) // Convert to cents
        self.currency = currency.lowercased()
        self.customerEmail = customerEmail
        self.customerName = customerName
        self.metadata = metadata
        self.description = description
        self.receiptEmail = receiptEmail
        self.applicationFeeAmount = applicationFeeAmount.map { Int($0 * 100) }
    }
}

/// Stripe checkout session configuration
struct StripeCheckoutConfig: Codable {
    let paymentIntentConfig: StripePaymentIntentConfig
    let successUrl: String
    let cancelUrl: String
    let mode: StripeCheckoutMode
    let paymentMethodTypes: [String]
    let allowPromotionCodes: Bool
    let billingAddressCollection: String?
    let customerCreation: String?
    
    enum StripeCheckoutMode: String, Codable {
        case payment = "payment"
        case setup = "setup"
        case subscription = "subscription"
    }
    
    init(
        paymentIntentConfig: StripePaymentIntentConfig,
        successUrl: String,
        cancelUrl: String,
        mode: StripeCheckoutMode = .payment,
        paymentMethodTypes: [String] = ["card", "apple_pay", "google_pay"],
        allowPromotionCodes: Bool = true,
        billingAddressCollection: String? = nil,
        customerCreation: String? = "always"
    ) {
        self.paymentIntentConfig = paymentIntentConfig
        self.successUrl = successUrl
        self.cancelUrl = cancelUrl
        self.mode = mode
        self.paymentMethodTypes = paymentMethodTypes
        self.allowPromotionCodes = allowPromotionCodes
        self.billingAddressCollection = billingAddressCollection
        self.customerCreation = customerCreation
    }
}

// MARK: - Payment Flow Models

/// Represents the current state of payment flow
enum PaymentFlowState {
    case idle
    case loading
    case selectingPaymentMethod
    case processingPayment
    case confirmingPayment
    case completed
    case failed(PaymentError)
    case cancelled
}

/// Payment flow configuration
struct PaymentFlowConfig: Codable {
    let eventId: String
    let ticketId: String
    let customerEmail: String
    let customerName: String?
    let checkoutOptions: PaymentCheckoutOptions
    let successRedirectUrl: String?
    let cancelRedirectUrl: String?
    
    init(
        eventId: String,
        ticketId: String,
        customerEmail: String,
        customerName: String? = nil,
        checkoutOptions: PaymentCheckoutOptions = .default,
        successRedirectUrl: String? = nil,
        cancelRedirectUrl: String? = nil
    ) {
        self.eventId = eventId
        self.ticketId = ticketId
        self.customerEmail = customerEmail
        self.customerName = customerName
        self.checkoutOptions = checkoutOptions
        self.successRedirectUrl = successRedirectUrl
        self.cancelRedirectUrl = cancelRedirectUrl
    }
}

// MARK: - Payment Error Models

/// Payment-related errors
enum PaymentError: Error, LocalizedError {
    case invalidAmount
    case invalidPaymentMethod
    case paymentDeclined(String)
    case insufficientFunds
    case expiredCard
    case invalidCard
    case networkError
    case serverError
    case userCancelled
    case sessionExpired
    case invalidConfiguration
    case stripeError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount:
            return "Invalid payment amount"
        case .invalidPaymentMethod:
            return "Invalid payment method"
        case .paymentDeclined(let reason):
            return "Payment declined: \(reason)"
        case .insufficientFunds:
            return "Insufficient funds"
        case .expiredCard:
            return "Card has expired"
        case .invalidCard:
            return "Invalid card information"
        case .networkError:
            return "Network connection error"
        case .serverError:
            return "Server error occurred"
        case .userCancelled:
            return "Payment was cancelled"
        case .sessionExpired:
            return "Payment session expired"
        case .invalidConfiguration:
            return "Invalid payment configuration"
        case .stripeError(let message):
            return "Stripe error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidAmount:
            return "Please check the payment amount and try again"
        case .invalidPaymentMethod:
            return "Please select a valid payment method"
        case .paymentDeclined:
            return "Please try a different payment method or contact your bank"
        case .insufficientFunds:
            return "Please ensure you have sufficient funds in your account"
        case .expiredCard:
            return "Please update your card information"
        case .invalidCard:
            return "Please check your card details and try again"
        case .networkError:
            return "Please check your internet connection and try again"
        case .serverError:
            return "Please try again later"
        case .userCancelled:
            return "You can try the payment again when ready"
        case .sessionExpired:
            return "Please start a new payment session"
        case .invalidConfiguration:
            return "Please contact support for assistance"
        case .stripeError:
            return "Please try again or contact support"
        }
    }
}

// MARK: - Payment Analytics Models

/// Payment analytics data
struct PaymentAnalytics: Codable {
    let sessionId: String
    let eventId: String
    let ticketId: String
    let amount: Double
    let currency: String
    let paymentMethod: PaymentMethodType
    let processingTime: TimeInterval
    let success: Bool
    let errorType: String?
    let timestamp: Date
    let userAgent: String?
    let deviceInfo: String?
}

/// Payment performance metrics
struct PaymentMetrics: Codable {
    let totalTransactions: Int
    let successfulTransactions: Int
    let failedTransactions: Int
    let totalRevenue: Double
    let averageTransactionValue: Double
    let conversionRate: Double
    let averageProcessingTime: TimeInterval
    let topPaymentMethods: [PaymentMethodType: Int]
    let timeRange: DateInterval
    
    var successRate: Double {
        guard totalTransactions > 0 else { return 0 }
        return Double(successfulTransactions) / Double(totalTransactions)
    }
}

// MARK: - Payment Validation Models

/// Payment validation result
struct PaymentValidationResult: Codable {
    let isValid: Bool
    let errors: [PaymentValidationError]
    let warnings: [PaymentValidationWarning]
    
    var hasErrors: Bool {
        !errors.isEmpty
    }
    
    var hasWarnings: Bool {
        !warnings.isEmpty
    }
}

enum PaymentValidationError: String, Codable {
    case invalidAmount = "invalid_amount"
    case invalidEmail = "invalid_email"
    case invalidPaymentMethod = "invalid_payment_method"
    case expiredTicket = "expired_ticket"
    case soldOutTicket = "sold_out_ticket"
    case invalidEvent = "invalid_event"
}

enum PaymentValidationWarning: String, Codable {
    case highAmount = "high_amount"
    case unusualTime = "unusual_time"
    case newPaymentMethod = "new_payment_method"
    case internationalTransaction = "international_transaction"
}

// MARK: - Extensions

extension PaymentSession {
    static func mock(
        eventId: String = "event_123",
        ticketId: String = "ticket_456",
        amount: Double = 29.99
    ) -> PaymentSession {
        PaymentSession(
            id: UUID().uuidString,
            eventId: eventId,
            ticketId: ticketId,
            amount: amount,
            currency: "USD",
            customerEmail: "test@example.com",
            customerName: "Test User",
            paymentIntentId: nil,
            status: .created,
            createdAt: Date(),
            expiresAt: Date().addingTimeInterval(15 * 60) // 15 minutes
        )
    }
}

extension Ticket {
    static func mock(
        eventId: String = "event_123",
        price: Double = 29.99
    ) -> Ticket {
        Ticket(
            id: UUID().uuidString,
            eventId: eventId,
            name: "General Admission",
            description: "Access to the main event area",
            price: price,
            currency: "USD",
            quantity: 100,
            availableQuantity: 50,
            isRefundable: true,
            refundPolicy: "Full refund available up to 24 hours before event",
            validFrom: Date(),
            validUntil: Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days
        )
    }
}

// MARK: - Financial Management Types

/// Commission rate structure
struct CommissionRate: Identifiable, Codable {
    var id = UUID()
    let eventType: String
    let rate: Double
    let description: String
    let isActive: Bool
}

/// Revenue sharing structure
struct RevenueShare: Identifiable, Codable {
    var id = UUID()
    let eventId: String
    let hostShare: Double
    let platformShare: Double
    let totalAmount: Double
    let date: Date
} 