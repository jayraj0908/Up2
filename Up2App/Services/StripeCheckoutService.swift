import Foundation
import SwiftUI

@MainActor
class StripeCheckoutService: ObservableObject {
    static let shared = StripeCheckoutService()
    
    @Published var isCheckoutPresented = false
    @Published var isPaymentSuccessful = false
    @Published var currentEvent: Event?
    @Published var isLoading = false
    
    private init() {}
    
    func initiateCheckout(for event: Event) {
        self.currentEvent = event
        self.isCheckoutPresented = true
    }
    
    func processPayment(completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        // Simulate payment processing
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isLoading = false
            self.isPaymentSuccessful = true
            self.isCheckoutPresented = false
            completion(true)
        }
    }
    
    func resetPaymentState() {
        isPaymentSuccessful = false
        currentEvent = nil
    }
} 