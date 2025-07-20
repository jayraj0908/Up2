import SwiftUI

struct EventChatPlaceholderView: View {
    var body: some View {
        VStack(spacing: 32) {
            Up2Card {
                VStack(spacing: 16) {
                    Text("Event Chat")
                        .font(Up2Typography.heading2)
                        .foregroundColor(Up2Colors.primary)
                    Text("This is a placeholder for the event chat screen.")
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
    EventChatPlaceholderView()
} 