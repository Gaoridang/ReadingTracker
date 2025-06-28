//
//  MinimalGrassGraph.swift
//  ReadingTracker
//
//  Created by 이재준 on 6/27/25.
//


import SwiftUI
import CoreData

struct MinimalGrassGraph: View {
    @Environment(\.managedObjectContext) private var viewContext
    let weeks = 12
    let days = 7
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<weeks, id: \.self) { week in
                VStack(spacing: 3) {
                    ForEach(0..<days, id: \.self) { day in
                        let date = Calendar.current.date(
                            byAdding: .day,
                            value: -(week * 7 + day),
                            to: Calendar.current.startOfDay(for: Date())
                        )!
                        RoundedRectangle(cornerRadius: 2)
                            .fill(colorForDate(date))
                            .frame(width: 10, height: 10)
                    }
                }
            }
        }
    }
    
    func colorForDate(_ date: Date) -> Color {
        let fetchRequest: NSFetchRequest<ReadingSession> = ReadingSession.fetchRequest()
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        fetchRequest.predicate = NSPredicate(format: "startTime >= %@ AND startTime < %@", start as NSDate, end as NSDate)
        
        guard let sessions = try? viewContext.fetch(fetchRequest), !sessions.isEmpty else {
            return Color.gray.opacity(0.1)
        }
        
        let pagesRead = sessions.reduce(0) { $0 + Int($1.endPage - $1.startPage) }
        let intensity = min(Double(pagesRead) / 50, 1.0) // Scale intensity
        return Color(hex: "4CAF50").opacity(intensity)
    }
}