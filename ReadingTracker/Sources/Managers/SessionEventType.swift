//
//  SessionEventType.swift
//  ReadingTracker
//
//  Created by 이재준 on 6/28/25.
//


// SessionEventType.swift
import Foundation

enum SessionEventType: String, Codable {
    case start = "start"
    case pause = "pause"
    case resume = "resume"
    case distraction = "distraction"
}
