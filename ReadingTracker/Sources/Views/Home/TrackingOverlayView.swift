import SwiftUI

struct TrackingOverlayView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var sessionManager = SessionManager.shared
    @State private var currentPage = ""
    @State private var showingEndSession = false
    @State private var showingCancelConfirmation = false
    @State private var isSessionStarted = false
    @State private var isStartingSession = false
    @State private var error: AppError?
    @FocusState private var isPageInputFocused: Bool
    @Binding var isPresented: Bool
    let book: Book
    let onSessionEnded: () -> Void
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Minimal Header
                HStack {
                    if isSessionStarted {
                        Button(action: { showingCancelConfirmation = true }) {
                            Text("Cancel")
                                .font(.body)
                                .foregroundColor(.red)
                        }
                    } else {
                        Button(action: { isPresented = false }) {
                            Text("Cancel")
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
                    Text("Cancel")
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
                    
                    // Timer Display (세션 시작 후에만 표시)
                    if isSessionStarted {
                        TimelineView(.periodic(from: Date(), by: 1.0)) { context in
                            Text(timeString(from: sessionManager.currentDuration(at: context.date)))
                                .font(.system(size: 56, weight: .light, design: .monospaced))
                                .foregroundColor(.black)
                        }
                        .padding(.vertical, 20)
                    }
                    
                    // Current Page Input (세션 시작 후에만 표시)
                    if isSessionStarted {
                        VStack(spacing: 12) {
                            Text("Current Page")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            TextField("0", text: $currentPage)
                                .keyboardType(.numberPad)
                                .font(.system(size: 28, weight: .medium))
                                .multilineTextAlignment(.center)
                                .frame(width: 140)
                                .padding(.vertical, 16)
                                .background(Color.gray.opacity(0.08))
                                .cornerRadius(16)
                                .focused($isPageInputFocused)
                        }
                    }
                    
                    // Distraction Counter (세션 시작 후에만 표시)
                    if isSessionStarted {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 16))
                                .foregroundColor(.gray)
                            Text("Distractions: \(sessionManager.distractionCount)")
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
                        // 세션 시작 후에만 Pause와 Distraction 버튼 표시
                        if isSessionStarted {
                            HStack(spacing: 16) {
                                Button(action: toggleReading) {
                                    VStack(spacing: 8) {
                                        Image(systemName: sessionManager.isPaused ? "play.fill" : "pause.fill")
                                            .font(.title2)
                                        Text(sessionManager.isPaused ? "Resume" : "Pause")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .foregroundColor(sessionManager.isPaused ? .white : .black)
                                    .frame(width: 100, height: 80)
                                    .background(
                                        RoundedRectangle(cornerRadius: 20)
                                            .fill(sessionManager.isPaused ? Color.orange : Color.gray.opacity(0.1))
                                            .shadow(color: .black.opacity(0.05), radius: 5)
                                    )
                                }
                                if !sessionManager.isPaused {
                                    Button(action: recordDistraction) {
                                        VStack(spacing: 8) {
                                            Image(systemName: "hand.raised.fill")
                                                .font(.title2)
                                            Text("Distraction")
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
                                }
                            }
                            .padding(.horizontal, 40)
                        }
                        
                        // Start Session과 End Session 버튼 (동일한 위치)
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
                                Button(action: startSession) {
                                    Text("Start Session")
                                        .font(.body)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 56)
                                        .background(Color(hex: "4CAF50"))
                                        .cornerRadius(28)
                                        .shadow(color: Color(hex: "4CAF50").opacity(0.3), radius: 8, y: 4)
                                }
                            }
                        } else {
                            Button(action: {
                                if !sessionManager.isPaused {
                                    sessionManager.pauseSession()
                                }
                                showingEndSession = true
                            }) {
                                Text("End Session")
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 56)
                                    .background(Color(hex: "4CAF50"))
                                    .cornerRadius(28)
                                    .shadow(color: Color(hex: "4CAF50").opacity(0.3), radius: 8, y: 4)
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            if sessionManager.currentSession != nil && sessionManager.currentSession?.endTime == nil {
                isSessionStarted = true
                setupView()
            } else {
                isSessionStarted = false
            }
        }
        .sheet(isPresented: $showingEndSession) {
            EndSessionView(currentPage: $currentPage, onCompletion: {
                isPresented = false
                onSessionEnded()
            })
            .interactiveDismissDisabled()
        }
        .alert("Cancel Session?", isPresented: $showingCancelConfirmation) {
            Button("Keep Reading", role: .cancel) { }
            Button("Cancel Session", role: .destructive) {
                sessionManager.cancelSession()
                isPresented = false
            }
        } message: {
            Text("Are you sure you want to cancel this reading session? Your progress will not be saved.")
        }
        .errorAlert($error)
    }
    
    private func setupView() {
        if let book = sessionManager.currentSession?.book {
            currentPage = "\(book.currentPage)"
        } else {
            currentPage = "\(book.currentPage)"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPageInputFocused = true
        }
    }
    
    private func startSession() {
            guard !isStartingSession, !isSessionStarted else {
                print("Session is already starting or started.")
                return
            }
            
            print("Attempting to start session for book: \(book.title)")
            isStartingSession = true
            
            SessionManager.shared.startSession(for: book, location: "Home") { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        print("Session started successfully for book: \(book.title)")
                        self.isSessionStarted = true
                        self.isStartingSession = false
                        self.setupView()
                    case .failure(let error):
                        print("Failed to start session: \(error.localizedDescription)")
                        self.error = AppError(
                            title: "Session Start Failed",
                            message: error.localizedDescription,
                            error: error
                        )
                        self.isStartingSession = false
                    }
                }
            }
        }
    
    private func toggleReading() {
        if sessionManager.isPaused {
            sessionManager.resumeSession()
        } else {
            sessionManager.pauseSession()
        }
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func recordDistraction() {
        sessionManager.recordDistraction()
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
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
