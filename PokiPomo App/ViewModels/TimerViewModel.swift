//
//  TimerViewModel.swift
//  PokiPomo App
//
//  Created by Ray Wang on 1/31/26.
//

import Foundation
import Combine
import SwiftUI

// MARK: - Timer View Model

@MainActor
final class TimerViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var currentSession: TimerSession?
    @Published var remainingSeconds: Int = 0
    @Published var isTimerActive: Bool = false
    @Published var showResumeWall: Bool = false
    @Published var showCompletion: Bool = false
    @Published var resumeCountdown: Int = 3
    
    // MARK: - Settings
    
    @AppStorage("resumeWallDelay") var resumeWallDelay: Double = 3.0
    @AppStorage("lastSelectedDuration") var lastSelectedDuration: Int = 25
    
    // MARK: - Private Properties
    
    private var timerCancellable: AnyCancellable?
    private var backgroundTime: Date?
    private var lastPersistTime: Date?
    private var resumeWallTimer: AnyCancellable?
    
    // MARK: - Initialization
    
    init() {
        restoreActiveSession()
    }
    
    // MARK: - Session Lifecycle
    
    /// Start a new focus session
    func startSession(minutes: Int, taskName: String?) {
        let session = TimerSession(
            taskName: taskName?.isEmpty == true ? nil : taskName,
            targetMinutes: minutes,
            startTime: Date(),
            status: .running
        )
        
        currentSession = session
        remainingSeconds = session.targetSeconds
        isTimerActive = true
        lastSelectedDuration = minutes
        
        startTimer()
        persistState()
    }
    
    /// Pause the current session
    func pauseSession() {
        guard var session = currentSession, session.status == .running else { return }
        
        session.status = .paused
        currentSession = session
        
        stopTimer()
        persistState()
    }
    
    /// Resume a paused session
    func resumeSession() {
        guard var session = currentSession, session.status == .paused else { return }
        
        // Recalculate start time to maintain remaining time
        let elapsedBeforePause = session.targetSeconds - remainingSeconds
        session.startTime = Date().addingTimeInterval(TimeInterval(-elapsedBeforePause))
        session.status = .running
        currentSession = session
        
        startTimer()
        persistState()
    }
    
    /// Complete the session successfully
    func completeSession() {
        guard var session = currentSession else { return }
        
        session.status = .completed
        session.endTime = Date()
        session.actualMinutes = session.targetMinutes
        currentSession = session
        
        stopTimer()
        isTimerActive = false
        showCompletion = true
        
        // Save to history and update streak
        TimerPersistence.saveToHistory(session)
        TimerPersistence.updateStreak()
        TimerPersistence.clearActive()
    }
    
    /// Fail the session (user exited via Urge Hold)
    func failSession() {
        guard var session = currentSession else { return }
        
        session.status = .failed
        session.endTime = Date()
        session.actualMinutes = (session.targetSeconds - remainingSeconds) / 60
        session.urgeHoldAttempts += 1
        currentSession = session
        
        stopTimer()
        isTimerActive = false
        
        // Save to history but don't update streak
        TimerPersistence.saveToHistory(session)
        TimerPersistence.clearActive()
        
        // Reset for next session
        currentSession = nil
    }
    
    /// Update session with reflection
    func saveReflection(_ reflection: String?) {
        guard var session = currentSession else { return }
        
        session.reflection = reflection
        currentSession = session
        
        // Update the session in history
        var history = TimerPersistence.loadHistory()
        if let index = history.firstIndex(where: { $0.id == session.id }) {
            history[index] = session
            // Re-save history with updated session
            if let data = try? JSONEncoder().encode(history) {
                UserDefaults.standard.set(data, forKey: "session_history")
            }
        }
    }
    
    /// Mark deliverable as checked
    func setDeliverableChecked(_ checked: Bool) {
        guard var session = currentSession else { return }
        session.deliverableChecked = checked
        currentSession = session
    }
    
    /// Reset after completion flow
    func resetAfterCompletion() {
        showCompletion = false
        currentSession = nil
    }
    
    // MARK: - Timer Engine
    
    private func startTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }
    
    private func stopTimer() {
        timerCancellable?.cancel()
        timerCancellable = nil
    }
    
    private func tick() {
        guard let session = currentSession, session.status == .running else { return }
        
        // Calculate remaining from start time (avoids drift)
        let elapsed = Int(Date().timeIntervalSince(session.startTime))
        let newRemaining = max(0, session.targetSeconds - elapsed)
        
        remainingSeconds = newRemaining
        
        // Check for completion
        if newRemaining == 0 {
            completeSession()
            return
        }
        
        // Persist every 60 seconds
        if let lastPersist = lastPersistTime,
           Date().timeIntervalSince(lastPersist) >= 60 {
            persistState()
        } else if lastPersistTime == nil {
            lastPersistTime = Date()
        }
    }
    
    // MARK: - State Persistence
    
    func persistState() {
        guard let session = currentSession else { return }
        TimerPersistence.saveActive(session)
        lastPersistTime = Date()
    }
    
    private func restoreActiveSession() {
        guard let session = TimerPersistence.restoreActive() else { return }
        
        currentSession = session
        
        // Recalculate remaining time
        let elapsed = Int(Date().timeIntervalSince(session.startTime))
        remainingSeconds = max(0, session.targetSeconds - elapsed)
        
        // Check if it should have completed while app was closed
        if remainingSeconds == 0 {
            completeSession()
        } else if session.status == .running {
            isTimerActive = true
            startTimer()
        } else if session.status == .paused {
            isTimerActive = true
        }
    }
    
    // MARK: - App Lifecycle
    
    func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        if newPhase == .background {
            persistState()
            backgroundTime = Date()
        }
        
        if newPhase == .active, let bgTime = backgroundTime {
            let elapsed = Date().timeIntervalSince(bgTime)
            backgroundTime = nil
            
            // Track app switch
            if var session = currentSession, session.status == .running {
                session.appSwitchCount += 1
                currentSession = session
            }
            
            // Show resume wall if away too long
            if elapsed >= resumeWallDelay && isTimerActive && currentSession?.status == .running {
                showResumeWall = true
                startResumeCountdown()
            }
        }
    }
    
    private func startResumeCountdown() {
        resumeCountdown = 3
        resumeWallTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.resumeCountdown > 0 {
                    self.resumeCountdown -= 1
                } else {
                    self.resumeWallTimer?.cancel()
                    self.showResumeWall = false
                }
            }
    }
    
    // MARK: - Urge Hold
    
    func incrementUrgeHoldAttempt() {
        guard var session = currentSession else { return }
        session.urgeHoldAttempts += 1
        currentSession = session
        persistState()
    }
    
    // MARK: - Computed Properties
    
    var formattedRemaining: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var progress: Double {
        guard let session = currentSession else { return 0 }
        let elapsed = session.targetSeconds - remainingSeconds
        return Double(elapsed) / Double(session.targetSeconds)
    }
}
