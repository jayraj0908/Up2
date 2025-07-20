import SwiftUI

struct PromoCodeCreationView: View {
    let event: HostEvent
    @StateObject private var viewModel = PromoCodeCreationViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var code = ""
    @State private var discount = 10.0
    @State private var maxUses = 50
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Event Info
                    eventInfoSection
                    
                    // Promo Code Form
                    promoCodeForm
                    
                    // Preview
                    previewSection
                    
                    Spacer()
                    
                    // Create Button
                    createButton
                }
                .padding()
            }
            .background(Up2Colors.background.ignoresSafeArea())
            .navigationTitle("Create Promo Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Up2Colors.textSecondary)
                }
            }
        }
        .alert("Promo Code Created!", isPresented: $showingConfirmation) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your promo code '\(code)' has been created successfully.")
        }
    }
    
    // MARK: - Event Info Section
    private var eventInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Event Details")
                .font(Up2Typography.heading3)
                .foregroundColor(Up2Colors.textPrimary)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(Up2Typography.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(Up2Colors.textPrimary)
                    
                    Text(event.venueName)
                        .font(Up2Typography.caption)
                        .foregroundColor(Up2Colors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(String(format: "%.0f", event.price))")
                        .font(Up2Typography.bodyMedium)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                    
                    Text("Original Price")
                        .font(Up2Typography.caption)
                        .foregroundColor(Up2Colors.textSecondary)
                }
            }
            .padding()
            .background(Up2Colors.surface)
            .cornerRadius(8)
        }
    }
    
    // MARK: - Promo Code Form
    private var promoCodeForm: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Promo Code Details")
                .font(Up2Typography.heading3)
                .foregroundColor(Up2Colors.textPrimary)
            
            // Code Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Promo Code")
                    .font(Up2Typography.bodyMedium)
                    .foregroundColor(Up2Colors.textPrimary)
                
                TextField("e.g., SUMMER20", text: $code)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .textInputAutocapitalization(.characters)
                    .onChange(of: code) { _, newValue in
                        code = newValue.uppercased()
                    }
                
                Text("Enter a unique code (letters and numbers only)")
                    .font(Up2Typography.caption)
                    .foregroundColor(Up2Colors.textSecondary)
            }
            
            // Discount Slider
            VStack(alignment: .leading, spacing: 8) {
                Text("Discount: \(Int(discount))%")
                    .font(Up2Typography.bodyMedium)
                    .foregroundColor(Up2Colors.textPrimary)
                
                Slider(value: $discount, in: 5...50, step: 5)
                    .accentColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                
                HStack {
                    Text("5%")
                        .font(Up2Typography.caption)
                        .foregroundColor(Up2Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("50%")
                        .font(Up2Typography.caption)
                        .foregroundColor(Up2Colors.textSecondary)
                }
            }
            
            // Max Uses
            VStack(alignment: .leading, spacing: 8) {
                Text("Maximum Uses")
                    .font(Up2Typography.bodyMedium)
                    .foregroundColor(Up2Colors.textPrimary)
                
                HStack {
                    Button("-") {
                        if maxUses > 10 {
                            maxUses -= 10
                        }
                    }
                    .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                    .frame(width: 40, height: 40)
                    .background(Up2Colors.surface)
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    Text("\(maxUses)")
                        .font(Up2Typography.heading3)
                        .fontWeight(.bold)
                        .foregroundColor(Up2Colors.textPrimary)
                        .frame(minWidth: 60)
                    
                    Spacer()
                    
                    Button("+") {
                        maxUses += 10
                    }
                    .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                    .frame(width: 40, height: 40)
                    .background(Up2Colors.surface)
                    .cornerRadius(8)
                }
                
                Text("Number of times this code can be used")
                    .font(Up2Typography.caption)
                    .foregroundColor(Up2Colors.textSecondary)
            }
        }
    }
    
    // MARK: - Preview Section
    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preview")
                .font(Up2Typography.heading3)
                .foregroundColor(Up2Colors.textPrimary)
            
            VStack(spacing: 12) {
                // Original Price
                HStack {
                    Text("Original Price")
                        .foregroundColor(Up2Colors.textSecondary)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.0f", event.price))")
                        .strikethrough()
                        .foregroundColor(Up2Colors.textSecondary)
                }
                
                // Discount
                HStack {
                    Text("Discount (\(Int(discount))%)")
                        .foregroundColor(.green)
                    
                    Spacer()
                    
                    Text("-$\(String(format: "%.0f", event.price * discount / 100))")
                        .foregroundColor(.green)
                        .fontWeight(.bold)
                }
                
                Divider()
                
                // Final Price
                HStack {
                    Text("Final Price")
                        .fontWeight(.bold)
                        .foregroundColor(Up2Colors.textPrimary)
                    
                    Spacer()
                    
                    Text("$\(String(format: "%.0f", event.price * (1 - discount / 100)))")
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                }
            }
            .padding()
            .background(Up2Colors.surface)
            .cornerRadius(8)
        }
    }
    
    // MARK: - Create Button
    private var createButton: some View {
        Button(action: createPromoCode) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .foregroundColor(.white)
                }
                
                Text(viewModel.isLoading ? "Creating..." : "Create Promo Code")
                    .font(Up2Typography.buttonMedium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                isFormValid && !viewModel.isLoading ?
                Color(red: 0.0, green: 0.48, blue: 1.0) :
                Color.gray
            )
            .cornerRadius(12)
        }
        .disabled(!isFormValid || viewModel.isLoading)
    }
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        !code.isEmpty && code.count >= 3 && discount > 0 && maxUses > 0
    }
    
    // MARK: - Actions
    private func createPromoCode() {
        guard isFormValid else { return }
        
        Task {
            await viewModel.createPromoCode(
                eventId: event.id,
                code: code,
                discount: discount,
                maxUses: maxUses
            )
            
            if viewModel.errorMessage == nil {
                showingConfirmation = true
            }
        }
    }
}

// MARK: - View Model

@MainActor
class PromoCodeCreationViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let hostService = EventHostService.shared
    
    func createPromoCode(eventId: UUID, code: String, discount: Double, maxUses: Int) async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await hostService.createPromoCode(
                eventId: eventId,
                code: code,
                discount: discount,
                maxUses: maxUses
            )
        } catch {
            errorMessage = "Failed to create promo code: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

#Preview {
    PromoCodeCreationView(event: HostEvent(
        id: UUID(),
        title: "Summer Beach Party",
        venueName: "Santa Monica Beach",
        date: Date().addingTimeInterval(86400 * 7),
        rsvpCount: 45,
        price: 25.0,
        status: .upcoming,
        imageURL: nil
    ))
} 