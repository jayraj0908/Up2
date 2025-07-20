import SwiftUI

struct MapPlaceholderView: View {
    var body: some View {
        VStack(spacing: 32) {
            Up2Card {
                VStack(spacing: 16) {
                    Text("Map View")
                        .font(Up2Typography.heading2)
                        .foregroundColor(Up2Colors.primary)
                    Text("This is a placeholder for the event map view.")
                        .font(Up2Typography.bodyMedium)
                        .foregroundColor(Up2Colors.textSecondary)
                    Text("[Epic 0 Placeholder]")
                        .font(Up2Typography.caption)
                        .foregroundColor(Up2Colors.textTertiary)
                    Rectangle()
                        .fill(Up2Colors.surface)
                        .frame(height: 180)
                        .overlay(Text("[Map Pins Placeholder]").font(Up2Typography.caption).foregroundColor(Up2Colors.textSecondary))
                        .cornerRadius(12)
                }
                .padding()
            }
        }
        .padding()
        .background(Up2Colors.background.ignoresSafeArea())
    }
}

#Preview {
    MapPlaceholderView()
} 