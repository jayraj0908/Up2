import SwiftUI

@MainActor
class EventAnalyticsViewModel: ObservableObject {
    @Published var analytics: HostEventAnalytics?
    @Published var promoCodes: [PromoCode] = []
    @Published var isLoading = false
    @Published var isLoadingPromoCodes = false
    @Published var errorMessage: String?
    
    private let hostService = EventHostService.shared
    
    func loadAnalytics(for eventId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load analytics and promo codes concurrently
            async let analyticsTask = hostService.getEventAnalytics(eventId: eventId)
            async let promoCodesTask = hostService.getEventPromoCodes(eventId: eventId)
            
            let (analytics, promoCodes) = try await (analyticsTask, promoCodesTask)
            
            self.analytics = analytics
            self.promoCodes = promoCodes
            
        } catch {
            errorMessage = "Failed to load analytics: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshAnalytics(for eventId: UUID) async {
        await loadAnalytics(for: eventId)
    }
    
    func createPromoCode(eventId: UUID, code: String, discount: Double, maxUses: Int) async {
        isLoadingPromoCodes = true
        errorMessage = nil
        
        do {
            try await hostService.createPromoCode(eventId: eventId, code: code, discount: discount, maxUses: maxUses)
            
            // Refresh promo codes
            promoCodes = try await hostService.getEventPromoCodes(eventId: eventId)
            
        } catch {
            errorMessage = "Failed to create promo code: \(error.localizedDescription)"
        }
        
        isLoadingPromoCodes = false
    }
} 