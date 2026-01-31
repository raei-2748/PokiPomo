import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var taskName: String = ""
    @State private var selectedDuration: Int = 25
    @State private var showTimer: Bool = false
    
    private let durations = [20, 35, 50]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Theater Background Section
                ZStack(alignment: .bottom) {
                    Image("homepage_theater")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                    
                    // Gradient Mask for seamless blend
                    LinearGradient(
                        colors: [.appCream, .appCream.opacity(0)],
                        startPoint: .bottom,
                        endPoint: .center
                    )
                    .frame(height: 150)
                    
                    // Overlay content on theater image
                    VStack(spacing: 32) {
                        Spacer()
                        
                        // Duration Selection
                        VStack(spacing: 20) {
                            Text("Choose your focus time")
                                .font(.system(.title3, design: .serif, weight: .bold)) // Serif font
                                .foregroundColor(.appCream)
                                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                            
                            HStack(spacing: 20) {
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
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Act I: The Task")
                                .font(.system(.subheadline, design: .serif, weight: .semibold))
                                .foregroundColor(.appCream)
                                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                            
                            TextField("", text: $taskName, prompt: Text("Enter scene title (e.g. Study)")
                                .foregroundColor(.appRed.opacity(0.6)))
                                .font(.system(.body, design: .serif))
                                .padding()
                                .background(Color.appCream)
                                .foregroundColor(.appRed) // Theater red text
                                .cornerRadius(8) // Sharper corners for ticket look
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.appGold, lineWidth: 2) // Gold border
                                )
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .padding(.horizontal, 32)
                        
                        // Start Button
                        Button {
                            viewModel.startSession(minutes: selectedDuration, taskName: taskName)
                            showTimer = true
                        } label: {
                            HStack {
                                Image(systemName: "curtains.closed")
                                    .font(.system(size: 20))
                                Text("Raise Curtain")
                                    .font(.system(.title3, design: .serif, weight: .bold))
                            }
                            .foregroundColor(.appCream)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                ZStack {
                                    Color.appRed
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.appGold, lineWidth: 3)
                                }
                            )
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.4), radius: 4, x: 0, y: 3)
                        }
                        .padding(.horizontal, 32)
                        .padding(.bottom, 60)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Cream Content Section
                VStack(spacing: 24) {
                    // Title for this section
                    Text("Now Showing")
                        .font(.system(.title2, design: .serif, weight: .bold))
                        .foregroundColor(.appRed)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                    
                    // Placeholder cards with "Playbill" style
                    PlaceholderCard(title: "Statistics", subtitle: "Review your performance")
                    PlaceholderCard(title: "Achievements", subtitle: "Your trophy room")
                    PlaceholderCard(title: "Settings", subtitle: "Backstage preferences")
                }
                .padding(.bottom, 40)
                .frame(maxWidth: .infinity)
                .background(Color.appCream)
            }
        }
        .ignoresSafeArea(edges: .top)
        .background(Color.appCream)
        .fullScreenCover(isPresented: $showTimer) {
            TimerView(viewModel: viewModel, isPresented: $showTimer)
        }
        .onAppear {
            selectedDuration = viewModel.lastSelectedDuration
            if viewModel.isTimerActive {
                showTimer = true
            }
        }
    }
}

// MARK: - Placeholder Card

struct PlaceholderCard: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(.headline, design: .serif, weight: .bold))
                    .foregroundColor(.appRed)
                Text(subtitle)
                    .font(.system(.subheadline, design: .serif))
                    .foregroundColor(.appBackground.opacity(0.7))
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.appGold)
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(4) // Paper-like sharp corners
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.black.opacity(0.1), lineWidth: 1)
        )
        // Add "ticket" notches effect using styling or keeping it simple as a playbill
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .padding(.horizontal, 24)
    }
}

// MARK: - Duration Button

struct DurationButton: View {
    let minutes: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text("\(minutes)")
                    .font(.system(.title2, design: .serif, weight: .bold))
                Text("MIN")
                    .font(.system(.caption2, design: .serif, weight: .bold))
                    .tracking(2) // Spaced out letters
            }
            .foregroundColor(isSelected ? .appRed : .appCream)
            .frame(width: 70, height: 70) // Slights smaller for cleaner look
            .background(isSelected ? Color.appGold : Color.black.opacity(0.4))
            .cornerRadius(35) // Circle for seal look
            .overlay(
                Circle()
                    .stroke(Color.appGold, lineWidth: isSelected ? 0 : 2)
            )
            .shadow(color: isSelected ? .appGold.opacity(0.5) : .clear, radius: 8, x: 0, y: 0)
        }
    }
}

#Preview {
    HomeView(viewModel: TimerViewModel())
}
