import SwiftUI

struct EndSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var sessionManager = SessionManager.shared
    @State private var currentPage: String = ""
    @State private var isProcessing = false
    @FocusState private var isPageInputFocused: Bool
    
    let frozenDuration: TimeInterval  // Duration captured when End Session was clicked
    let onCompletion: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Success icon
                ZStack {
                    Circle()
                        .fill(Color(hex: "4CAF50").opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 50))
                        .foregroundColor(Color(hex: "4CAF50"))
                }
                .padding(.top, 40)
                
                Text("Great Reading Session!")
                    .font(.largeTitle)
                    .bold()
                    .foregroundColor(.black)
                
                // Book title
                if let session = sessionManager.currentSession {
                    Text(session.book.title)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                // Stats (using frozen duration and live session data)
                if let session = sessionManager.currentSession {
                    VStack(spacing: 20) {
                        SessionStatRow(
                            icon: "clock",
                            label: "Duration",
                            value: formatDuration(frozenDuration)  // Use frozen duration
                        )
                        
                        SessionStatRow(
                            icon: "book.pages",
                            label: "Started from",
                            value: "Page \(session.startPage)"
                        )
                        
                        SessionStatRow(
                            icon: "exclamationmark.triangle",
                            label: "Distractions",
                            value: "\(sessionManager.distractionCount)"
                        )
                        
                        // Focus Score
                        let focusScore = calculateFocusScore()
                        SessionStatRow(
                            icon: "target",
                            label: "Focus Score",
                            value: "\(Int(focusScore))%"
                        )
                    }
                    .padding(.horizontal, 40)
                }
                
                // Page input
                VStack(spacing: 12) {
                    Text("What page did you end on?")
                        .font(.headline)
                        .foregroundColor(.black)
                    
                    TextField("Page number", text: $currentPage)
                        .font(.title2)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 120)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .focused($isPageInputFocused)
                        .onSubmit { hideKeyboard() }  // Return 키로 키보드 닫기
                    
                    if let session = sessionManager.currentSession,
                       let pageNum = Int(currentPage),
                       pageNum > 0 {
                        let pagesRead = pageNum - Int(session.startPage)
                        if pagesRead > 0 {
                            VStack(spacing: 4) {
                                Text("You read \(pagesRead) pages!")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "4CAF50"))
                                
                                // Reading speed calculation
                                if frozenDuration > 60 {  // Only show if more than 1 minute
                                    let pagesPerHour = Double(pagesRead) / (frozenDuration / 3600)
                                    Text("\(Int(pagesPerHour)) pages/hour")
                                        .font(.caption2)
                                        .foregroundColor(.gray)
                                }
                            }
                        } else if pagesRead == 0 {
                            Text("No progress made?")
                                .font(.caption)
                                .foregroundColor(.orange)
                        } else {
                            Text("End page must be after page \(session.startPage)")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 12) {
                    // Done button
                    Button(action: finishSession) {
                        if isProcessing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Done")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isValidPage ? Color(hex: "4CAF50") : Color.gray)
                    .cornerRadius(12)
                    .disabled(!isValidPage || isProcessing)
                    
                    // Cancel button
                    Button(action: {
                        if sessionManager.isPaused {
                            sessionManager.resumeSession()
                        }
                        dismiss()
                    }) {
                        Text("Cancel")
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    .disabled(isProcessing)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
            .navigationBarHidden(true)
            .contentShape(Rectangle())
            .onTapGesture {
                isPageInputFocused = false
            }
        }
        .onAppear {
            setupInitialPage()
        }
        .interactiveDismissDisabled(isProcessing)
    }
    
    private var isValidPage: Bool {
        guard let session = sessionManager.currentSession,
              let pageNum = Int(currentPage) else { return false }
        return pageNum >= session.startPage  // Allow same page (no progress is valid)
    }
    
    private func setupInitialPage() {
        if let session = sessionManager.currentSession {
            currentPage = "\(max(session.book.currentPage, session.startPage))"
        }
    }
    
    private func finishSession() {
        guard let page = Int(currentPage), isValidPage else { return }
        
        isProcessing = true
        
        sessionManager.endSession(currentPage: page) {
            DispatchQueue.main.async {
                self.isProcessing = false
                self.dismiss()
                self.onCompletion()
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }
    
    private func calculateFocusScore() -> Double {
        guard frozenDuration > 0 else { return 100 }
        let distractionPenalty = Double(sessionManager.distractionCount) * 5
        return max(0, 100 - distractionPenalty)
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct SessionStatRow: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(Color(hex: "4CAF50"))
                .frame(width: 30)
            
            Text(label)
                .font(.body)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.black)
        }
    }
}
