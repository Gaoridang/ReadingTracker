// ReadingSession+CoreDataProperties.swift
import Foundation
import CoreData

extension ReadingSession {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ReadingSession> {
        return NSFetchRequest<ReadingSession>(entityName: "ReadingSession")
    }

    @NSManaged public var id: UUID
    @NSManaged public var startTime: Date
    @NSManaged public var endTime: Date?
    @NSManaged public var startPage: Int16
    @NSManaged public var endPage: Int16
    @NSManaged public var distractionCount: Int16
    @NSManaged public var location: String?
    @NSManaged public var book: Book
    @NSManaged public var sessionEvents: NSSet?

    var pagesRead: Int {
        return Int(endPage - startPage)
    }

    var focusScore: Double {
        let start = startTime
        let end = endTime ?? Date()
        
        let duration = end.timeIntervalSince(start)
        guard duration > 0 else { return 100 }
        
        let distractionPenalty = Double(distractionCount) * 5 // Penalty of 5 points per distraction
        return max(0, 100 - distractionPenalty)
    }
}

// Generated accessors for sessionEvents
extension ReadingSession {
    @objc(addSessionEventsObject:)
    @NSManaged public func addToSessionEvents(_ value: SessionEvent)

    @objc(removeSessionEventsObject:)
    @NSManaged public func removeFromSessionEvents(_ value: SessionEvent)

    @objc(addSessionEvents:)
    @NSManaged public func addToSessionEvents(_ values: NSSet)

    @objc(removeSessionEvents:)
    @NSManaged public func removeFromSessionEvents(_ values: NSSet)
}
