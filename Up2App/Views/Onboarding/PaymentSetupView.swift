import SwiftUI

struct PaymentSetupView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            VStack(spacing: Up2Spacing.xxxl) {
                // Header
                headerView
                
                // Content
                VStack(spacing: Up2Spacing.xl) {
                    Image(systemName: "creditcard")
                        .font(.system(size: 80))
                        .foregroundColor(Up2Colors.accent)
                    
                    Text("Payment Setup")
                        .font(Up2Typography.displayMedium)
                        .foregroundColor(Up2Colors.textInverse)
                        .multilineTextAlignment(.center)
                    
                    Text("Set up payment methods to start selling tickets and managing your events.")
                        .font(Up2Typography.bodyMedium)
                        .foregroundColor(Up2Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Up2Spacing.xl)
                    
                    // Placeholder for payment setup
                    VStack(spacing: Up2Spacing.lg) {
                        paymentMethodCard
                        paymentMethodCard
                        paymentMethodCard
                    }
                }
                
                Spacer()
                
                // Continue button
                Up2Button("Continue", style: .primary) {
                    appStateManager.updateSoftGateState(.complete)
                }
            }
            .padding(.horizontal, Up2Spacing.screenEdge)
            .padding(.vertical, Up2Spacing.xl)
        }
    }
    
    // MARK: - Background View
    private var backgroundView: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.1, green: 0.0, blue: 0.3),
                    Color(red: 0.3, green: 0.0, blue: 0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Color(red: 0.0, green: 0.2, blue: 0.4).opacity(0.1)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: Up2Spacing.lg) {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .shadow(color: Up2Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
            
            Text("Almost Done!")
                .font(Up2Typography.displayMedium)
                .foregroundColor(Up2Colors.textInverse)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Up2Spacing.xxxl)
    }
    
    // MARK: - Payment Method Card
    private var paymentMethodCard: some View {
        HStack(spacing: Up2Spacing.lg) {
            Image(systemName: "plus.circle")
                .font(.system(size: 24))
                .foregroundColor(Up2Colors.accent)
            
            Text("Add Payment Method")
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2Colors.textInverse)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 16))
                .foregroundColor(Up2Colors.textSecondary)
        }
        .padding(Up2Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Up2Colors.primary.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    PaymentSetupView()
        .environmentObject(AppStateManager())
} 