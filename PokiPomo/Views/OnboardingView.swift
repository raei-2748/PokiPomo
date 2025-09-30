import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var viewModel: OnboardingViewModel
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        VStack(spacing: 24) {
            ProgressView(value: viewModel.progress)
                .tint(.blue)
                .padding(.top)

            VStack(spacing: 8) {
                Text(viewModel.currentStep.title)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text(viewModel.currentStep.subtitle)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            stepContent
                .transition(.opacity.combined(with: .move(edge: .trailing)))

            Spacer()

            actionButtons
        }
        .padding()
        .navigationTitle("Onboarding")
        .animation(.easeInOut, value: viewModel.currentStep)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch viewModel.currentStep {
        case .name:
            VStack(alignment: .leading, spacing: 12) {
                TextField("Your name", text: $viewModel.name)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .padding()
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .focused($isNameFieldFocused)

                Text("Poki will cheer you on, \(viewModel.name.isEmpty ? "friend" : viewModel.name)!")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .onAppear { isNameFieldFocused = true }

        case .screenTime:
            VStack(spacing: 20) {
                Text("Twist the dial to match the screen time that feels closest.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Picker("Daily screen time", selection: $viewModel.dailyScreenTime) {
                    ForEach(viewModel.screenTimeOptions, id: \.self) { value in
                        Text(viewModel.screenTimeLabel(for: value))
                            .tag(value)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxHeight: 180)

                Text("Estimated daily screen time: \(viewModel.screenTimeLabel(for: viewModel.dailyScreenTime))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

        case .doomscrollReflection:
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(viewModel.doomscrollFeelingOptions) { option in
                        Button {
                            viewModel.doomscrollFeeling = option
                        } label: {
                            HStack(alignment: .center, spacing: 12) {
                                Text(option.rawValue)
                                    .font(.body)
                                    .multilineTextAlignment(.leading)

                                Spacer()

                                if viewModel.doomscrollFeeling == option {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .buttonStyle(.plain)
                        .background {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(viewModel.doomscrollFeeling == option ? Color.green.opacity(0.15) : Color(.secondarySystemBackground))
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(viewModel.doomscrollFeeling == option ? Color.green : Color.clear, lineWidth: 1)
                        }
                    }
                }
                .padding(.vertical)
            }

        case .goal:
            VStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.purple.opacity(0.2))
                    .frame(height: 160)
                    .overlay {
                        Text("Goal Setting Placeholder")
                            .font(.headline)
                            .foregroundStyle(.purple)
                    }

                Stepper(value: $viewModel.focusGoal, in: 1...12) {
                    Text("Daily focus sessions: \(viewModel.focusGoal)")
                        .font(.headline)
                }

                Text("Consistency unlocks Poki's evolutions!")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        HStack {
            if viewModel.currentStep != .name {
                Button("Back") {
                    viewModel.back()
                }
                .buttonStyle(.bordered)
            }

            Spacer()

            Button(viewModel.currentStep == .goal ? "Finish" : "Next") {
                viewModel.next()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canAdvance)
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            OnboardingView()
                .environmentObject(OnboardingViewModel())
        }
    }
}
