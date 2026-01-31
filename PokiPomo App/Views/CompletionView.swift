//
//  CompletionView.swift
//  PokiPomo App
//
//  Created by Ray Wang on 1/31/26.
//

import SwiftUI

struct CompletionView: View {
    @ObservedObject var viewModel: TimerViewModel
    @State private var deliverableChecked: Bool = false
    @State private var showReflection: Bool = false
    @State private var animateIn: Bool = false
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            // Subtle theater background for celebration
            Image("theater_scene")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .ignoresSafeArea()
                .opacity(0.12)
                .blur(radius: 2)

            VStack(spacing: 32) {
                Spacer()

                // Cat mascot with animation
                Image("cat_mascot")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .scaleEffect(animateIn ? 1.0 : 0.5)
                    .opacity(animateIn ? 1.0 : 0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: animateIn)
                
                // Completion message
                VStack(spacing: 12) {
                    Text("Great focus!")
                        .font(.system(.largeTitle, design: .rounded, weight: .medium))
                        .foregroundColor(.appCream)
                    
                    Text("\(viewModel.currentSession?.actualMinutes ?? 0) minutes completed")
                        .font(.system(.title3, design: .rounded))
                        .foregroundColor(.appCream.opacity(0.7))
                    
                    if let taskName = viewModel.currentSession?.taskName {
                        Text(taskName)
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.appCoral)
                            .padding(.top, 4)
                    }
                }
                
                Spacer()
                
                // Deliverable checkbox
                Button {
                    deliverableChecked.toggle()
                    viewModel.setDeliverableChecked(deliverableChecked)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: deliverableChecked ? "checkmark.square.fill" : "square")
                            .font(.system(size: 24))
                            .foregroundColor(deliverableChecked ? .appCoral : .appCream.opacity(0.5))
                        
                        Text("I finished my task")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.appCream)
                    }
                }
                .padding(.bottom, 16)
                
                // Continue button
                Button {
                    showReflection = true
                } label: {
                    Text("Continue")
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
        .sheet(isPresented: $showReflection) {
            ReflectionView(viewModel: viewModel)
        }
        .onAppear {
            animateIn = true
        }
    }
}

#Preview {
    CompletionView(viewModel: TimerViewModel())
}
