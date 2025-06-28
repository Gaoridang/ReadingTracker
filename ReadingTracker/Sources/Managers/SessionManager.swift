import Combine
import CoreData

class SessionManager: ObservableObject {
    static let shared = SessionManager()
    @Published var currentSession: ReadingSession?
    @Published var isTracking: Bool = false
    @Published var isPaused: Bool = false
    @Published var distractionCount: Int = 0
    @Published var totalReadingTime: TimeInterval = 0 // Total time before current segment
    private var lastResumeTime: Date? // Start of current active segment
    private var distractionStartTime: Date?
    private var distractionTimerSubscription: AnyCancellable?
    let context: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
    }

    func startSession(for book: Book, location: String? = nil, completion: @escaping (Result<Void, Error>) -> Void) {
        let session = ReadingSession(context: context)
        session.id = UUID()
        session.book = book
        session.startTime = Date()
        session.startPage = Int16(book.currentPage)
        session.distractionDuration = 0
        session.location = location

        do {
            try context.save()
            DispatchQueue.main.async {
                self.currentSession = session
                self.isTracking = true
                self.isPaused = false
                self.totalReadingTime = 0
                self.lastResumeTime = Date()
                self.distractionCount = 0
                completion(.success(()))
            }
        } catch {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }
    }

    func pauseSession() {
        guard let session = currentSession, isTracking, !isPaused else { return }
        if let lastResume = lastResumeTime {
            totalReadingTime += Date().timeIntervalSince(lastResume)
            lastResumeTime = nil
        }
        DispatchQueue.main.async {
            self.isPaused = true
        }
        _ = SessionEvent.create(type: .pause, for: session, context: context)
        try? context.save()
    }

    func resumeSession() {
        guard let session = currentSession, isTracking, isPaused else { return }
        lastResumeTime = Date()
        DispatchQueue.main.async {
            self.isPaused = false
        }
        _ = SessionEvent.create(type: .resume, for: session, context: context)
        try? context.save()
    }

    func startDistraction() {
        guard isTracking, !isPaused else { return }
        distractionStartTime = Date()
        distractionCount += 1
        // No timer needed here; compute duration on end
    }

    func endDistraction() {
        guard let start = distractionStartTime, let session = currentSession else { return }
        let duration = Date().timeIntervalSince(start)
        session.distractionDuration += Int16(duration)
        distractionStartTime = nil
        try? context.save()
    }

    func endSession(currentPage: Int) {
        guard let session = currentSession else { return }
        session.endTime = Date()
        session.endPage = Int16(currentPage)
        session.book.currentPage = Int16(currentPage)
        
        do {
            try context.save()              // Save changes first
            context.refreshAllObjects()     // Refresh all objects after saving
            print("Session ended and context refreshed successfully")
        } catch {
            print("Error ending session: \(error)")
        }
        
        // Reset session state on main thread
        DispatchQueue.main.async {
            self.currentSession = nil
            self.isTracking = false
            self.isPaused = false
            self.totalReadingTime = 0
            self.distractionCount = 0
        }
    }

    func cancelSession() {
        guard let session = currentSession else { return }
        context.delete(session)
        try? context.save()
        DispatchQueue.main.async {
            self.currentSession = nil
            self.isTracking = false
            self.isPaused = false
            self.totalReadingTime = 0
            self.distractionCount = 0
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
