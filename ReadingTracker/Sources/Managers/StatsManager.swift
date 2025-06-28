// StatsManager.swift
import Foundation
import CoreData

class StatsManager: ObservableObject {
    static let shared = StatsManager()
        
    struct DailyStats {
        let totalMinutes: Double
        let pagesRead: Int
        let sessionsCount: Int
        let averageFocusScore: Double
        let favoriteLocation: String?
    }
    
    struct PeriodStats {
        let totalMinutes: Double
        let pagesRead: Int
        let sessionsCount: Int
        let daysActive: Int
    }
    
    private let context = PersistenceController.shared.container.viewContext
    
    @MainActor
    func getStatsForDate(_ date: Date) -> DailyStats {
        do {
            let sessions = try fetchSessions(for: date)
            
            let totalMinutes = sessions.reduce(0.0) { total, session in
                return total + (session.actualReadingTime / 60.0)
            }
            
            let pagesRead = sessions.reduce(0) { $0 + Int($1.endPage - $1.startPage) }
            
            let avgFocus = sessions.isEmpty ? 0 : sessions.reduce(0) { total, session in
                total + session.focusScore
            } / Double(sessions.count)
            
            let locations = sessions.compactMap { $0.location }
            let favoriteLocation = locations.isEmpty ? nil : mostFrequent(locations)
            
            return DailyStats(
                totalMinutes: totalMinutes,
                pagesRead: pagesRead,
                sessionsCount: sessions.count,
                averageFocusScore: avgFocus,
                favoriteLocation: favoriteLocation
            )
        } catch {
            print("Error fetching sessions for stats: \(error)")
            return DailyStats(totalMinutes: 0, pagesRead: 0, sessionsCount: 0, averageFocusScore: 0, favoriteLocation: nil)
        }
    }
    
    @MainActor
    func getTodayStats() -> DailyStats {
        return getStatsForDate(Date())
    }
    
    @MainActor
    func getWeeklyStats() -> PeriodStats {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -7, to: endDate)!
        
        return getStatsForPeriod(from: startDate, to: endDate)
    }
    
    @MainActor
    func getMonthlyStats() -> PeriodStats {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .month, value: -1, to: endDate)!
        
        return getStatsForPeriod(from: startDate, to: endDate)
    }
    
    @MainActor
    func getYearlyStats() -> PeriodStats {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .year, value: -1, to: endDate)!
        
        return getStatsForPeriod(from: startDate, to: endDate)
    }
    
    @MainActor
    private func getStatsForPeriod(from startDate: Date, to endDate: Date) -> PeriodStats {
        do {
            let sessions = try fetchSessionsForPeriod(from: startDate, to: endDate)
            
            let totalMinutes = sessions.reduce(0.0) { total, session in
                return total + (session.actualReadingTime / 60.0)
            }
            
            let pagesRead = sessions.reduce(0) { $0 + Int($1.endPage - $1.startPage) }
            
            let calendar = Calendar.current
            let uniqueDays = Set(sessions.map { calendar.startOfDay(for: $0.startTime) }).count
            
            return PeriodStats(
                totalMinutes: totalMinutes,
                pagesRead: pagesRead,
                sessionsCount: sessions.count,
                daysActive: uniqueDays
            )
        } catch {
            print("Error fetching period stats: \(error)")
            return PeriodStats(totalMinutes: 0, pagesRead: 0, sessionsCount: 0, daysActive: 0)
        }
    }
    
    @MainActor
    func getStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var date = Date()
        
        while true {
            do {
                let sessions = try fetchSessions(for: date)
                if sessions.isEmpty {
                    if calendar.isDateInToday(date) {
                        return streak
                    }
                    break
                }
                streak += 1
                date = calendar.date(byAdding: .day, value: -1, to: date)!
            } catch {
                print("Error fetching sessions for streak: \(error)")
                break
            }
        }
        
        return streak
    }
    
    @MainActor
    func getReadingHistory(days: Int) -> [(date: Date, minutes: Double, pages: Int)] {
        let calendar = Calendar.current
        var history: [(date: Date, minutes: Double, pages: Int)] = []
        
        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let stats = getStatsForDate(date)
                history.append((date: date, minutes: stats.totalMinutes, pages: stats.pagesRead))
            }
        }
        
        return history.reversed()
    }
    
    @MainActor
    private func fetchSessions(for date: Date) throws -> [ReadingSession] {
        let request: NSFetchRequest<ReadingSession> = ReadingSession.fetchRequest()
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@",
                                       startOfDay as NSDate, endOfDay as NSDate)
        
        return try context.fetch(request)
    }
    
    @MainActor
    private func fetchSessionsForPeriod(from startDate: Date, to endDate: Date) throws -> [ReadingSession] {
        let request: NSFetchRequest<ReadingSession> = ReadingSession.fetchRequest()
        
        let calendar = Calendar.current
        let startOfStartDate = calendar.startOfDay(for: startDate)
        let endOfEndDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: endDate))!
        
        request.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@",
                                       startOfStartDate as NSDate, endOfEndDate as NSDate)
        
        return try context.fetch(request)
    }
    
    private func mostFrequent<T: Hashable>(_ array: [T]) -> T? {
        let counts = array.reduce(into: [:]) { counts, element in
            counts[element, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }
    
    // MARK: - Achievement Helpers
    
    @MainActor
    func getTotalPagesAllTime() -> Int {
        let request: NSFetchRequest<ReadingSession> = ReadingSession.fetchRequest()
        
        do {
            let sessions = try context.fetch(request)
            return sessions.reduce(0) { $0 + Int($1.endPage - $1.startPage) }
        } catch {
            print("Error fetching total pages: \(error)")
            return 0
        }
    }
    
    @MainActor
    func getTotalHoursAllTime() -> Int {
        let request: NSFetchRequest<ReadingSession> = ReadingSession.fetchRequest()
        
        do {
            let sessions = try context.fetch(request)
            let totalMinutes = sessions.reduce(0.0) { total, session in
                return total + (session.actualReadingTime / 60.0)
            }
            return Int(totalMinutes / 60.0)
        } catch {
            print("Error fetching total hours: \(error)")
            return 0
        }
    }
    
    @MainActor
    func getLongestStreak() -> Int {
        // This would require storing historical streak data
        // For now, return current streak
        return getStreak()
    }
    
    // MARK: - Reading Speed Analytics
    
    @MainActor
    func getAverageReadingSpeed() -> Double {
        let request: NSFetchRequest<ReadingSession> = ReadingSession.fetchRequest()
        
        do {
            let sessions = try context.fetch(request)
            let validSessions = sessions.filter { session in
                let duration = session.actualReadingTime / 60.0
                return duration > 5 && session.pagesRead > 0
            }
            
            guard !validSessions.isEmpty else { return 0 }
            
            let totalPages = validSessions.reduce(0) { $0 + $1.pagesRead }
            let totalMinutes = validSessions.reduce(0.0) { total, session in
                return total + (session.actualReadingTime / 60.0)
            }
            
            guard totalMinutes > 0 else { return 0 }
            
            return Double(totalPages) / totalMinutes * 60 // Pages per hour
        } catch {
            print("Error calculating reading speed: \(error)")
            return 0
        }
    }
}
