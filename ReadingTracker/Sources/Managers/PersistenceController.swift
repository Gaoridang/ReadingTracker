// PersistenceController.swift
import CoreData

class PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.viewContext

        // Add sample data
        let book = Book(context: context)
        book.id = UUID()
        book.title = "Test Book"
        book.author = "Author"
        book.totalPages = 300
        book.currentPage = 50
        book.difficulty = 3
        book.dateAdded = Date()
        book.isActive = true
        book.category = "Fiction"

        let session = ReadingSession(context: context)
        session.id = UUID()
        session.startTime = Date()
        session.endTime = Date()
        session.startPage = 50
        session.endPage = 70
        session.distractionCount = 2
        session.location = "Home"
        session.book = book

        let event = SessionEvent.create(type: .start, for: session, context: context)

        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "ReadingTracker")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            self.container.viewContext.automaticallyMergesChangesFromParent = true
            self.container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        }
    }
}
