import SwiftUI

struct ForYouFeedPlaceholderView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Up2Card {
                    VStack(spacing: 12) {
                        Text("For You Feed")
                            .font(Up2Typography.heading2)
                            .foregroundColor(Up2Colors.primary)
                        Text("This is a placeholder for the personalized event feed.")
                            .font(Up2Typography.bodyMedium)
                            .foregroundColor(Up2Colors.textSecondary)
                        Text("[Epic 0 Placeholder]")
                            .font(Up2Typography.caption)
                            .foregroundColor(Up2Colors.textTertiary)
                    }
                    .padding()
                }
                ForEach(0..<3) { i in
                    Up2Card {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Sample Event #\(i+1)")
                                .font(Up2Typography.heading3)
                                .foregroundColor(Up2Colors.primary)
                            Text("Nightlife Venue • 9:00 PM")
                                .font(Up2Typography.bodyMedium)
                                .foregroundColor(Up2Colors.textSecondary)
                            Text("This is a sample event card for the feed placeholder.")
                                .font(Up2Typography.caption)
                                .foregroundColor(Up2Colors.textTertiary)
                        }
                        .padding()
                    }
                }
            }
            .padding()
        }
        .background(Up2Colors.background.ignoresSafeArea())
    }
}

#Preview {
    ForYouFeedPlaceholderView()
} 