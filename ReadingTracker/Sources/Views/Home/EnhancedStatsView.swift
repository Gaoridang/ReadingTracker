// EnhancedStatsView.swift
import SwiftUI
import CoreData

struct EnhancedStatsView: View {
    @StateObject private var statsManager = StatsManager.shared
    @State private var selectedPeriod = StatsPeriod.week
    @State private var weeklyData: [DailyReading] = []
    @State private var isLoading = true
    
    enum StatsPeriod: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case year = "Year"
    }
    
    struct DailyReading: Identifiable {
        let id = UUID()
        let date: Date
        let minutes: Double
        let pages: Int
        let dayName: String
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reading Statistics")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text("Track your reading progress")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Period Selector
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(StatsPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 24)
                .onChange(of: selectedPeriod) { _ in
                    DispatchQueue.main.async {
                        loadData()
                    }
                }
                
                // Summary Cards
                HStack(spacing: 12) {
                    StatsSummaryCard(
                        title: "Total Time",
                        value: formatTime(Int(getPeriodStats().totalMinutes)),
                        icon: "clock.fill",
                        color: Color(hex: "4CAF50")
                    )
                    
                    StatsSummaryCard(
                        title: "Pages Read",
                        value: "\(getPeriodStats().pagesRead)",
                        icon: "book.fill",
                        color: Color.blue
                    )
                    
                    StatsSummaryCard(
                        title: "Sessions",
                        value: "\(getPeriodStats().sessionsCount)",
                        icon: "calendar",
                        color: Color.orange
                    )
                }
                .padding(.horizontal, 24)
                
                // Reading Chart
                if !isLoading && !weeklyData.isEmpty {
                    SimpleBarChart(data: weeklyData, period: selectedPeriod)
                        .padding(.horizontal, 24)
                        .transition(.opacity)
                } else if isLoading {
                    ProgressView()
                        .frame(height: 250)
                        .frame(maxWidth: .infinity)
                }
                
                // Reading Streak
                StreakCard(streak: statsManager.getStreak())
                    .padding(.horizontal, 24)
                
                // Reading Insights
                if !isLoading {
                    ReadingInsights(periodStats: getPeriodStats())
                        .padding(.horizontal, 24)
                }
                
                // Recent Achievements
                AchievementsSection()
                    .padding(.horizontal, 24)
                
                Spacer(minLength: 100)
            }
        }
        .background(Color.gray.opacity(0.05))
        .onAppear {
            DispatchQueue.main.async {
                loadData()
            }
        }
    }
    
    private func getPeriodStats() -> StatsManager.PeriodStats {
        switch selectedPeriod {
        case .week:
            return statsManager.getWeeklyStats()
        case .month:
            return statsManager.getMonthlyStats()
        case .year:
            return statsManager.getYearlyStats()
        }
    }
    
    private func loadData() {
        isLoading = true
        
        // Perform data loading asynchronously
        DispatchQueue.global(qos: .userInitiated).async {
            let calendar = Calendar.current
            var data: [DailyReading] = []
            
            let days = selectedPeriod == .week ? 7 : (selectedPeriod == .month ? 30 : 365)
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = selectedPeriod == .week ? "EEE" : "d"
            
            for i in 0..<min(days, 30) { // Limit to 30 for performance
                if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                    let stats = statsManager.getStatsForDate(date)
                    data.append(DailyReading(
                        date: date,
                        minutes: stats.totalMinutes,
                        pages: stats.pagesRead,
                        dayName: dateFormatter.string(from: date)
                    ))
                }
            }
            
            let reversedData = data.reversed()
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.weeklyData = Array(reversedData)
                self.isLoading = false
            }
        }
    }
    
    private func formatTime(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let mins = minutes % 60
            if mins == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(mins)m"
            }
        }
    }
}

// Custom Bar Chart Component
struct SimpleBarChart: View {
    let data: [EnhancedStatsView.DailyReading]
    let period: EnhancedStatsView.StatsPeriod
    
