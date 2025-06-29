// SessionManager.swift
import Combine
import CoreData

class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    // MARK: - Published Properties (Always updated on main thread)
    @Published var currentSession: ReadingSession?
    @Published var isTracking: Bool = false
    @Published var isPaused: Bool = false
    @Published var distractionCount: Int = 0
    @Published var totalReadingTime: TimeInterval = 0
    
    // MARK: - Private Properties
    private var lastResumeTime: Date?
    private let context: NSManagedObjectContext
    
    private lazy var backgroundContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self.context
        return context
    }()

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        // Clean up any incomplete sessions on init
        cleanupIncompleteSessions()
    }
    
    // MARK: - Cleanup
    private func cleanupIncompleteSessions() {
        context.perform { [weak self] in
            guard let self = self else { return }
            
            let fetchRequest: NSFetchRequest<ReadingSession> = ReadingSession.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "endTime == nil")
            
            do {
                let incompleteSessions = try self.context.fetch(fetchRequest)
                
                // Filter out the current session if it exists
                let sessionsToCleanup = incompleteSessions.filter { session in
                    // Don't clean up if this is the current session
                    if let currentSession = self.currentSession {
                        return session.objectID != currentSession.objectID
                    }
                    return true
                }
                
                for session in sessionsToCleanup {
                    // Set a reasonable end time (1 minute after start)
                    session.endTime = session.startTime.addingTimeInterval(60)
                    session.endPage = session.startPage // No progress made
                    print("Cleaned up incomplete session: \(session.id)")
                }
                
                if !sessionsToCleanup.isEmpty {
                    try self.context.save()
                    print("Cleaned up \(sessionsToCleanup.count) incomplete sessions")
                }
            } catch {
                print("Error cleaning up incomplete sessions: \(error)")
            }
        }
    }

    // MARK: - Main Actor for UI Updates
    @MainActor
    private func updatePublishedProperties(
        currentSession: ReadingSession? = nil,
        isTracking: Bool? = nil,
        isPaused: Bool? = nil,
        distractionCount: Int? = nil,
        totalReadingTime: TimeInterval? = nil,
        updateSession: Bool = false
    ) {
        if updateSession || currentSession != nil {
            self.currentSession = currentSession
        }
        if let isTracking = isTracking {
            self.isTracking = isTracking
        }
        if let isPaused = isPaused {
            self.isPaused = isPaused
        }
        if let distractionCount = distractionCount {
            self.distractionCount = distractionCount
        }
        if let totalReadingTime = totalReadingTime {
            self.totalReadingTime = totalReadingTime
        }
    }

    // MARK: - Session Management
    func startSession(for book: Book, location: String? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        if let currentSession = currentSession, currentSession.endTime == nil {
            print("Active session detected: \(currentSession.startTime ?? Date()), endTime: \(currentSession.endTime)")
            DispatchQueue.main.async {
                completion(.failure(CoreDataError.sessionAlreadyActive))
            }
            return
        }
        
        print("Starting session for book: \(book.title)")
        
        backgroundContext.perform { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(.failure(CoreDataError.objectNotFound))
                }
                return
            }
            
            print("Inside background context perform block")
            
            do {
                guard let bookInContext = try self.backgroundContext.existingObject(with: book.objectID) as? Book else {
                    print("Failed to fetch book in background context")
                    DispatchQueue.main.async {
                        completion(.failure(CoreDataError.objectNotFound))
                    }
                    return
                }
                print("Book found in background context: \(bookInContext.title)")
                
                let session = ReadingSession(context: self.backgroundContext)
                session.id = UUID()
                session.book = bookInContext
                session.startTime = Date()
                session.startPage = Int16(bookInContext.currentPage)
                session.distractionCount = 0
                session.location = location
                
                try self.backgroundContext.save()
                print("Background context saved successfully")
                
                self.context.performAndWait {
                    do {
                        try self.context.save()
                        print("Main context saved successfully")
                        
                        // 페치 요청을 사용하여 세션 객체를 가져옵니다.
                        let fetchRequest: NSFetchRequest<ReadingSession> = ReadingSession.fetchRequest()
                        fetchRequest.predicate = NSPredicate(format: "id == %@", session.id as CVarArg)
                        fetchRequest.fetchLimit = 1
                        
                        if let sessionInMainContext = try self.context.fetch(fetchRequest).first {
                            print("Session fetched successfully in main context")
                            Task { @MainActor in
                                self.updatePublishedProperties(
                                    currentSession: sessionInMainContext,
                                    isTracking: true,
                                    isPaused: false,
                                    distractionCount: 0,
                                    totalReadingTime: 0
                                )
                                self.lastResumeTime = Date()
                                completion(.success(()))
                                print("Completion handler called with success")
                            }
                        } else {
                            print("Failed to fetch session in main context")
                            // 실패 시 오류를 호출자에게 전달
                            DispatchQueue.main.async {
                                completion(.failure(NSError(domain: "SessionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch session in main context"])))
                            }
                        }
                    } catch {
                        print("Error saving main context: \(error)")
                        DispatchQueue.main.async {
                            completion(.failure(error))
                        }
                    }
                }
            } catch {
                print("Error in background context: \(error)")
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }

    func pauseSession() {
        guard let session = currentSession, isTracking, !isPaused else { return }
        
        backgroundContext.perform { [weak self] in
            guard let self = self,
                  let sessionInContext = try? self.backgroundContext.existingObject(with: session.objectID) as? ReadingSession else { return }
            
            // Calculate time to add
            var timeToAdd: TimeInterval = 0
            if let lastResume = self.lastResumeTime {
                timeToAdd = Date().timeIntervalSince(lastResume)
                self.lastResumeTime = nil
            }
            
            // Create pause event
            _ = SessionEvent.create(type: .pause, for: sessionInContext, context: self.backgroundContext)
            
            do {
                try self.backgroundContext.save()
                
                // Update main context
                self.context.performAndWait {
                    try? self.context.save()
                }
                
                // Update UI on main thread
                Task { @MainActor in
                    self.totalReadingTime += timeToAdd
                    self.isPaused = true
                }
            } catch {
                print("Error pausing session: \(error)")
            }
        }
    }

    func resumeSession() {
        guard let session = currentSession, isTracking, isPaused else { return }
        
        backgroundContext.perform { [weak self] in
            guard let self = self,
                  let sessionInContext = try? self.backgroundContext.existingObject(with: session.objectID) as? ReadingSession else { return }
            
            self.lastResumeTime = Date()
            
            // Create resume event
            _ = SessionEvent.create(type: .resume, for: sessionInContext, context: self.backgroundContext)
            
            do {
                try self.backgroundContext.save()
                
                // Update main context
                self.context.performAndWait {
                    try? self.context.save()
                }
                
                // Update UI on main thread
                Task { @MainActor in
                    self.isPaused = false
                }
            } catch {
                print("Error resuming session: \(error)")
            }
        }
    }

    func recordDistraction() {
        guard isTracking, !isPaused, let session = currentSession else { return }
        
        backgroundContext.perform { [weak self] in
            guard let self = self,
                  let sessionInContext = try? self.backgroundContext.existingObject(with: session.objectID) as? ReadingSession else { return }
            
            // Increment distraction count
            let newCount = self.distractionCount + 1
            sessionInContext.distractionCount = Int16(newCount)
            
            // Create distraction event
            _ = SessionEvent.create(type: .distraction, for: sessionInContext, context: self.backgroundContext)
            
            do {
                try self.backgroundContext.save()
                
                // Update main context
                self.context.performAndWait {
                    try? self.context.save()
                }
                
                // Update UI on main thread
                Task { @MainActor in
                    self.distractionCount = newCount
                }
            } catch {
                print("Error recording distraction: \(error)")
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
            
            // Calculate final reading time if not paused
            var finalTimeToAdd: TimeInterval = 0
            if !self.isPaused, let lastResume = self.lastResumeTime {
                finalTimeToAdd = Date().timeIntervalSince(lastResume)
            }
            
            // Update session
            sessionInContext.endTime = Date()
            sessionInContext.endPage = Int16(currentPage)
            sessionInContext.distractionCount = Int16(self.distractionCount)
            
            // Update book progress
            bookInContext.currentPage = Int16(currentPage)
            
            do {
                try self.backgroundContext.save()
                
                // Update main context
                self.context.performAndWait {
                    do {
                        try self.context.save()
                        NotificationCenter.default.post(name: .sessionEnded, object: nil)
                    } catch {
                        print("Error saving to main context: \(error)")
                    }
                }
                print("Ending session for page \(currentPage)")
                
                // Reset state on main thread
                Task { @MainActor in
                    self.updatePublishedProperties(
                        currentSession: nil,
                        isTracking: false,
                        isPaused: false,
                        distractionCount: 0,
                        totalReadingTime: 0
                    )
                    self.lastResumeTime = nil
                    print("Session state reset: currentSession is now nil")
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
                
                // Update main context
                self.context.performAndWait {
                    try? self.context.save()
                }
                
                // Reset state on main thread
                Task { @MainActor in
                    self.updatePublishedProperties(
                        currentSession: nil,
                        isTracking: false,
                        isPaused: false,
                        distractionCount: 0,
                        totalReadingTime: 0
                    )
                    self.lastResumeTime = nil
                }
            } catch {
                print("Error canceling session: \(error)")
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

// MARK: - Error Types
enum CoreDataError: LocalizedError {
    case objectNotFound
    case saveFailed(Error)
    case sessionAlreadyActive
    
    var errorDescription: String? {
        switch self {
        case .objectNotFound:
            return "The requested object could not be found"
        case .saveFailed(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .sessionAlreadyActive:
            return "A reading session is already in progress"
        }
    }
}
