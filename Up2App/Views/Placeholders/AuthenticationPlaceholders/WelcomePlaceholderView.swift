import SwiftUI

struct WelcomePlaceholderView: View {
    var body: some View {
        VStack(spacing: 32) {
            Up2Card {
                VStack(spacing: 16) {
                    Text("Welcome to Up2App!")
                        .font(Up2Typography.heading1)
                        .foregroundColor(Up2Colors.primary)
                    Text("This is a placeholder for the onboarding/welcome screen.")
                        .font(Up2Typography.bodyMedium)
                        .foregroundColor(Up2Colors.textSecondary)
                    Text("[Epic 0 Placeholder]")
                        .font(Up2Typography.caption)
                        .foregroundColor(Up2Colors.textTertiary)
                }
                .padding()
            }
            Up2Button("Continue to Registration/Login", style: .primary) {}
        }
        .padding()
        .background(Up2Colors.background.ignoresSafeArea())
    }
}

#Preview {
    WelcomePlaceholderView()
} 