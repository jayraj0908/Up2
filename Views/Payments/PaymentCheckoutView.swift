import SwiftUI
import Stripe

/// Main payment checkout view for ticket purchases
struct PaymentCheckoutView: View {
    
    // MARK: - Environment
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appStateManager: AppStateManager
    
    // MARK: - View Models
    
    @StateObject private var paymentService = PaymentProcessingService()
    @StateObject private var viewModel = PaymentCheckoutViewModel()
    
    // MARK: - Properties
    
    let eventId: String
    let ticketId: String
    let amount: Double
    let currency: String
    let eventTitle: String
    let ticketName: String
    
    // MARK: - State
    
    @State private var showingPaymentConfirmation = false
    @State private var showingErrorAlert = false
    @State private var selectedPaymentMethod: UserPaymentMethod?
    @State private var availablePaymentMethods: [UserPaymentMethod] = []
    @State private var isLoading = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundView
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 24) {
                            // Ticket Summary
                            ticketSummarySection
                            
                            // Payment Methods
                            paymentMethodsSection
                            
                            // Payment Button
                            paymentButtonSection
                            
                            // Security Info
                            securityInfoSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 24)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                setupPaymentFlow()
            }
            .onChange(of: paymentService.currentFlowState) { state in
                handleFlowStateChange(state)
            }
            .sheet(isPresented: $showingPaymentConfirmation) {
                PaymentConfirmationView(confirmation: paymentService.paymentConfirmation!)
            }
            .alert("Payment Error", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(paymentService.lastError?.errorDescription ?? "An error occurred")
            }
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
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Navigation bar
            HStack {
                Button(action: {
                    paymentService.cancelPayment()
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                Text("Checkout")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Timer for session expiry
                if paymentService.isPaymentFlowActive {
                    SessionTimerView(timeRemaining: paymentService.sessionTimeRemaining)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Progress indicator
            PaymentProgressView(currentState: paymentService.currentFlowState)
        }
    }
    
    // MARK: - Ticket Summary Section
    
    private var ticketSummarySection: some View {
        VStack(spacing: 16) {
            // Event info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(eventTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Text(ticketName)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Amount
                VStack(alignment: .trailing, spacing: 4) {
                    Text(paymentService.formattedAmount)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1)
            
            // Price breakdown
            VStack(spacing: 8) {
                HStack {
                    Text("Ticket Price")
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text(paymentService.formattedAmount)
                        .foregroundColor(.white)
                }
                
                HStack {
                    Text("Service Fee")
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("$0.00")
                        .foregroundColor(.white.opacity(0.6))
                }
                
                HStack {
                    Text("Tax")
                        .foregroundColor(.white.opacity(0.8))
                    Spacer()
                    Text("$0.00")
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .font(.subheadline)
        }
        .padding(20)
        .background(Color.white.opacity(0.1))
        .cornerRadius(16)
    }
    
    // MARK: - Payment Methods Section
    
    private var paymentMethodsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Payment Method")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if isLoading {
                HStack {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Text("Loading payment methods...")
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(availablePaymentMethods) { method in
                        PaymentMethodRow(
                            method: method,
                            isSelected: selectedPaymentMethod?.id == method.id,
                            onSelect: {
                                selectedPaymentMethod = method
                                paymentService.selectPaymentMethod(method)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Payment Button Section
    
    private var paymentButtonSection: some View {
        VStack(spacing: 16) {
            // Pay button
            Button(action: {
                Task {
                    await processPayment()
                }
            }) {
                HStack {
                    if paymentService.currentFlowState == .processingPayment {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "creditcard.fill")
                            .font(.title3)
                    }
                    
                    Text(paymentService.currentFlowState == .processingPayment ? "Processing..." : "Pay \(paymentService.formattedAmount)")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    LinearGradient(
                        colors: paymentService.canProcessPayment ? [Color.blue, Color.purple] : [Color.gray],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
            }
            .disabled(!paymentService.canProcessPayment || paymentService.currentFlowState == .processingPayment)
            
            // Terms and conditions
            Text("By completing this purchase, you agree to our Terms of Service and Privacy Policy")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Security Info Section
    
    private var securityInfoSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(.green)
                
                Text("Secure Payment")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            
            Text("Your payment information is encrypted and secure. We never store your card details.")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Helper Methods
    
    private func setupPaymentFlow() {
        Task {
            isLoading = true
            
            do {
                // Start payment flow
                let session = try await paymentService.startPaymentFlow(
                    eventId: eventId,
                    ticketId: ticketId,
                    amount: amount,
                    currency: currency,
                    customerEmail: appStateManager.currentUser?.email ?? "",
                    customerName: appStateManager.currentUser?.displayName
                )
                
                // Load available payment methods
                availablePaymentMethods = try await paymentService.getAvailablePaymentMethods()
                
                // Set default payment method
                if let defaultMethod = availablePaymentMethods.first(where: { $0.isDefault }) {
                    selectedPaymentMethod = defaultMethod
                }
                
            } catch {
                showingErrorAlert = true
            }
            
            isLoading = false
        }
    }
    
    private func processPayment() async {
        do {
            let confirmation = try await paymentService.processPayment()
            showingPaymentConfirmation = true
        } catch {
            showingErrorAlert = true
        }
    }
    
    private func handleFlowStateChange(_ state: PaymentFlowState) {
        switch state {
        case .completed:
            // Payment completed successfully
            break
        case .failed(let error):
            showingErrorAlert = true
        case .cancelled:
            presentationMode.wrappedValue.dismiss()
        default:
            break
        }
    }
}

// MARK: - Supporting Views

/// Payment method selection row
struct PaymentMethodRow: View {
    let method: UserPaymentMethod
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Payment method icon
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                    .frame(width: 30)
                
                // Payment method details
                VStack(alignment: .leading, spacing: 2) {
                    Text(method.displayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    if let expiry = method.expiryDisplay {
                        Text("Expires \(expiry)")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue.opacity(0.2) : Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!method.isEnabled)
        .opacity(method.isEnabled ? 1.0 : 0.5)
    }
    
    private var iconName: String {
        switch method.type {
        case .applePay:
            return "applelogo"
        case .googlePay:
            return "creditcard.fill"
        case .creditCard:
            return "creditcard.fill"
        case .paypal:
            return "creditcard.fill"
        case .bankTransfer:
            return "building.columns.fill"
        case .invalid:
            return "exclamationmark.triangle.fill"
        }
    }
}

/// Payment progress indicator
struct PaymentProgressView: View {
    let currentState: PaymentFlowState
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(progressSteps, id: \.self) { step in
                Circle()
                    .fill(stepColor(for: step))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.3), value: currentState)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var progressSteps: [String] {
        ["loading", "selecting", "processing", "completed"]
    }
    
    private func stepColor(for step: String) -> Color {
        let stepIndex = progressSteps.firstIndex(of: step) ?? 0
        let currentIndex = currentStepIndex
        
        if stepIndex <= currentIndex {
            return .blue
        } else {
            return .white.opacity(0.3)
        }
    }
    
    private var currentStepIndex: Int {
        switch currentState {
        case .idle, .loading:
            return 0
        case .selectingPaymentMethod:
            return 1
        case .processingPayment, .confirmingPayment:
            return 2
        case .completed:
            return 3
        case .failed, .cancelled:
            return 0
        }
    }
}

/// Session timer view
struct SessionTimerView: View {
    let timeRemaining: TimeInterval
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock")
                .font(.caption)
                .foregroundColor(.orange)
            
            Text(timeString)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.orange)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.2))
        .cornerRadius(8)
    }
    
    private var timeString: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Preview

#Preview {
    PaymentCheckoutView(
        eventId: "event_123",
        ticketId: "ticket_456",
        amount: 29.99,
        currency: "USD",
        eventTitle: "Summer Music Festival",
        ticketName: "General Admission"
    )
    .environmentObject(AppStateManager.shared)
} 