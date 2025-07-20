import Foundation
import SwiftUI
import Combine

/// Comprehensive error handling service for centralized error management
class ErrorHandlingService: ObservableObject {
    static let shared = ErrorHandlingService()
    
    @Published var currentError: AppError?
    @Published var showErrorAlert = false
    @Published var errorHistory: [AppError] = []
    
    private let analyticsService = AnalyticsService.shared
    private let hapticService = HapticService.shared
    private let maxErrorHistory = 100
    
    private init() {}
    
    // MARK: - Error Handling
    
    func handleError(_ error: Error, context: String = "", showAlert: Bool = true) {
        let appError = AppError(
            originalError: error,
            context: context,
            timestamp: Date(),
            userInfo: extractUserInfo(from: error)
        )
        
        // Add to error history
        addToErrorHistory(appError)
        
        // Track error analytics
        analyticsService.trackError(error, context: context, properties: [
            "error_type": appError.type.rawValue,
            "error_severity": appError.severity.rawValue,
            "show_alert": showAlert
        ])
        
        // Provide haptic feedback
        hapticService.errorNotification()
        
        // Show alert if requested
        if showAlert {
            DispatchQueue.main.async {
                self.currentError = appError
                self.showErrorAlert = true
            }
        }
        
        // Log error for debugging
        logError(appError)
    }
    
    func handleNetworkError(_ error: Error, endpoint: String = "") {
        let context = endpoint.isEmpty ? "Network Request" : "API Call to \(endpoint)"
        handleError(error, context: context, showAlert: true)
    }
    
    func handleValidationError(_ field: String, message: String) {
        let error = ValidationError(field: field, message: message)
        handleError(error, context: "Form Validation", showAlert: false)
    }
    
    func handleAuthenticationError(_ error: Error) {
        handleError(error, context: "Authentication", showAlert: true)
    }
    
    func handlePaymentError(_ error: Error) {
        handleError(error, context: "Payment Processing", showAlert: true)
    }
    
    func handleFileError(_ error: Error, operation: String) {
        handleError(error, context: "File Operation: \(operation)", showAlert: true)
    }
    
    // MARK: - Error Recovery
    
    func retryLastOperation() {
        guard let lastError = errorHistory.last else { return }
        
        // Track retry attempt
        analyticsService.trackUserAction("error_retry", properties: [
            "error_type": lastError.type.rawValue,
            "error_context": lastError.context
        ])
        
        // Provide haptic feedback
        hapticService.lightImpact()
        
        // Clear current error
        clearCurrentError()
        
        // In a real app, this would trigger the retry logic
        // For now, we just log the retry attempt
        print("🔄 Retrying operation for error: \(lastError.type.rawValue)")
    }
    
    func clearCurrentError() {
        DispatchQueue.main.async {
            self.currentError = nil
            self.showErrorAlert = false
        }
    }
    
    func clearErrorHistory() {
        errorHistory.removeAll()
    }
    
    // MARK: - Error Analysis
    
    func getErrorSummary() -> ErrorSummary {
        let totalErrors = errorHistory.count
        let errorsByType = Dictionary(grouping: errorHistory, by: { $0.type })
            .mapValues { $0.count }
        let errorsBySeverity = Dictionary(grouping: errorHistory, by: { $0.severity })
            .mapValues { $0.count }
        
        return ErrorSummary(
            totalErrors: totalErrors,
            errorsByType: errorsByType,
            errorsBySeverity: errorsBySeverity,
            lastError: errorHistory.last
        )
    }
    
    func getErrorsByType(_ type: AppErrorType) -> [AppError] {
        return errorHistory.filter { $0.type == type }
    }
    
    func getErrorsBySeverity(_ severity: AppErrorSeverity) -> [AppError] {
        return errorHistory.filter { $0.severity == severity }
    }
    
    // MARK: - Private Methods
    
    private func addToErrorHistory(_ error: AppError) {
        errorHistory.append(error)
        
        // Keep only the last N errors
        if errorHistory.count > maxErrorHistory {
            errorHistory.removeFirst(errorHistory.count - maxErrorHistory)
        }
    }
    
    private func extractUserInfo(from error: Error) -> [String: Any] {
        let nsError = error as NSError
        return [
            "domain": nsError.domain,
            "code": nsError.code,
            "description": nsError.localizedDescription,
            "userInfo": nsError.userInfo
        ]
    }
    
