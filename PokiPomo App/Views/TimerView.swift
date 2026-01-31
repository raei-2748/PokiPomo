//
//  TimerView.swift
//  PokiPomo App
//
//  Created by Ray Wang on 1/31/26.
//

import SwiftUI

struct TimerView: View {
    @ObservedObject var viewModel: TimerViewModel
    @Binding var isPresented: Bool
    @Environment(\.scenePhase) var scenePhase
    
    @State private var showExitConfirmation: Bool = false
    @State private var urgeHoldProgress: CGFloat = 0
    @State private var isHoldingExit: Bool = false
    @State private var holdStartTime: Date?
    @State private var holdTimer: Timer?
    
    private let urgeHoldDuration: TimeInterval = 10.0
    
    var body: some View {
        ZStack {
            // Pure black background
            Color.black
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Task name (if provided)
                if let taskName = viewModel.currentSession?.taskName {
                    Text(taskName)
                        .font(.system(.title3, design: .rounded, weight: .medium))
                        .foregroundColor(.appCream.opacity(0.6))
                        .padding(.bottom, 8)
                }
                
                // Timer Display
                Text(viewModel.formattedRemaining)
                    .font(.system(size: 80, weight: .medium, design: .monospaced))
                    .foregroundColor(.appCream)
                    .monospacedDigit()
                
                Spacer()
                
                // Bottom Controls
                HStack(spacing: 40) {
                    // Pause/Resume Button
                    Button {
                        if viewModel.currentSession?.status == .running {
                            viewModel.pauseSession()
                        } else {
                            viewModel.resumeSession()
                        }
                    } label: {
                        Image(systemName: viewModel.currentSession?.status == .running ? "pause.fill" : "play.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.appCream.opacity(0.8))
                            .frame(width: 60, height: 60)
                            .background(Color.appCream.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    // Exit Button (Urge Hold)
                    UrgeHoldButton(
                        progress: urgeHoldProgress,
                        isHolding: isHoldingExit,
                        onHoldStart: startUrgeHold,
                        onHoldEnd: endUrgeHold,
                        onHoldComplete: completeUrgeHold
                    )
                }
                .padding(.bottom, 60)
            }
            
            // Resume Wall Overlay
            if viewModel.showResumeWall {
                ResumeWallOverlay(countdown: viewModel.resumeCountdown)
            }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            viewModel.handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
        .onChange(of: viewModel.showCompletion) { _, showCompletion in
            if showCompletion {
                isPresented = false
            }
        }
        .alert("Exit Focus?", isPresented: $showExitConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Exit", role: .destructive) {
                viewModel.failSession()
                isPresented = false
            }
        } message: {
            Text("This session will be marked as incomplete.")
        }
    }
    
    // MARK: - Urge Hold Logic
    
    private func startUrgeHold() {
        isHoldingExit = true
        holdStartTime = Date()
        urgeHoldProgress = 0
        
        holdTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            guard let startTime = holdStartTime else { return }
            let elapsed = Date().timeIntervalSince(startTime)
            let progress = min(elapsed / urgeHoldDuration, 1.0)
            
            Task { @MainActor in
                urgeHoldProgress = progress
                
                if progress >= 1.0 {
                    completeUrgeHold()
                }
            }
        }
    }
    
    private func endUrgeHold() {
        holdTimer?.invalidate()
        holdTimer = nil
        holdStartTime = nil
        isHoldingExit = false
        urgeHoldProgress = 0
        
        // Track the attempt if they held for at least 1 second
        if urgeHoldProgress > 0.1 {
            viewModel.incrementUrgeHoldAttempt()
        }
    }
    
    private func completeUrgeHold() {
        holdTimer?.invalidate()
        holdTimer = nil
        holdStartTime = nil
        isHoldingExit = false
        urgeHoldProgress = 0
        
        showExitConfirmation = true
    }
}

// MARK: - Urge Hold Button

struct UrgeHoldButton: View {
    let progress: CGFloat
    let isHolding: Bool
    let onHoldStart: () -> Void
    let onHoldEnd: () -> Void
    let onHoldComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.appCream.opacity(0.2), lineWidth: 3)
                .frame(width: 60, height: 60)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.appCoral, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(-90))
            
            // Icon
            Image(systemName: "xmark")
                .font(.system(size: 24))
                .foregroundColor(isHolding ? .appCoral : .appCream.opacity(0.8))
        }
        .background(Color.appCream.opacity(0.1))
        .clipShape(Circle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isHolding {
                        onHoldStart()
                    }
                }
                .onEnded { _ in
                    if progress < 1.0 {
                        onHoldEnd()
                    }
                }
        )
    }
}

// MARK: - Resume Wall Overlay

struct ResumeWallOverlay: View {
    let countdown: Int
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.appCoral)
                
                Text("You left the app")
                    .font(.system(.title2, design: .rounded, weight: .medium))
                    .foregroundColor(.appCream)
                
                if countdown > 0 {
                    Text("\(countdown)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundColor(.appCream)
                } else {
                    Text("Resuming focus...")
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.appCream.opacity(0.7))
                }
            }
        }
    }
}

#Preview {
    TimerView(viewModel: TimerViewModel(), isPresented: .constant(true))
}