    private var maxValue: Double {
        data.map { $0.minutes }.max() ?? 1
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reading Activity")
                .font(.headline)
                .foregroundColor(.black)
            
            HStack(alignment: .bottom, spacing: period == .week ? 8 : 4) {
                ForEach(data) { reading in
                    VStack(spacing: 4) {
                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(hex: "4CAF50"))
                            .frame(height: max(2, CGFloat(reading.minutes) / CGFloat(maxValue) * 150))
                            .animation(.easeInOut(duration: 0.3), value: reading.minutes)
                        
                        // Label
                        Text(reading.dayName)
                            .font(.caption2)
                            .foregroundColor(.gray)
                        
                        // Value
                        if reading.minutes > 0 {
                            Text("\(Int(reading.minutes))")
                                .font(.caption2)
                                .foregroundColor(.black)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 200)
            .padding(.horizontal, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct StatsSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct StreakCard: View {
    let streak: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Streak")
                    .font(.headline)
                    .foregroundColor(.black)
                
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(streak) days")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                }
                
                Text("Keep it up!")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Visual streak indicator
            ZStack {
                Circle()
                    .stroke(Color.orange.opacity(0.2), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: min(CGFloat(streak) / 30, 1))
                    .stroke(Color.orange, lineWidth: 4)
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                Text("\(min(streak, 30))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5)
    }
}

struct ReadingInsights: View {
    let periodStats: StatsManager.PeriodStats
    
    var averageMinutesPerDay: Double {
        guard periodStats.daysActive > 0 else { return 0 }
        return periodStats.totalMinutes / Double(periodStats.daysActive)
    }
    
    var averagePagesPerDay: Double {
        guard periodStats.daysActive > 0 else { return 0 }
        return Double(periodStats.pagesRead) / Double(periodStats.daysActive)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Reading Insights")
                .font(.headline)
                .foregroundColor(.black)
            
            VStack(spacing: 12) {
                InsightRow(
                    icon: "clock.arrow.circlepath",
                    title: "Average Daily Time",
                    value: "\(Int(averageMinutesPerDay)) minutes"
                )
                
                InsightRow(
                    icon: "book.pages",
                    title: "Average Daily Pages",
                    value: "\(Int(averagePagesPerDay)) pages"
                )
                
                InsightRow(
                    icon: "calendar.badge.clock",
                    title: "Active Days",
                    value: "\(periodStats.daysActive) days"
                )
            }
            .padding()
            .background(Color.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5)
        }
    }
}

struct InsightRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(hex: "4CAF50"))
                .frame(width: 30)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.black)
        }
    }
}

struct AchievementsSection: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var achievements: [Achievement] {
        var totalPages = 0
        var totalHours = 0
        viewContext.performAndWait {
            totalPages = calculateTotalPages()
            totalHours = calculateTotalHours()
        }
        let currentStreak = StatsManager.shared.getStreak()
        
        return [
            Achievement(
                icon: "book.fill",
                title: "Book Worm",
                description: "Read 1000 pages",
                progress: min(Double(totalPages) / 1000, 1.0),
                isUnlocked: totalPages >= 1000
            ),
            Achievement(
                icon: "clock.fill",
                title: "Dedicated Reader",
                description: "Read for 10 hours",
                progress: min(Double(totalHours) / 10, 1.0),
                isUnlocked: totalHours >= 10
            ),
            Achievement(
                icon: "flame.fill",
                title: "Consistent",
                description: "7 day streak",
                progress: min(Double(currentStreak) / 7, 1.0),
                isUnlocked: currentStreak >= 7
            )
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Achievements")
                .font(.headline)
                .foregroundColor(.black)
            
            VStack(spacing: 12) {
                ForEach(achievements) { achievement in
                    AchievementRow(achievement: achievement)
                }
            }
        }
    }
    
    private func calculateTotalPages() -> Int {
        let request: NSFetchRequest<ReadingSession> = ReadingSession.fetchRequest()
        guard let sessions = try? viewContext.fetch(request) else { return 0 }
        return sessions.reduce(0) { $0 + Int($1.endPage - $1.startPage) }
    }
    
    private func calculateTotalHours() -> Int {
        let request: NSFetchRequest<ReadingSession> = ReadingSession.fetchRequest()
        guard let sessions = try? viewContext.fetch(request) else { return 0 }
        let totalMinutes = sessions.reduce(0.0) { total, session in
            return total + (session.actualReadingTime / 60.0)
        }
        return Int(totalMinutes / 60.0)
    }
}

struct Achievement: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let progress: Double
    let isUnlocked: Bool
}

struct AchievementRow: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color(hex: "4CAF50").opacity(0.1) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                if !achievement.isUnlocked {
                    Circle()
                        .trim(from: 0, to: achievement.progress)
                        .stroke(Color(hex: "4CAF50"), lineWidth: 2)
                        .frame(width: 50, height: 50)
                        .rotationEffect(.degrees(-90))
                }
                
                Image(systemName: achievement.icon)
                    .font(.title3)
                    .foregroundColor(achievement.isUnlocked ? Color(hex: "4CAF50") : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(achievement.isUnlocked ? .black : .gray)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                if !achievement.isUnlocked {
                    Text("\(Int(achievement.progress * 100))% complete")
                        .font(.caption2)
                        .foregroundColor(Color(hex: "4CAF50"))
                }
            }
            
            Spacer()
            
            if achievement.isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color(hex: "4CAF50"))
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.03), radius: 3)
    }
}

#Preview {
    EnhancedStatsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
