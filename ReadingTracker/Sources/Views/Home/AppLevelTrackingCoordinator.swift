import SwiftUI
import Combine
import os.log

// MARK: - App Level Tracking Coordinator
@MainActor
class AppLevelTrackingCoordinator: ObservableObject {
    static let shared = AppLevelTrackingCoordinator()
    
    @Published var isTrackingOverlayPresented = false
    @Published var currentTrackingBook: Book?
    
    private let logger = Logger(subsystem: "AppLevelTrackingCoordinator", category: "Modal")
    private var presentationID = UUID()
    
    private init() {}
    
    func presentTrackingOverlay(for book: Book) {
        guard !isTrackingOverlayPresented else {
            logger.warning("Tracking overlay already presented")
            return
        }
        
        logger.info("Presenting tracking overlay for book: \(book.title)")
        currentTrackingBook = book
        presentationID = UUID()
        
        // Small delay to ensure state consistency
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.isTrackingOverlayPresented = true
        }
    }
    
    func dismissTrackingOverlay() {
        logger.info("Dismissing tracking overlay")
        isTrackingOverlayPresented = false
        
        // Clean up after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.currentTrackingBook = nil
        }
    }
    
    var currentPresentationID: UUID {
        presentationID
    }
}

// MARK: - App Level Tracking View
struct AppLevelTrackingView: View {
    @StateObject private var coordinator = AppLevelTrackingCoordinator.shared
    @Environment(\.managedObjectContext) private var viewContext
    
    let content: AnyView
    
    init<Content: View>(@ViewBuilder content: () -> Content) {
        self.content = AnyView(content())
    }
    
    var body: some View {
        ZStack {
            content
        }
        .fullScreenCover(
            isPresented: $coordinator.isTrackingOverlayPresented,
            onDismiss: {
                coordinator.dismissTrackingOverlay()
            }
        ) {
            if let book = coordinator.currentTrackingBook {
                SimplifiedTrackingOverlayView(
                    isPresented: $coordinator.isTrackingOverlayPresented,
                    book: book,
                    onSessionEnded: {
                        coordinator.dismissTrackingOverlay()
                        
                        // Notify other views of session completion
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NotificationCenter.default.post(name: .sessionEnded, object: nil)
                        }
                    }
                )
                .environment(\.managedObjectContext, viewContext)
                .id(coordinator.currentPresentationID)
            }
        }
    }
}

// MARK: - Simplified TrackingOverlayView (앱 레벨 관리용)
struct SimplifiedTrackingOverlayView: View {
    @Environment(\.managedObjectContext) private var viewContext
    private let sessionManager = SessionManager.shared
    private let trackingCoordinator = AppLevelTrackingCoordinator.shared
    
    @State private var startingPage = ""
    @State private var showingEndSession = false
    @State private var showingCancelConfirmation = false
    @State private var isSessionStarted = false
    @State private var isStartingSession = false
    @State private var error: TrackingError?
    @State private var finalDuration: TimeInterval = 0
    @State private var isProcessingAction = false
    @State private var hasInitialized = false
    
    // 로컬 상태 관리
    @State private var localIsTracking = false
    @State private var localIsPaused = false
    @State private var localDistractionCount = 0
    @State private var localTotalReadingTime: TimeInterval = 0
    @State private var localCurrentSession: ReadingSession?
    @State private var localStartTime: Date?
    
    @FocusState private var isStartingPageFocused: Bool
    @Binding var isPresented: Bool
    let book: Book
    let onSessionEnded: () -> Void
    
    private let logger = Logger(subsystem: "SimplifiedTrackingOverlayView", category: "Session")
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
                .onTapGesture {
                    isStartingPageFocused = false
                }
            
