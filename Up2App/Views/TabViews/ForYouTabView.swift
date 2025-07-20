import SwiftUI

// MARK: - For You Tab View
struct ForYouTabView: View {
    
    // MARK: - Environment
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject var appStateManager: AppStateManager
    
    // MARK: - Body
    var body: some View {
        ForYouFeedView()
    }
}

// MARK: - Preview
#Preview {
    ForYouTabView()
        .environmentObject(NavigationCoordinator())
        .environmentObject(AppStateManager.shared)
} 