// Book+CoreDataProperties.swift
import Foundation
import CoreData

extension Book {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Book> {
        return NSFetchRequest<Book>(entityName: "Book")
    }

    @NSManaged public var id: UUID
    @NSManaged public var title: String
    @NSManaged public var author: String
    @NSManaged public var totalPages: Int16
    @NSManaged public var currentPage: Int16
    @NSManaged public var difficulty: Int16
    @NSManaged public var dateAdded: Date
    @NSManaged public var isActive: Bool
    @NSManaged public var category: String?
    @NSManaged public var sessions: NSSet?

    var percentComplete: Double {
        guard totalPages > 0 else { return 0 }
        return Double(currentPage) / Double(totalPages) * 100
    }
}

// Generated accessors for sessions
extension Book {
    @objc(addSessionsObject:)
    @NSManaged public func addToSessions(_ value: ReadingSession)

    @objc(removeSessionsObject:)
    @NSManaged public func removeFromSessions(_ value: ReadingSession)

    @objc(addSessions:)
    @NSManaged public func addToSessions(_ values: NSSet)

    @objc(removeSessions:)
    @NSManaged public func removeFromSessions(_ values: NSSet)
}
