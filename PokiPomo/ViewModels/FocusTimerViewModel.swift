import Foundation
import Combine

@MainActor
/// Central coordinator for timer state transitions and session persistence feeding the Progress view.
final class FocusTimerViewModel: ObservableObject {
    enum TimerState {
        case idle
        case running
        case paused
        case completed
    }

    enum UrgeSurfMode: Equatable {
        case inactive
        case holding(secondsRemaining: Int)
        case allowExit
    }

    enum PokiMood {
        case sleeping
        case awake
        case celebratory
    }

    struct DurationOption: Identifiable, Equatable {
        let minutes: Int

        var id: Int { minutes }
        var seconds: TimeInterval { TimeInterval(minutes * 60) }
        var label: String { "\(minutes) min" }
    }

    // MARK: - Published state exposed to the UI
    @Published private(set) var remainingTime: TimeInterval
    @Published private(set) var state: TimerState = .idle
    @Published private(set) var totalFocusSeconds: TimeInterval = 0
    @Published private(set) var streakCount: Int = 0
    @Published private(set) var todaysCompletedSessions: Int = 0
    @Published private(set) var sessions: [FocusSession] = []
    @Published private(set) var urgeSurfMode: UrgeSurfMode = .inactive
    @Published private(set) var urgeSurfCountdown: Int = 10
    @Published private(set) var toastMessage: String?
    @Published private(set) var showReflectionPrompt = false
    @Published var selectedDuration: DurationOption

    // MARK: - Configuration
    let durationOptions: [DurationOption] = [DurationOption(minutes: 15),
                                             DurationOption(minutes: 25),
                                             DurationOption(minutes: 45)]

    // MARK: - Private state
    private var timer: AnyCancellable?
    private var urgeSurfTimer: AnyCancellable?
    private var sessionStartDate: Date?
    private var lastInteractionDate: Date?
    private var lastMicroRescueDate: Date?
    private var lastStreakAnchorDate: Date?
    private var pendingReflectionSessionID: FocusSession.ID?

    private let microRescueDelay: TimeInterval = 5 * 60

    init(defaultDuration: TimeInterval = 25 * 60) {
        let defaultMinutes = Int(defaultDuration) / 60
        let initialOption = DurationOption(minutes: defaultMinutes)
        self.selectedDuration = initialOption
        self.remainingTime = initialOption.seconds
    }

    // MARK: - Computed helpers
    var formattedRemainingTime: String {
        let totalSeconds = max(0, Int(remainingTime))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedTotalFocusTime: String {
        let minutes = Int(totalFocusSeconds) / 60
        return "\(minutes) min"
    }

    var pokiMood: PokiMood {
        switch state {
        case .running: return .sleeping
        case .completed: return .celebratory
        case .paused: return .awake
        case .idle: return .awake
        }
    }

    var dailyGoalProgressDescription: String {
        "\(todaysCompletedSessions) session\(todaysCompletedSessions == 1 ? "" : "s") today"
    }

    var hasPendingReflection: Bool {
        pendingReflectionSessionID != nil
    }

    // MARK: - Intent methods
    func start() {
        guard state != .running else { return }

        // When resuming from idle/completed we reset the countdown.
        if state == .idle || state == .completed {
            remainingTime = selectedDuration.seconds
        }

        state = .running
        sessionStartDate = Date()
        registerInteraction()
        microRescueReset()
        startTimer()
    }

    func pause() {
        guard state == .running else { return }
        timer?.cancel()
        timer = nil
        state = .paused
        registerInteraction()
    }

    func stopAndReset() {
        timer?.cancel()
        timer = nil
        state = .idle
        remainingTime = selectedDuration.seconds
        sessionStartDate = nil
        microRescueReset()
    }

    func resetToDefaults() {
        selectedDuration = durationOptions.first { $0.minutes == 25 } ?? durationOptions[0]
        stopAndReset()
    }

    func selectDuration(_ option: DurationOption) {
        selectedDuration = option
        if state == .idle || state == .completed {
            remainingTime = option.seconds
        }
        registerInteraction()
    }

    /// Applies the user's reflection to the most recent session so the Progress view and streak metrics stay in sync.
    func saveReflection(_ text: String) {
        guard let sessionID = pendingReflectionSessionID,
              let index = sessions.firstIndex(where: { $0.id == sessionID }) else {
            showReflectionPrompt = false
            pendingReflectionSessionID = nil
            return
        }

        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        var updatedSession = sessions[index]
        updatedSession.reflection = trimmed
        sessions[index] = updatedSession
        pendingReflectionSessionID = nil
        showReflectionPrompt = false
    }

    func discardReflection() {
        pendingReflectionSessionID = nil
        showReflectionPrompt = false
    }

    func startAnotherSession() {
        stopAndReset()
        start()
    }

    /// Starts the supportive 10 second hold when the user attempts to leave mid-session.
    func beginUrgeSurfHold() {
        guard state == .running, urgeSurfMode == .inactive else { return }
        urgeSurfCountdown = 10
        urgeSurfMode = .holding(secondsRemaining: urgeSurfCountdown)
        urgeSurfTimer?.cancel()
        urgeSurfTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.handleUrgeSurfTick()
            }
    }

