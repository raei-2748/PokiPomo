//
//  HomeView.swift
//  PokiPomo App
//
//  Created by Ray Wang on 1/31/26.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var taskName: String = ""
    @State private var selectedDuration: Int = 25
    @State private var showTimer: Bool = false
    
    private let durations = [20, 35, 50]
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Header with mascot
                VStack(spacing: 8) {
                    Image("cat_mascot")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    Text("PokiPomo")
                        .font(.system(.largeTitle, design: .rounded, weight: .medium))
                        .foregroundColor(.appCream)
                }
                
                Spacer()
                
                // Duration Selection
                VStack(spacing: 16) {
                    Text("Choose your focus time")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundColor(.appCream.opacity(0.7))
                    
                    HStack(spacing: 16) {
                        ForEach(durations, id: \.self) { duration in
                            DurationButton(
                                minutes: duration,
                                isSelected: selectedDuration == duration
                            ) {
                                selectedDuration = duration
                            }
                        }
                    }
                }
                
                // Task Name Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("What are you working on? (optional)")
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundColor(.appCream.opacity(0.7))
                    
                    TextField("", text: $taskName, prompt: Text("e.g. Math homework")
                        .foregroundColor(.appBackground.opacity(0.5)))
                    .font(.system(.body, design: .rounded))
                    .padding()
                    .background(Color.appCream)
                    .foregroundColor(.appBackground)
                    .cornerRadius(20)
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Start Button
                Button {
                    viewModel.startSession(minutes: selectedDuration, taskName: taskName)
                    showTimer = true
                } label: {
                    Text("Start Focus")
                        .font(.system(.title3, design: .rounded, weight: .medium))
                        .foregroundColor(.appBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.appCream)
                        .cornerRadius(20)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .fullScreenCover(isPresented: $showTimer) {
            TimerView(viewModel: viewModel, isPresented: $showTimer)
        }
        .onAppear {
            selectedDuration = viewModel.lastSelectedDuration
            
            // Check if there's an active session to restore
            if viewModel.isTimerActive {
                showTimer = true
            }
        }
    }
}

// MARK: - Duration Button

struct DurationButton: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text("\(minutes)")
                    .font(.system(.title, design: .rounded, weight: .medium))
                Text("min")
                    .font(.system(.caption, design: .rounded, weight: .medium))
            }
            .foregroundColor(isSelected ? .appBackground : .appCream)
            .frame(width: 80, height: 80)
            .background(isSelected ? Color.appCream : Color.clear)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.appCream, lineWidth: isSelected ? 0 : 2)
            )
        }
    }
}

#Preview {
    HomeView(viewModel: TimerViewModel())
}
