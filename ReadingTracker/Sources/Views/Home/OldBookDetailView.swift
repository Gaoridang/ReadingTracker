//import SwiftUI
//import CoreData
//import os.log
//
//@MainActor
//struct OldBookDetailView: View {
//    @Environment(\.managedObjectContext) private var viewContext
//    @Environment(\.dismiss) private var dismiss
//    @ObservedObject var book: Book
//    
//    // 🔥 SessionManager를 직접 관찰하지 않음 - 참조만 사용
//    private let sessionManager = SessionManager.shared
//    
//    @State private var refreshID = UUID()
//    @State private var error: BookDetailError?
//    
//    // 🔥 완전히 분리된 모달 상태 관리
//    @State private var isTrackingOverlayPresented = false
//    @State private var modalPresentationID = UUID() // 모달 고유성 보장
//    @State private var isHandlingAction = false // 중복 액션 방지
//    
//    // Modern logging system
//    private let logger = Logger(subsystem: "BookDetailView", category: "UI")
//    
//    // Fetch sessions for this book
//    @FetchRequest private var sessions: FetchedResults<ReadingSession>
//    
//    init(book: Book) {
//        self.book = book
//        self._sessions = FetchRequest<ReadingSession>(
//            sortDescriptors: [NSSortDescriptor(keyPath: \ReadingSession.startTime, ascending: false)],
//            predicate: NSPredicate(format: "book == %@", book)
//        )
//    }
//    
//    var lastReadingDate: String {
//        guard let lastSession = sessions.first else {
//            return "아직 시작하지 않음"
//        }
//        
//        let formatter = RelativeDateTimeFormatter()
//        formatter.unitsStyle = .full
//        return formatter.localizedString(for: lastSession.startTime, relativeTo: Date())
//    }
//    
//    var body: some View {
//        ZStack {
//            Color.white
//                .ignoresSafeArea()
//            
//            ScrollView {
//                VStack(alignment: .leading, spacing: 24) {
//                    // Header Section
//                    VStack(alignment: .leading, spacing: 12) {
//                        Text(book.title)
//                            .font(.system(size: 28, weight: .bold))
//                            .foregroundColor(.black)
//                        
//                        Text(book.author)
//                            .font(.system(size: 18))
//                            .foregroundColor(.gray)
//                        
//                        Text("마지막 독서: \(lastReadingDate)")
//                            .font(.system(size: 14))
//                            .foregroundColor(.gray.opacity(0.8))
//                    }
//                    .padding(.horizontal, 24)
//                    .padding(.top, 20)
//                    
//                    // Progress Section
//                    VStack(alignment: .leading, spacing: 16) {
//                        HStack {
//                            VStack(alignment: .leading, spacing: 4) {
//                                Text("\(book.currentPage) / \(book.totalPages) 페이지")
//                                    .font(.system(size: 16, weight: .medium))
//                                    .foregroundColor(.black)
//                                
//                                Text("\(Int(book.percentComplete))% 완료")
//                                    .font(.system(size: 14))
//                                    .foregroundColor(.gray)
//                            }
//                            
//                            Spacer()
//                            
//                            // Reading stats
//                            VStack(alignment: .trailing, spacing: 4) {
//                                Text("\(totalReadingTime) 분")
//                                    .font(.system(size: 16, weight: .medium))
//                                    .foregroundColor(.black)
//                                
//                                Text("총 독서 시간")
//                                    .font(.system(size: 14))
//                                    .foregroundColor(.gray)
//                            }
//                        }
//                        
//                        // Progress Bar
//                        GeometryReader { geometry in
//                            ZStack(alignment: .leading) {
//                                Rectangle()
//                                    .fill(Color.gray.opacity(0.1))
//                                    .frame(height: 8)
//                                    .cornerRadius(4)
//                                
//                                Rectangle()
//                                    .fill(Color(hex: "4CAF50"))
//                                    .frame(width: geometry.size.width * (book.percentComplete / 100), height: 8)
//                                    .cornerRadius(4)
//                            }
//                        }
//                        .frame(height: 8)
//                    }
//                    .padding(.horizontal, 24)
//                    .padding(.vertical, 20)
//                    .background(Color.gray.opacity(0.05))
//                    
//                    // Sessions Section
//                    VStack(alignment: .leading, spacing: 16) {
//                        Text("독서 세션")
//                            .font(.system(size: 20, weight: .semibold))
//                            .foregroundColor(.black)
//                            .padding(.horizontal, 24)
//                        
//                        if sessions.isEmpty {
//                            EmptySessionsView()
//                                .padding(.horizontal, 24)
//                        } else {
//                            VStack(spacing: 12) {
//                                ForEach(sessions) { session in
//                                    SessionRowView(session: session)
//                                        .onTapGesture {
//                                            handleSessionTap(session)
//                                        }
//                                }
//                            }
//                            .padding(.horizontal, 24)
//                        }
//                    }
//                    .id(refreshID)
//                    
//                    // Bottom padding
//                    Spacer(minLength: 100)
//                }
//            }
//            
//            // Floating Action Button for adding session
//            VStack {
//                Spacer()
//                HStack {
//                    Spacer()
//                    FloatingActionButton(action: {
//                        handleStartSession()
//                    })
//                    .disabled(isHandlingAction) // 중복 방지
//                    .padding(.trailing, 24)
//                    .padding(.bottom, 40)
//                }
//            }
//        }
//        .navigationBarTitleDisplayMode(.inline)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarTrailing) {
//                Button(action: {
//                    // Add edit functionality here
//                }) {
//                    Image(systemName: "ellipsis")
//                        .foregroundColor(.black)
//                }
//            }
//        }
//        // 🔥 완전히 분리된 모달 표시 방식
//        .fullScreenCover(isPresented: $isTrackingOverlayPresented, onDismiss: {
//            handleModalDismiss()
//        }) {
//            TrackingOverlayView(
//                isPresented: $isTrackingOverlayPresented,
//                book: book,
//                onSessionEnded: {
//                    handleSessionEnded()
//                }
//            )
//            .environment(\.managedObjectContext, viewContext)
//            .id(modalPresentationID) // 모달 고유성 보장
//        }
//        .task {
//            logger.info("BookDetailView appeared for book: \(book.title)")
//        }
//        .errorAlert($error)
//    }
//    
//    // MARK: - Private Methods
//    private func handleSessionTap(_ session: ReadingSession) {
//        // 중복 처리 방지
//        guard !isHandlingAction else { return }
//        
//        // 현재 세션 상태를 직접 확인 (관찰하지 않음)
//        let currentSession = sessionManager.currentSession
//        
//        // Only open TrackingOverlayView if this is the current active session and not ended
//        if let currentSession = currentSession,
//           currentSession.objectID == session.objectID,
//           currentSession.endTime == nil {
//            logger.info("Opening active session: \(session.id)")
//            presentTrackingOverlay()
//        } else {
//            logger.info("Tapped completed session: \(session.id)")
//            // Could add session detail view here
//        }
//    }
//    
//    private func handleStartSession() {
//        // 중복 처리 방지
//        guard !isHandlingAction, !isTrackingOverlayPresented else {
//            logger.warning("Action already in progress or modal already presented")
//            return
//        }
//        
//        logger.info("Starting new session for book: \(book.title)")
//        presentTrackingOverlay()
//    }
//    
//    private func presentTrackingOverlay() {
//        // 중복 방지 및 상태 설정
//        guard !isTrackingOverlayPresented else { return }
//        
//        isHandlingAction = true
//        modalPresentationID = UUID() // 새로운 모달 ID 생성
//        
//        // 지연을 통해 상태 변경과 모달 표시 분리
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
//            self.isTrackingOverlayPresented = true
//            
//            // 액션 처리 완료
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                self.isHandlingAction = false
//            }
//        }
//    }
//    
//    private func handleModalDismiss() {
//        logger.info("Modal dismissed")
//        isHandlingAction = false
//    }
//    
//    private func handleSessionEnded() {
//        logger.info("Session ended - refreshing data")
//        
//        // 모달 해제 후 데이터 새로고침
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            self.refreshSessions()
//        }
//    }
//    
//    private func refreshSessions() {
//        logger.info("Refreshing sessions for book: \(book.title)")
//        
//        // UI 새로고침
//        refreshID = UUID()
//        
//        // 추가 새로고침 (CoreData 변경 감지용)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
//            self.refreshID = UUID()
//        }
//    }
//    
//    private var totalReadingTime: Int {
//        sessions.reduce(0) { total, session in
//            total + Int(session.actualReadingTime / 60)
//        }
//    }
//}
//
//// MARK: - Error Types
//enum BookDetailError: LocalizedError {
//    case sessionStartFailed(Error)
//    case dataRefreshFailed(Error)
//    
//    var errorDescription: String? {
//        switch self {
//        case .sessionStartFailed(let error):
//            return "세션 시작 실패: \(error.localizedDescription)"
//        case .dataRefreshFailed(let error):
//            return "데이터 새로고침 실패: \(error.localizedDescription)"
//        }
//    }
//}
//
//// MARK: - Empty Sessions View
//struct EmptySessionsView: View {
//    var body: some View {
//        VStack(spacing: 12) {
//            Image(systemName: "clock")
//                .font(.system(size: 40))
//                .foregroundColor(.gray.opacity(0.3))
//            
//            Text("아직 독서 세션이 없습니다")
//                .font(.subheadline)
//                .foregroundColor(.gray)
//            
//            Text("+ 버튼을 눌러 첫 세션을 시작하세요")
//                .font(.caption)
//                .foregroundColor(.gray.opacity(0.8))
//        }
//        .frame(maxWidth: .infinity)
//        .padding(.vertical, 40)
//        .background(Color.gray.opacity(0.05))
//        .cornerRadius(12)
//    }
//}
//
//// MARK: - Error Alert Extension
//extension View {
//    func errorAlert(_ error: Binding<BookDetailError?>) -> some View {
//        alert("오류", isPresented: .constant(error.wrappedValue != nil)) {
//            Button("확인") {
//                error.wrappedValue = nil
//            }
//        } message: {
//            Text(error.wrappedValue?.errorDescription ?? "알 수 없는 오류가 발생했습니다.")
//        }
//    }
//}
//
//#Preview {
//    BookDetailView(book: Book())
//        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//}
