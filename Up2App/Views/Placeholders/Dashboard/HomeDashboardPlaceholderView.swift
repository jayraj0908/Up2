import SwiftUI

struct HomeDashboardPlaceholderView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Up2Card {
                    VStack(spacing: 16) {
                        Text("Home Dashboard")
                            .font(Up2Typography.heading1)
                            .foregroundColor(Up2Colors.primary)
                        Text("This is a placeholder for the main dashboard screen.")
                            .font(Up2Typography.bodyMedium)
                            .foregroundColor(Up2Colors.textSecondary)
                        Text("[Epic 0 Placeholder]")
                            .font(Up2Typography.caption)
                            .foregroundColor(Up2Colors.textTertiary)
                    }
                    .padding()
                }
                Up2Card {
                    VStack(spacing: 8) {
                        Text("Quick Actions")
                            .font(Up2Typography.heading3)
                            .foregroundColor(Up2Colors.primary)
                        Text("(Placeholder for quick actions)")
                            .font(Up2Typography.bodyMedium)
                            .foregroundColor(Up2Colors.textSecondary)
                    }
                    .padding()
                }
                Up2Card {
                    VStack(spacing: 8) {
                        Text("Notifications")
                            .font(Up2Typography.heading3)
                            .foregroundColor(Up2Colors.primary)
                        Text("(Placeholder for notifications)")
                            .font(Up2Typography.bodyMedium)
                            .foregroundColor(Up2Colors.textSecondary)
                    }
                    .padding()
                }
            }
            .padding()
        }
        .background(Up2Colors.background.ignoresSafeArea())
    }
}

#Preview {
    HomeDashboardPlaceholderView()
} 