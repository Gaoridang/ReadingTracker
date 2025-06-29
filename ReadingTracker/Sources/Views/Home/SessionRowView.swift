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
        // Only calculate duration if session has ended
        guard let endTime = session.endTime else {
            return "In Progress"
        }
        
        let totalSeconds = Int(endTime.timeIntervalSince(session.startTime))
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
        // Only show pages if session has ended
        guard session.endTime != nil else {
            return 0
        }
        return Int(session.endPage - session.startPage)
    }
    
    private var isInProgress: Bool {
        session.endTime == nil
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
                        Image(systemName: isInProgress ? "clock.badge.exclamationmark" : "clock")
                            .font(.system(size: 12))
                            .foregroundColor(isInProgress ? .orange : .gray)
                        Text(duration)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isInProgress ? .orange : .black)
                    }
                    
                    // Pages (only show if session ended)
                    if !isInProgress {
                        HStack(spacing: 4) {
                            Image(systemName: "book")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            Text("\(pagesRead) pages")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.black)
                        }
                    }
                    
                    Spacer()
                }
            }
            
            Spacer()
            
            // Show indicator for in-progress sessions
            if isInProgress {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                            .opacity(0.5)
                            .scaleEffect(2)
                            .animation(
                                Animation.easeInOut(duration: 1.5)
                                    .repeatForever(autoreverses: true),
                                value: isInProgress
                            )
                    )
            }
        }
        .padding(16)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isInProgress ? Color.orange.opacity(0.3) : Color.gray.opacity(0.1), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}
