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
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Cat mascot placeholder
                ZStack {
                    Circle()
                        .fill(Color.appCream.opacity(0.1))
                        .frame(width: 160, height: 160)
                    
                    Image(systemName: "cat.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.appCoral)
                }
                
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
    }
}

#Preview {
    CompletionView(viewModel: TimerViewModel())
}
