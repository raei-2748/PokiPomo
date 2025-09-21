import SwiftUI

struct ProgressTrackerView: View {
    @EnvironmentObject private var focusTimerViewModel: FocusTimerViewModel
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel

    private let calendar = Calendar.current

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                pokiStatusCard
                statsCard
                if !focusTimerViewModel.sessions.isEmpty {
                    reflectionsCard
                }
            }
            .padding()
        }
        .background(PokiTheme.background.ignoresSafeArea())
        .navigationTitle("Progress")
    }

    private var pokiStatusCard: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(LinearGradient(colors: [PokiTheme.pastelPink.opacity(0.7), PokiTheme.accent.opacity(0.5)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(height: 220)
            .overlay {
                VStack(spacing: 12) {
                    Text(pokiHeadline)
                        .font(.title2.bold())
                        .foregroundStyle(.white)
                    Text(pokiSubheadline)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Snapshot")
                .font(.headline)
            statRow(title: "Total Focus Time", value: focusTimerViewModel.formattedTotalFocusTime)
            statRow(title: "Sessions Today", value: "\(todaysSessions.count)")
            statRow(title: "Daily Goal", value: "\(onboardingViewModel.focusGoal)")
            statRow(title: "Current Streak", value: "\(focusTimerViewModel.streakCount) day\(focusTimerViewModel.streakCount == 1 ? "" : "s")")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 20))
    }

    private var reflectionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Session Reflections")
                .font(.headline)

            ForEach(focusTimerViewModel.sessions.sorted(by: { $0.endedAt > $1.endedAt }).prefix(5)) { session in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(session.endedAt, format: .dateTime.month().day().hour().minute())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(session.formattedDuration)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(session.reflection.isEmpty ? "No reflection added." : session.reflection)
                        .font(.body)
                        .foregroundStyle(.primary)
                }
                .padding()
                .background(PokiTheme.pastelGreen.opacity(0.3), in: RoundedRectangle(cornerRadius: 16))
            }

            if focusTimerViewModel.sessions.count > 5 {
                Text("Showing latest 5 entries.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 20))
    }

    private func statRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.headline)
        }
    }

    private var todaysSessions: [FocusSession] {
        let today = Date()
        return focusTimerViewModel.sessions.filter { calendar.isDate($0.endedAt, inSameDayAs: today) }
    }

    private var pokiHeadline: String {
        if focusTimerViewModel.streakCount >= onboardingViewModel.focusGoal {
            return "Poki is glowing!"
        }
        switch focusTimerViewModel.pokiMood {
        case .sleeping:
            return "Poki is cheering quietly"
        case .awake:
            return "Ready when you are"
        case .celebratory:
            return "Celebration time"
        }
    }

    private var pokiSubheadline: String {
        if focusTimerViewModel.streakCount >= onboardingViewModel.focusGoal {
            return "You've hit a new milestone streak. Keep that momentum going!"
        }
        switch focusTimerViewModel.pokiMood {
        case .sleeping:
            return "Stay in the flow. Breathe and let Poki keep watch."
        case .awake:
            return "Pick a session length and Poki will nap alongside you."
        case .celebratory:
            return "Log your wins and notice how you're growing."
        }
    }
}
