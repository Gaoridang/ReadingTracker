// SessionEvent+Helpers.swift
import Foundation
import CoreData

extension ReadingSession {
    var orderedEvents: [SessionEvent] {
        let events = sessionEvents as? Set<SessionEvent> ?? []
        return events.sorted { $0.timestamp < $1.timestamp }
    }
    
    var pauseEvents: [SessionEvent] {
        orderedEvents.filter { $0.eventTypeEnum == .pause }
    }
    
    var distractionEvents: [SessionEvent] {
        orderedEvents.filter { $0.eventTypeEnum == .distraction }
    }
    
    // Calculate actual reading time (excluding pauses)
    var actualReadingTime: TimeInterval {
        let events = orderedEvents
        var totalTime: TimeInterval = 0
        var lastStartTime = startTime
        var isPaused = false
        
        for event in events {
            switch event.eventTypeEnum {
            case .pause:
                if !isPaused {
                    totalTime += event.timestamp.timeIntervalSince(lastStartTime)
                    isPaused = true
                }
            case .resume:
                if isPaused {
                    lastStartTime = event.timestamp
                    isPaused = false
                }
            default:
                break
            }
        }
        
        if endTime == nil && !isPaused {
            totalTime += Date().timeIntervalSince(lastStartTime)
        } else if let endTime = endTime, !isPaused {
            totalTime += endTime.timeIntervalSince(lastStartTime)
        }
        
        return totalTime
    }
}
