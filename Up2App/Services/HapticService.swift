import Foundation
import UIKit

/// Service for providing haptic feedback throughout the app
class HapticService: ObservableObject {
    static let shared = HapticService()
    
    @Published var isHapticEnabled: Bool = true
    
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let softImpactGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let rigidImpactGenerator = UIImpactFeedbackGenerator(style: .rigid)
    
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    private init() {
        prepareHaptics()
    }
    
    // MARK: - Haptic Preparation
    
    private func prepareHaptics() {
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        softImpactGenerator.prepare()
        rigidImpactGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }
    
    // MARK: - Impact Feedback
    
    func lightImpact() {
        guard isHapticEnabled else { return }
        lightImpactGenerator.impactOccurred()
    }
    
    func mediumImpact() {
        guard isHapticEnabled else { return }
        mediumImpactGenerator.impactOccurred()
    }
    
    func heavyImpact() {
        guard isHapticEnabled else { return }
        heavyImpactGenerator.impactOccurred()
    }
    
    func softImpact() {
        guard isHapticEnabled else { return }
        softImpactGenerator.impactOccurred()
    }
    
    func rigidImpact() {
        guard isHapticEnabled else { return }
        rigidImpactGenerator.impactOccurred()
    }
    
    // MARK: - Notification Feedback
    
    func successNotification() {
        guard isHapticEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
    }
    
    func warningNotification() {
        guard isHapticEnabled else { return }
        notificationGenerator.notificationOccurred(.warning)
    }
    
    func errorNotification() {
        guard isHapticEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
    }
    
    // MARK: - Selection Feedback
    
    func selectionChanged() {
        guard isHapticEnabled else { return }
        selectionGenerator.selectionChanged()
    }
    
    // MARK: - Custom Haptic Patterns
    
    func buttonTap() {
        lightImpact()
    }
    
    func cardSwipe() {
        softImpact()
    }
    
    func successfulAction() {
        successNotification()
    }
    
    func errorAction() {
        errorNotification()
    }
    
    func warningAction() {
        warningNotification()
    }
    
    func navigationTransition() {
        lightImpact()
    }
    
    func formValidation() {
        selectionChanged()
    }
    
    func imageUpload() {
        mediumImpact()
    }
    
    func paymentSuccess() {
        successNotification()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.mediumImpact()
        }
    }
    
    func paymentError() {
        errorNotification()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.heavyImpact()
        }
    }
    
    func eventRSVP() {
        successNotification()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.lightImpact()
        }
    }
    
    func eventCancel() {
        warningNotification()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.mediumImpact()
        }
    }
    
    func profileUpdate() {
        softImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.successNotification()
        }
    }
    
    func messageSent() {
        lightImpact()
    }
    
    func messageReceived() {
        softImpact()
    }
    
    func searchResult() {
        selectionChanged()
    }
    
    func mapPinTap() {
        lightImpact()
    }
    
    func mapZoom() {
        softImpact()
    }
    
    func listScroll() {
        softImpact()
    }
    
    func refreshPull() {
        mediumImpact()
    }
    
    func longPress() {
        heavyImpact()
    }
    
    func doubleTap() {
        rigidImpact()
    }
    
    // MARK: - Accessibility Support
    
    func accessibilityAnnouncement(_ message: String) {
        guard isHapticEnabled else { return }
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    func accessibilityScreenChanged(_ screenName: String) {
        guard isHapticEnabled else { return }
        UIAccessibility.post(notification: .screenChanged, argument: screenName)
    }
    
    // MARK: - Settings Management
    
    func toggleHapticFeedback() {
        isHapticEnabled.toggle()
        
        if isHapticEnabled {
            prepareHaptics()
            successNotification()
        }
    }
    
    func setHapticEnabled(_ enabled: Bool) {
        isHapticEnabled = enabled
        
        if enabled {
            prepareHaptics()
        }
    }
}

// MARK: - Haptic Extensions for SwiftUI

extension HapticService {
    /// Convenience method for SwiftUI button actions
    func hapticButtonTap() {
        buttonTap()
    }
    
    /// Convenience method for SwiftUI navigation
    func hapticNavigation() {
        navigationTransition()
    }
    
    /// Convenience method for SwiftUI form validation
    func hapticValidation() {
        formValidation()
    }
    
    /// Convenience method for SwiftUI success states
    func hapticSuccess() {
        successfulAction()
    }
    
    /// Convenience method for SwiftUI error states
    func hapticError() {
        errorAction()
    }
    
    /// Convenience method for SwiftUI warning states
    func hapticWarning() {
        warningAction()
    }
}

// MARK: - Haptic Feedback for Common UI Patterns

extension HapticService {
    /// Haptic feedback for authentication flows
    func authSuccess() {
        successNotification()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.mediumImpact()
        }
    }
    
    func authError() {
        errorNotification()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.heavyImpact()
        }
    }
    
    func authValidation() {
        selectionChanged()
    }
    
    /// Haptic feedback for event interactions
    func eventLike() {
        lightImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.successNotification()
        }
    }
    
    func eventShare() {
        mediumImpact()
    }
    
    func eventBookmark() {
        softImpact()
    }
    
    /// Haptic feedback for social interactions
    func followUser() {
        lightImpact()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.successNotification()
        }
    }
    
    func unfollowUser() {
        warningNotification()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.mediumImpact()
        }
    }
    
    func inviteSent() {
        successNotification()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.lightImpact()
        }
    }
    
    /// Haptic feedback for media interactions
    func imageTap() {
        lightImpact()
    }
    
    func videoPlay() {
        softImpact()
    }
    
    func mediaUpload() {
        mediumImpact()
    }
    
    func mediaDelete() {
        warningNotification()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.heavyImpact()
        }
    }
} 