import Foundation
import PassKit
import Combine

/// Service for managing multiple payment methods
@MainActor
class PaymentMethodService: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var availablePaymentMethods: [PaymentMethodType] = []
    @Published var userPaymentMethods: [UserPaymentMethod] = []
    @Published var defaultPaymentMethod: UserPaymentMethod?
    @Published var isApplePayAvailable = false
    @Published var isGooglePayAvailable = false
    @Published var isLoading = false
    
    // MARK: - Private Properties
    
    private let analyticsService: AnalyticsService
    private let errorHandlingService: ErrorHandlingService
    private let securityService: PaymentSecurityService
    private let hapticService: HapticService
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        analyticsService: AnalyticsService = .shared,
        errorHandlingService: ErrorHandlingService = .shared,
        securityService: PaymentSecurityService = .shared,
        hapticService: HapticService = .shared
    ) {
        self.analyticsService = analyticsService
        self.errorHandlingService = errorHandlingService
        self.securityService = securityService
        self.hapticService = hapticService
        
        setupPaymentMethods()
        checkPaymentMethodAvailability()
    }
    
    // MARK: - Payment Method Management
    
    /// Setup available payment methods
    private func setupPaymentMethods() {
        availablePaymentMethods = [
            .applePay,
            .googlePay,
            .creditCard,
            .paypal,
            .bankTransfer
        ]
    }
    
    /// Check payment method availability
    private func checkPaymentMethodAvailability() {
        // Check Apple Pay availability
        isApplePayAvailable = PKPaymentAuthorizationController.canMakePayments()
        
        // Check Google Pay availability (simplified for demo)
        isGooglePayAvailable = checkGooglePayAvailability()
        
        analyticsService.trackEvent("payment_methods_availability_checked", properties: [
            "apple_pay_available": isApplePayAvailable,
            "google_pay_available": isGooglePayAvailable
        ])
    }
    
    /// Load user's saved payment methods
    func loadUserPaymentMethods() async throws -> [UserPaymentMethod] {
        isLoading = true
        
        do {
            // In a real implementation, this would fetch from secure storage
            let methods = try await fetchUserPaymentMethods()
            
            userPaymentMethods = methods
            defaultPaymentMethod = methods.first { $0.isDefault }
            
            analyticsService.trackEvent("user_payment_methods_loaded", properties: [
                "methods_count": methods.count,
                "has_default": defaultPaymentMethod != nil
            ])
            
            return methods
            
        } catch {
            errorHandlingService.handleError(error, context: "PaymentMethodService.loadUserPaymentMethods")
            throw error
        } finally {
            isLoading = false
        }
    }
    
    /// Add new payment method
    func addPaymentMethod(
        type: PaymentMethodType,
        paymentData: PaymentData,
        isDefault: Bool = false
    ) async throws -> UserPaymentMethod {
        
        isLoading = true
        
        do {
            // Validate payment data
            try validatePaymentData(paymentData)
            
            // Tokenize payment data for security
            let token = try await securityService.tokenizePaymentData(paymentData)
            
            // Create payment method
            let paymentMethod = UserPaymentMethod(
                id: token.token,
                type: type,
                last4: paymentData.last4,
                brand: paymentData.brand,
                expiryMonth: paymentData.expiryMonth,
                expiryYear: paymentData.expiryYear,
                isDefault: isDefault,
                isEnabled: true,
                addedAt: Date()
            )
            
            // Update default payment method if needed
            if isDefault {
                try await setDefaultPaymentMethod(paymentMethod)
            }
            
            // Add to user's methods
            userPaymentMethods.append(paymentMethod)
            
            // Save to secure storage
            try await savePaymentMethod(paymentMethod)
            
            hapticService.trigger(.success)
            
            analyticsService.trackEvent("payment_method_added", properties: [
                "payment_method_type": type.rawValue,
                "is_default": isDefault,
                "brand": paymentData.brand ?? "unknown"
            ])
            
            return paymentMethod
            
        } catch {
            errorHandlingService.handleError(error, context: "PaymentMethodService.addPaymentMethod")
            throw error
        } finally {
            isLoading = false
        }
    }
    
    /// Set default payment method
    func setDefaultPaymentMethod(_ paymentMethod: UserPaymentMethod) async throws {
        // Update all methods to not default
        for i in 0..<userPaymentMethods.count {
            userPaymentMethods[i].isDefault = false
        }
        
        // Set new default
        if let index = userPaymentMethods.firstIndex(where: { $0.id == paymentMethod.id }) {
            userPaymentMethods[index].isDefault = true
            defaultPaymentMethod = userPaymentMethods[index]
        }
        
        // Save to secure storage
        try await saveDefaultPaymentMethod(paymentMethod)
        
        hapticService.trigger(.light)
        
        analyticsService.trackEvent("default_payment_method_changed", properties: [
            "payment_method_type": paymentMethod.type.rawValue,
            "payment_method_id": paymentMethod.id
        ])
    }
    
    /// Remove payment method
    func removePaymentMethod(_ paymentMethod: UserPaymentMethod) async throws {
        // Check if it's the default method
        if paymentMethod.isDefault {
            throw PaymentMethodError.cannotRemoveDefaultMethod
        }
        
        // Remove from user's methods
        userPaymentMethods.removeAll { $0.id == paymentMethod.id }
        
        // Remove from secure storage
        try await deletePaymentMethod(paymentMethod)
        
        hapticService.trigger(.light)
        
        analyticsService.trackEvent("payment_method_removed", properties: [
            "payment_method_type": paymentMethod.type.rawValue,
            "payment_method_id": paymentMethod.id
        ])
    }
    
    /// Update payment method
    func updatePaymentMethod(_ paymentMethod: UserPaymentMethod) async throws {
        // Validate updated data
        guard let index = userPaymentMethods.firstIndex(where: { $0.id == paymentMethod.id }) else {
            throw PaymentMethodError.paymentMethodNotFound
        }
        
        // Update in array
        userPaymentMethods[index] = paymentMethod
        
        // Save to secure storage
        try await savePaymentMethod(paymentMethod)
        
        hapticService.trigger(.light)
        
        analyticsService.trackEvent("payment_method_updated", properties: [
            "payment_method_type": paymentMethod.type.rawValue,
            "payment_method_id": paymentMethod.id
        ])
    }
    
    /// Get payment method by ID
    func getPaymentMethod(by id: String) -> UserPaymentMethod? {
        return userPaymentMethods.first { $0.id == id }
    }
    
    /// Get enabled payment methods
    func getEnabledPaymentMethods() -> [UserPaymentMethod] {
        return userPaymentMethods.filter { $0.isEnabled }
    }
    
    /// Check if payment method is available for transaction
    func isPaymentMethodAvailable(_ method: UserPaymentMethod, for amount: Double) -> Bool {
        guard method.isEnabled else { return false }
        
        switch method.type {
        case .applePay:
            return isApplePayAvailable && PKPaymentAuthorizationController.canMakePayments(usingNetworks: supportedNetworks)
        case .googlePay:
            return isGooglePayAvailable
        case .creditCard:
            return true // Credit cards are always available
        case .paypal:
            return true // PayPal is always available
        case .bankTransfer:
            return amount >= 10.0 // Minimum amount for bank transfer
        case .invalid:
            return false
        }
    }
    
    // MARK: - Apple Pay Integration
    
    /// Create Apple Pay payment request
    func createApplePayRequest(
        amount: Double,
        currency: String = "USD",
        merchantIdentifier: String = "merchant.com.up2app"
    ) -> PKPaymentRequest {
        
        let request = PKPaymentRequest()
        request.merchantIdentifier = merchantIdentifier
        request.supportedNetworks = supportedNetworks
        request.merchantCapabilities = .capability3DS
        request.countryCode = "US"
        request.currencyCode = currency
        
        // Create payment summary items
        let total = PKPaymentSummaryItem(
            label: "Up2 Events",
            amount: NSDecimalNumber(value: amount)
        )
        
        request.paymentSummaryItems = [total]
        
        return request
    }
    
    /// Process Apple Pay payment
    func processApplePayPayment(
        payment: PKPayment,
        amount: Double,
        currency: String
    ) async throws -> PaymentTransaction {
        
        // Create payment transaction
        let transaction = PaymentTransaction(
            transactionId: UUID().uuidString,
            amount: amount,
            currency: currency,
            paymentMethod: .applePay,
            status: .processing,
            timestamp: Date(),
            customerEmail: "user@example.com", // Get from user profile
            customerName: "User Name", // Get from user profile
            location: nil,
            country: "US",
            metadata: [
                "payment_method": "apple_pay",
                "device_model": UIDevice.current.model,
                "os_version": UIDevice.current.systemVersion
            ]
        )
        
        // Process payment through Stripe or other processor
        let processedTransaction = try await processPaymentTransaction(transaction)
        
        analyticsService.trackEvent("apple_pay_payment_processed", properties: [
            "transaction_id": processedTransaction.transactionId,
            "amount": amount,
            "currency": currency
        ])
        
        return processedTransaction
    }
    
    // MARK: - Google Pay Integration
    
    /// Check Google Pay availability
    private func checkGooglePayAvailability() -> Bool {
        // In a real implementation, this would check Google Pay availability
        // For demo purposes, return true
        return true
    }
    
    /// Create Google Pay payment request
    func createGooglePayRequest(
        amount: Double,
        currency: String = "USD"
    ) -> [String: Any] {
        
        return [
            "apiVersion": 2,
            "apiVersionMinor": 0,
            "allowedPaymentMethods": [
                [
                    "type": "CARD",
                    "parameters": [
                        "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
                        "allowedCardNetworks": ["VISA", "MASTERCARD", "AMEX"]
                    ],
                    "tokenizationSpecification": [
                        "type": "PAYMENT_GATEWAY",
                        "parameters": [
                            "gateway": "stripe",
                            "gatewayMerchantId": "merchant.com.up2app"
                        ]
                    ]
                ]
            ],
            "transactionInfo": [
                "totalPriceStatus": "FINAL",
                "totalPrice": String(amount),
                "currencyCode": currency,
                "countryCode": "US"
            ],
            "merchantInfo": [
                "merchantName": "Up2 Events"
            ]
        ]
    }
    
    /// Process Google Pay payment
    func processGooglePayPayment(
        paymentData: [String: Any],
        amount: Double,
        currency: String
    ) async throws -> PaymentTransaction {
        
        // Create payment transaction
        let transaction = PaymentTransaction(
            transactionId: UUID().uuidString,
            amount: amount,
            currency: currency,
            paymentMethod: .googlePay,
            status: .processing,
            timestamp: Date(),
            customerEmail: "user@example.com", // Get from user profile
            customerName: "User Name", // Get from user profile
            location: nil,
            country: "US",
            metadata: [
                "payment_method": "google_pay",
                "device_model": UIDevice.current.model,
                "os_version": UIDevice.current.systemVersion
            ]
        )
        
        // Process payment through Stripe or other processor
        let processedTransaction = try await processPaymentTransaction(transaction)
        
        analyticsService.trackEvent("google_pay_payment_processed", properties: [
            "transaction_id": processedTransaction.transactionId,
            "amount": amount,
            "currency": currency
        ])
        
        return processedTransaction
    }
    
    // MARK: - Credit Card Processing
    
    /// Process credit card payment
    func processCreditCardPayment(
        cardData: PaymentData,
        amount: Double,
        currency: String
    ) async throws -> PaymentTransaction {
        
        // Validate card data
        try validateCardData(cardData)
        
        // Create payment transaction
        let transaction = PaymentTransaction(
            transactionId: UUID().uuidString,
            amount: amount,
            currency: currency,
            paymentMethod: .creditCard,
            status: .processing,
            timestamp: Date(),
            customerEmail: "user@example.com", // Get from user profile
            customerName: "User Name", // Get from user profile
            location: nil,
            country: "US",
            metadata: [
                "payment_method": "credit_card",
                "card_brand": cardData.brand ?? "unknown",
                "last4": cardData.last4 ?? "unknown"
            ]
        )
        
        // Process payment through Stripe or other processor
        let processedTransaction = try await processPaymentTransaction(transaction)
        
        analyticsService.trackEvent("credit_card_payment_processed", properties: [
            "transaction_id": processedTransaction.transactionId,
            "amount": amount,
            "currency": currency,
            "card_brand": cardData.brand ?? "unknown"
        ])
        
        return processedTransaction
    }
    
    // MARK: - Validation Methods
    
    private func validatePaymentData(_ paymentData: PaymentData) throws {
        switch paymentData.type {
        case .creditCard:
            try validateCardData(paymentData)
        case .applePay, .googlePay:
            // Digital wallets are validated by their respective systems
            break
        case .paypal:
            // PayPal validation
            break
        case .bankTransfer:
            // Bank transfer validation
            break
        case .invalid:
            throw PaymentMethodError.invalidPaymentData
        }
    }
    
    private func validateCardData(_ cardData: PaymentData) throws {
        // Validate card number
        guard let cardNumber = cardData.cardNumber, !cardNumber.isEmpty else {
            throw PaymentMethodError.invalidCardNumber
        }
        
        // Validate card number format (Luhn algorithm)
        if !isValidCardNumber(cardNumber) {
            throw PaymentMethodError.invalidCardNumber
        }
        
        // Validate expiry date
        guard let expiryMonth = cardData.expiryMonth,
              let expiryYear = cardData.expiryYear else {
            throw PaymentMethodError.invalidExpiryDate
        }
        
        if !isValidExpiryDate(month: expiryMonth, year: expiryYear) {
            throw PaymentMethodError.invalidExpiryDate
        }
        
        // Validate CVV
        guard let cvv = cardData.cvv, !cvv.isEmpty else {
            throw PaymentMethodError.invalidCVV
        }
        
        if !isValidCVV(cvv, for: cardData.brand) {
            throw PaymentMethodError.invalidCVV
        }
    }
    
    private func isValidCardNumber(_ cardNumber: String) -> Bool {
        // Remove spaces and dashes
        let cleaned = cardNumber.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        
        // Check length
        guard cleaned.count >= 13 && cleaned.count <= 19 else { return false }
        
        // Luhn algorithm
        var sum = 0
        var isEven = false
        
        for char in cleaned.reversed() {
            guard let digit = Int(String(char)) else { return false }
            
            if isEven {
                let doubled = digit * 2
                sum += doubled > 9 ? doubled - 9 : doubled
            } else {
                sum += digit
            }
            
            isEven.toggle()
        }
        
        return sum % 10 == 0
    }
    
    private func isValidExpiryDate(month: Int, year: Int) -> Bool {
        let currentDate = Date()
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: currentDate)
        let currentMonth = calendar.component(.month, from: currentDate)
        
        // Check if year is valid
        guard year >= currentYear else { return false }
        
        // If same year, check if month is not in the past
        if year == currentYear && month < currentMonth {
            return false
        }
        
        // Check if month is valid (1-12)
        return month >= 1 && month <= 12
    }
    
    private func isValidCVV(_ cvv: String, for brand: String?) -> Bool {
        let cvvLength = cvv.count
        
        switch brand?.lowercased() {
        case "amex":
            return cvvLength == 4
        default:
            return cvvLength == 3
        }
    }
    
    // MARK: - Storage Methods (Mock Implementation)
    
    private func fetchUserPaymentMethods() async throws -> [UserPaymentMethod] {
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Return mock data
        return [
            UserPaymentMethod(
                id: "pm_apple_pay",
                type: .applePay,
                last4: nil,
                brand: nil,
                expiryMonth: nil,
                expiryYear: nil,
                isDefault: isApplePayAvailable,
                isEnabled: isApplePayAvailable,
                addedAt: Date()
            ),
            UserPaymentMethod(
                id: "pm_credit_card",
                type: .creditCard,
                last4: "4242",
                brand: "Visa",
                expiryMonth: 12,
                expiryYear: 2025,
                isDefault: !isApplePayAvailable,
                isEnabled: true,
                addedAt: Date()
            )
        ]
    }
    
    private func savePaymentMethod(_ paymentMethod: UserPaymentMethod) async throws {
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // In a real implementation, this would save to secure storage
    }
    
    private func saveDefaultPaymentMethod(_ paymentMethod: UserPaymentMethod) async throws {
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // In a real implementation, this would save to secure storage
    }
    
    private func deletePaymentMethod(_ paymentMethod: UserPaymentMethod) async throws {
        // Simulate API call delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // In a real implementation, this would delete from secure storage
    }
    
    private func processPaymentTransaction(_ transaction: PaymentTransaction) async throws -> PaymentTransaction {
        // Simulate payment processing delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Return successful transaction
        var processedTransaction = transaction
        processedTransaction.status = .completed
        
        return processedTransaction
    }
    
    // MARK: - Computed Properties
    
    private var supportedNetworks: [PKPaymentNetwork] {
        return [.visa, .masterCard, .amex, .discover]
    }
}

