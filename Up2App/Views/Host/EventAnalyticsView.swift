import SwiftUI
import Charts

struct EventAnalyticsView: View {
    let event: HostEvent
    @StateObject private var viewModel = EventAnalyticsViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTimeframe: Timeframe = .week
    @State private var showingPromoCodeSheet = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Stats
                    headerStats
                    
                    // Performance Metrics
                    performanceMetrics
                    
                    // Revenue Chart
                    revenueChart
                    
                    // Referrer Analytics
                    referrerAnalytics
                    
                    // Promo Codes
                    promoCodeSection
                    
                    // Daily Activity
                    dailyActivityChart
                }
                .padding()
            }
            .background(Up2Colors.background.ignoresSafeArea())
            .navigationTitle("Event Analytics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(Up2Colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Promo Code") {
                        showingPromoCodeSheet = true
                    }
                    .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadAnalytics(for: event.id)
            }
        }
        .sheet(isPresented: $showingPromoCodeSheet) {
            PromoCodeCreationView(event: event)
        }
    }
    
    // MARK: - Header Stats
    private var headerStats: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(Up2Typography.heading2)
                        .foregroundColor(Up2Colors.textPrimary)
                    
                    Text(event.venueName)
                        .font(Up2Typography.bodyMedium)
                        .foregroundColor(Up2Colors.textSecondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$\(String(format: "%.0f", viewModel.analytics?.revenue ?? 0))")
                        .font(Up2Typography.heading2)
                        .fontWeight(.bold)
                        .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
                    
                    Text("Total Revenue")
                        .font(Up2Typography.caption)
                        .foregroundColor(Up2Colors.textSecondary)
                }
            }
            
            // Key Metrics Row
            HStack(spacing: 20) {
                AnalyticsStatCard(
                    title: "Total Views",
                    value: "\(viewModel.analytics?.totalViews ?? 0)",
                    subtitle: "Unique: \(viewModel.analytics?.uniqueViews ?? 0)",
                    icon: "eye.fill",
                    color: .blue
                )
                
                AnalyticsStatCard(
                    title: "RSVP Rate",
                    value: "\(Int((viewModel.analytics?.rsvpRate ?? 0) * 100))%",
                    subtitle: "Conversion: \(Int((viewModel.analytics?.conversionRate ?? 0) * 100))%",
                    icon: "person.3.fill",
                    color: .green
                )
            }
        }
        .padding()
        .background(Up2Colors.surface)
        .cornerRadius(12)
    }
    
    // MARK: - Performance Metrics
    private var performanceMetrics: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Performance Metrics")
                .font(Up2Typography.heading3)
                .foregroundColor(Up2Colors.textPrimary)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                MetricCard(
                    title: "Average RSVPs",
                    value: "\(event.rsvpCount)",
                    trend: "+12%",
                    isPositive: true
                )
                
                MetricCard(
                    title: "Ticket Price",
                    value: "$\(String(format: "%.0f", event.price))",
                    trend: "Avg",
                    isPositive: true
                )
                
                MetricCard(
                    title: "Days Until Event",
                    value: "\(Calendar.current.dateComponents([.day], from: Date(), to: event.date).day ?? 0)",
                    trend: "Remaining",
                    isPositive: true
                )
                
                MetricCard(
                    title: "Event Status",
                    value: event.status.rawValue,
                    trend: "Active",
                    isPositive: event.status == .active
                )
            }
        }
    }
    
    // MARK: - Revenue Chart
    private var revenueChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Revenue Trend")
                    .font(Up2Typography.heading3)
                    .foregroundColor(Up2Colors.textPrimary)
                
                Spacer()
                
                Picker("Timeframe", selection: $selectedTimeframe) {
                    ForEach(Timeframe.allCases, id: \.self) { timeframe in
                        Text(timeframe.rawValue).tag(timeframe)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            
            if let analytics = viewModel.analytics {
                Chart(analytics.dailyStats) { dataPoint in
                    LineMark(
                        x: .value("Day", dataPoint.label),
                        y: .value("Revenue", dataPoint.value)
                    )
                    .foregroundStyle(Color(red: 0.0, green: 0.48, blue: 1.0))
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    AreaMark(
                        x: .value("Day", dataPoint.label),
                        y: .value("Revenue", dataPoint.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.3),
                                Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.1)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Up2Colors.textSecondary.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.2)
                    )
            }
        }
        .padding()
        .background(Up2Colors.surface)
        .cornerRadius(12)
    }
    
    // MARK: - Referrer Analytics
    private var referrerAnalytics: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Traffic Sources")
                .font(Up2Typography.heading3)
                .foregroundColor(Up2Colors.textPrimary)
            
            if let analytics = viewModel.analytics {
                VStack(spacing: 12) {
                    ForEach(Array(analytics.topReferrers.sorted(by: { $0.value > $1.value })), id: \.key) { referrer in
                        ReferrerRow(
                            source: referrer.key,
                            count: referrer.value,
                            total: analytics.totalViews
                        )
                    }
                }
            } else {
                ForEach(0..<4, id: \.self) { _ in
                    HStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Up2Colors.textSecondary.opacity(0.2))
                            .frame(width: 80, height: 16)
                        
                        Spacer()
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Up2Colors.textSecondary.opacity(0.2))
                            .frame(width: 60, height: 16)
                    }
                }
            }
        }
        .padding()
        .background(Up2Colors.surface)
        .cornerRadius(12)
    }
    
    // MARK: - Promo Code Section
    private var promoCodeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Promo Codes")
                    .font(Up2Typography.heading3)
                    .foregroundColor(Up2Colors.textPrimary)
                
                Spacer()
                
                Button("View All") {
                    // Navigate to promo codes list
                }
                .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0))
            }
            
            if viewModel.isLoadingPromoCodes {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.promoCodes) { promoCode in
                            PromoCodeCard(promoCode: promoCode)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(Up2Colors.surface)
        .cornerRadius(12)
    }
    
    // MARK: - Daily Activity Chart
    private var dailyActivityChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Activity")
                .font(Up2Typography.heading3)
                .foregroundColor(Up2Colors.textPrimary)
            
            if let analytics = viewModel.analytics {
                Chart(analytics.dailyStats) { dataPoint in
                    BarMark(
                        x: .value("Day", dataPoint.label),
                        y: .value("Activity", dataPoint.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.0, green: 0.48, blue: 1.0),
                                Color(red: 0.0, green: 0.6, blue: 1.0)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                }
                .frame(height: 150)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Up2Colors.textSecondary.opacity(0.1))
                    .frame(height: 150)
                    .overlay(
                        ProgressView()
                            .scaleEffect(1.2)
                    )
            }
        }
        .padding()
        .background(Up2Colors.surface)
        .cornerRadius(12)
    }
}

