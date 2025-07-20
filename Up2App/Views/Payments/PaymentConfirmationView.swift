import SwiftUI

struct PaymentConfirmationView: View {
    let event: Event
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var checkoutService: StripeCheckoutService
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Success Header
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        
                        Text("Payment Successful!")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Your ticket has been purchased successfully")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Event Details
                    VStack(spacing: 12) {
                        Text(event.title)
                            .font(.headline)
                            .multilineTextAlignment(.center)
                        
                        Text("Ticket Price: $\(event.ticketPrice, specifier: "%.2f")")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        
                        Text("Date: \(event.date, style: .date)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    
                    // Refund Information Block
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("Refund Policy")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Full refund available up to 24 hours before the event")
                            Text("• 50% refund available up to 2 hours before the event")
                            Text("• No refunds within 2 hours of event start")
                            Text("• Contact support for special circumstances")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer(minLength: 40)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button("View Event Details") {
                            // Navigate back to event details
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        
                        Button("Done") {
                            checkoutService.resetPaymentState()
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 20)
            }
            .navigationBarHidden(true)
        }
    }
} 