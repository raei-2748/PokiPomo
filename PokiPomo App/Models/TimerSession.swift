//
//  TimerSession.swift
//  PokiPomo App
//
//  Created by Ray Wang on 1/31/26.
//

import Foundation

// MARK: - Timer Status

enum TimerStatus: String, Codable {
    case notStarted
    case running
    case paused
    case completed
    case failed
}

// MARK: - Timer Session

struct TimerSession: Codable, Identifiable {
    let id: UUID
    var taskName: String?
    var targetMinutes: Int
    var actualMinutes: Int
    var startTime: Date
    var endTime: Date?
    var status: TimerStatus
    var deliverableChecked: Bool
    var urgeHoldAttempts: Int
    var appSwitchCount: Int
    var reflection: String?
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        taskName: String? = nil,
        targetMinutes: Int,
        actualMinutes: Int = 0,
        startTime: Date = Date(),
        endTime: Date? = nil,
        status: TimerStatus = .notStarted,
        deliverableChecked: Bool = false,
        urgeHoldAttempts: Int = 0,
        appSwitchCount: Int = 0,
        reflection: String? = nil
    ) {
        self.id = id
        self.taskName = taskName
        self.targetMinutes = targetMinutes
        self.actualMinutes = actualMinutes
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.deliverableChecked = deliverableChecked
        self.urgeHoldAttempts = urgeHoldAttempts
        self.appSwitchCount = appSwitchCount
        self.reflection = reflection
    }
    
    // MARK: - Computed Properties
    
    /// Total target duration in seconds
    var targetSeconds: Int {
        targetMinutes * 60
    }
    
    /// Elapsed seconds since start (clamped to target)
    var elapsedSeconds: Int {
        guard status == .running || status == .paused else {
            return actualMinutes * 60
        }
        let elapsed = Int(Date().timeIntervalSince(startTime))
        return min(elapsed, targetSeconds)
    }
    
    /// Remaining seconds in the session
    var remainingSeconds: Int {
        max(0, targetSeconds - elapsedSeconds)
    }
    
    /// Whether the timer has reached zero
    var isComplete: Bool {
        remainingSeconds == 0
    }
    
    /// Formatted remaining time as MM:SS
    var formattedRemaining: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
