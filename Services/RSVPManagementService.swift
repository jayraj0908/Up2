import Foundation
import Combine
import SwiftUI

@MainActor
class RSVPManagementService: ObservableObject {
    static let shared = RSVPManagementService()
    
    // MARK: - Dependencies
    private let analyticsService = AnalyticsService.shared
    private let performanceService = AppPerformanceService.shared
    private let errorService = ErrorHandlingService.shared
    private let securityService = SecurityService.shared
    private let hapticService = HapticService.shared
    private let eventManagementService = EventManagementService.shared
    
    // MARK: - Configuration
    private let maxRSVPHistory = 1000
    private let reminderIntervals: [TimeInterval] = [86400, 3600, 1800] // 24h, 1h, 30min
    private let maxGroupSize = 10
    private let rsvpCooldown: TimeInterval = 300 // 5 minutes
    
    // MARK: - Published Properties
    @Published var activeRSVPs: [UUID: RSVPStatus] = [:]
    @Published var rsvpHistory: [RSVPEntry] = []
    @Published var reminderStats = ReminderStatistics()
    @Published var lastRSVPUpdate: Date?
    
    // MARK: - Private Properties
    private var rsvpSubscriptions: [UUID: AnyCancellable] = [:]
    private var reminderTimer: Timer?
    private var rsvpCooldowns: [String: Date] = [:]
    private var groupRSVPs: [UUID: GroupRSVP] = [:]
    
    private init() {
        setupReminderSystem()
        loadRSVPHistory()
    }
    
    // MARK: - Public Interface
    
    /// Submit RSVP for an event
    func submitRSVP(
        eventId: UUID,
        userId: UUID,
        rsvpType: RSVPType,
        guestCount: Int = 1,
        message: String? = nil
    ) async throws -> RSVPResult {
        
        let startTime = Date()
        
        do {
            // Check cooldown
            let cooldownKey = "\(userId.uuidString)_\(eventId.uuidString)"
            if let lastRSVP = rsvpCooldowns[cooldownKey],
               Date().timeIntervalSince(lastRSVP) < rsvpCooldown {
                throw RSVPError.cooldownActive
            }
            
            // Track performance
            let result = try await performanceService.trackAPICall {
                try await performRSVPSubmission(
                    eventId: eventId,
                    userId: userId,
                    rsvpType: rsvpType,
                    guestCount: guestCount,
                    message: message
                )
            }
            
            // Update cooldown
            rsvpCooldowns[cooldownKey] = Date()
            
            // Update active RSVPs
            activeRSVPs[eventId] = result.status
            
            // Add to history
            addRSVPToHistory(result.entry)
            
            // Send notifications
            await sendRSVPNotifications(for: result)
            
            // Track analytics
            analyticsService.trackUserAction("rsvp_submitted", properties: [
                "event_id": eventId.uuidString,
                "user_id": userId.uuidString,
                "rsvp_type": rsvpType.rawValue,
                "guest_count": guestCount,
                "processing_time": Date().timeIntervalSince(startTime)
            ])
            
            return result
            
        } catch {
            errorService.handleSystemError(error, context: "RSVPManagementService.submitRSVP")
            throw error
        }
    }
    
    /// Submit group RSVP
    func submitGroupRSVP(
        eventId: UUID,
        hostUserId: UUID,
        guests: [GroupGuest],
        message: String? = nil
    ) async throws -> GroupRSVPResult {
        
        let startTime = Date()
        
        do {
            // Validate group size
            guard guests.count <= maxGroupSize else {
                throw RSVPError.groupTooLarge
            }
            
            // Track performance
            let result = try await performanceService.trackAPICall {
                try await performGroupRSVPSubmission(
                    eventId: eventId,
                    hostUserId: hostUserId,
                    guests: guests,
                    message: message
                )
            }
            
            // Store group RSVP
            groupRSVPs[result.groupId] = result.groupRSVP
            
            // Send group notifications
            await sendGroupRSVPNotifications(for: result)
            
            // Track analytics
            analyticsService.trackUserAction("group_rsvp_submitted", properties: [
                "event_id": eventId.uuidString,
                "host_user_id": hostUserId.uuidString,
                "guest_count": guests.count,
                "processing_time": Date().timeIntervalSince(startTime)
            ])
            
            return result
            
        } catch {
            errorService.handleSystemError(error, context: "RSVPManagementService.submitGroupRSVP")
            throw error
        }
    }
    