// MARK: - Payment Method Errors

enum PaymentMethodError: Error, LocalizedError {
    case paymentMethodNotFound
    case cannotRemoveDefaultMethod
    case invalidPaymentData
    case invalidCardNumber
    case invalidExpiryDate
    case invalidCVV
    case paymentMethodNotSupported
    case paymentProcessingFailed
    
    var errorDescription: String? {
        switch self {
        case .paymentMethodNotFound:
            return "Payment method not found"
        case .cannotRemoveDefaultMethod:
            return "Cannot remove default payment method"
        case .invalidPaymentData:
            return "Invalid payment data"
        case .invalidCardNumber:
            return "Invalid card number"
        case .invalidExpiryDate:
            return "Invalid expiry date"
        case .invalidCVV:
            return "Invalid CVV"
        case .paymentMethodNotSupported:
            return "Payment method not supported"
        case .paymentProcessingFailed:
            return "Payment processing failed"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .paymentMethodNotFound:
            return "Please select a different payment method"
        case .cannotRemoveDefaultMethod:
            return "Set another payment method as default first"
        case .invalidPaymentData:
            return "Please check your payment information"
        case .invalidCardNumber:
            return "Please enter a valid card number"
        case .invalidExpiryDate:
            return "Please enter a valid expiry date"
        case .invalidCVV:
            return "Please enter a valid CVV"
        case .paymentMethodNotSupported:
            return "Please try a different payment method"
        case .paymentProcessingFailed:
            return "Please try again or contact support"
        }
    }
}

// MARK: - Extensions

extension PaymentMethodService {
    /// Create a mock instance for testing
    static func mock() -> PaymentMethodService {
        PaymentMethodService(
            analyticsService: .shared,
            errorHandlingService: .shared,
            securityService: .shared,
            hapticService: .shared
        )
    }
} 