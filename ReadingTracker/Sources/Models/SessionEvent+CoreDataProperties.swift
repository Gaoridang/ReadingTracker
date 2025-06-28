import Foundation
import CoreData

extension SessionEvent {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<SessionEvent> {
        return NSFetchRequest<SessionEvent>(entityName: "SessionEvent")
    }

    @NSManaged public var id: UUID
    @NSManaged public var timestamp: Date
    @NSManaged public var eventType: String
    @NSManaged public var session: ReadingSession
}