    /// Update RSVP status
    func updateRSVPStatus(
        eventId: UUID,
        userId: UUID,
        newStatus: RSVPStatusType,
        reason: String? = nil
    ) async throws -> RSVPUpdate {
        
        let startTime = Date()
        
        do {
            let update = try await performRSVPStatusUpdate(
                eventId: eventId,
                userId: userId,
                newStatus: newStatus,
                reason: reason
            )
            
            // Update active RSVPs
            activeRSVPs[eventId] = update.newStatus
            
            // Send status update notifications
            await sendStatusUpdateNotifications(for: update)
            
            // Track analytics
            analyticsService.trackUserAction("rsvp_status_updated", properties: [
                "event_id": eventId.uuidString,
                "user_id": userId.uuidString,
                "new_status": newStatus.rawValue,
                "processing_time": Date().timeIntervalSince(startTime)
            ])
            
            return update
            
        } catch {
            errorService.handleSystemError(error, context: "RSVPManagementService.updateRSVPStatus")
            throw error
        }
    }
    
    /// Get RSVP analytics
    func getRSVPAnalytics(eventId: UUID) async throws -> RSVPAnalytics {
        let startTime = Date()
        
        do {
            let analytics = try await performRSVPAnalyticsRequest(eventId)
            
            // Track analytics
            analyticsService.trackUserAction("rsvp_analytics_retrieved", properties: [
                "event_id": eventId.uuidString,
                "processing_time": Date().timeIntervalSince(startTime)
            ])
            
            return analytics
            
        } catch {
            errorService.handleSystemError(error, context: "RSVPManagementService.getRSVPAnalytics")
            throw error
        }
    }
    
    /// Schedule RSVP reminder
    func scheduleRSVPReminder(
        eventId: UUID,
        userId: UUID,
        reminderType: ReminderType,
        customTime: Date? = nil
    ) async throws -> ReminderSchedule {
        
        do {
            let schedule = try await performReminderScheduling(
                eventId: eventId,
                userId: userId,
                reminderType: reminderType,
                customTime: customTime
            )
            
            // Track analytics
            analyticsService.trackUserAction("rsvp_reminder_scheduled", properties: [
                "event_id": eventId.uuidString,
                "user_id": userId.uuidString,
                "reminder_type": reminderType.rawValue
            ])
            
            return schedule
            
        } catch {
            errorService.handleSystemError(error, context: "RSVPManagementService.scheduleRSVPReminder")
            throw error
        }
    }
    
    /// Cancel RSVP reminder
    func cancelRSVPReminder(reminderId: UUID) async throws {
        do {
            try await performReminderCancellation(reminderId)
            
            // Track analytics
            analyticsService.trackUserAction("rsvp_reminder_cancelled", properties: [
                "reminder_id": reminderId.uuidString
            ])
            
        } catch {
            errorService.handleSystemError(error, context: "RSVPManagementService.cancelRSVPReminder")
            throw error
        }
    }
    
    /// Get RSVP history for user
    func getRSVPHistory(userId: UUID, limit: Int = 50) async throws -> [RSVPEntry] {
        do {
            return rsvpHistory
                .filter { $0.userId == userId }
                .sorted { $0.timestamp > $1.timestamp }
                .prefix(limit)
                .map { $0 }
            
        } catch {
            errorService.handleSystemError(error, context: "RSVPManagementService.getRSVPHistory")
            throw error
        }
    }
    
    /// Get group RSVP details
    func getGroupRSVP(groupId: UUID) async throws -> GroupRSVP? {
        return groupRSVPs[groupId]
    }
    
    // MARK: - Private Methods
    