// MARK: - Supporting Views

struct AnalyticsStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(Up2Typography.heading3)
                .fontWeight(.bold)
                .foregroundColor(Up2Colors.textPrimary)
            
            Text(title)
                .font(Up2Typography.caption)
                .foregroundColor(Up2Colors.textSecondary)
            
            Text(subtitle)
                .font(Up2Typography.caption)
                .foregroundColor(Up2Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let trend: String
    let isPositive: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Up2Typography.caption)
                .foregroundColor(Up2Colors.textSecondary)
            
            Text(value)
                .font(Up2Typography.heading3)
                .fontWeight(.bold)
                .foregroundColor(Up2Colors.textPrimary)
            
            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.up" : "arrow.down")
                    .font(.caption)
                    .foregroundColor(isPositive ? .green : .red)
                
                Text(trend)
                    .font(Up2Typography.caption)
                    .foregroundColor(isPositive ? .green : .red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Up2Colors.surface)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Up2Colors.border, lineWidth: 1)
        )
    }
}

struct ReferrerRow: View {
    let source: String
    let count: Int
    let total: Int
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(count) / Double(total)
    }
    
    var body: some View {
        HStack {
            Text(source)
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2Colors.textPrimary)
            
            Spacer()
            
            Text("\(count)")
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2Colors.textSecondary)
            
            Text("(\(Int(percentage * 100))%)")
                .font(Up2Typography.caption)
                .foregroundColor(Up2Colors.textSecondary)
        }
        .padding(.vertical, 4)
    }
}

struct PromoCodeCard: View {
    let promoCode: PromoCode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(promoCode.code)
                    .font(Up2Typography.bodyMedium)
                    .fontWeight(.bold)
                    .foregroundColor(Up2Colors.textPrimary)
                
                Spacer()
                
                Text("\(Int(promoCode.discount))%")
                    .font(Up2Typography.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Text("\(promoCode.usedCount)/\(promoCode.maxUses) used")
                .font(Up2Typography.caption)
                .foregroundColor(Up2Colors.textSecondary)
            
            ProgressView(value: promoCode.usagePercentage)
                .progressViewStyle(LinearProgressViewStyle(tint: Color(red: 0.0, green: 0.48, blue: 1.0)))
        }
        .padding()
        .frame(width: 160)
        .background(Up2Colors.surface)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Up2Colors.border, lineWidth: 1)
        )
    }
}

// MARK: - Enums

enum Timeframe: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}

#Preview {
    EventAnalyticsView(event: HostEvent(
        id: UUID(),
        title: "Summer Beach Party",
        venueName: "Santa Monica Beach",
        date: Date().addingTimeInterval(86400 * 7),
        rsvpCount: 45,
        price: 25.0,
        status: .upcoming,
        imageURL: nil
    ))
} 