            VStack(spacing: 0) {
                // Minimal Header
                HStack {
                    if isSessionStarted {
                        Button(action: {
                            guard !isProcessingAction else { return }
                            showingCancelConfirmation = true
                        }) {
                            Text("취소")
                                .font(.body)
                                .foregroundColor(.red)
                        }
                        .disabled(isProcessingAction)
                    } else {
                        Button(action: {
                            logger.info("User tapped cancel button")
                            trackingCoordinator.dismissTrackingOverlay()
                        }) {
                            Text("취소")
                                .font(.body)
                                .foregroundColor(.red)
                        }
                    }
                    Spacer()
                    Text(book.title)
                        .font(.headline)
                        .foregroundColor(.black)
                        .lineLimit(1)
                    Spacer()
                    Text("취소")
                        .font(.body)
                        .foregroundColor(.clear)
                }
                .padding()
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 0.5),
                    alignment: .bottom
                )
                
                // Main Content
                VStack(spacing: 40) {
                    Spacer()
                    
                    // Starting Page Input (before session starts)
                    if !isSessionStarted {
                        VStack(spacing: 20) {
                            Image(systemName: "book.pages")
                                .font(.system(size: 50))
                                .foregroundColor(Color(hex: "4CAF50"))
                                .padding(.bottom, 20)
                            
                            Text("어느 페이지부터 시작하시나요?")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.black)
                            
                            VStack(spacing: 12) {
                                HStack {
                                    Text("페이지")
                                        .font(.body)
                                        .foregroundColor(.gray)
                                    
                                    TextField("\(book.currentPage)", text: $startingPage)
                                        .keyboardType(.numberPad)
                                        .font(.system(size: 24, weight: .medium))
                                        .multilineTextAlignment(.center)
                                        .frame(width: 100)
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 16)
                                        .background(Color.gray.opacity(0.08))
                                        .cornerRadius(12)
                                        .focused($isStartingPageFocused)
                                }
                                
                                Text("책 진행률: \(book.currentPage) / \(book.totalPages) 페이지")
                                    .font(.caption)
                                    .foregroundColor(.gray.opacity(0.8))
                            }
                        }
                    }
                    
                    // Timer Display (after session starts)
                    if isSessionStarted {
                        TimelineView(.periodic(from: Date(), by: 1.0)) { context in
                            Text(timeString(from: calculateCurrentDuration(at: context.date)))
                                .font(.system(size: 56, weight: .light, design: .monospaced))
                                .foregroundColor(.black)
                        }
                        .padding(.vertical, 20)
                    }
                    
                    // Starting Page Display (after session starts)
                    if isSessionStarted {
                        VStack(spacing: 12) {
                            Text("시작 페이지")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            
                            HStack {
                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(Color(hex: "4CAF50"))
                                
                                if let session = localCurrentSession {
                                    Text("\(session.startPage) 페이지")
                                        .font(.system(size: 28, weight: .medium))
                                        .foregroundColor(.black)
                                }
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 24)
                            .background(Color.gray.opacity(0.08))
                            .cornerRadius(16)
                            
                            Text("독서에 집중하세요")
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.8))
                        }
                    }
                    
                    // Distraction Counter (after session starts)
                    if isSessionStarted {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                            Text("방해 요소: \(localDistractionCount)")
                                .font(.body)
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(20)
                    }
                    
                    Spacer()
                    
                    // Control Buttons
                    VStack(spacing: 16) {
                        // Pause/Resume and Distraction buttons (after session starts)
                        if isSessionStarted {
                            HStack {
                                Button(action: {
                                    guard !isProcessingAction else { return }
                                    Task { await toggleReading() }
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: localIsPaused ? "play.fill" : "pause.fill")
                                            .font(.title2)
                                        Text(localIsPaused ? "재개" : "일시정지")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(localIsPaused ? .white : .black)
                                    .frame(width: 100, height: 80)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(localIsPaused ? Color.orange : Color.gray.opacity(0.1))
                                            .shadow(color: .black.opacity(0.05), radius: 5)
                                    )
                                }
                                .disabled(isProcessingAction)
                                
                                if !localIsPaused {
                                    Button(action: {
                                        guard !isProcessingAction else { return }
                                        Task { await recordDistraction() }
                                    }) {
                                        VStack(spacing: 8) {
                                            Image(systemName: "hand.raised.fill")
                                                .font(.title2)
                                            Text("방해 요소")
                                                .font(.caption)
                                                .fontWeight(.medium)
                                        }
                                        .foregroundColor(.black)
                                        .frame(width: 100, height: 80)
                                        .background(
                                            RoundedRectangle(cornerRadius: 20)
                                                .fill(Color.gray.opacity(0.1))
                                                .shadow(color: .black.opacity(0.05), radius: 5)
                                        )
                                    }
                                    .disabled(isProcessingAction)
                                }
                            }
                            .padding(.horizontal, 40)
                        }
                        
                        // Start Session / End Session button
                        if !isSessionStarted {
                            if isStartingSession {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(1.5)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color(hex: "4CAF50"))
                                    .cornerRadius(28)
                            } else {
                                Button(action: {
                                    guard !isProcessingAction else { return }
                                    Task { await startSession() }
                                }) {
                                    Text("세션 시작")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(Color(hex: "4CAF50"))
                                        .cornerRadius(28)
                                        .shadow(color: Color(hex: "4CAF50").opacity(0.3), radius: 8, y: 4)
                                }
                                .disabled(isProcessingAction)
                            }
                        } else {
                            Button(action: {
                                guard !isProcessingAction else { return }
                                Task { await handleEndSession() }
                            }) {
                                Text("세션 종료")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color(hex: "4CAF50"))
                                    .cornerRadius(28)
                                    .shadow(color: Color(hex: "4CAF50").opacity(0.3), radius: 8, y: 4)
                            }
                            .disabled(isProcessingAction)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("완료") {
                        isStartingPageFocused = false
                    }
                }
            }
        }
        .task {
            if !hasInitialized {
                await setupInitialState()
            }
        }
        .interactiveDismissDisabled(isStartingSession || isProcessingAction || (isSessionStarted && localIsTracking))
        .sheet(isPresented: $showingEndSession) {
            EndSessionView(
                frozenDuration: finalDuration,
                onCompletion: {
                    trackingCoordinator.dismissTrackingOverlay()
                    onSessionEnded()
                }
            )
            .interactiveDismissDisabled()
        }
        .alert("세션을 취소하시겠습니까?", isPresented: $showingCancelConfirmation) {
            Button("계속 읽기", role: .cancel) { }
            Button("세션 취소", role: .destructive) {
                Task { await cancelSession() }
            }
        } message: {
            Text("정말로 이 독서 세션을 취소하시겠습니까? 진행률이 저장되지 않습니다.")
        }
        .errorAlert($error)
    }
    
    // MARK: - Methods
    private func setupInitialState() async {
        guard !hasInitialized else { return }
        hasInitialized = true
        
        logger.info("Setting up initial state for book: \(book.title)")
        
        let currentSession = sessionManager.currentSession
        
        if let currentSession = currentSession,
           currentSession.endTime == nil,
           currentSession.book.objectID == book.objectID {
            logger.info("Found existing active session for this book")
            localCurrentSession = currentSession
            localIsTracking = true
            localIsPaused = false
            localDistractionCount = Int(currentSession.distractionCount)
            localStartTime = currentSession.startTime
            isSessionStarted = true
        } else {
            logger.info("No active session found for this book, setting up new session")
            isSessionStarted = false
            startingPage = "\(book.currentPage)"
            
            try? await Task.sleep(nanoseconds: 500_000_000)
            isStartingPageFocused = true
        }
    }
    
    private func calculateCurrentDuration(at date: Date) -> TimeInterval {
        guard localIsTracking, let startTime = localStartTime else { return 0 }
        
        if localIsPaused {
            return localTotalReadingTime
        } else {
            return localTotalReadingTime + date.timeIntervalSince(startTime)
        }
    }
    
    private func startSession() async {
        guard !isStartingSession, !isSessionStarted, !isProcessingAction else { return }
        
        logger.info("Starting session for book: \(book.title)")
        
        isProcessingAction = true
        isStartingSession = true
        
        let startPage = Int(startingPage) ?? Int(book.currentPage)
        
        do {
            try await sessionManager.startSession(for: book, startingPage: startPage, location: "독서 추적")
            
            try await Task.sleep(nanoseconds: 300_000_000)
            
            if let newSession = sessionManager.currentSession,
               newSession.book.objectID == book.objectID {
                localCurrentSession = newSession
                localIsTracking = true
                localIsPaused = false
                localDistractionCount = 0
                localTotalReadingTime = 0
                localStartTime = newSession.startTime
                
                logger.info("Session started successfully - keeping view open")
                isSessionStarted = true
            } else {
                throw SessionError.sessionNotFound
            }
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
        } catch {
            logger.error("Failed to start session: \(error.localizedDescription)")
            self.error = TrackingError.sessionStartFailed(error)
        }
        
        isStartingSession = false
        isProcessingAction = false
    }
    
    private func toggleReading() async {
        guard !isProcessingAction else { return }
        isProcessingAction = true
        
        do {
            if localIsPaused {
                logger.info("Resuming session")
                try await sessionManager.resumeSession()
                localIsPaused = false
                localStartTime = Date()
            } else {
                logger.info("Pausing session")
                try await sessionManager.pauseSession()
                
                if let startTime = localStartTime {
                    localTotalReadingTime += Date().timeIntervalSince(startTime)
                }
                localIsPaused = true
            }
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
        } catch {
            logger.error("Failed to toggle reading state: \(error.localizedDescription)")
            self.error = TrackingError.sessionToggleFailed(error)
        }
        
        isProcessingAction = false
    }
    
    private func recordDistraction() async {
        guard !isProcessingAction else { return }
        isProcessingAction = true
        
        do {
            logger.info("Recording distraction")
            try await sessionManager.recordDistraction()
            localDistractionCount += 1
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
        } catch {
            logger.error("Failed to record distraction: \(error.localizedDescription)")
            self.error = TrackingError.distractionRecordFailed(error)
        }
        
        isProcessingAction = false
    }
    
    private func handleEndSession() async {
        guard !isProcessingAction else { return }
        isProcessingAction = true
        
        logger.info("Handling end session")
        
        do {
            finalDuration = calculateCurrentDuration(at: Date())
            
            if !localIsPaused {
                try await sessionManager.pauseSession()
                localIsPaused = true
            }
            
            showingEndSession = true
            
        } catch {
            logger.error("Failed to handle end session: \(error.localizedDescription)")
            self.error = TrackingError.sessionEndFailed(error)
        }
        
        isProcessingAction = false
    }
    
    private func cancelSession() async {
        guard !isProcessingAction else { return }
        isProcessingAction = true
        
        logger.info("Canceling session")
        
        do {
            try await sessionManager.cancelSession()
            
            localCurrentSession = nil
            localIsTracking = false
            localIsPaused = false
            localDistractionCount = 0
            localTotalReadingTime = 0
            localStartTime = nil
            
            trackingCoordinator.dismissTrackingOverlay()
            onSessionEnded()
            
        } catch {
            logger.error("Failed to cancel session: \(error.localizedDescription)")
            self.error = TrackingError.sessionCancelFailed(error)
        }
        
        isProcessingAction = false
    }
    
    private func timeString(from interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        let seconds = Int(interval) % 60
        
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Error Types
enum TrackingError: LocalizedError {
    case sessionStartFailed(Error)
    case sessionToggleFailed(Error)
    case distractionRecordFailed(Error)
    case sessionEndFailed(Error)
    case sessionCancelFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .sessionStartFailed(let error):
            return "세션 시작 실패: \(error.localizedDescription)"
        case .sessionToggleFailed(let error):
            return "세션 상태 변경 실패: \(error.localizedDescription)"
        case .distractionRecordFailed(let error):
            return "방해 요소 기록 실패: \(error.localizedDescription)"
        case .sessionEndFailed(let error):
            return "세션 종료 실패: \(error.localizedDescription)"
        case .sessionCancelFailed(let error):
            return "세션 취소 실패: \(error.localizedDescription)"
        }
    }
}

// MARK: - Error Alert Extension
extension View {
    func errorAlert(_ error: Binding<TrackingError?>) -> some View {
        alert("오류", isPresented: .constant(error.wrappedValue != nil)) {
            Button("확인") {
                error.wrappedValue = nil
            }
        } message: {
            Text(error.wrappedValue?.errorDescription ?? "알 수 없는 오류가 발생했습니다.")
        }
    }
}
