//
//  ReflectionView.swift
//  PokiPomo App
//
//  Created by Ray Wang on 1/31/26.
//

import SwiftUI

struct ReflectionView: View {
    @ObservedObject var viewModel: TimerViewModel
    @Environment(\.dismiss) var dismiss
    @State private var reflectionText: String = ""
    
    private let maxCharacters = 280
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Spacer()
                    Button {
                        skip()
                    } label: {
                        Text("Skip")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(.appCream.opacity(0.7))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                Spacer()
                
                // Prompt
                VStack(spacing: 8) {
                    Image(systemName: "text.bubble.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.appCoral)
                    
                    Text("How did it go?")
                        .font(.system(.title2, design: .rounded, weight: .medium))
                        .foregroundColor(.appCream)
                    
                    Text("Optional — take a moment to reflect")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.appCream.opacity(0.6))
                }
                
                // Text input
                VStack(alignment: .trailing, spacing: 8) {
                    TextEditor(text: $reflectionText)
                        .font(.system(.body, design: .rounded))
                        .foregroundColor(.appBackground)
                        .scrollContentBackground(.hidden)
                        .padding(16)
                        .frame(height: 150)
                        .background(Color.appCream)
                        .cornerRadius(20)
                        .onChange(of: reflectionText) { _, newValue in
                            if newValue.count > maxCharacters {
                                reflectionText = String(newValue.prefix(maxCharacters))
                            }
                        }
                    
                    Text("\(reflectionText.count)/\(maxCharacters)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.appCream.opacity(0.5))
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Save button
                Button {
                    save()
                } label: {
                    Text("Save")
                        .font(.system(.title3, design: .rounded, weight: .medium))
                        .foregroundColor(.appBackground)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.appCoral)
                        .cornerRadius(20)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
    
    private func skip() {
        viewModel.resetAfterCompletion()
        dismiss()
    }
    
    private func save() {
        let reflection = reflectionText.trimmingCharacters(in: .whitespacesAndNewlines)
        viewModel.saveReflection(reflection.isEmpty ? nil : reflection)
        viewModel.resetAfterCompletion()
        dismiss()
    }
}

#Preview {
    ReflectionView(viewModel: TimerViewModel())
}
