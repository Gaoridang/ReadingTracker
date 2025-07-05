//import SwiftUI
//import os.log
//
//@MainActor
//struct TrackingOverlayView: View {
//    @Environment(\.managedObjectContext) private var viewContext
//    // 🔥 SessionManager를 직접 관찰하지 않음 - 참조만 사용
//    private let sessionManager = SessionManager.shared
//    @State private var startingPage = ""
//    @State private var showingEndSession = false
//    @State private var showingCancelConfirmation = false
//    @State private var isSessionStarted = false
//    @State private var isStartingSession = false
//    @State private var error: TrackingError?
//    @State private var finalDuration: TimeInterval = 0
//    @State private var localSessionCreated = false
//    
//    // 🔥 중복 호출 방지를 위한 상태
//    @State private var isProcessingAction = false
//    @State private var hasInitialized = false
//    
//    // 완전한 로컬 상태 관리 - SessionManager의 @Published 속성들을 전혀 사용하지 않음
//    @State private var localIsTracking = false
//    @State private var localIsPaused = false
//    @State private var localDistractionCount = 0
//    @State private var localTotalReadingTime: TimeInterval = 0
//    @State private var localCurrentSession: ReadingSession?
//    @State private var localStartTime: Date?
//    
//    @FocusState private var isStartingPageFocused: Bool
//    @Binding var isPresented: Bool
//    let book: Book
//    let onSessionEnded: () -> Void
//    
//    // Modern logging system
//    private let logger = Logger(subsystem: "TrackingOverlayView", category: "Session")
//    
//    var body: some View {
//        ZStack {
//            Color.white
//                .ignoresSafeArea()
//                .onTapGesture {
//                    isStartingPageFocused = false
//                }
//            
//            VStack(spacing: 0) {
//                // Minimal Header
//                HStack {
//                    if isSessionStarted {
//                        Button(action: {
//                            // 🔥 중복 클릭 방지
//                            guard !isProcessingAction else { return }
//                            showingCancelConfirmation = true
//                        }) {
//                            Text("취소")
//                                .font(.body)
//                                .foregroundColor(.red)
//                        }
//                        .disabled(isProcessingAction)
//                    } else {
//                        Button(action: {
//                            logger.info("User tapped cancel button")
//                            isPresented = false
//                        }) {
//                            Text("취소")
//                                .font(.body)
//                                .foregroundColor(.red)
//                        }
//                    }
//                    Spacer()
//                    Text(book.title)
//                        .font(.headline)
//                        .foregroundColor(.black)
//                        .lineLimit(1)
//                    Spacer()
//                    Text("취소")
//                        .font(.body)
//                        .foregroundColor(.clear)
//                }
//                .padding()
//                .background(Color.white)
//                .overlay(
//                    Rectangle()
//                        .fill(Color.gray.opacity(0.2))
//                        .frame(height: 0.5),
//                    alignment: .bottom
//                )
//                
//                // Main Content
//                VStack(spacing: 40) {
//                    Spacer()
//                    
//                    // Starting Page Input (before session starts)
//                    if !isSessionStarted {
//                        VStack(spacing: 20) {
//                            Image(systemName: "book.pages")
//                                .font(.system(size: 50))
//                                .foregroundColor(Color(hex: "4CAF50"))
//                                .padding(.bottom, 20)
//                            
//                            Text("어느 페이지부터 시작하시나요?")
//                                .font(.title2)
//                                .fontWeight(.semibold)
//                                .foregroundColor(.black)
//                            
//                            VStack(spacing: 12) {
//                                HStack {
//                                    Text("페이지")
//                                        .font(.body)
//                                        .foregroundColor(.gray)
//                                    
//                                    TextField("\(book.currentPage)", text: $startingPage)
//                                        .keyboardType(.numberPad)
//                                        .font(.system(size: 24, weight: .medium))
//                                        .multilineTextAlignment(.center)
//                                        .frame(width: 100)
//                                        .padding(.vertical, 12)
//                                        .padding(.horizontal, 16)
//                                        .background(Color.gray.opacity(0.08))
//                                        .cornerRadius(12)
//                                        .focused($isStartingPageFocused)
//                                }
//                                
//                                Text("책 진행률: \(book.currentPage) / \(book.totalPages) 페이지")
//                                    .font(.caption)
//                                    .foregroundColor(.gray.opacity(0.8))
//                            }
//                        }
//                    }
//                    
//                    // Timer Display (after session starts)
//                    if isSessionStarted {
//                        TimelineView(.periodic(from: Date(), by: 1.0)) { context in
//                            Text(timeString(from: calculateCurrentDuration(at: context.date)))
//                                .font(.system(size: 56, weight: .light, design: .monospaced))
//                                .foregroundColor(.black)
//                        }
//                        .padding(.vertical, 20)
//                    }
//                    
//                    // Starting Page Display (after session starts)
//                    if isSessionStarted {
//                        VStack(spacing: 12) {
//                            Text("시작 페이지")
//                                .font(.subheadline)
//                                .foregroundColor(.gray)
//                            
//                            HStack {
//                                Image(systemName: "bookmark.fill")
//                                    .font(.system(size: 20))
//                                    .foregroundColor(Color(hex: "4CAF50"))
//                                
//                                if let session = localCurrentSession {
//                                    Text("\(session.startPage) 페이지")
//                                        .font(.system(size: 28, weight: .medium))
//                                        .foregroundColor(.black)
//                                }
//                            }
//                            .padding(.vertical, 12)
//                            .padding(.horizontal, 24)
//                            .background(Color.gray.opacity(0.08))
//                            .cornerRadius(16)
//                            
//                            Text("독서에 집중하세요")
//                                .font(.caption)
//                                .foregroundColor(.gray.opacity(0.8))
//                        }
//                    }
//                    
//                    // Distraction Counter (after session starts)
//                    if isSessionStarted {
//                        HStack(spacing: 8) {
//                            Image(systemName: "exclamationmark.triangle")
//                                .font(.system(size: 16))
//                                .foregroundColor(.gray)
//                            Text("방해 요소: \(localDistractionCount)")
//                                .font(.body)
//                                .foregroundColor(.gray)
//                        }
//                        .padding(.horizontal, 20)
//                        .padding(.vertical, 12)
//                        .background(Color.gray.opacity(0.05))
//                        .cornerRadius(20)
//                    }
//                    
//                    Spacer()
//                    
//                    // Control Buttons
//                    VStack(spacing: 16) {
//                        // Pause/Resume and Distraction buttons (after session starts)
//                        if isSessionStarted {
//                            HStack {
//                                Button(action: {
//                                    // 🔥 중복 클릭 방지
//                                    guard !isProcessingAction else { return }
//                                    Task {
//                                        await toggleReading()
//                                    }
//                                }) {
//                                    VStack(spacing: 8) {
//                                        Image(systemName: localIsPaused ? "play.fill" : "pause.fill")
//                                            .font(.title2)
//                                        Text(localIsPaused ? "재개" : "일시정지")
//                                            .font(.caption)
//                                            .fontWeight(.medium)
//                                    }
//                                    .foregroundColor(localIsPaused ? .white : .black)
//                                    .frame(width: 100, height: 80)
//                                    .background(
//                                        RoundedRectangle(cornerRadius: 20)
//                                            .fill(localIsPaused ? Color.orange : Color.gray.opacity(0.1))
//                                            .shadow(color: .black.opacity(0.05), radius: 5)
//                                    )
//                                }
//                                .disabled(isProcessingAction)
//                                
//                                if !localIsPaused {
//                                    Button(action: {
//                                        // 🔥 중복 클릭 방지
//                                        guard !isProcessingAction else { return }
//                                        Task {
//                                            await recordDistraction()
//                                        }
//                                    }) {
//                                        VStack(spacing: 8) {
//                                            Image(systemName: "hand.raised.fill")
//                                                .font(.title2)
//                                            Text("방해 요소")
//                                                .font(.caption)
//                                                .fontWeight(.medium)
//                                        }
//                                        .foregroundColor(.black)
//                                        .frame(width: 100, height: 80)
//                                        .background(
//                                            RoundedRectangle(cornerRadius: 20)
//                                                .fill(Color.gray.opacity(0.1))
//                                                .shadow(color: .black.opacity(0.05), radius: 5)
//                                        )
//                                    }
//                                    .disabled(isProcessingAction)
//                                }
//                            }
//                            .padding(.horizontal, 40)
//                        }
//                        
//                        // Start Session / End Session button
//                        if !isSessionStarted {
//                            if isStartingSession {
//                                ProgressView()
//                                    .tint(.white)
//                                    .scaleEffect(1.5)
//                                    .frame(maxWidth: .infinity)
//                                    .frame(height: 56)
//                                    .background(Color(hex: "4CAF50"))
//                                    .cornerRadius(28)
//                            } else {
//                                Button(action: {
//                                    // 🔥 중복 클릭 방지
//                                    guard !isProcessingAction else { return }
//                                    Task {
//                                        await startSession()
//                                    }
//                                }) {
//                                    Text("세션 시작")
//                                        .font(.body)
//                                        .fontWeight(.semibold)
//                                        .foregroundColor(.white)
//                                        .frame(maxWidth: .infinity)
//                                        .frame(height: 56)
//                                        .background(Color(hex: "4CAF50"))
//                                        .cornerRadius(28)
//                                        .shadow(color: Color(hex: "4CAF50").opacity(0.3), radius: 8, y: 4)
//                                }
//                                .disabled(isProcessingAction) // 처리 중일 때 비활성화
//                            }
//                        } else {
//                            Button(action: {
//                                // 🔥 중복 클릭 방지
//                                guard !isProcessingAction else { return }
//                                Task {
//                                    await handleEndSession()
//                                }
//                            }) {
//                                Text("세션 종료")
//                                    .font(.body)
//                                    .fontWeight(.semibold)
//                                    .foregroundColor(.white)
//                                    .frame(maxWidth: .infinity)
//                                    .frame(height: 56)
//                                    .background(Color(hex: "4CAF50"))
//                                    .cornerRadius(28)
//                                    .shadow(color: Color(hex: "4CAF50").opacity(0.3), radius: 8, y: 4)
//                            }
//                            .disabled(isProcessingAction) // 처리 중일 때 비활성화
//                        }
//                    }
//                    .padding(.horizontal, 40)
//                    .padding(.bottom, 40)
//                }
//            }
//            .toolbar {
//                ToolbarItemGroup(placement: .keyboard) {
//                    Spacer()
//                    Button("완료") {
//                        isStartingPageFocused = false
//                    }
//                }
//            }
//        }
//        .task {
//            // 🔥 중복 초기화 방지
//            if !hasInitialized {
//                await setupInitialState()
//            }
//        }
//        .interactiveDismissDisabled(isStartingSession || isProcessingAction || (isSessionStarted && localIsTracking))
//        .sheet(isPresented: $showingEndSession) {
//            EndSessionView(
//                frozenDuration: finalDuration,
//                onCompletion: {
//                    isPresented = false
//                    onSessionEnded()
//                }
//            )
//            .interactiveDismissDisabled()
//        }
//        .alert("세션을 취소하시겠습니까?", isPresented: $showingCancelConfirmation) {
//            Button("계속 읽기", role: .cancel) { }
//            Button("세션 취소", role: .destructive) {
//                Task {
//                    await cancelSession()
//                }
//            }
//        } message: {
//            Text("정말로 이 독서 세션을 취소하시겠습니까? 진행률이 저장되지 않습니다.")
//        }
//        .errorAlert($error)
//    }
//    
//    // MARK: - Private Methods
//    private func setupInitialState() async {
//        // 🔥 중복 초기화 방지
//        guard !hasInitialized else {
//            logger.warning("Already initialized, skipping")
//            return
//        }
//        hasInitialized = true
//        
//        logger.info("Setting up initial state for book: \(book.title)")
//        
//        // SessionManager에서 현재 세션 정보만 가져오기 (상태 관찰 없이)
//        let currentSession = sessionManager.currentSession
//        
//        if let currentSession = currentSession,
//           currentSession.endTime == nil,
//           currentSession.book.objectID == book.objectID {
//            logger.info("Found existing active session for this book")
//            // 로컬 상태 초기화
//            localCurrentSession = currentSession
//            localIsTracking = true
//            localIsPaused = false // 기본값으로 설정
//            localDistractionCount = Int(currentSession.distractionCount)
//            localStartTime = currentSession.startTime
//            isSessionStarted = true
//        } else {
//            logger.info("No active session found for this book, setting up new session")
//            isSessionStarted = false
//            startingPage = "\(book.currentPage)"
//            
//            // Small delay for better UX
//            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
//            isStartingPageFocused = true
//        }
//    }
//    
//    private func calculateCurrentDuration(at date: Date) -> TimeInterval {
//        guard localIsTracking, let startTime = localStartTime else { return 0 }
//        
//        if localIsPaused {
//            return localTotalReadingTime
//        } else {
//            return localTotalReadingTime + date.timeIntervalSince(startTime)
//        }
//    }
//    
//    private func startSession() async {
//        // 🔥 강화된 중복 방지 로직
//        guard !isStartingSession,
//              !isSessionStarted,
//              !isProcessingAction else {
//            logger.warning("Session is already starting/started or action in progress")
//            return
//        }
//        
//        logger.info("Starting session for book: \(book.title)")
//        
//        // 상태 설정
//        isProcessingAction = true
//        isStartingSession = true
//        
//        let startPage = Int(startingPage) ?? Int(book.currentPage)
//        
//        do {
//            localSessionCreated = true
//            
//            // SessionManager에서 세션 시작 (상태 관찰 없이)
//            try await sessionManager.startSession(for: book, startingPage: startPage, location: "독서 추적")
//            
//            // 작은 지연 후 로컬 상태 업데이트
//            try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
//            
//            // 세션 정보 다시 가져오기 (단순 조회)
//            if let newSession = sessionManager.currentSession,
//               newSession.book.objectID == book.objectID {
//                localCurrentSession = newSession
//                localIsTracking = true
//                localIsPaused = false
//                localDistractionCount = 0
//                localTotalReadingTime = 0
//                localStartTime = newSession.startTime
//                
//                logger.info("Session started successfully - keeping view open") // 단일 성공 로그
//                isSessionStarted = true
//            } else {
//                throw SessionError.sessionNotFound
//            }
//            
//            // Haptic feedback
//            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
//            impactFeedback.impactOccurred()
//            
//        } catch {
//            logger.error("Failed to start session: \(error.localizedDescription)")
//            localSessionCreated = false
//            self.error = TrackingError.sessionStartFailed(error)
//        }
//        
//        // 상태 리셋
//        isStartingSession = false
//        isProcessingAction = false
//    }
//    
//    private func toggleReading() async {
//        // 🔥 중복 클릭 방지
//        guard !isProcessingAction else { return }
//        isProcessingAction = true
//        
//        do {
//            if localIsPaused {
//                logger.info("Resuming session")
//                try await sessionManager.resumeSession()
//                localIsPaused = false
//                localStartTime = Date() // 재개 시간 기록
//            } else {
//                logger.info("Pausing session")
//                try await sessionManager.pauseSession()
//                
//                // 일시정지 시 현재까지의 시간 누적
//                if let startTime = localStartTime {
//                    localTotalReadingTime += Date().timeIntervalSince(startTime)
//                }
//                localIsPaused = true
//            }
//            
//            // Haptic feedback
//            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
//            impactFeedback.impactOccurred()
//            
//        } catch {
//            logger.error("Failed to toggle reading state: \(error.localizedDescription)")
//            self.error = TrackingError.sessionToggleFailed(error)
//        }
//        
//        isProcessingAction = false
//    }
//    
//    private func recordDistraction() async {
//        // 🔥 중복 클릭 방지
//        guard !isProcessingAction else { return }
//        isProcessingAction = true
//        
//        do {
//            logger.info("Recording distraction")
//            try await sessionManager.recordDistraction()
//            
//            // 로컬 상태 업데이트
//            localDistractionCount += 1
//            
//            // Haptic feedback
//            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
//            impactFeedback.impactOccurred()
//            
//        } catch {
//            logger.error("Failed to record distraction: \(error.localizedDescription)")
//            self.error = TrackingError.distractionRecordFailed(error)
//        }
//        
//        isProcessingAction = false
//    }
//    
//    private func handleEndSession() async {
//        // 🔥 중복 클릭 방지
//        guard !isProcessingAction else { return }
//        isProcessingAction = true
//        
//        logger.info("Handling end session")
//        
//        do {
//            finalDuration = calculateCurrentDuration(at: Date())
//            
//            if !localIsPaused {
//                try await sessionManager.pauseSession()
//                localIsPaused = true
//            }
//            
//            showingEndSession = true
//            
//        } catch {
//            logger.error("Failed to handle end session: \(error.localizedDescription)")
//            self.error = TrackingError.sessionEndFailed(error)
//        }
//        
//        isProcessingAction = false
//    }
//    
//    private func cancelSession() async {
//        // 🔥 중복 클릭 방지
//        guard !isProcessingAction else { return }
//        isProcessingAction = true
//        
//        logger.info("Canceling session")
//        
//        do {
//            try await sessionManager.cancelSession()
//            localSessionCreated = false
//            
//            // 로컬 상태 리셋
//            localCurrentSession = nil
//            localIsTracking = false
//            localIsPaused = false
//            localDistractionCount = 0
//            localTotalReadingTime = 0
//            localStartTime = nil
//            
//            isPresented = false
//            onSessionEnded()
//            
//        } catch {
//            logger.error("Failed to cancel session: \(error.localizedDescription)")
//            self.error = TrackingError.sessionCancelFailed(error)
//        }
//        
//        isProcessingAction = false
//    }
//    
//    private func timeString(from interval: TimeInterval) -> String {
//        let hours = Int(interval) / 3600
//        let minutes = Int(interval) % 3600 / 60
//        let seconds = Int(interval) % 60
//        
//        if hours > 0 {
//            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
//        } else {
//            return String(format: "%02d:%02d", minutes, seconds)
//        }
//    }
//}
//
//// MARK: - Error Types
//enum TrackingError: LocalizedError {
//    case sessionStartFailed(Error)
//    case sessionToggleFailed(Error)
//    case distractionRecordFailed(Error)
//    case sessionEndFailed(Error)
//    case sessionCancelFailed(Error)
//    
//    var errorDescription: String? {
//        switch self {
//        case .sessionStartFailed(let error):
//            return "세션 시작 실패: \(error.localizedDescription)"
//        case .sessionToggleFailed(let error):
//            return "세션 상태 변경 실패: \(error.localizedDescription)"
//        case .distractionRecordFailed(let error):
//            return "방해 요소 기록 실패: \(error.localizedDescription)"
//        case .sessionEndFailed(let error):
//            return "세션 종료 실패: \(error.localizedDescription)"
//        case .sessionCancelFailed(let error):
//            return "세션 취소 실패: \(error.localizedDescription)"
//        }
//    }
//}
//
//// MARK: - Error Alert Extension
//extension View {
//    func errorAlert(_ error: Binding<TrackingError?>) -> some View {
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
//    TrackingOverlayView(
//        isPresented: .constant(true),
//        book: Book(),
//        onSessionEnded: {}
//    )
//    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
//}
