import XCTest
import Combine
@testable import Up2App

/// Integration tests for payment flow functionality
final class PaymentFlowTests: XCTestCase {
    
    var paymentService: PaymentProcessingService!
    var stripeService: StripeIntegrationService!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        paymentService = PaymentProcessingService.mock()
        stripeService = StripeIntegrationService.mock()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        paymentService = nil
        stripeService = nil
        cancellables = nil
    }
    
    // MARK: - Payment Session Tests
    
    func testCreatePaymentSession() async throws {
        // Given
        let eventId = "event_123"
        let ticketId = "ticket_456"
        let amount = 29.99
        let customerEmail = "test@example.com"
        
        // When
        let session = try await paymentService.startPaymentFlow(
            eventId: eventId,
            ticketId: ticketId,
            amount: amount,
            currency: "USD",
            customerEmail: customerEmail,
            customerName: "Test User"
        )
        
        // Then
        XCTAssertNotNil(session)
        XCTAssertEqual(session.eventId, eventId)
        XCTAssertEqual(session.ticketId, ticketId)
        XCTAssertEqual(session.amount, amount)
        XCTAssertEqual(session.customerEmail, customerEmail)
        XCTAssertEqual(session.status, .created)
        XCTAssertFalse(session.isExpired)
        XCTAssertGreaterThan(session.timeRemaining, 0)
    }
    
    func testPaymentSessionExpiration() async throws {
        // Given
        let session = PaymentSession.mock()
        
        // When - Wait for session to expire (in real test, you'd mock the time)
        // For now, we'll test the expiration logic
        let isExpired = session.isExpired
        let timeRemaining = session.timeRemaining
        
        // Then
        XCTAssertFalse(isExpired) // Should not be expired immediately
        XCTAssertGreaterThan(timeRemaining, 0) // Should have time remaining
    }
    
    // MARK: - Payment Method Tests
    
    func testLoadPaymentMethods() async throws {
        // When
        let methods = try await paymentService.getAvailablePaymentMethods()
        
        // Then
        XCTAssertFalse(methods.isEmpty)
        XCTAssertTrue(methods.contains { $0.type == .applePay })
        XCTAssertTrue(methods.contains { $0.type == .creditCard })
        
        // Check that at least one method is enabled
        let enabledMethods = methods.filter { $0.isEnabled }
        XCTAssertFalse(enabledMethods.isEmpty)
    }
    
    func testSelectPaymentMethod() async throws {
        // Given
        let methods = try await paymentService.getAvailablePaymentMethods()
        let creditCardMethod = methods.first { $0.type == .creditCard }!
        
        // When
        paymentService.selectPaymentMethod(creditCardMethod)
        
        // Then
        XCTAssertEqual(paymentService.selectedPaymentMethod?.id, creditCardMethod.id)
        XCTAssertEqual(paymentService.currentFlowState, .processingPayment)
    }
    
    // MARK: - Payment Processing Tests
    
    func testProcessPayment() async throws {
        // Given
        let session = try await paymentService.startPaymentFlow(
            eventId: "event_123",
            ticketId: "ticket_456",
            amount: 29.99,
            currency: "USD",
            customerEmail: "test@example.com"
        )
        
        let methods = try await paymentService.getAvailablePaymentMethods()
        let creditCardMethod = methods.first { $0.type == .creditCard }!
        paymentService.selectPaymentMethod(creditCardMethod)
        
        // When
        let confirmation = try await paymentService.processPayment()
        
        // Then
        XCTAssertNotNil(confirmation)
        XCTAssertEqual(confirmation.paymentSessionId, session.id)
        XCTAssertEqual(confirmation.amount, session.amount)
        XCTAssertEqual(confirmation.currency, session.currency)
        XCTAssertEqual(confirmation.customerEmail, session.customerEmail)
        XCTAssertFalse(confirmation.transactionId.isEmpty)
        XCTAssertFalse(confirmation.confirmationCode.isEmpty)
        XCTAssertEqual(paymentService.currentFlowState, .completed)
    }
    
    func testPaymentFlowStateTransitions() async throws {
        // Given
        var stateChanges: [PaymentFlowState] = []
        
        paymentService.$currentFlowState
            .sink { state in
                stateChanges.append(state)
            }
            .store(in: &cancellables)
        
        // When
        let _ = try await paymentService.startPaymentFlow(
            eventId: "event_123",
            ticketId: "ticket_456",
            amount: 29.99,
            currency: "USD",
            customerEmail: "test@example.com"
        )
        
        // Then
        XCTAssertTrue(stateChanges.contains(.loading))
        XCTAssertTrue(stateChanges.contains(.selectingPaymentMethod))
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidAmountError() async throws {
        // When & Then
        do {
            let _ = try await paymentService.startPaymentFlow(
                eventId: "event_123",
                ticketId: "ticket_456",
                amount: -10.0, // Invalid amount
                currency: "USD",
                customerEmail: "test@example.com"
            )
            XCTFail("Should throw error for invalid amount")
        } catch {
            XCTAssertTrue(error is PaymentError)
            if case .invalidAmount = error as? PaymentError {
                // Expected error
            } else {
                XCTFail("Expected invalidAmount error")
            }
        }
    }
    
    func testInvalidEmailError() async throws {
        // When & Then
        do {
            let _ = try await paymentService.startPaymentFlow(
                eventId: "event_123",
                ticketId: "ticket_456",
                amount: 29.99,
                currency: "USD",
                customerEmail: "invalid-email" // Invalid email
            )
            XCTFail("Should throw error for invalid email")
        } catch {
            XCTAssertTrue(error is PaymentError)
            if case .invalidConfiguration = error as? PaymentError {
                // Expected error
            } else {
                XCTFail("Expected invalidConfiguration error")
            }
        }
    }
    
    func testPaymentRetry() async throws {
        // Given
        let session = try await paymentService.startPaymentFlow(
            eventId: "event_123",
            ticketId: "ticket_456",
            amount: 29.99,
            currency: "USD",
            customerEmail: "test@example.com"
        )
        
        let methods = try await paymentService.getAvailablePaymentMethods()
        let creditCardMethod = methods.first { $0.type == .creditCard }!
        paymentService.selectPaymentMethod(creditCardMethod)
        
        // When
        let confirmation = try await paymentService.retryPayment()
        
        // Then
        XCTAssertNotNil(confirmation)
        XCTAssertEqual(confirmation.paymentSessionId, session.id)
        XCTAssertEqual(paymentService.currentFlowState, .completed)
    }
    
    // MARK: - Utility Tests
    
    func testFormattedAmount() {
        // Given
        let session = PaymentSession.mock(amount: 29.99)
        
        // When
        let formatted = session.amount.formatted(.currency(code: session.currency))
        
        // Then
        XCTAssertTrue(formatted.contains("29.99") || formatted.contains("$29.99"))
    }
    
    func testPaymentMethodDisplayName() {
        // Given
        let creditCardMethod = UserPaymentMethod(
            id: "pm_123",
            type: .creditCard,
            last4: "4242",
            brand: "Visa",
            expiryMonth: 12,
            expiryYear: 2025,
            isDefault: false,
            isEnabled: true,
            addedAt: Date()
        )
        
        // When
        let displayName = creditCardMethod.displayName
        
        // Then
        XCTAssertTrue(displayName.contains("Visa"))
        XCTAssertTrue(displayName.contains("4242"))
    }
    
    func testTicketAvailability() {
        // Given
        let availableTicket = Ticket.mock()
        let soldOutTicket = Ticket(
            id: "ticket_456",
            eventId: "event_123",
            name: "Sold Out Ticket",
            description: nil,
            price: 29.99,
            currency: "USD",
            quantity: 100,
            availableQuantity: 0, // Sold out
            isRefundable: true,
            refundPolicy: nil,
            validFrom: Date(),
            validUntil: Date().addingTimeInterval(7 * 24 * 60 * 60)
        )
        
        // When & Then
        XCTAssertTrue(availableTicket.isAvailable)
        XCTAssertFalse(soldOutTicket.isAvailable)
    }
    
    // MARK: - Performance Tests
    
    func testPaymentSessionCreationPerformance() throws {
        measure {
            let expectation = XCTestExpectation(description: "Payment session creation")
            
            Task {
                do {
                    let _ = try await paymentService.startPaymentFlow(
                        eventId: "event_123",
                        ticketId: "ticket_456",
                        amount: 29.99,
                        currency: "USD",
                        customerEmail: "test@example.com"
                    )
                    expectation.fulfill()
                } catch {
                    XCTFail("Payment session creation failed: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    func testPaymentProcessingPerformance() throws {
        measure {
            let expectation = XCTestExpectation(description: "Payment processing")
            
            Task {
                do {
                    let session = try await paymentService.startPaymentFlow(
                        eventId: "event_123",
                        ticketId: "ticket_456",
                        amount: 29.99,
                        currency: "USD",
                        customerEmail: "test@example.com"
                    )
                    
                    let methods = try await paymentService.getAvailablePaymentMethods()
                    let creditCardMethod = methods.first { $0.type == .creditCard }!
                    paymentService.selectPaymentMethod(creditCardMethod)
                    
                    let _ = try await paymentService.processPayment()
                    expectation.fulfill()
                } catch {
                    XCTFail("Payment processing failed: \(error)")
                }
            }
            
            wait(for: [expectation], timeout: 10.0)
        }
    }
}

// MARK: - Test Helpers

extension PaymentFlowTests {
    
    /// Wait for async operation with timeout
    func waitForAsyncOperation<T>(_ operation: @escaping () async throws -> T, timeout: TimeInterval = 5.0) throws -> T {
        let expectation = XCTestExpectation(description: "Async operation")
        var result: T?
        var error: Error?
        
        Task {
            do {
                result = try await operation()
                expectation.fulfill()
            } catch {
                error = error
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: timeout)
        
        if let error = error {
            throw error
        }
        
        guard let result = result else {
            throw NSError(domain: "TestError", code: -1, userInfo: [NSLocalizedDescriptionKey: "No result returned"])
        }
        
        return result
    }
} 