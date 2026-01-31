//
//  PokiPomo_AppApp.swift
//  PokiPomo App
//
//  Created by Ray Wang on 1/31/26.
//

import SwiftUI

@main
struct PokiPomo_AppApp: App {
    @StateObject private var timerViewModel = TimerViewModel()
    @Environment(\.scenePhase) var scenePhase
    
    var body: some Scene {
        WindowGroup {
            MainTabView(viewModel: timerViewModel)
                .onChange(of: scenePhase) { oldPhase, newPhase in
                    timerViewModel.handleScenePhaseChange(from: oldPhase, to: newPhase)
                }
                .fullScreenCover(isPresented: $timerViewModel.showCompletion) {
                    CompletionView(viewModel: timerViewModel)
                }
        }
    }
}

// MARK: - Main Tab View

struct MainTabView: View {
    @ObservedObject var viewModel: TimerViewModel
    
    var body: some View {
        TabView {
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("Focus", systemImage: "house.fill")
                }
            
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(.appCoral)
    }
}
