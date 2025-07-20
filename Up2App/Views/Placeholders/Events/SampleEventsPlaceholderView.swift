import SwiftUI

struct SampleEventsPlaceholderView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Up2Card {
                    VStack(spacing: 12) {
                        Text("Sample Events")
                            .font(Up2Typography.heading2)
                            .foregroundColor(Up2Colors.primary)
                        Text("This is a placeholder for sample event data.")
                            .font(Up2Typography.bodyMedium)
                            .foregroundColor(Up2Colors.textSecondary)
                        Text("[Epic 0 Placeholder]")
                            .font(Up2Typography.caption)
                            .foregroundColor(Up2Colors.textTertiary)
                    }
                    .padding()
                }
                ForEach(PlaceholderData.events) { event in
                    Up2Card {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(event.title)
                                .font(Up2Typography.heading3)
                                .foregroundColor(Up2Colors.primary)
                            Text("\(event.venue) • \(event.time)")
                                .font(Up2Typography.bodyMedium)
                                .foregroundColor(Up2Colors.textSecondary)
                            Text(event.description)
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
    SampleEventsPlaceholderView()
} 