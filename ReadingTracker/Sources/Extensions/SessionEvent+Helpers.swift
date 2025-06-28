//
//  SessionEvent+Helpers.swift
//  ReadingTracker
//
//  Created by 이재준 on 6/28/25.
//

// SessionEvent+Helpers.swift
import Foundation
import CoreData

extension SessionEvent {
    enum EventType: String {
        case start = "start"
        case pause = "pause"
        case resume = "resume"
        case distraction = "distraction"
        case end = "end"
    }
    
    static func create(type: EventType, for session: ReadingSession, context: NSManagedObjectContext) -> SessionEvent {
        let event = SessionEvent(context: context)
        event.id = UUID()
        event.timestamp = Date()
        event.eventType = type.rawValue
        event.session = session
        
        // Add to session's events
        session.addToSessionEvents(event)
        
        return event
    }
}

// Extension to get typed events from a session
extension ReadingSession {
    var orderedEvents: [SessionEvent] {
        let events = sessionEvents as? Set<SessionEvent> ?? []
        return events.sorted { $0.timestamp < $1.timestamp }
    }
    
    var pauseEvents: [SessionEvent] {
        orderedEvents.filter { $0.eventType == SessionEvent.EventType.pause.rawValue }
    }
    
    var distractionEvents: [SessionEvent] {
        orderedEvents.filter { $0.eventType == SessionEvent.EventType.distraction.rawValue }
    }
    
    // Calculate actual reading time (excluding pauses)
    var actualReadingTime: TimeInterval {
        let events = orderedEvents
        var totalTime: TimeInterval = 0
        var lastStartTime = startTime
        var isPaused = false
        
        for event in events {
            switch event.eventType {
            case SessionEvent.EventType.pause.rawValue:
                if !isPaused {
                    totalTime += event.timestamp.timeIntervalSince(lastStartTime)
                    isPaused = true
                }
            case SessionEvent.EventType.resume.rawValue:
                if isPaused {
                    lastStartTime = event.timestamp
                    isPaused = false
                }
            case SessionEvent.EventType.end.rawValue:
                if !isPaused {
                    totalTime += event.timestamp.timeIntervalSince(lastStartTime)
                }
            default:
                break
            }
        }
        
        if endTime == nil && !isPaused {
            totalTime += Date().timeIntervalSince(lastStartTime)
        }
        
        return totalTime
    }
}

extension Notification.Name {
    static let sessionEnded = Notification.Name("sessionEnded")
}
