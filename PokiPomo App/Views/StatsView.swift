//
//  StatsView.swift
//  PokiPomo App
//
//  Created by Ray Wang on 1/31/26.
//

import SwiftUI

struct StatsView: View {
    @State private var todayUFM: Int = 0
    @State private var currentStreak: Int = 0
    @State private var recentSessions: [TimerSession] = []
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text("Your Stats")
                        .font(.system(.largeTitle, design: .rounded, weight: .medium))
                        .foregroundColor(.appCream)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    
                    // Today's UFM
                    StatCard(
                        title: "Today's Focus",
                        value: "\(todayUFM)",
                        unit: "UFM",
                        subtitle: "Uninterrupted Focus Minutes",
                        color: .appCoral
                    )
                    
                    // Current Streak
                    StatCard(
                        title: "Current Streak",
                        value: "\(currentStreak)",
                        unit: currentStreak == 1 ? "day" : "days",
                        subtitle: currentStreak > 0 ? "Keep it going!" : "Start your streak today",
                        color: .appCream
                    )
                    
                    // Recent Sessions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Sessions")
                            .font(.system(.headline, design: .rounded, weight: .medium))
                            .foregroundColor(.appCream)
                        
                        if recentSessions.isEmpty {
                            Text("No sessions yet. Start your first focus session!")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.appCream.opacity(0.6))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.vertical, 32)
                        } else {
                            ForEach(recentSessions) { session in
                                SessionRow(session: session)
                            }
                        }
                    }
                    .padding(20)
                    .background(Color.appCream.opacity(0.05))
                    .cornerRadius(20)
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 32)
                }
            }
        }
        .onAppear {
            loadStats()
        }
    }
    
    private func loadStats() {
        todayUFM = TimerPersistence.getTodayUFM()
        currentStreak = TimerPersistence.getCurrentStreak()
        recentSessions = TimerPersistence.getRecentSessions(count: 10)
    }
}

// MARK: - Stat Card

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundColor(.appCream.opacity(0.7))
            
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text(value)
                    .font(.system(size: 64, weight: .medium, design: .rounded))
                    .foregroundColor(color)
                
                Text(unit)
                    .font(.system(.title3, design: .rounded))
                    .foregroundColor(color.opacity(0.7))
            }
            
            Text(subtitle)
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.appCream.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color.appCream.opacity(0.05))
        .cornerRadius(20)
        .padding(.horizontal, 24)
    }
}

// MARK: - Session Row

struct SessionRow: View {
    let session: TimerSession
    
    private var statusIcon: String {
        switch session.status {
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        default: return "circle"
        }
    }
    
    private var statusColor: Color {
        switch session.status {
        case .completed: return .green
        case .failed: return .appCoral
        default: return .appCream.opacity(0.5)
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: session.startTime)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon)
                .foregroundColor(statusColor)
                .font(.system(size: 20))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.taskName ?? "Focus Session")
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundColor(.appCream)
                
                Text(formattedDate)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.appCream.opacity(0.5))
            }
            
            Spacer()
            
            Text("\(session.actualMinutes) min")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(.appCream.opacity(0.7))
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    StatsView()
}
