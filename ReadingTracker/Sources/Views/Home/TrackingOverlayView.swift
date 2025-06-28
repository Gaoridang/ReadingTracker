import SwiftUI

struct TrackingOverlayView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var sessionManager = SessionManager.shared
    @State private var currentPage = ""
    @State private var showingEndSession = false
    @State private var showingCancelConfirmation = false
    @State private var isRecordingDistraction = false
    @Binding var isPresented: Bool
    let book: Book
    let onSessionEnded: () -> Void
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Button(action: { showingCancelConfirmation = true }) {
                        Text("Cancel")
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    Text(book.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("Cancel")
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
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Timer Display using TimelineView
                    TimelineView(.periodic(from: Date(), by: 1.0)) { context in
                        Text(timeString(from: sessionManager.currentDuration(at: context.date)))
                            .font(.system(size: 60, weight: .thin, design: .monospaced))
                            .foregroundColor(.black)
                    }
                    
                    // Session Stats
                    if sessionManager.isTracking, let session = sessionManager.currentSession {
                        HStack(spacing: 0) {
                            VStack(spacing: 8) {
                                Image(systemName: "book")
                                    .font(.title2)
                                    .foregroundColor(.black.opacity(0.6))
                                Text("\(session.pagesRead)")
                                    .font(.title)
                                    .bold()
                                    .foregroundColor(.black)
                                Text("pages")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 1, height: 60)
                            
                            VStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.title2)
                                    .foregroundColor(.black.opacity(0.6))
                                Text("\(sessionManager.distractionCount)")
                                    .font(.title)
                                    .bold()
                                    .foregroundColor(.black)
                                Text("distractions")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 60)
                    }
                    
                    // Page Input
                    VStack(spacing: 8) {
                        Text("Current Page")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                        TextField("Page number", text: $currentPage)
                            .keyboardType(.numberPad)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .frame(width: 120)
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                    }
                    
                    Spacer()
                    
                    // Control Buttons
                    VStack(spacing: 16) {
                        Button(action: toggleReading) {
                            HStack {
                                Image(systemName: sessionManager.isPaused ? "play.fill" : "pause.fill")
                                Text(sessionManager.isPaused ? "Resume" : "Pause")
                            }
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 56)
                            .background(sessionManager.isPaused ? Color.orange : Color.gray)
                            .cornerRadius(28)
                        }
                        
                        if sessionManager.isTracking && !sessionManager.isPaused {
                            Button(action: toggleDistraction) {
                                HStack {
                                    Image(systemName: isRecordingDistraction ? "phone.fill.arrow.down.left" : "phone.fill")
                                    Text(isRecordingDistraction ? "End Distraction" : "Distraction")
                                }
                                .font(.title3)
                                .foregroundColor(.white)
                                .frame(width: 200, height: 50)
                                .background(Color.red)
                                .cornerRadius(25)
                            }
                        }
                        
                        Button(action: {
                            if !sessionManager.isPaused {
                                sessionManager.pauseSession()
                            }
                            showingEndSession = true
                        }) {
                            Text("End Session")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(width: 250, height: 56)
                                .background(Color(hex: "4CAF50"))
                                .cornerRadius(28)
                        }
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            setupView()
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
    }
    
    private func setupView() {
        if let book = sessionManager.currentSession?.book {
            currentPage = "\(book.currentPage)"
        } else {
            currentPage = "\(book.currentPage)"
        }
    }
    
    private func toggleReading() {
        if sessionManager.isPaused {
            sessionManager.resumeSession()
        } else {
            sessionManager.pauseSession()
        }
    }
    
    private func toggleDistraction() {
        if isRecordingDistraction {
            sessionManager.endDistraction()
            isRecordingDistraction = false
        } else {
            sessionManager.startDistraction()
            isRecordingDistraction = true
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        }
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
