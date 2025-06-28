import SwiftUI

struct EndSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var sessionManager = SessionManager.shared
    @Binding var currentPage: String
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
                
                // Stats
                if let session = sessionManager.currentSession {
                    VStack(spacing: 20) {
                        SessionStatRow(
                            icon: "clock",
                            label: "Duration",
                            value: formatDuration(sessionManager.totalReadingTime)
                        )
                        
                        SessionStatRow(
                            icon: "book",
                            label: "Pages Read",
                            value: "\(session.pagesRead) pages"
                        )
                        
                        SessionStatRow(
                            icon: "exclamationmark.triangle",
                            label: "Distractions",
                            value: "\(sessionManager.distractionCount)"
                        )
                    }
                    .padding(.horizontal, 40)
                }
                
                // Page input
                VStack(spacing: 12) {
                    Text("Ending page")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    TextField("Page number", text: $currentPage)
                        .font(.title2)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .frame(width: 120)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Spacer()
                
                // Done button
                Button(action: finishSession) {
                    Text("Done")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(hex: "4CAF50"))
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
                .disabled(!currentPage.isNumeric)
            }
            .navigationBarHidden(true)
        }
    }
    
    private func finishSession() {
        if let page = Int(currentPage) {
            print("Ending session with page: \(page)")
            sessionManager.endSession(currentPage: page)
            DispatchQueue.main.async {
                self.dismiss()
                self.onCompletion()
            }
        } else {
            print("Invalid page input: \(currentPage)")
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        if minutes < 1 {
            return "\(seconds) seconds"
        } else if minutes == 1 {
            return "1 minute \(seconds) seconds"
        } else {
            return "\(minutes) minutes \(seconds) seconds"
        }
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

extension String {
    var isNumeric: Bool {
        return !isEmpty && allSatisfy { $0.isNumber }
    }
}
