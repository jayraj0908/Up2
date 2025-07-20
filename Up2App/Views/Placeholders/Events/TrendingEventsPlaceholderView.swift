import SwiftUI

struct TrendingEventsPlaceholderView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Up2Card {
                    VStack(spacing: 12) {
                        Text("Trending Events")
                            .font(Up2Typography.heading2)
                            .foregroundColor(Up2Colors.primary)
                        Text("This is a placeholder for trending events.")
                            .font(Up2Typography.bodyMedium)
                            .foregroundColor(Up2Colors.textSecondary)
                        Text("[Epic 0 Placeholder]")
                            .font(Up2Typography.caption)
                            .foregroundColor(Up2Colors.textTertiary)
                    }
                    .padding()
                }
                ForEach(0..<2) { i in
                    Up2Card {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Trending Event #\(i+1)")
                                .font(Up2Typography.heading3)
                                .foregroundColor(Up2Colors.primary)
                            Text("Popular Venue • 10:00 PM")
                                .font(Up2Typography.bodyMedium)
                                .foregroundColor(Up2Colors.textSecondary)
                            Text("This is a sample trending event card.")
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
    TrendingEventsPlaceholderView()
} 