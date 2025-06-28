// SessionRowView.swift
import SwiftUI

struct SessionRowView: View {
    let session: ReadingSession
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
    
    private var duration: String {
        let start = session.startTime
        let end = session.endTime ?? Date()
        
        let totalSeconds = Int(end.timeIntervalSince(start))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        
        if minutes < 1 {
            return "\(seconds)s"
        } else if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes == 0 {
                return "\(hours)h"
            } else {
                return "\(hours)h \(remainingMinutes)m"
            }
        }
    }
    
    private var pagesRead: Int {
        Int(session.endPage - session.startPage)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Date section
            VStack(spacing: 2) {
                Text(dateFormatter.string(from: session.startTime))
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
                
                Text(timeFormatter.string(from: session.startTime))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.black)
            }
            .frame(width: 80, alignment: .leading)
            
            // Divider
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 1)
                .frame(maxHeight: 40)
            
            // Stats section
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 16) {
                    // Duration
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text(duration)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                    }
                    
                    // Pages
                    HStack(spacing: 4) {
                        Image(systemName: "book")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        Text("\(pagesRead) pages")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

// Simplified preview without Core Data
struct SessionRowView_Previews: PreviewProvider {
    static var previews: some View {
        SessionRowView(session: previewSession)
            .padding()
            .background(Color.gray.opacity(0.05))
            .previewLayout(.sizeThatFits)
    }
    
    static var previewSession: ReadingSession {
        // Create a mock session for preview
        let session = ReadingSession()
        session.id = UUID()
        session.startTime = Date().addingTimeInterval(-3600)
        session.endTime = Date()
        session.startPage = 100
        session.endPage = 125
        session.distractionCount = 2
        return session
    }
}