    private func logError(_ error: AppError) {
        #if DEBUG
        print("🚨 Error: \(error.type.rawValue) - \(error.message)")
        print("   Context: \(error.context)")
        print("   Severity: \(error.severity.rawValue)")
        print("   Timestamp: \(error.timestamp)")
        #endif
    }
}

// MARK: - Error Models

struct AppError: Identifiable, Equatable {
    let id = UUID()
    let originalError: Error
    let context: String
    let timestamp: Date
    let userInfo: [String: Any]
    
    var type: AppErrorType {
        if originalError is NetworkError {
            return .network
        } else if originalError is ValidationError {
            return .validation
        } else if originalError is AuthenticationError {
            return .authentication
        } else if originalError is PaymentError {
            return .payment
        } else if originalError is FileError {
            return .file
        } else {
            return .unknown
        }
    }
    
    var severity: AppErrorSeverity {
        switch type {
        case .network:
            return .medium
        case .validation:
            return .low
        case .authentication:
            return .high
        case .payment:
            return .critical
        case .file:
            return .medium
        case .unknown:
            return .medium
        }
    }
    
    var message: String {
        return originalError.localizedDescription
    }
    
    var title: String {
        switch type {
        case .network:
            return "Connection Error"
        case .validation:
            return "Validation Error"
        case .authentication:
            return "Authentication Error"
        case .payment:
            return "Payment Error"
        case .file:
            return "File Error"
        case .unknown:
            return "Error"
        }
    }
    
    var shouldRetry: Bool {
        switch type {
        case .network:
            return true
        case .validation:
            return false
        case .authentication:
            return true
        case .payment:
            return false
        case .file:
            return true
        case .unknown:
            return false
        }
    }
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        return lhs.id == rhs.id
    }
}

enum AppErrorType: String, CaseIterable {
    case network = "Network"
    case validation = "Validation"
    case authentication = "Authentication"
    case payment = "Payment"
    case file = "File"
    case unknown = "Unknown"
}

enum AppErrorSeverity: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
}

struct ErrorSummary {
    let totalErrors: Int
    let errorsByType: [AppErrorType: Int]
    let errorsBySeverity: [AppErrorSeverity: Int]
    let lastError: AppError?
}

// MARK: - Custom Error Types

struct NetworkError: LocalizedError {
    let message: String
    let code: Int?
    
    var errorDescription: String? {
        return message
    }
}

struct ValidationError: LocalizedError {
    let field: String
    let message: String
    
    var errorDescription: String? {
        return "\(field): \(message)"
    }
}

struct AuthenticationError: LocalizedError {
    let message: String
    
    var errorDescription: String? {
        return message
    }
}

struct FileError: LocalizedError {
    let operation: String
    let message: String
    
    var errorDescription: String? {
        return "\(operation): \(message)"
    }
}

// MARK: - Error Alert View

struct ErrorAlertView: View {
    @ObservedObject var errorService = ErrorHandlingService.shared
    @EnvironmentObject var hapticService: HapticService
    
    var body: some View {
        Group {
            if let error = errorService.currentError {
                VStack(spacing: 16) {
                    Image(systemName: errorIcon(for: error.type))
                        .font(.system(size: 48))
                        .foregroundColor(errorColor(for: error.severity))
                    
                    Text(error.title)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(error.message)
                        .font(.body)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        Up2Button("Dismiss", style: .secondary) {
                            hapticService.lightImpact()
                            errorService.clearCurrentError()
                        }
                        
                        if error.shouldRetry {
                            Up2Button("Retry", style: .primary) {
                                hapticService.mediumImpact()
                                errorService.retryLastOperation()
                            }
                        }
                    }
                }
                .padding(24)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(radius: 10)
                .padding(.horizontal, 20)
            }
        }
        .alert("Error", isPresented: $errorService.showErrorAlert) {
            Button("OK") {
                hapticService.lightImpact()
                errorService.clearCurrentError()
            }
        } message: {
            if let error = errorService.currentError {
                Text(error.message)
            }
        }
    }
    
    private func errorIcon(for type: AppErrorType) -> String {
        switch type {
        case .network:
            return "wifi.slash"
        case .validation:
            return "exclamationmark.triangle"
        case .authentication:
            return "lock.shield"
        case .payment:
            return "creditcard"
        case .file:
            return "doc.badge.ellipsis"
        case .unknown:
            return "exclamationmark.circle"
        }
    }
    
    private func errorColor(for severity: AppErrorSeverity) -> Color {
        switch severity {
        case .low:
            return .orange
        case .medium:
            return .yellow
        case .high:
            return .red
        case .critical:
            return .purple
        }
    }
} 