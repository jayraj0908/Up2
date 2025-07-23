import SwiftUI

struct RoleSelectionView: View {
    @EnvironmentObject var appStateManager: AppStateManager
    @State private var selectedRole: UserRole?
    @State private var isProcessing = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    enum UserRole: String, CaseIterable {
        case user = "user"
        case host = "host"
        
        var title: String {
            switch self {
            case .user: return "User"
            case .host: return "Host"
            }
        }
        
        var description: String {
            switch self {
            case .user: return "Discover and attend events"
            case .host: return "Create and manage events"
            }
        }
        
        var icon: String {
            switch self {
            case .user: return "person.fill"
            case .host: return "calendar.badge.plus"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            backgroundView
            
            VStack(spacing: Up2Spacing.xxxl) {
                // Header
                headerView
                
                // Role Selection Cards
                VStack(spacing: Up2Spacing.xl) {
                    ForEach(UserRole.allCases, id: \.self) { role in
                        roleCard(for: role)
                    }
                }
                
                Spacer()
                
                // Continue Button
                if let selectedRole = selectedRole {
                    Up2Button("Continue as \(selectedRole.title)", style: .primary) {
                        Task {
                            await selectRole(selectedRole)
                        }
                    }
                    .disabled(isProcessing)
                }
            }
            .padding(.horizontal, Up2Spacing.screenEdge)
            .padding(.vertical, Up2Spacing.xl)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Background View
    private var backgroundView: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.black,
                    Color(red: 0.1, green: 0.0, blue: 0.3),
                    Color(red: 0.3, green: 0.0, blue: 0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle pattern overlay
            Color(red: 0.0, green: 0.2, blue: 0.4).opacity(0.1)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: Up2Spacing.lg) {
            // Logo
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .shadow(color: Up2Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
            
            Text("Choose Your Role")
                .font(Up2Typography.displayMedium)
                .foregroundColor(Up2Colors.textInverse)
                .multilineTextAlignment(.center)
            
            Text("Select how you'd like to use Up2")
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, Up2Spacing.xxxl)
    }
    
    // MARK: - Role Card
    private func roleCard(for role: UserRole) -> some View {
        let isSelected = selectedRole == role
        
        return Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedRole = role
            }
        }) {
            HStack(spacing: Up2Spacing.lg) {
                // Icon
                Image(systemName: role.icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(isSelected ? Up2Colors.accent : Up2Colors.textSecondary)
                    .frame(width: 60, height: 60)
                    .background(
                        Circle()
                            .fill(isSelected ? Up2Colors.accent.opacity(0.2) : Up2Colors.primary.opacity(0.1))
                    )
                
                // Content
                VStack(alignment: .leading, spacing: Up2Spacing.xs) {
                    Text(role.title)
                        .font(Up2Typography.heading3)
                        .fontWeight(.semibold)
                        .foregroundColor(Up2Colors.textInverse)
                    
                    Text(role.description)
                        .font(Up2Typography.bodySmall)
                        .foregroundColor(Up2Colors.textSecondary)
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Up2Colors.accent)
                }
            }
            .padding(Up2Spacing.lg)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? Up2Colors.accent : Color.clear,
                                lineWidth: 2
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    // MARK: - Role Selection Logic
    private func selectRole(_ role: UserRole) async {
        isProcessing = true
        
        do {
            guard let currentUser = appStateManager.currentUser else {
                throw NSError(domain: "RoleSelection", code: 1, userInfo: [NSLocalizedDescriptionKey: "No authenticated user found"])
            }
            
            let profileService = ProfileService.shared
            let userId = UUID(uuidString: currentUser.id) ?? UUID()
            
            // Create or update profile with selected role
            if role == .host {
                // For hosts, set is_curator to true
                _ = try await profileService.updateProfileToHost(userId: userId)
                appStateManager.updateSoftGateState(.hostOnboarding)
            } else {
                // For regular users, create basic profile
                _ = try await profileService.createBasicProfile(userId: userId)
                appStateManager.updateSoftGateState(.complete)
            }
            
            isProcessing = false
            
        } catch {
            isProcessing = false
            errorMessage = error.localizedDescription
            showingError = true
            print("❌ Failed to select role: \(error)")
        }
    }
}

#Preview {
    RoleSelectionView()
        .environmentObject(AppStateManager())
} 