import Foundation

@MainActor
final class OnboardingViewModel: ObservableObject {
    enum Step: Int, CaseIterable, Identifiable {
        case name
        case screenTime
        case goal

        var id: Int { rawValue }

        var title: String {
            switch self {
            case .name:
                return "Let's get to know you"
            case .screenTime:
                return "How long is your daily screen time?"
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
            case .goal:
                return "What's a win for today?"
            }
        }
    }

    @Published var currentStep: Step = .name
    @Published var name: String = ""
    @Published var dailyScreenTime: Double = 2
    @Published var focusGoal: Int = 3
    @Published private(set) var hasCompletedOnboarding = false

    private let minimumFocusGoal = 1
    private let maximumFocusGoal = 12

    var progress: Double {
        Double(currentStep.rawValue + 1) / Double(Step.allCases.count)
    }

    var canAdvance: Bool {
        switch currentStep {
        case .name:
            return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .screenTime:
            return true
        case .goal:
            return focusGoal >= minimumFocusGoal && focusGoal <= maximumFocusGoal
        }
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
        focusGoal = 3
        hasCompletedOnboarding = false
    }
}
