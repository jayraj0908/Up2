import Foundation
import Combine

/// Service for managing payment disputes and resolutions
class DisputeResolutionService: ObservableObject {
    @Published var activeDisputes: [PaymentDispute] = []
    @Published var resolvedDisputes: [PaymentDispute] = []
    @Published var isLoading = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadDisputeData()
    }
    
    /// Load dispute data
    private func loadDisputeData() {
        // Mock data for now
        activeDisputes = [
            PaymentDispute(
                id: UUID(),
                transactionId: "txn_123456",
                amount: 150.0,
                reason: "Service not provided",
                status: .underReview,
                date: Date().addingTimeInterval(-86400 * 3),
                customerEmail: "customer@example.com"
            ),
            PaymentDispute(
                id: UUID(),
                transactionId: "txn_789012",
                amount: 75.0,
                reason: "Unauthorized transaction",
                status: .investigating,
                date: Date().addingTimeInterval(-86400 * 1),
                customerEmail: "user@example.com"
            )
        ]
        
        resolvedDisputes = [
            PaymentDispute(
                id: UUID(),
                transactionId: "txn_345678",
                amount: 200.0,
                reason: "Duplicate charge",
                status: .resolved,
                date: Date().addingTimeInterval(-86400 * 30),
                customerEmail: "client@example.com"
            )
        ]
    }
    
    /// Create a new dispute
    func createDispute(
        transactionId: String,
        amount: Double,
        reason: String,
        customerEmail: String
    ) async throws -> PaymentDispute {
        let dispute = PaymentDispute(
            id: UUID(),
            transactionId: transactionId,
            amount: amount,
            reason: reason,
            status: .new,
            date: Date(),
            customerEmail: customerEmail
        )
        
        await MainActor.run {
            activeDisputes.append(dispute)
        }
        
        return dispute
    }
    
    /// Update dispute status
    func updateDisputeStatus(_ disputeId: UUID, status: DisputeStatus) async throws {
        await MainActor.run {
            if let index = activeDisputes.firstIndex(where: { $0.id == disputeId }) {
                var dispute = activeDisputes[index]
                dispute.status = status
                
                if status == .resolved {
                    resolvedDisputes.append(dispute)
                    activeDisputes.remove(at: index)
                } else {
                    activeDisputes[index] = dispute
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct PaymentDispute: Identifiable, Codable {
    let id: UUID
    let transactionId: String
    let amount: Double
    let reason: String
    var status: DisputeStatus
    let date: Date
    let customerEmail: String
}

enum DisputeStatus: String, Codable, CaseIterable {
    case new = "new"
    case underReview = "under_review"
    case investigating = "investigating"
    case resolved = "resolved"
    case closed = "closed"
    
    var displayName: String {
        switch self {
        case .new:
            return "New"
        case .underReview:
            return "Under Review"
        case .investigating:
            return "Investigating"
        case .resolved:
            return "Resolved"
        case .closed:
            return "Closed"
        }
    }
} 