    private func performRSVPSubmission(
        eventId: UUID,
        userId: UUID,
        rsvpType: RSVPType,
        guestCount: Int,
        message: String?
    ) async throws -> RSVPResult {
        
        // Simulate RSVP submission
        // In a real implementation, this would validate and save to database
        
        let rsvpId = UUID()
        let timestamp = Date()
        
        let status = RSVPStatus(
            rsvpId: rsvpId,
            eventId: eventId,
            userId: userId,
            status: .confirmed,
            guestCount: guestCount,
            timestamp: timestamp,
            lastUpdated: timestamp
        )
        
        let entry = RSVPEntry(
            id: rsvpId,
            eventId: eventId,
            userId: userId,
            rsvpType: rsvpType,
            status: .confirmed,
            guestCount: guestCount,
            message: message,
            timestamp: timestamp,
            metadata: RSVPMetadata(
                isGroupRSVP: false,
                groupId: nil,
                reminderScheduled: false,
                notificationPreferences: .all
            )
        )
        
        return RSVPResult(
            rsvpId: rsvpId,
            status: status,
            entry: entry,
            message: "RSVP submitted successfully"
        )
    }
    
    private func performGroupRSVPSubmission(
        eventId: UUID,
        hostUserId: UUID,
        guests: [GroupGuest],
        message: String?
    ) async throws -> GroupRSVPResult {
        
        let groupId = UUID()
        let timestamp = Date()
        
        let groupRSVP = GroupRSVP(
            id: groupId,
            eventId: eventId,
            hostUserId: hostUserId,
            guests: guests,
            status: .pending,
            message: message,
            timestamp: timestamp,
            lastUpdated: timestamp
        )
        
        let hostEntry = RSVPEntry(
            id: UUID(),
            eventId: eventId,
            userId: hostUserId,
            rsvpType: .group,
            status: .pending,
            guestCount: guests.count + 1, // Include host
            message: message,
            timestamp: timestamp,
            metadata: RSVPMetadata(
                isGroupRSVP: true,
                groupId: groupId,
                reminderScheduled: false,
                notificationPreferences: .all
            )
        )
        
        return GroupRSVPResult(
            groupId: groupId,
            groupRSVP: groupRSVP,
            hostEntry: hostEntry,
            message: "Group RSVP submitted successfully"
        )
    }
    
    private func performRSVPStatusUpdate(
        eventId: UUID,
        userId: UUID,
        newStatus: RSVPStatusType,
        reason: String?
    ) async throws -> RSVPUpdate {
        
        let updateId = UUID()
        let timestamp = Date()
        
        let newRSVPStatus = RSVPStatus(
            rsvpId: updateId,
            eventId: eventId,
            userId: userId,
            status: newStatus,
            guestCount: 1,
            timestamp: timestamp,
            lastUpdated: timestamp
        )
        
        return RSVPUpdate(
            id: updateId,
            eventId: eventId,
            userId: userId,
            previousStatus: activeRSVPs[eventId]?.status ?? .pending,
            newStatus: newRSVPStatus,
            reason: reason,
            timestamp: timestamp
        )
    }
    
    private func performRSVPAnalyticsRequest(_ eventId: UUID) async throws -> RSVPAnalytics {
        // Simulate RSVP analytics request
        // In a real implementation, this would aggregate data from database
        
        return RSVPAnalytics(
            eventId: eventId,
            totalRSVPs: Int.random(in: 100...500),
            confirmedRSVPs: Int.random(in: 80...400),
            declinedRSVPs: Int.random(in: 10...50),
            pendingRSVPs: Int.random(in: 10...50),
            waitlistRSVPs: Int.random(in: 5...30),
            conversionRate: Double.random(in: 0.6...0.9),
            averageResponseTime: TimeInterval.random(in: 3600...86400), // 1h to 24h
            groupRSVPCount: Int.random(in: 5...20),
            averageGroupSize: Double.random(in: 2.5...4.0),
            topRSVPTime: "7:00 PM",
            rsvpTrends: [
                "Day 1": Int.random(in: 20...50),
                "Day 2": Int.random(in: 15...40),
                "Day 3": Int.random(in: 10...30),
                "Day 4": Int.random(in: 5...20),
                "Day 5": Int.random(in: 2...10)
            ],
            demographics: RSVPDemographics(
                ageGroups: [
                    "18-24": Double.random(in: 0.2...0.4),
                    "25-34": Double.random(in: 0.3...0.5),
                    "35-44": Double.random(in: 0.1...0.3),
                    "45+": Double.random(in: 0.05...0.2)
                ],
                genderDistribution: [
                    "Male": Double.random(in: 0.4...0.6),
                    "Female": Double.random(in: 0.4...0.6),
                    "Other": Double.random(in: 0.01...0.05)
                ]
            ),
            timestamp: Date()
        )
    }
    
