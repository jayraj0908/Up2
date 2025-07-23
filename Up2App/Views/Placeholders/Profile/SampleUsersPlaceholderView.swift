import SwiftUI

struct SampleUser {
    let name: String
    let vibe: String
    let bio: String
}

struct SampleUsersPlaceholderView: View {
    private let sampleUsers = [
        SampleUser(name: "Alex Chen", vibe: "Adventure Seeker", bio: "Always looking for the next exciting event to attend"),
        SampleUser(name: "Sarah Johnson", vibe: "Social Butterfly", bio: "Love connecting with new people at events"),
        SampleUser(name: "Mike Rodriguez", vibe: "Music Lover", bio: "Passionate about live music and concerts"),
        SampleUser(name: "Emma Wilson", vibe: "Foodie", bio: "Exploring culinary events and food festivals")
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Up2Card {
                    VStack(spacing: 12) {
                        Text("Sample Users")
                            .font(Up2Typography.heading2)
                            .foregroundColor(Up2Colors.primary)
                        Text("This is a placeholder for sample user data.")
                            .font(Up2Typography.bodyMedium)
                            .foregroundColor(Up2Colors.textSecondary)
                        Text("[Epic 0 Placeholder]")
                            .font(Up2Typography.caption)
                            .foregroundColor(Up2Colors.textTertiary)
                    }
                    .padding()
                }
                ForEach(sampleUsers, id: \.name) { user in
                    Up2Card {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(user.name)
                                .font(Up2Typography.heading3)
                                .foregroundColor(Up2Colors.primary)
                            Text(user.vibe)
                                .font(Up2Typography.bodyMedium)
                                .foregroundColor(Up2Colors.textSecondary)
                            Text(user.bio)
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
    SampleUsersPlaceholderView()
} 