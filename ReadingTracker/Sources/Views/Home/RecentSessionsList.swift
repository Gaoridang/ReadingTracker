//
//  RecentSessionsList.swift
//  ReadingTracker
//
//  Created by 이재준 on 6/27/25.
//

import SwiftUI
import CoreData

struct RecentSessionsList: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ReadingSession.startTime, ascending: false)],
        predicate: nil,
        animation: .default
    ) private var sessions: FetchedResults<ReadingSession>
    
    // Define the fetch request with fetchLimit
    private let fetchRequest: NSFetchRequest<ReadingSession> = {
        let request: NSFetchRequest<ReadingSession> = ReadingSession.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ReadingSession.startTime, ascending: false)]
        request.fetchLimit = 3 // Set fetchLimit here
        return request
    }()
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(sessions) { session in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.book.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.black)
                        Text(sessionSummary(for: session))
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Text(timeAgo(for: session.startTime))
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.03), radius: 5)
            }
        }
    }
    
    private func sessionSummary(for session: ReadingSession) -> String {
        let duration = (session.endTime ?? Date()).timeIntervalSince(session.startTime) / 60
        let pages = session.endPage - session.startPage
        let focus = max(100 - Double(session.distractionCount * 10), 0)
        return "\(Int(duration)) min • \(pages) pages • \(Int(focus))% focus"
    }
    
    private func timeAgo(for date: Date) -> String {
        let minutes = Int(Date().timeIntervalSince(date) / 60)
        if minutes < 60 {
            return "\(minutes)m ago"
        } else {
            return "\(minutes / 60)h ago"
        }
    }
}

#Preview {
    RecentSessionsList()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
