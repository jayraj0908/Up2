import SwiftUI

/// Payment confirmation view shown after successful payment
struct PaymentConfirmationView: View {
    
    // MARK: - Environment
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appStateManager: AppStateManager
    
    // MARK: - Properties
    
    let confirmation: PaymentConfirmation
    
    // MARK: - State
    
    @State private var showingReceipt = false
    @State private var showingEventDetails = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundView
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Success Header
                        successHeaderSection
                        
                        // Payment Details
                        paymentDetailsSection
                        
                        // Confirmation Code
                        confirmationCodeSection
                        
                        // Next Steps
                        nextStepsSection
                        
                        // Action Buttons
                        actionButtonsSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 24)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Background View
    
    private var backgroundView: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.black,
                Color(red: 0.1, green: 0.0, blue: 0.3),
                Color(red: 0.3, green: 0.0, blue: 0.4)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Success Header Section
    
    private var successHeaderSection: some View {
        VStack(spacing: 24) {
            // Success icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
            }
            
            // Success message
            VStack(spacing: 8) {
                Text("Payment Successful!")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Your ticket has been purchased successfully")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Payment Details Section
    
    private var paymentDetailsSection: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("Payment Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Payment details card
            VStack(spacing: 12) {
                DetailRow(
                    title: "Transaction ID",
                    value: confirmation.transactionId,
                    isCopyable: true
                )
                
                DetailRow(
                    title: "Amount Paid",
                    value: confirmation.formattedAmount,
                    isCopyable: false
                )
                
                DetailRow(
                    title: "Payment Method",
                    value: confirmation.paymentMethod.displayName,
                    isCopyable: false
                )
                
                DetailRow(
                    title: "Date & Time",
                    value: formatDate(confirmation.processedAt),
                    isCopyable: false
                )
                
                DetailRow(
                    title: "Customer Email",
                    value: confirmation.customerEmail,
                    isCopyable: true
                )
            }
            .padding(20)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Confirmation Code Section
    
    private var confirmationCodeSection: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("Confirmation Code")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Confirmation code card
            VStack(spacing: 12) {
                Text("Save this code for your records")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                
                Text(confirmation.confirmationCode)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                
                Button("Copy Code") {
                    copyToClipboard(confirmation.confirmationCode)
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding(20)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Next Steps Section
    
    private var nextStepsSection: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("What's Next?")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            
            // Next steps list
            VStack(spacing: 12) {
                NextStepRow(
                    icon: "envelope.fill",
                    title: "Check Your Email",
                    description: "You'll receive a confirmation email with your ticket details"
                )
                
                NextStepRow(
                    icon: "calendar",
                    title: "Add to Calendar",
                    description: "Add the event to your calendar to get reminders"
                )
                
                NextStepRow(
                    icon: "person.2.fill",
                    title: "Share with Friends",
                    description: "Invite friends to join you at the event"
                )
                
                NextStepRow(
                    icon: "location.fill",
                    title: "Get Directions",
                    description: "Plan your route to the event venue"
                )
            }
        }
    }
    
    // MARK: - Action Buttons Section
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Primary action button
            Button(action: {
                showingEventDetails = true
            }) {
                HStack {
                    Image(systemName: "ticket.fill")
                        .font(.title3)
                    
                    Text("View Event Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            
            // Secondary action buttons
            HStack(spacing: 12) {
                // Receipt button
                Button(action: {
                    showingReceipt = true
                }) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .font(.subheadline)
                        
                        Text("Receipt")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
                }
                
                // Done button
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "checkmark")
                            .font(.subheadline)
                        
                        Text("Done")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        
        // Show feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

// MARK: - Supporting Views

/// Detail row for payment information
struct DetailRow: View {
    let title: String
    let value: String
    let isCopyable: Bool
    
    @State private var showingCopiedFeedback = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            if isCopyable {
                Button(action: {
                    copyToClipboard(value)
                    showingCopiedFeedback = true
                    
                    // Hide feedback after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showingCopiedFeedback = false
                    }
                }) {
                    Image(systemName: showingCopiedFeedback ? "checkmark" : "doc.on.doc")
                        .font(.caption)
                        .foregroundColor(showingCopiedFeedback ? .green : .blue)
                }
            }
        }
    }
    
    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
}

/// Next step row for instructions
struct NextStepRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    PaymentConfirmationView(
        confirmation: PaymentConfirmation(
            transactionId: "txn_123456789",
            paymentSessionId: "sess_123456789",
            eventId: "event_123",
            ticketId: "ticket_456",
            amount: 29.99,
            currency: "USD",
            paymentMethod: .creditCard,
            customerEmail: "test@example.com",
            customerName: "Test User",
            processedAt: Date(),
            receiptUrl: "https://receipt.stripe.com/test/123",
            confirmationCode: "UP2X8K9M"
        )
    )
    .environmentObject(AppStateManager.shared)
} 