    private func performReminderScheduling(
        eventId: UUID,
        userId: UUID,
        reminderType: ReminderType,
        customTime: Date?
    ) async throws -> ReminderSchedule {
        
        let reminderId = UUID()
        let scheduledTime = customTime ?? calculateReminderTime(for: reminderType)
        
        return ReminderSchedule(
            id: reminderId,
            eventId: eventId,
            userId: userId,
            reminderType: reminderType,
            scheduledTime: scheduledTime,
            isActive: true,
            createdAt: Date()
        )
    }
    
    private func performReminderCancellation(_ reminderId: UUID) async throws {
        // Simulate reminder cancellation
        // In a real implementation, this would update the database
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
    }
    
    private func calculateReminderTime(for reminderType: ReminderType) -> Date {
        let now = Date()
        
        switch reminderType {
        case .dayBefore:
            return Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        case .hourBefore:
            return Calendar.current.date(byAdding: .hour, value: -1, to: now) ?? now
        case .thirtyMinutesBefore:
            return Calendar.current.date(byAdding: .minute, value: -30, to: now) ?? now
        case .custom:
            return now
        }
    }
    
    private func addRSVPToHistory(_ entry: RSVPEntry) {
        rsvpHistory.append(entry)
        
        // Keep history size manageable
        if rsvpHistory.count > maxRSVPHistory {
            rsvpHistory.removeFirst()
        }
        
        lastRSVPUpdate = Date()
    }
    
    private func sendRSVPNotifications(for result: RSVPResult) async {
        // Send confirmation notification
        do {
            try await eventManagementService.sendEventNotification(
                to: result.status.userId,
                eventId: result.status.eventId,
                notificationType: .rsvpConfirmation,
                message: "Your RSVP has been confirmed!"
            )
        } catch {
            errorService.handleSystemError(error, context: "RSVPManagementService.sendRSVPNotifications")
        }
        
        // Trigger haptic feedback
        hapticService.rsvpSuccess()
    }
    
    private func sendGroupRSVPNotifications(for result: GroupRSVPResult) async {
        // Send notifications to all guests
        for guest in result.groupRSVP.guests {
            do {
                try await eventManagementService.sendEventNotification(
                    to: guest.userId,
                    eventId: result.groupRSVP.eventId,
                    notificationType: .groupRSVPInvitation,
                    message: "You've been invited to join a group RSVP!"
                )
            } catch {
                errorService.handleSystemError(error, context: "RSVPManagementService.sendGroupRSVPNotifications")
            }
        }
        
        // Trigger haptic feedback
        hapticService.groupRSVPSuccess()
    }
    
    private func sendStatusUpdateNotifications(for update: RSVPUpdate) async {
        // Send status update notification
        do {
            try await eventManagementService.sendEventNotification(
                to: update.userId,
                eventId: update.eventId,
                notificationType: .rsvpStatusUpdate,
                message: "Your RSVP status has been updated to \(update.newStatus.status.rawValue)"
            )
        } catch {
            errorService.handleSystemError(error, context: "RSVPManagementService.sendStatusUpdateNotifications")
        }
    }
    
    private func setupReminderSystem() {
        // Setup reminder timer
        reminderTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in // 5 minutes
            Task {
                await self.processReminders()
            }
        }
    }
    
    private func processReminders() async {
        // Process scheduled reminders
        // This would typically check for due reminders and send notifications
        
        reminderStats.totalRemindersProcessed += 1
        reminderStats.lastProcessedTime = Date()
    }
    
    private func loadRSVPHistory() {
        // Load RSVP history from persistent storage
        // For now, start with empty history
    }
}

// MARK: - Supporting Types

