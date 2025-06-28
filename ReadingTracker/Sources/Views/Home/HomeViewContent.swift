// HomeViewContent.swift
import SwiftUI
import CoreData

struct HomeViewContent: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var statsManager = StatsManager.shared
    @Binding var currentDate: Date
    @State private var userName = "Reader"
    @State private var showingAddBook = false
    @State private var refreshID = UUID()
    @State private var todayStats = StatsManager.DailyStats(
        totalMinutes: 0,
        pagesRead: 0,
        sessionsCount: 0,
        averageFocusScore: 0,
        favoriteLocation: nil
    )
    @State private var weeklyStats = StatsManager.PeriodStats(
        totalMinutes: 0,
        pagesRead: 0,
        sessionsCount: 0,
        daysActive: 0
    )
    @State private var currentStreak = 0
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)],
        predicate: NSPredicate(format: "isActive == YES"),
        animation: .default
    ) private var activeBooks: FetchedResults<Book>
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Hey, \(userName)!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.top, 20)
                        .padding(.bottom, 24)
                    
                    // Today's Stats
                    HStack(spacing: 12) {
                        QuickStatCard(
                            icon: "book",
                            value: "\(todayStats.pagesRead)",
                            label: "pages today",
                            iconColor: .black.opacity(0.6),
                            backgroundColor: Color.gray.opacity(0.1)
                        )
                        
                        QuickStatCard(
                            icon: "clock",
                            value: "\(Int(todayStats.totalMinutes))",
                            label: "minutes",
                            iconColor: .black.opacity(0.6),
                            backgroundColor: Color.gray.opacity(0.1)
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                    
                    // Quick Stats Preview with navigation to full stats
                    Button(action: {
                        NavigationCoordinator.shared.navigateToStatsTab()
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Week Overview")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                
                                HStack(spacing: 16) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "flame.fill")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                        Text("\(currentStreak) day streak")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.black)
                                    }
                                    
                                    Text("•")
                                        .foregroundColor(.gray.opacity(0.5))
                                    
                                    Text("\(weeklyStats.pagesRead) pages this week")
                                        .font(.caption)
                                        .foregroundColor(.black)
                                }
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .background(Color(hex: "4CAF50").opacity(0.1))
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    
                    // Currently Reading Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Currently Reading")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 24)
                        
                        if activeBooks.isEmpty {
                            EmptyBooksView()
                                .padding(.horizontal, 24)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(activeBooks, id: \.objectID) { book in
                                    BookRowView(book: book)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    
                    Spacer(minLength: 50)
                }
            }
            .refreshable {
                await refreshData()
            }
            .onReceive(NotificationCenter.default.publisher(for: .sessionEnded)) { _ in
                Task {
                    await refreshData()
                }
            }
            .task {
                await loadStats()
            }
            .onChange(of: currentDate) { _ in
                Task {
                    await loadStats()
                }
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton(action: {
                        showingAddBook = true
                    })
                    .padding(.trailing, 24)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showingAddBook) {
            AddBookView()
                .environment(\.managedObjectContext, viewContext)
        }
    }
    
    @MainActor
    private func loadStats() async {
        // Load stats asynchronously to avoid blocking UI
        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor in
                self.todayStats = self.statsManager.getTodayStats()
            }
            
            group.addTask { @MainActor in
                self.weeklyStats = self.statsManager.getWeeklyStats()
            }
            
            group.addTask { @MainActor in
                self.currentStreak = self.statsManager.getStreak()
            }
        }
    }
    
    @MainActor
    private func refreshData() async {
        // Refresh Core Data
        await viewContext.perform {
            self.viewContext.refreshAllObjects()
        }
        
        // Reload stats
        await loadStats()
        
        // Update refresh ID to force view refresh
        refreshID = UUID()
    }
}
