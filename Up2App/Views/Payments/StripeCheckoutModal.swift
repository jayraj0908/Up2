import SwiftUI

struct StripeCheckoutModal: View {
    @ObservedObject var checkoutService: StripeCheckoutService
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue)
                    
                    Text("Stripe Checkout")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Secure Payment Processing")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Event Details
                if let event = checkoutService.currentEvent {
                    VStack(spacing: 12) {
                        Text(event.title)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Text("Ticket Price: $\(event.ticketPrice, specifier: "%.2f")")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                
                Spacer()
                
                // Payment Button
                Button(action: {
                    checkoutService.processPayment { success in
                        if success {
                            dismiss()
                        }
                    }
                }) {
                    HStack {
                        if checkoutService.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "lock.fill")
                            Text("Pay Securely")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(checkoutService.isLoading)
                
                // Cancel Button
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.secondary)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 20)
            .navigationBarHidden(true)
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
} 