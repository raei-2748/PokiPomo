import SwiftUI

@main
struct PokiPomoApp: App {
    @StateObject private var focusTimerViewModel = FocusTimerViewModel()
    @StateObject private var onboardingViewModel = OnboardingViewModel()
    @State private var selectedTab: Tab = .welcome

    var body: some Scene {
        WindowGroup {
            MainTabView(selectedTab: $selectedTab)
                .environmentObject(focusTimerViewModel)
                .environmentObject(onboardingViewModel)
        }
    }
}

extension PokiPomoApp {
    enum Tab: Hashable {
        case welcome
        case onboarding
        case focus
        case progress
    }

    struct MainTabView: View {
        @Binding var selectedTab: Tab
        @State private var pendingTab: Tab?
        @EnvironmentObject private var focusTimerViewModel: FocusTimerViewModel
        @EnvironmentObject private var onboardingViewModel: OnboardingViewModel

        var body: some View {
            TabView(selection: selectionBinding) {
                NavigationStack {
                    WelcomeView {
                        selectedTab = .onboarding
                    }
                }
                .tabItem { Label("Welcome", systemImage: "sparkles") }
                .tag(Tab.welcome)

                NavigationStack {
                    OnboardingView()
                        .environmentObject(onboardingViewModel)
                }
                .tabItem { Label("Onboarding", systemImage: "list.number") }
                .tag(Tab.onboarding)

                NavigationStack {
                    FocusTimerView()
                        .environmentObject(focusTimerViewModel)
                        .environmentObject(onboardingViewModel)
                }
                .tabItem { Label("Focus", systemImage: "hourglass") }
                .tag(Tab.focus)

                NavigationStack {
                    ProgressTrackerView()
                        .environmentObject(focusTimerViewModel)
                        .environmentObject(onboardingViewModel)
                }
                .tabItem { Label("Progress", systemImage: "chart.bar") }
                .tag(Tab.progress)
            }
            .onChange(of: focusTimerViewModel.urgeSurfMode) { newValue in
                handleUrgeSurfModeChange(newValue)
            }
        }

        private var selectionBinding: Binding<Tab> {
            Binding(
                get: { selectedTab },
                set: { newValue in handleTabSelection(newValue) }
            )
        }

        private func handleTabSelection(_ newValue: Tab) {
            if selectedTab == .focus && newValue != .focus && focusTimerViewModel.state == .running {
                pendingTab = newValue
                focusTimerViewModel.beginUrgeSurfHold()
                return
            }
            selectedTab = newValue
        }

        private func handleUrgeSurfModeChange(_ mode: FocusTimerViewModel.UrgeSurfMode) {
            switch mode {
            case .allowExit:
                if let destination = pendingTab {
                    selectedTab = destination
                    pendingTab = nil
                    focusTimerViewModel.completeUrgeSurfCycle()
                } else {
                    focusTimerViewModel.completeUrgeSurfCycle()
                }
            case .inactive:
                pendingTab = nil
            case .holding:
                break
            }
        }
    }
}

