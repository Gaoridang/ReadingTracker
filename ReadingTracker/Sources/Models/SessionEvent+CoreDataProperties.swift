// SessionEvent+CoreDataProperties.swift
import Foundation
import CoreData

extension SessionEvent {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SessionEvent> {
        return NSFetchRequest<SessionEvent>(entityName: "SessionEvent")
    }

    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Date
    @NSManaged public var eventType: String // Changed from eventTypeRaw to eventType
    @NSManaged public var session: ReadingSession

    var eventTypeEnum: SessionEventType {
        get {
            return SessionEventType(rawValue: eventType) ?? .pause // Use eventType instead of eventTypeRaw
        }
        set {
            eventType = newValue.rawValue
        }
    }

    // Consolidated create method
    static func create(type: SessionEventType, for session: ReadingSession, context: NSManagedObjectContext) -> SessionEvent {
        let event = SessionEvent(context: context)
        event.id = UUID()
        event.timestamp = Date()
        event.eventTypeEnum = type
        event.session = session
        session.addToSessionEvents(event) // Ensure relationship is updated
        return event
    }
}
