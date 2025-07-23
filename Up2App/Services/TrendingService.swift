import Foundation
import Supabase
import SwiftUI

@MainActor
class TrendingService: ObservableObject {
    static let shared = TrendingService()
    
    private let authService = SupabaseAuthService.shared
    private var supabase: SupabaseClient { authService.supabase }
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Trending Events
    
    func fetchTrendingEvents(timeframe: TrendingTimeframe = .today) async throws -> [TrendingEvent] {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch real trending events from Supabase
            let response: [TrendingEventResponse] = try await supabase
                .from("trending_events")
                .select("*")
                .eq("timeframe", value: timeframe.rawValue)
                .order("growth_rate", ascending: false)
                .limit(20)
                .execute()
                .value
            
            let trendingEvents = response.compactMap { convertToTrendingEvent($0) }
            
            isLoading = false
            return trendingEvents
        } catch {
            isLoading = false
            errorMessage = "Failed to fetch trending events: \(error.localizedDescription)"
            throw error
        }
    }
    
    func fetchTrendingStats(timeframe: TrendingTimeframe = .today) async throws -> TrendingStats {
        isLoading = true
        errorMessage = nil
        
        do {
            // Fetch trending statistics from Supabase
            let response: [TrendingStatsResponse] = try await supabase
                .from("trending_stats")
                .select("*")
                .eq("timeframe", value: timeframe.rawValue)
                .limit(1)
                .execute()
                .value
            
            guard let statsData = response.first else {
                // Return default stats if no data exists
                let defaultStats = TrendingStats(
                    totalEvents: 0,
                    averageGrowth: 0.0,
                    peakTime: timeframe.peakTime
                )
                isLoading = false
                return defaultStats
            }
            
            let stats = TrendingStats(
                totalEvents: statsData.totalEvents,
                averageGrowth: statsData.averageGrowth,
                peakTime: statsData.peakTime
            )
            
            isLoading = false
            return stats
        } catch {
            isLoading = false
            errorMessage = "Failed to fetch trending stats: \(error.localizedDescription)"
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    private func convertToTrendingEvent(_ response: TrendingEventResponse) -> TrendingEvent? {
        guard let id = response.id else { return nil }
        
        return TrendingEvent(
            id: id,
            title: response.title,
            attendees: response.attendees,
            growth: Int(response.growthRate * 100), // Convert to percentage
            category: TrendingCategory(rawValue: response.category) ?? .entertainment
        )
    }
}

// MARK: - Database Models

private struct TrendingEventResponse: Codable {
    let id: String?
    let title: String
    let attendees: Int
    let growthRate: Double
    let category: String
    let timeframe: String
    let createdAt: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case attendees
        case growthRate = "growth_rate"
        case category
        case timeframe
        case createdAt = "created_at"
    }
}

private struct TrendingStatsResponse: Codable {
    let timeframe: String
    let totalEvents: Int
    let averageGrowth: Double
    let peakTime: String
    
    enum CodingKeys: String, CodingKey {
        case timeframe
        case totalEvents = "total_events"
        case averageGrowth = "average_growth"
        case peakTime = "peak_time"
    }
}

// MARK: - Supporting Types

struct TrendingStats {
    let totalEvents: Int
    let averageGrowth: Double
    let peakTime: String
}

enum TrendingTimeframe: String, CaseIterable {
    case today = "today"
    case thisWeek = "this_week"
    case thisMonth = "this_month"
    
    var displayName: String {
        switch self {
        case .today: return "Today"
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        }
    }
    
    var peakTime: String {
        switch self {
        case .today: return "6-8 PM"
        case .thisWeek: return "Fri-Sun"
        case .thisMonth: return "Weekends"
        }
    }
}

enum TrendingCategory: String, CaseIterable {
    case music = "music"
    case technology = "technology"
    case arts = "arts"
    case food = "food"
    case business = "business"
    case entertainment = "entertainment"
    case fitness = "fitness"
    case community = "community"
    
    var icon: String {
        switch self {
        case .music: return "music.note"
        case .technology: return "laptopcomputer"
        case .arts: return "paintbrush"
        case .food: return "fork.knife"
        case .business: return "briefcase"
        case .entertainment: return "tv"
        case .fitness: return "figure.run"
        case .community: return "person.3"
        }
    }
    
    var color: Color {
        switch self {
        case .music: return .purple
        case .technology: return .blue
        case .arts: return .pink
        case .food: return .orange
        case .business: return .green
        case .entertainment: return .red
        case .fitness: return .cyan
        case .community: return .yellow
        }
    }
}

struct TrendingEvent: Identifiable {
    let id: String
    let title: String
    let attendees: Int
    let growth: Int // percentage
    let category: TrendingCategory
} 