struct RSVPStatus {
    let rsvpId: UUID
    let eventId: UUID
    let userId: UUID
    let status: RSVPStatusType
    let guestCount: Int
    let timestamp: Date
    let lastUpdated: Date
}

struct RSVPEntry: Identifiable {
    let id: UUID
    let eventId: UUID
    let userId: UUID
    let rsvpType: RSVPType
    let status: RSVPStatusType
    let guestCount: Int
    let message: String?
    let timestamp: Date
    let metadata: RSVPMetadata
}

struct RSVPMetadata {
    let isGroupRSVP: Bool
    let groupId: UUID?
    let reminderScheduled: Bool
    let notificationPreferences: NotificationPreferences
}

struct GroupRSVP: Identifiable {
    let id: UUID
    let eventId: UUID
    let hostUserId: UUID
    let guests: [GroupGuest]
    let status: RSVPStatusType
    let message: String?
    let timestamp: Date
    let lastUpdated: Date
    
    var totalGuests: Int {
        guests.count + 1 // Include host
    }
}

struct GroupGuest {
    let userId: UUID
    let name: String
    let email: String?
    let phone: String?
    let status: GuestStatus
    let invitedAt: Date
    let respondedAt: Date?
}

struct RSVPResult {
    let rsvpId: UUID
    let status: RSVPStatus
    let entry: RSVPEntry
    let message: String
}

struct GroupRSVPResult {
    let groupId: UUID
    let groupRSVP: GroupRSVP
    let hostEntry: RSVPEntry
    let message: String
}

struct RSVPUpdate {
    let id: UUID
    let eventId: UUID
    let userId: UUID
    let previousStatus: RSVPStatusType
    let newStatus: RSVPStatus
    let reason: String?
    let timestamp: Date
}

struct RSVPAnalytics {
    let eventId: UUID
    let totalRSVPs: Int
    let confirmedRSVPs: Int
    let declinedRSVPs: Int
    let pendingRSVPs: Int
    let waitlistRSVPs: Int
    let conversionRate: Double
    let averageResponseTime: TimeInterval
    let groupRSVPCount: Int
    let averageGroupSize: Double
    let topRSVPTime: String
    let rsvpTrends: [String: Int]
    let demographics: RSVPDemographics
    let timestamp: Date
}

struct RSVPDemographics {
    let ageGroups: [String: Double]
    let genderDistribution: [String: Double]
}

struct ReminderSchedule {
    let id: UUID
    let eventId: UUID
    let userId: UUID
    let reminderType: ReminderType
    let scheduledTime: Date
    var isActive: Bool
    let createdAt: Date
}

struct ReminderStatistics {
    var totalRemindersProcessed: Int = 0
    var totalRemindersSent: Int = 0
    var lastProcessedTime: Date?
}

enum RSVPType: String, CaseIterable {
    case attending = "attending"
    case notAttending = "not_attending"
    case maybe = "maybe"
    case waitlist = "waitlist"
    case group = "group"
}

enum RSVPStatusType: String, CaseIterable {
    case pending = "pending"
    case confirmed = "confirmed"
    case declined = "declined"
    case waitlist = "waitlist"
    case cancelled = "cancelled"
}

enum GuestStatus: String, CaseIterable {
    case invited = "invited"
    case accepted = "accepted"
    case declined = "declined"
    case pending = "pending"
}

enum ReminderType: String, CaseIterable {
    case dayBefore = "day_before"
    case hourBefore = "hour_before"
    case thirtyMinutesBefore = "thirty_minutes_before"
    case custom = "custom"
}

enum NotificationPreferences: String, CaseIterable {
    case all = "all"
    case important = "important"
    case none = "none"
}

enum RSVPError: LocalizedError {
    case cooldownActive
    case groupTooLarge
    case eventFull
    case invalidRSVP
    case userNotFound
    
    var errorDescription: String? {
        switch self {
        case .cooldownActive:
            return "Please wait before submitting another RSVP"
        case .groupTooLarge:
            return "Group size exceeds maximum allowed"
        case .eventFull:
            return "Event is at full capacity"
        case .invalidRSVP:
            return "Invalid RSVP request"
        case .userNotFound:
            return "User not found"
        }
    }
} 