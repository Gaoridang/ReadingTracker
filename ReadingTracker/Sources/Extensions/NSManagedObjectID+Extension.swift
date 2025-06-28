// NSManagedObjectID+Extension.swift
import CoreData

extension NSManagedObjectContext {
    /// Safely retrieves an object in this context using an objectID from another context
    func existingObject<T: NSManagedObject>(withID objectID: NSManagedObjectID, ofType type: T.Type) -> T? {
        do {
            let object = try existingObject(with: objectID)
            return object as? T
        } catch {
            print("Error fetching object with ID \(objectID): \(error)")
            return nil
        }
    }
}
