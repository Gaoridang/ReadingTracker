// HomeView.swift
import SwiftUI
import CoreData

// Separate HomeViewContent without date navigation
struct HomeViewContent: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var statsManager = StatsManager.shared
    @Binding var currentDate: Date
    @State private var userName = "Reader"
    @State private var showingAddBook = false
    @State private var refreshID = UUID() // Add this to force refresh
    
    var activeBooks: [Book] {
        let request: NSFetchRequest<Book> = Book.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            return []
        }
    }
    
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
                    
                    HStack(spacing: 12) {
                        QuickStatCard(
                            icon: "book",
                            value: "\(statsManager.getTodayStats().pagesRead)",
                            label: "pages today",
                            iconColor: .black.opacity(0.6),
                            backgroundColor: Color.gray.opacity(0.1)
                        )
                        
                        QuickStatCard(
                            icon: "clock",
                            value: "\(statsManager.getTodayStats().totalMinutes)",
                            label: "minutes",
                            iconColor: .black.opacity(0.6),
                            backgroundColor: Color.gray.opacity(0.1)
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                    
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
                viewContext.refreshAllObjects()
            }
            // Listen for session end notification
            .onReceive(NotificationCenter.default.publisher(for: .sessionEnded)) { _ in
                refreshID = UUID() // Trigger a refresh
            }
            .id(refreshID) // Force re-render when refreshID changes
            
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
}