    func allowExitDuringUrgeSurf() {
        urgeSurfTimer?.cancel()
        urgeSurfCountdown = 0
        urgeSurfMode = .allowExit
    }

    func completeUrgeSurfCycle() {
        urgeSurfTimer?.cancel()
        urgeSurfMode = .inactive
        urgeSurfCountdown = 10
    }

    // MARK: - Private helpers
    private func startTimer() {
        timer?.cancel()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        guard remainingTime > 0 else {
            completeSession()
            return
        }

        remainingTime = max(0, remainingTime - 1)
        evaluateMicroRescueCue()

        if remainingTime == 0 {
            completeSession()
        }
    }

    private func completeSession() {
        timer?.cancel()
        timer = nil
        state = .completed

        let endDate = Date()
        let startDate = sessionStartDate ?? endDate

        let session = FocusSession(duration: selectedDuration.seconds,
                                   startedAt: startDate,
                                   endedAt: endDate,
                                   outcome: .completed)
        sessions.append(session)
        pendingReflectionSessionID = session.id
        showReflectionPrompt = true

        totalFocusSeconds += selectedDuration.seconds
        updateDailyStats(with: endDate)
        updateStreak(using: endDate)

        remainingTime = 0
        sessionStartDate = nil
    }

    private func updateDailyStats(with date: Date) {
        let calendar = Calendar.current
        todaysCompletedSessions = sessions.filter { calendar.isDate($0.endedAt, inSameDayAs: date) }.count
    }

    private func updateStreak(using completionDate: Date) {
        let calendar = Calendar.current

        guard let lastDate = lastStreakAnchorDate else {
            streakCount = 1
            lastStreakAnchorDate = completionDate
            return
        }

        if calendar.isDate(completionDate, inSameDayAs: lastDate) {
            streakCount = max(streakCount, 1)
        } else if let nextDay = calendar.date(byAdding: .day, value: 1, to: lastDate),
                  calendar.isDate(completionDate, inSameDayAs: nextDay) {
            streakCount += 1
        } else {
            streakCount = 1
        }

        lastStreakAnchorDate = completionDate
    }

    private func registerInteraction() {
        lastInteractionDate = Date()
    }

    private func microRescueReset() {
        lastMicroRescueDate = nil
        lastInteractionDate = Date()
    }

    private func evaluateMicroRescueCue() {
        guard state == .running else { return }

        if let lastInteractionDate {
            let elapsedSinceInteraction = Date().timeIntervalSince(lastInteractionDate)
            let elapsedSinceCue = lastMicroRescueDate.map { Date().timeIntervalSince($0) } ?? .infinity

            if elapsedSinceInteraction >= microRescueDelay && elapsedSinceCue > microRescueDelay {
                showToast(message: "Deep breath. You've got this.")
                lastMicroRescueDate = Date()
            }
        }
    }

    private func showToast(message: String) {
        toastMessage = message
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            if Task.isCancelled { return }
            self?.toastMessage = nil
        }
    }

    private func handleUrgeSurfTick() {
        guard case .holding = urgeSurfMode else { return }
        if urgeSurfCountdown <= 1 {
            urgeSurfCountdown = 0
            urgeSurfMode = .allowExit
            urgeSurfTimer?.cancel()
        } else {
            urgeSurfCountdown -= 1
            urgeSurfMode = .holding(secondsRemaining: urgeSurfCountdown)
        }
    }
}
