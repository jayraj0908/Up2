import SwiftUI

struct ForgotPasswordPlaceholderView: View {
    var body: some View {
        VStack(spacing: 32) {
            Up2Card {
                VStack(spacing: 16) {
                    Text("Forgot Password")
                        .font(Up2Typography.heading2)
                        .foregroundColor(Up2Colors.primary)
                    Text("This is a placeholder for the forgot password flow.")
                        .font(Up2Typography.bodyMedium)
                        .foregroundColor(Up2Colors.textSecondary)
                    Text("[Epic 0 Placeholder]")
                        .font(Up2Typography.caption)
                        .foregroundColor(Up2Colors.textTertiary)
                }
                .padding()
            }
            Up2Button("Back to Login", style: .secondary) {}
        }
        .padding()
        .background(Up2Colors.background.ignoresSafeArea())
    }
}

#Preview {
    ForgotPasswordPlaceholderView()
} 