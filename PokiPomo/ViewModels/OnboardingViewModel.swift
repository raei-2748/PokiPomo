import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable, Identifiable {
        case name
        case screenTime
        case doomscrollReflection
        case goal

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .name:
                return "Let's get to know you"
            case .screenTime:
                return "How long is your daily screen time?"
            case .doomscrollReflection:
                return "When you doomscroll, how does it usually leave you feeling?"
            case .goal:
                return "Set your first focus goal"
            }
        }

        var subtitle: String {
            switch self {
            case .name:
                return "Tell Poki what to call you."
            case .screenTime:
                return "Give Poki a sense of your current scrolling habits."
            case .doomscrollReflection:
                return "Pick the vibe that describes most doomscroll sessions."
            case .goal:
                return "What's a win for today?"
            }
        }
    }

    enum DoomscrollFeeling: String, CaseIterable, Identifiable {
        case eyesSoreEnergyGone = "Eyes sore, energy gone. 💤"
        case mindBuzzingCantSettle = "Mind buzzing, can’t settle down. 😰"
        case regretWastingHours = "I regret wasting hours. 😔"
        case hardToConcentrate = "Hard to concentrate on anything real. 🤯"
        case nothingFeelsFun = "Nothing feels fun anymore. 😶"
        case notReallyMe = "That’s not really me. 🌱"

        var id: String { rawValue }
    }

    @Published var currentStep: Step = .name
    @Published var name: String = ""
    @Published var dailyScreenTime: Double = 2
    @Published var doomscrollFeeling: DoomscrollFeeling?
    @Published var focusGoal: Int = 3
    @Published private(set) var hasCompletedOnboarding = false

    private let minimumFocusGoal = 1
    private let maximumFocusGoal = 12

    var screenTimeOptions: [Double] {
        stride(from: 0.5, through: 8.0, by: 0.5).map { $0 }
    }

    var doomscrollFeelingOptions: [DoomscrollFeeling] {
        DoomscrollFeeling.allCases
    }

    var progress: Double {
        Double(currentStep.rawValue + 1) / Double(Step.allCases.count)
    }

    var canAdvance: Bool {
        switch currentStep {
        case .name:
            return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .screenTime:
            return true
        case .doomscrollReflection:
            return doomscrollFeeling != nil
        case .goal:
            return focusGoal >= minimumFocusGoal && focusGoal <= maximumFocusGoal
        }
    }

    func screenTimeLabel(for value: Double) -> String {
        if value >= 8 { return "8+ hrs" }

        if value < 1 {
            let minutes = Int(value * 60)
            return "\(minutes) min"
        }

        if value.rounded(.towardZero) == value {
            return "\(Int(value)) hrs"
        }

        return "\(value.formatted(.number.precision(.fractionLength(1)))) hrs"
    }

    func next() {
        guard canAdvance else { return }

        if let nextStep = Step(rawValue: currentStep.rawValue + 1) {
            currentStep = nextStep
        } else {
            hasCompletedOnboarding = true
        }
    }

    func back() {
        guard currentStep != .name else { return }
        if let previousStep = Step(rawValue: currentStep.rawValue - 1) {
            currentStep = previousStep
        }
    }

    func reset() {
        currentStep = .name
        name = ""
        dailyScreenTime = 2
        doomscrollFeeling = nil
        focusGoal = 3
        hasCompletedOnboarding = false
    }
}
