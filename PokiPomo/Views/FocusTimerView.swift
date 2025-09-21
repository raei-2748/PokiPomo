import SwiftUI

struct FocusTimerView: View {
    @EnvironmentObject private var viewModel: FocusTimerViewModel
    @EnvironmentObject private var onboardingViewModel: OnboardingViewModel
    @State private var reflectionDraft: String = ""

    private var reflectionBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showReflectionPrompt },
            set: { newValue in
                if !newValue {
                    viewModel.discardReflection()
                }
            }
        )
    }

    var body: some View {
        ZStack {
            PokiTheme.background
                .ignoresSafeArea()

            VStack(spacing: 24) {
                header
                pokiAnimationPlaceholder
                timerPanel
                controlButtons
                goalRow
                Spacer(minLength: 24)
                if viewModel.state == .completed {
                    startAnotherSessionButton
                }
            }
            .padding()

            streakBadge
            toastView

            if viewModel.urgeSurfMode != .inactive {
                urgeSurfOverlay
            }
        }
        .sheet(isPresented: reflectionBinding, onDismiss: { reflectionDraft = "" }) {
            ReflectionPromptView(reflectionText: $reflectionDraft) { text in
                viewModel.saveReflection(text)
            }
        }
        .onChange(of: viewModel.showReflectionPrompt) { newValue in
            if newValue {
                reflectionDraft = ""
            }
        }
    }

    // MARK: - Subviews
    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("Focus Session")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                Text(viewModel.dailyGoalProgressDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }

    private var pokiAnimationPlaceholder: some View {
        RoundedRectangle(cornerRadius: 28)
            .fill(gradientForPokiState)
            .frame(height: 220)
            .overlay(alignment: .center) {
                VStack(spacing: 12) {
                    Text(pokiStateTitle)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)
                    Text(pokiStateSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .animation(.easeInOut(duration: 0.3), value: viewModel.pokiMood)
    }

    private var timerPanel: some View {
        VStack(spacing: 20) {
            Text(viewModel.formattedRemainingTime)
                .font(.system(size: 72, weight: .semibold, design: .rounded))
                .foregroundStyle(.primary)
                .monospacedDigit()
                .onTapGesture {
                    cycleDurationIfPossible()
                }

            durationSelector
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 28))
    }

    private var durationSelector: some View {
        HStack(spacing: 12) {
            ForEach(viewModel.durationOptions) { option in
                Button {
                    viewModel.selectDuration(option)
                } label: {
                    Text(option.label)
                        .font(.headline)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(DurationPillStyle(isSelected: option == viewModel.selectedDuration,
                                               isDisabled: viewModel.state == .running))
                .disabled(viewModel.state == .running)
            }
        }
    }

    private var controlButtons: some View {
        HStack(spacing: 16) {
            Button(primaryButtonTitle) {
                handlePrimaryAction()
            }
            .buttonStyle(.borderedProminent)
            .tint(PokiTheme.accent)
            .controlSize(.large)

            Button("Reset") {
                viewModel.stopAndReset()
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(viewModel.state == .running)
        }
    }

    private var goalRow: some View {
        let goal = max(onboardingViewModel.focusGoal, 1)
        let reachedGoal = viewModel.todaysCompletedSessions >= goal
        let goalText = "\(viewModel.todaysCompletedSessions) of \(goal) sessions completed today"
        return HStack(spacing: 8) {
            Circle()
                .fill((reachedGoal ? PokiTheme.pastelGreen : PokiTheme.accent).opacity(0.8))
                .frame(width: 12, height: 12)
            Text(goalText)
                .font(.subheadline)
                .foregroundStyle(reachedGoal ? Color.primary : .secondary)
            Spacer()
        }
        .padding(.top, 8)
    }

    private var streakBadge: some View {
        VStack {
            HStack {
                Spacer()
                if viewModel.streakCount > 0 {
                    Text("🔥 \(viewModel.streakCount)")
                        .font(.caption.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(PokiTheme.pastelOrange.opacity(0.8), in: Capsule())
                        .padding(.trailing, 20)
                        .padding(.top, 16)
                        .transition(.scale)
                }
            }
            Spacer()
        }
    }

    private var toastView: some View {
        Group {
            if let message = viewModel.toastMessage {
                VStack {
                    Spacer()
                    Text(message)
                        .font(.footnote)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.7), in: Capsule())
                        .foregroundStyle(.white)
                        .padding(.bottom, 32)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                .animation(.easeInOut, value: viewModel.toastMessage)
            }
        }
    }

    private var urgeSurfOverlay: some View {
        ZStack {
            Color.black.opacity(0.45)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                Text(urgeSurfHeadline)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                Text(urgeSurfSubtitle)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Button(viewModel.urgeSurfMode == .allowExit ? "Exit" : "Exit Anyway") {
                    viewModel.allowExitDuringUrgeSurf()
                }
                .buttonStyle(.bordered)
                .tint(.white)

                if case .holding = viewModel.urgeSurfMode {
                    Button("I'm staying") {
                        viewModel.completeUrgeSurfCycle()
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.white.opacity(0.9))
                }
            }
            .padding()
            .frame(maxWidth: 320)
            .background(PokiTheme.pastelPurple.opacity(0.95), in: RoundedRectangle(cornerRadius: 24))
            .foregroundStyle(.primary)
        }
        .transition(.opacity)
        .animation(.easeInOut, value: viewModel.urgeSurfMode)
    }

    private var startAnotherSessionButton: some View {
        Button {
            viewModel.startAnotherSession()
        } label: {
            Text("Start Another Session")
                .font(.headline)
                .padding()
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(PokiTheme.accent)
    }

    // MARK: - Helper values
    private var pokiStateTitle: String {
        switch viewModel.pokiMood {
        case .sleeping: return "Poki is snoozing"
        case .awake: return "Poki is ready"
        case .celebratory: return "Poki is proud!"
        }
    }

    private var pokiStateSubtitle: String {
        switch viewModel.pokiMood {
        case .sleeping: return "Quietly cheering you on while you focus."
        case .awake: return "Tap start when you’re ready to dive in."
        case .celebratory: return "That was great! Log your win below."
        }
    }

    private var gradientForPokiState: LinearGradient {
        switch viewModel.pokiMood {
        case .sleeping:
            return LinearGradient(colors: [PokiTheme.pastelPurple.opacity(0.6), PokiTheme.pastelBlue], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .awake:
            return LinearGradient(colors: [PokiTheme.pastelGreen.opacity(0.7), PokiTheme.pastelOrange.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .celebratory:
            return LinearGradient(colors: [PokiTheme.pastelPink.opacity(0.7), PokiTheme.accent.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var primaryButtonTitle: String {
        switch viewModel.state {
        case .idle: return "Start"
        case .running: return "Pause"
        case .paused: return "Resume"
        case .completed: return "Restart"
        }
    }

    private func cycleDurationIfPossible() {
        guard viewModel.state != .running,
              let currentIndex = viewModel.durationOptions.firstIndex(of: viewModel.selectedDuration) else { return }
        let nextIndex = (currentIndex + 1) % viewModel.durationOptions.count
        viewModel.selectDuration(viewModel.durationOptions[nextIndex])
    }

    private var urgeSurfHeadline: String {
        switch viewModel.urgeSurfMode {
        case .holding:
            return "Let’s ride this urge together for \(viewModel.urgeSurfCountdown) sec"
        case .allowExit:
            return "You made it!"
        case .inactive:
            return ""
        }
    }

    private var urgeSurfSubtitle: String {
        switch viewModel.urgeSurfMode {
        case .holding:
            return "Stay with Poki a little longer. Breathe, and notice the urge passing."
        case .allowExit:
            return "If you still want to leave, Poki will understand."
        case .inactive:
            return ""
        }
    }

    private func handlePrimaryAction() {
        switch viewModel.state {
        case .idle:
            viewModel.start()
        case .running:
            viewModel.pause()
        case .paused:
            viewModel.start()
        case .completed:
            viewModel.start()
        }
    }

}

// MARK: - Supporting Views & Styles

private struct DurationPillStyle: ButtonStyle {
    let isSelected: Bool
    let isDisabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isSelected ? .white : .primary)
            .background(backgroundColor(configuration: configuration))
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.primary.opacity(isSelected ? 0 : 0.1), lineWidth: 1)
            )
            .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    private func backgroundColor(configuration: Configuration) -> Color {
        if isSelected {
            return PokiTheme.accent
        }
        if isDisabled {
            return Color.white.opacity(0.4)
        }
        return Color.white.opacity(configuration.isPressed ? 0.7 : 0.9)
    }
}

private struct ReflectionPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var reflectionText: String
    var onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("What did you get done?")
                    .font(.headline)
                TextEditor(text: $reflectionText)
                    .scrollContentBackground(.hidden)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
                    .frame(minHeight: 160)
                Spacer()
            }
            .padding()
            .navigationTitle("Session Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(reflectionText)
                        dismiss()
                    }
                    .disabled(reflectionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private extension PokiTheme {
    static let pastelBlue = Color(red: 0.78, green: 0.84, blue: 0.96)
}
