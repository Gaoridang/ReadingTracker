// BookDetailView.swift
import SwiftUI
import CoreData

struct BookDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var book: Book
    @State private var showingAddSession = false
    @State private var showingTrackingOverlay = false
    @State private var refreshID = UUID()
    
    // Fetch sessions for this book
    @FetchRequest private var sessions: FetchedResults<ReadingSession>
    
    init(book: Book) {
        self.book = book
        self._sessions = FetchRequest<ReadingSession>(
            sortDescriptors: [NSSortDescriptor(keyPath: \ReadingSession.startTime, ascending: false)],
            predicate: NSPredicate(format: "book == %@", book)
        )
    }
    
    var lastReadingDate: String {
        guard let lastSession = sessions.first else {
            return "Not started yet"
        }
        
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastSession.startTime, relativeTo: Date())
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text(book.title)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text(book.author)
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                        
                        Text("Last read \(lastReadingDate)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Progress Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(book.currentPage) of \(book.totalPages) pages")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.black)
                                
                                Text("\(Int(book.percentComplete))% complete")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            // Reading stats
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(totalReadingTime) min")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.black)
                                
                                Text("Total time")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Progress Bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.1))
                                    .frame(height: 8)
                                    .cornerRadius(4)
                                
                                Rectangle()
                                    .fill(Color(hex: "4CAF50"))
                                    .frame(width: geometry.size.width * (book.percentComplete / 100), height: 8)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .background(Color.gray.opacity(0.05))
                    
                    // Sessions Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Reading Sessions")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 24)
                        
                        if sessions.isEmpty {
                            EmptySessionsView()
                                .padding(.horizontal, 24)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(sessions) { session in
                                    SessionRowView(session: session)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }
                    .id(refreshID)
                    
                    // Bottom padding
                    Spacer(minLength: 100)
                }
            }
            
            // Floating Action Button for adding session
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    FloatingActionButton(action: {
                        showingAddSession = true
                    })
                    .padding(.trailing, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Add edit functionality here
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.black)
                }
            }
        }
        .sheet(isPresented: $showingAddSession) {
            StartSessionView(book: book, onStarted: {
                showingTrackingOverlay = true
            })
            .environment(\.managedObjectContext, viewContext)
            .interactiveDismissDisabled()
        }
        // Present TrackingOverlayView
        .fullScreenCover(isPresented: $showingTrackingOverlay) {
            TrackingOverlayView(isPresented: $showingTrackingOverlay, book: book, onSessionEnded: {
                refreshID = UUID()
            })
            .environment(\.managedObjectContext, viewContext)
        }
    }
    
    private var totalReadingTime: Int {
        sessions.reduce(0) { total, session in
            total + Int(session.actualReadingTime / 60)
        }
    }
}

// Empty Sessions View
struct EmptySessionsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("No reading sessions yet")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("Tap + to start your first session")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// Disable preview - Core Data relationships can cause preview crashes
// Test by running the app in simulator
/*
#Preview {
    NavigationView {
        BookDetailView(book: Book.preview)
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
*/
