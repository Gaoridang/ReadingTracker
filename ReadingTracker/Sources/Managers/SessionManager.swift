// SessionManager.swift
import Combine
import CoreData

class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    @Published var currentSession: ReadingSession? {
        didSet {
            print("currentSession updated on \(Thread.current.isMainThread ? "main" : "background") thread")
        }
    }
    @Published var isTracking: Bool = false {
        didSet {
            print("isTracking updated to \(isTracking) on \(Thread.current.isMainThread ? "main" : "background") thread")
        }
    }
    @Published var isPaused: Bool = false {
        didSet {
            print("isPaused updated to \(isPaused) on \(Thread.current.isMainThread ? "main" : "background") thread")
        }
    }
    @Published var distractionCount: Int = 0 {
        didSet {
            print("distractionCount updated to \(distractionCount) on \(Thread.current.isMainThread ? "main" : "background") thread")
        }
    }
    @Published var totalReadingTime: TimeInterval = 0 {
        didSet {
            print("totalReadingTime updated to \(totalReadingTime) on \(Thread.current.isMainThread ? "main" : "background") thread")
        }
    }
    
    private var lastResumeTime: Date?
    private var distractionStartTime: Date?
    private var distractionTimerSubscription: AnyCancellable?
    private let context: NSManagedObjectContext
    
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
            
            let session = ReadingSession(context: self.context)
            session.id = UUID()
            session.book = book
            session.startTime = Date()
            session.startPage = Int16(book.currentPage)
            session.distractionCount = 0
            session.location = location

            do {
                try self.context.save()
                print("Session saved to main context")
                
                self.currentSession = session
                self.isTracking = true
                self.isPaused = false
                self.totalReadingTime = 0
                self.lastResumeTime = Date()
                self.distractionCount = 0
                
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
            
            var timeToAdd: TimeInterval = 0
            if let lastResume = self.lastResumeTime {
                timeToAdd = Date().timeIntervalSince(lastResume)
                self.lastResumeTime = nil
            }
            
            _ = SessionEvent.create(type: .pause, for: sessionInContext, context: self.backgroundContext)
            try? self.backgroundContext.save()
            
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
            if let session = self.currentSession,
               let sessionInContext = try? self.context.existingObject(with: session.objectID) as? ReadingSession {
                sessionInContext.distractionCount = Int16(self.distractionCount)
                try? self.context.save()
            }
        }
    }

    func endDistraction() {
        guard distractionStartTime != nil, let session = currentSession else { return }
        
        backgroundContext.perform { [weak self] in
            guard let self = self,
                  let sessionInContext = try? self.backgroundContext.existingObject(with: session.objectID) as? ReadingSession else { return }
            
            _ = SessionEvent.create(type: .distraction, for: sessionInContext, context: self.backgroundContext)
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
            
            let bookInContext = sessionInContext.book
            
            // Update session
            sessionInContext.endTime = Date()
            sessionInContext.endPage = Int16(currentPage)
            sessionInContext.distractionCount = Int16(self.distractionCount)
            
            // Update book progress
            bookInContext.currentPage = Int16(currentPage)
            
            do {
                try self.backgroundContext.save()
                
                DispatchQueue.main.async {
                    self.context.performAndWait {
                        do {
                            try self.context.save()
                            NotificationCenter.default.post(name: .sessionEnded, object: nil)
                        } catch {
                            print("Error saving to main context: \(error)")
                        }
                    }
                    
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
