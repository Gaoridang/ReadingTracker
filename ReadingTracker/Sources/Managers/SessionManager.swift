import Combine
import CoreData

class SessionManager: ObservableObject {
    static let shared = SessionManager()
    @Published var currentSession: ReadingSession?
    @Published var isTracking: Bool = false
    @Published var isPaused: Bool = false
    @Published var distractionCount: Int = 0
    @Published var totalReadingTime: TimeInterval = 0
    private var lastResumeTime: Date?
    private var distractionStartTime: Date?
    private var distractionTimerSubscription: AnyCancellable?
    private let context: NSManagedObjectContext
    
    // Use a background context for write operations
    private lazy var backgroundContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.context
        return context
    }()

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    func startSession(for book: Book, location: String? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        context.perform { [weak self] in
            guard let self = self else { return }
            
            // Create the session in the main context
            let session = ReadingSession(context: self.context)
            session.id = UUID()
            session.book = book
            session.startTime = Date()
            session.startPage = Int16(book.currentPage)
            session.distractionDuration = 0
            session.location = location

            do {
                // Save the session to the main context
                try self.context.save()
                print("Session saved to main context")
                
                // Update state
                self.currentSession = session
                self.isTracking = true
                self.isPaused = false
                self.totalReadingTime = 0
                self.lastResumeTime = Date()
                self.distractionCount = 0
                
                // Notify success
                completion(.success(()))
            } catch {
                print("Error saving session: \(error)")
                completion(.failure(error))
            }
        }
    }

    func pauseSession() {
        guard let session = currentSession, isTracking, !isPaused else { return }
        
        backgroundContext.perform { [weak self] in
            guard let self = self,
                  let sessionInContext = try? self.backgroundContext.existingObject(with: session.objectID) as? ReadingSession else { return }
            
            // Calculate time to add on background thread
            var timeToAdd: TimeInterval = 0
            if let lastResume = self.lastResumeTime {
                timeToAdd = Date().timeIntervalSince(lastResume)
                self.lastResumeTime = nil
            }
            
            _ = SessionEvent.create(type: .pause, for: sessionInContext, context: self.backgroundContext)
            try? self.backgroundContext.save()
            
            // Update @Published property on main thread
            DispatchQueue.main.async {
                self.totalReadingTime += timeToAdd
                self.isPaused = true
                self.context.performAndWait {
                    try? self.context.save()
                }
            }
        }
    }

    func resumeSession() {
        guard let session = currentSession, isTracking, isPaused else { return }
        
        backgroundContext.perform { [weak self] in
            guard let self = self,
                  let sessionInContext = try? self.backgroundContext.existingObject(with: session.objectID) as? ReadingSession else { return }
            
            self.lastResumeTime = Date()
            _ = SessionEvent.create(type: .resume, for: sessionInContext, context: self.backgroundContext)
            try? self.backgroundContext.save()
            
            DispatchQueue.main.async {
                self.isPaused = false
                self.context.performAndWait {
                    try? self.context.save()
                }
            }
        }
    }

    func startDistraction() {
        guard isTracking, !isPaused else { return }
        distractionStartTime = Date()
        DispatchQueue.main.async {
            self.distractionCount += 1
        }
    }

    func endDistraction() {
        guard let start = distractionStartTime, let session = currentSession else { return }
        
        let duration = Date().timeIntervalSince(start)
        
        backgroundContext.perform { [weak self] in
            guard let self = self,
                  let sessionInContext = try? self.backgroundContext.existingObject(with: session.objectID) as? ReadingSession else { return }
            
            sessionInContext.distractionDuration += Int16(duration)
            sessionInContext.distractionCount = Int16(self.distractionCount)
            try? self.backgroundContext.save()
            
            DispatchQueue.main.async {
                self.distractionStartTime = nil
                self.context.performAndWait {
                    try? self.context.save()
                }
            }
        }
    }

    func endSession(currentPage: Int, completion: @escaping () -> Void) {
        guard let session = currentSession else {
            DispatchQueue.main.async {
                completion()
            }
            return
        }
        
        backgroundContext.perform { [weak self] in
            guard let self = self,
                  let sessionInContext = try? self.backgroundContext.existingObject(with: session.objectID) as? ReadingSession else {
                DispatchQueue.main.async {
                    completion()
                }
                return
            }
            
            let bookInContext = sessionInContext.book // Directly access the non-optional book property
            
            // Update session
            sessionInContext.endTime = Date()
            sessionInContext.endPage = Int16(currentPage)
            sessionInContext.distractionCount = Int16(self.distractionCount)
            
            // Update book progress
            bookInContext.currentPage = Int16(currentPage)
            
            do {
                try self.backgroundContext.save()
                
                // Save to parent context and broadcast notification
                DispatchQueue.main.async {
                    self.context.performAndWait {
                        do {
                            try self.context.save()
                            // Post notification after successful save
                            NotificationCenter.default.post(name: .sessionEnded, object: nil)
                        } catch {
                            print("Error saving to main context: \(error)")
                        }
                    }
                    
                    // Reset session state
                    self.currentSession = nil
                    self.isTracking = false
                    self.isPaused = false
                    self.totalReadingTime = 0
                    self.distractionCount = 0
                    self.lastResumeTime = nil
                    
                    completion()
                }
            } catch {
                print("Error ending session: \(error)")
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }

    func cancelSession() {
        guard let session = currentSession else { return }
        
        backgroundContext.perform { [weak self] in
            guard let self = self,
                  let sessionInContext = try? self.backgroundContext.existingObject(with: session.objectID) as? ReadingSession else { return }
            
            self.backgroundContext.delete(sessionInContext)
            do {
                try self.backgroundContext.save()
                print("Session deleted from background context")
            } catch {
                print("Error deleting session from background context: \(error)")
            }
            
            DispatchQueue.main.async {
                self.context.performAndWait {
                    do {
                        try self.context.save()
                        print("Main context updated after session deletion")
                    } catch {
                        print("Error saving main context after deletion: \(error)")
                    }
                }
                self.currentSession = nil
                self.isTracking = false
                self.isPaused = false
                self.totalReadingTime = 0
                self.distractionCount = 0
                self.lastResumeTime = nil
                print("SessionManager state reset after cancellation")
            }
        }
    }
    
    func currentDuration(at date: Date) -> TimeInterval {
        guard isTracking else { return 0 }
        if isPaused {
            return totalReadingTime
        } else if let lastResume = lastResumeTime {
            return totalReadingTime + date.timeIntervalSince(lastResume)
        } else {
            return totalReadingTime
        }
    }
}

enum CoreDataError: Error {
    case objectNotFound
    case saveFailed
}
