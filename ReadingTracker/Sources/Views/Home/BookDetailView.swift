//
//  BookDetailView.swift
//  ReadingTracker
//
//  Created by 이재준 on 7/3/25.
//


// MARK: - 최종 BookDetailView (기존 파일 교체용)
import SwiftUI
import CoreData
import os.log

@MainActor
struct BookDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var book: Book
    
    // 🔥 SessionManager를 직접 관찰하지 않음
    private let sessionManager = SessionManager.shared
    private let trackingCoordinator = AppLevelTrackingCoordinator.shared
    
    @State private var refreshID = UUID()
    @State private var error: BookDetailError?
    @State private var isHandlingAction = false
    
    // Modern logging system
    private let logger = Logger(subsystem: "BookDetailView", category: "UI")
    
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
            return "아직 시작하지 않음"
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
                        
                        Text("마지막 독서: \(lastReadingDate)")
                            .font(.system(size: 14))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Progress Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(book.currentPage) / \(book.totalPages) 페이지")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.black)
                                
                                Text("\(Int(book.percentComplete))% 완료")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            // Reading stats
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(totalReadingTime) 분")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.black)
                                
                                Text("총 독서 시간")
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
                        Text("독서 세션")
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
                                        .onTapGesture {
                                            handleSessionTap(session)
                                        }
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
                        handleStartSession()
                    })
                    .disabled(isHandlingAction)
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
        .onReceive(NotificationCenter.default.publisher(for: .sessionEnded)) { _ in
            Task {
                await refreshSessions()
            }
        }
        .task {
            logger.info("BookDetailView appeared for book: \(book.title)")
        }
        .errorAlert($error)
    }
    
    // MARK: - Private Methods
    private func handleSessionTap(_ session: ReadingSession) {
        guard !isHandlingAction else { return }
        
        // 현재 세션 상태를 직접 확인 (관찰하지 않음)
        let currentSession = sessionManager.currentSession
        
        if let currentSession = currentSession,
           currentSession.objectID == session.objectID,
           currentSession.endTime == nil {
            logger.info("Opening active session: \(session.id)")
            presentTrackingOverlay()
        } else {
            logger.info("Tapped completed session: \(session.id)")
        }
    }
    
    private func handleStartSession() {
        guard !isHandlingAction else {
            logger.warning("Action already in progress")
            return
        }
        
        logger.info("Starting new session for book: \(book.title)")
        presentTrackingOverlay()
    }
    
    private func presentTrackingOverlay() {
        guard !isHandlingAction else { return }
        
        isHandlingAction = true
        
        // 🔥 앱 레벨 코디네이터를 통해 모달 표시
        trackingCoordinator.presentTrackingOverlay(for: book)
        
        // Reset action flag
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.isHandlingAction = false
        }
    }
    
    private func refreshSessions() async {
        logger.info("Refreshing sessions for book: \(book.title)")
        
        // UI 새로고침
        refreshID = UUID()
        
        // 추가 새로고침
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.refreshID = UUID()
        }
    }
    
    private var totalReadingTime: Int {
        sessions.reduce(0) { total, session in
            total + Int(session.actualReadingTime / 60)
        }
    }
}

// MARK: - Error Types
enum BookDetailError: LocalizedError {
    case sessionStartFailed(Error)
    case dataRefreshFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .sessionStartFailed(let error):
            return "세션 시작 실패: \(error.localizedDescription)"
        case .dataRefreshFailed(let error):
            return "데이터 새로고침 실패: \(error.localizedDescription)"
        }
    }
}

// MARK: - Supporting Views
struct EmptySessionsView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 40))
                .foregroundColor(.gray.opacity(0.3))
            
            Text("아직 독서 세션이 없습니다")
                .font(.subheadline)
                .foregroundColor(.gray)
            
            Text("+ 버튼을 눌러 첫 세션을 시작하세요")
                .font(.caption)
                .foregroundColor(.gray.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Error Alert Extension
extension View {
    func errorAlert(_ error: Binding<BookDetailError?>) -> some View {
        alert("오류", isPresented: .constant(error.wrappedValue != nil)) {
            Button("확인") {
                error.wrappedValue = nil
            }
        } message: {
            Text(error.wrappedValue?.errorDescription ?? "알 수 없는 오류가 발생했습니다.")
        }
    }
}

#Preview {
    BookDetailView(book: Book())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

// MARK: - 구현 가이드라인