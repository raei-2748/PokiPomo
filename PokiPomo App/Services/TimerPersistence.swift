//
//  TimerPersistence.swift
//  PokiPomo App
//
//  Created by Ray Wang on 1/31/26.
//

import Foundation

// MARK: - Timer Persistence Service

final class TimerPersistence {
    
    // MARK: - Keys
    
    private static let activeSessionKey = "active_session"
    private static let sessionHistoryKey = "session_history"
    private static let lastSessionDateKey = "lastSessionDate"
    private static let currentStreakKey = "currentStreak"
    
    // MARK: - Active Session
    
    /// Save the current active session
    static func saveActive(_ session: TimerSession) {
        do {
            let data = try JSONEncoder().encode(session)
            UserDefaults.standard.set(data, forKey: activeSessionKey)
        } catch {
            print("Failed to save active session: \(error)")
        }
    }
    
    /// Restore an active session if one exists
    static func restoreActive() -> TimerSession? {
        guard let data = UserDefaults.standard.data(forKey: activeSessionKey) else {
            return nil
        }
        do {
            let session = try JSONDecoder().decode(TimerSession.self, from: data)
            // Only restore if it was running or paused
            if session.status == .running || session.status == .paused {
                return session
            }
            return nil
        } catch {
            print("Failed to restore active session: \(error)")
            return nil
        }
    }
    
    /// Clear the active session
    static func clearActive() {
        UserDefaults.standard.removeObject(forKey: activeSessionKey)
    }
    
    // MARK: - Session History
    
    /// Save a completed session to history
    static func saveToHistory(_ session: TimerSession) {
        var history = loadHistory()
        history.insert(session, at: 0)
        
        // Keep only last 100 sessions
        if history.count > 100 {
            history = Array(history.prefix(100))
        }
        
        do {
            let data = try JSONEncoder().encode(history)
            UserDefaults.standard.set(data, forKey: sessionHistoryKey)
        } catch {
            print("Failed to save session history: \(error)")
        }
    }
    
    /// Load all session history
    static func loadHistory() -> [TimerSession] {
        guard let data = UserDefaults.standard.data(forKey: sessionHistoryKey) else {
            return []
        }
        do {
            return try JSONDecoder().decode([TimerSession].self, from: data)
        } catch {
            print("Failed to load session history: \(error)")
            return []
        }
    }
    
    // MARK: - Streak Management
    
    /// Update streak based on session completion
    static func updateStreak() {
        let lastDate = UserDefaults.standard.object(forKey: lastSessionDateKey) as? Date
        let today = Calendar.current.startOfDay(for: Date())
        var currentStreak = UserDefaults.standard.integer(forKey: currentStreakKey)
        
        if let last = lastDate {
            let lastDay = Calendar.current.startOfDay(for: last)
            let daysDiff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if daysDiff == 1 {
                // Consecutive day - increment streak
                currentStreak += 1
            } else if daysDiff > 1 {
                // Missed days - reset streak
                currentStreak = 1
            }
            // If same day (daysDiff == 0), streak stays the same
        } else {
            // First session ever
            currentStreak = 1
        }
        
        UserDefaults.standard.set(Date(), forKey: lastSessionDateKey)
        UserDefaults.standard.set(currentStreak, forKey: currentStreakKey)
    }
    
    /// Get current streak
    static func getCurrentStreak() -> Int {
        let lastDate = UserDefaults.standard.object(forKey: lastSessionDateKey) as? Date
        let today = Calendar.current.startOfDay(for: Date())
        var currentStreak = UserDefaults.standard.integer(forKey: currentStreakKey)
        
        // Check if streak is still valid (completed session yesterday or today)
        if let last = lastDate {
            let lastDay = Calendar.current.startOfDay(for: last)
            let daysDiff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if daysDiff > 1 {
                // Streak broken - hasn't completed in over a day
                currentStreak = 0
            }
        } else {
            currentStreak = 0
        }
        
        return currentStreak
    }
    
    // MARK: - Stats Helpers
    
    /// Get today's Uninterrupted Focus Minutes
    static func getTodayUFM() -> Int {
        let history = loadHistory()
        let today = Calendar.current.startOfDay(for: Date())
        
        return history
            .filter { session in
                guard session.status == .completed else { return false }
                let sessionDay = Calendar.current.startOfDay(for: session.startTime)
                return sessionDay == today
            }
            .reduce(0) { $0 + $1.actualMinutes }
    }
    
    /// Get last N sessions
    static func getRecentSessions(count: Int = 10) -> [TimerSession] {
        return Array(loadHistory().prefix(count))
    }
}
