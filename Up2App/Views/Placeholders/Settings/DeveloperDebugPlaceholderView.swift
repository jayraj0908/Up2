import SwiftUI

struct DeveloperDebugPlaceholderView: View {
    var body: some View {
        VStack(spacing: 32) {
            Up2Card {
                VStack(spacing: 16) {
                    Text("Developer / Debug")
                        .font(Up2Typography.heading2)
                        .foregroundColor(Up2Colors.primary)
                    Text("This is a placeholder for developer/debug screens.")
                        .font(Up2Typography.bodyMedium)
                        .foregroundColor(Up2Colors.textSecondary)
                    Text("[Epic 0 Placeholder]")
                        .font(Up2Typography.caption)
                        .foregroundColor(Up2Colors.textTertiary)
                }
                .padding()
            }
        }
        .padding()
        .background(Up2Colors.background.ignoresSafeArea())
    }
}

#Preview {
    DeveloperDebugPlaceholderView()
} 