import SwiftUI

struct SampleEvent {
    let title: String
    let venue: String
    let time: String
    let description: String
}

struct SampleEventsPlaceholderView: View {
    private let sampleEvents = [
        SampleEvent(
            title: "Summer Music Festival",
            venue: "Central Park",
            time: "7:00 PM",
            description: "An amazing evening of live music under the stars"
        ),
        SampleEvent(
            title: "Tech Meetup",
            venue: "Innovation Hub",
            time: "6:30 PM",
            description: "Network with fellow developers and tech enthusiasts"
        ),
        SampleEvent(
            title: "Food & Wine Tasting",
            venue: "Downtown Bistro",
            time: "8:00 PM",
            description: "Experience the finest local cuisine and wines"
        )
    ]
    
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
                ForEach(sampleEvents, id: \.title) { event in
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