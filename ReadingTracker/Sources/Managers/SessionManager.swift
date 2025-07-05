import Combine
import CoreData
import os.log

// MARK: - Modern SessionManager with async/await
@MainActor
class SessionManager: ObservableObject {
    static let shared = SessionManager()
    
    // MARK: - Published Properties (Always on main thread)
    @Published var currentSession: ReadingSession?
    @Published var isTracking: Bool = false
    @Published var isPaused: Bool = false
    @Published var distractionCount: Int = 0
    @Published var totalReadingTime: TimeInterval = 0
    
    // MARK: - Private Properties
    private var lastResumeTime: Date?
    private let container: NSPersistentContainer
    private let logger = Logger(subsystem: "SessionManager", category: "CoreData")
    private var isUpdatingState = false // Prevent concurrent state updates
    
    // Background context for heavy operations
    private lazy var backgroundContext: NSManagedObjectContext = {
        let context = container.newBackgroundContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }()
    
    // MARK: - Initialization
    init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
        
        // Setup merge notification handling
        setupMergeHandling()
        
        // Clean up incomplete sessions asynchronously
        Task {
            await cleanupIncompleteSessions()
        }
    }
    
    // MARK: - Setup Methods
    private func setupMergeHandling() {
        NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextDidSave,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self,
                  let context = notification.object as? NSManagedObjectContext,
                  context !== self.container.viewContext else { return }
            
            self.container.viewContext.mergeChanges(fromContextDidSave: notification)
        }
    }
    
    // MARK: - Cleanup Methods
    private func cleanupIncompleteSessions() async {
        logger.info("Starting cleanup of incomplete sessions")
        
        do {
            try await backgroundContext.perform {
                let fetchRequest: NSFetchRequest<ReadingSession> = ReadingSession.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "endTime == nil")
                
                let incompleteSessions = try self.backgroundContext.fetch(fetchRequest)
                
                // Filter out current session if it exists
                let currentSessionID = self.currentSession?.objectID
                let sessionsToCleanup = incompleteSessions.filter { session in
                    session.objectID != currentSessionID
                }
                
                for session in sessionsToCleanup {
                    // Set reasonable end time (1 minute after start)
                    session.endTime = session.startTime.addingTimeInterval(60)
                    session.endPage = session.startPage // No progress made
                    self.logger.info("Cleaned up incomplete session: \(session.id)")
                }
                
                if !sessionsToCleanup.isEmpty {
                    try self.backgroundContext.save()
                    self.logger.info("Cleaned up \(sessionsToCleanup.count) incomplete sessions")
                }
            }
        } catch {
            logger.error("Error cleaning up incomplete sessions: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Session Management (Modern async/await)
    func startSession(for book: Book, startingPage: Int?, location: String? = nil) async throws {
        // Prevent concurrent state updates and duplicate calls
        guard !isUpdatingState else {
            logger.warning("State update already in progress, ignoring duplicate call")
            return
        }
        
        isUpdatingState = true
        defer {
            isUpdatingState = false
            logger.info("State update completed") // 단일 완료 로그
        }
        
        // Check for existing active session
        if let currentSession = currentSession, currentSession.endTime == nil {
            // If it's the same book, don't throw error, just return
            if currentSession.book.objectID == book.objectID {
                logger.info("Same book session already active, returning existing session")
                return
            } else {
                logger.warning("Active session detected for different book: \(currentSession.book.title)")
                throw SessionError.sessionAlreadyActive
            }
        }
        
        do {
            let sessionID = try await backgroundContext.perform {
                // Get book in background context
                guard let bookInContext = try? self.backgroundContext.existingObject(with: book.objectID) as? Book else {
                    throw SessionError.objectNotFound
                }
                
                // Create new session
                let session = ReadingSession(context: self.backgroundContext)
                session.id = UUID()
                session.book = bookInContext
                session.startTime = Date()
                session.startPage = Int16(startingPage ?? Int(bookInContext.currentPage))
                session.distractionCount = 0
                session.location = location
                
                try self.backgroundContext.save()
                self.logger.info("Background context saved successfully")
                
                return session.id
            }
            
            // Small delay to ensure CoreData merge is complete
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            // Fetch session in view context using ID
            let fetchRequest: NSFetchRequest<ReadingSession> = ReadingSession.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", sessionID as CVarArg)
            fetchRequest.fetchLimit = 1
            
            guard let sessionInViewContext = try container.viewContext.fetch(fetchRequest).first else {
                throw SessionError.sessionNotFound
            }
            
            // Update UI state sequentially with delays to prevent modal dismissal
            await updateSessionStateSequentially(
                currentSession: sessionInViewContext,
                isTracking: true,
                isPaused: false,
                distractionCount: 0,
                totalReadingTime: 0
            )
            
            lastResumeTime = Date()
            logger.info("Session started successfully") // 단일 성공 로그
            
        } catch {
            logger.error("Error starting session: \(error.localizedDescription)")
            throw error
        }
    }
    
    func pauseSession() async throws {
        guard let session = currentSession, isTracking, !isPaused else { return }
        
        logger.info("Pausing session")
        
        do {
            try await backgroundContext.perform {
                guard let sessionInContext = try? self.backgroundContext.existingObject(with: session.objectID) as? ReadingSession else {
                    throw SessionError.objectNotFound
                }
                
                // Create pause event
                _ = SessionEvent.create(type: .pause, for: sessionInContext, context: self.backgroundContext)
                
                try self.backgroundContext.save()
            }
            
            // Update UI state
            var timeToAdd: TimeInterval = 0
            if let lastResume = lastResumeTime {
                timeToAdd = Date().timeIntervalSince(lastResume)
                lastResumeTime = nil
            }
            
            await updateSessionStateSequentially(
                isPaused: true,
                totalReadingTime: totalReadingTime + timeToAdd
            )
            
            logger.info("Session paused successfully")
            
        } catch {
            logger.error("Error pausing session: \(error.localizedDescription)")
            throw error
        }
    }
    
    func resumeSession() async throws {
        guard let session = currentSession, isTracking, isPaused else { return }
        
        logger.info("Resuming session")
        
        do {
            try await backgroundContext.perform {
                guard let sessionInContext = try? self.backgroundContext.existingObject(with: session.objectID) as? ReadingSession else {
                    throw SessionError.objectNotFound
                }
                
                // Create resume event
                _ = SessionEvent.create(type: .resume, for: sessionInContext, context: self.backgroundContext)
                
                try self.backgroundContext.save()
            }
            
            // Update UI state
            lastResumeTime = Date()
            await updateSessionStateSequentially(isPaused: false)
            
            logger.info("Session resumed successfully")
            
        } catch {
            logger.error("Error resuming session: \(error.localizedDescription)")
            throw error
        }
    }
    
    func recordDistraction() async throws {
        guard isTracking, !isPaused, let session = currentSession else { return }
        
        logger.info("Recording distraction")
        
        do {
            let newCount = try await backgroundContext.perform {
                guard let sessionInContext = try? self.backgroundContext.existingObject(with: session.objectID) as? ReadingSession else {
                    throw SessionError.objectNotFound
                }
                
                // Increment distraction count
                let newCount = self.distractionCount + 1
                sessionInContext.distractionCount = Int16(newCount)
                
                // Create distraction event
                _ = SessionEvent.create(type: .distraction, for: sessionInContext, context: self.backgroundContext)
                
                try self.backgroundContext.save()
                
                return newCount
            }
            
            // Update UI state
            await updateSessionStateSequentially(distractionCount: newCount)
            
            logger.info("Distraction recorded successfully")
            
        } catch {
            logger.error("Error recording distraction: \(error.localizedDescription)")
            throw error
        }
    }
    
    func endSession(currentPage: Int) async throws {
        guard let session = currentSession else { return }
        
        logger.info("Ending session at page \(currentPage)")
        
        do {
            try await backgroundContext.perform {
                guard let sessionInContext = try? self.backgroundContext.existingObject(with: session.objectID) as? ReadingSession else {
                    throw SessionError.objectNotFound
                }
                
                let bookInContext = sessionInContext.book
                
                // Calculate final reading time if not paused
                if !self.isPaused, let lastResume = self.lastResumeTime {
                    let finalTimeToAdd = Date().timeIntervalSince(lastResume)
                    // Could store this if needed
                }
                
                // Update session
                sessionInContext.endTime = Date()
                sessionInContext.endPage = Int16(currentPage)
                sessionInContext.distractionCount = Int16(self.distractionCount)
                
                // Update book progress
                bookInContext.currentPage = Int16(currentPage)
                
                try self.backgroundContext.save()
            }
            
            // Reset UI state sequentially
            await updateSessionStateSequentially(
                currentSession: nil,
                isTracking: false,
                isPaused: false,
                distractionCount: 0,
                totalReadingTime: 0
            )
            
            lastResumeTime = nil
            
            // Post notification after a small delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                NotificationCenter.default.post(name: .sessionEnded, object: nil)
            }
            
            logger.info("Session ended successfully")
            
        } catch {
            logger.error("Error ending session: \(error.localizedDescription)")
            throw error
        }
    }
    
    func cancelSession() async throws {
        guard let session = currentSession else { return }
        
        logger.info("Canceling session")
        
        do {
            try await backgroundContext.perform {
                guard let sessionInContext = try? self.backgroundContext.existingObject(with: session.objectID) as? ReadingSession else {
                    throw SessionError.objectNotFound
                }
                
                self.backgroundContext.delete(sessionInContext)
                try self.backgroundContext.save()
            }
            
            // Reset UI state sequentially
            await updateSessionStateSequentially(
                currentSession: nil,
                isTracking: false,
                isPaused: false,
                distractionCount: 0,
                totalReadingTime: 0
            )
            
            lastResumeTime = nil
            
            logger.info("Session canceled successfully")
            
        } catch {
            logger.error("Error canceling session: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Legacy Support Methods (for backward compatibility)
    func startSession(for book: Book, startingPage: Int?, location: String? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        Task {
            do {
                try await startSession(for: book, startingPage: startingPage, location: location)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    func pauseSession() {
        Task {
            do {
                try await pauseSession()
            } catch {
                logger.error("Error in legacy pauseSession: \(error.localizedDescription)")
            }
        }
    }
    
    func resumeSession() {
        Task {
            do {
                try await resumeSession()
            } catch {
                logger.error("Error in legacy resumeSession: \(error.localizedDescription)")
            }
        }
    }
    
    func recordDistraction() {
        Task {
            do {
                try await recordDistraction()
            } catch {
                logger.error("Error in legacy recordDistraction: \(error.localizedDescription)")
            }
        }
    }
    
    func endSession(currentPage: Int, completion: @escaping () -> Void) {
        Task {
            do {
                try await endSession(currentPage: currentPage)
                completion()
            } catch {
                logger.error("Error in legacy endSession: \(error.localizedDescription)")
                completion()
            }
        }
    }
    
    func cancelSession() {
        Task {
            do {
                try await cancelSession()
            } catch {
                logger.error("Error in legacy cancelSession: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Sequential State Update Methods
    private func updateSessionStateSequentially(
        currentSession: ReadingSession? = nil,
        isTracking: Bool? = nil,
        isPaused: Bool? = nil,
        distractionCount: Int? = nil,
        totalReadingTime: TimeInterval? = nil
    ) async {
        // Update @Published properties one at a time with small delays
        // to prevent "Publishing changes from within view updates" warnings
        
        if let currentSession = currentSession {
            self.currentSession = currentSession
            try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        }
        
        if let isTracking = isTracking {
            self.isTracking = isTracking
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        
        if let isPaused = isPaused {
            self.isPaused = isPaused
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        
        if let distractionCount = distractionCount {
            self.distractionCount = distractionCount
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        
        if let totalReadingTime = totalReadingTime {
            self.totalReadingTime = totalReadingTime
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }
    
    // MARK: - Deprecated Method (kept for compatibility)
    private func updateSessionState(
        currentSession: ReadingSession? = nil,
        isTracking: Bool? = nil,
        isPaused: Bool? = nil,
        distractionCount: Int? = nil,
        totalReadingTime: TimeInterval? = nil
    ) async {
        // Use the new sequential update method
        await updateSessionStateSequentially(
            currentSession: currentSession,
            isTracking: isTracking,
            isPaused: isPaused,
            distractionCount: distractionCount,
            totalReadingTime: totalReadingTime
        )
    }
    
    // MARK: - Utility Methods
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Modern Error Types
enum SessionError: LocalizedError {
    case objectNotFound
    case sessionNotFound
    case saveFailed(Error)
    case sessionAlreadyActive
    case invalidContext
    
    var errorDescription: String? {
        switch self {
        case .objectNotFound:
            return "요청한 객체를 찾을 수 없습니다"
        case .sessionNotFound:
            return "세션을 찾을 수 없습니다"
        case .saveFailed(let error):
            return "저장 실패: \(error.localizedDescription)"
        case .sessionAlreadyActive:
            return "이미 진행 중인 독서 세션이 있습니다"
        case .invalidContext:
            return "유효하지 않은 컨텍스트입니다"
        }
    }
}

// MARK: - Extensions
extension Notification.Name {
    static let sessionEnded = Notification.Name("sessionEnded")
    static let sessionPaused = Notification.Name("sessionPaused")
    static let sessionResumed = Notification.Name("sessionResumed")
}

// MARK: - Modern Usage Example
extension SessionManager {
    /// Modern async usage example
    func performSessionLifecycle(book: Book, startPage: Int, endPage: Int) async throws {
        // Start session
        try await startSession(for: book, startingPage: startPage)
        
        // Simulate reading time
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Pause session
        try await pauseSession()
        
        // Simulate break
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Resume session
        try await resumeSession()
        
        // Record distraction
        try await recordDistraction()
        
        // End session
        try await endSession(currentPage: endPage)
    }
}
