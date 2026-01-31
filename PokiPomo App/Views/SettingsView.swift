//
//  SettingsView.swift
//  PokiPomo App
//
//  Created by Ray Wang on 1/31/26.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("resumeWallDelay") private var resumeWallDelay: Double = 3.0
    @AppStorage("breakBankingEnabled") private var breakBankingEnabled: Bool = false
    
    private let resumeWallOptions: [(String, Double)] = [
        ("Off", 0),
        ("3 seconds", 3),
        ("10 seconds", 10)
    ]
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    Text("Settings")
                        .font(.system(.largeTitle, design: .rounded, weight: .medium))
                        .foregroundColor(.appCream)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                    
                    // Focus Settings
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Focus Settings")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundColor(.appCream.opacity(0.7))
                        
                        // Resume Wall Delay
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Resume Wall Delay")
                                .font(.system(.body, design: .rounded, weight: .medium))
                                .foregroundColor(.appCream)
                            
                            Text("How long you can be away from the app before seeing the resume wall")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.appCream.opacity(0.5))
                            
                            HStack(spacing: 12) {
                                ForEach(resumeWallOptions, id: \.1) { option in
                                    Button {
                                        resumeWallDelay = option.1
                                    } label: {
                                        Text(option.0)
                                            .font(.system(.subheadline, design: .rounded))
                                            .foregroundColor(resumeWallDelay == option.1 ? .appBackground : .appCream)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(resumeWallDelay == option.1 ? Color.appCream : Color.appCream.opacity(0.1))
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        
                        Divider()
                            .background(Color.appCream.opacity(0.2))
                        
                        // Break Banking Toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Break Banking")
                                    .font(.system(.body, design: .rounded, weight: .medium))
                                    .foregroundColor(.appCream)
                                
                                Text("Save unused break time for later")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.appCream.opacity(0.5))
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $breakBankingEnabled)
                                .tint(.appCoral)
                        }
                    }
                    .padding(20)
                    .background(Color.appCream.opacity(0.05))
                    .cornerRadius(20)
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 40)
                    
                    // App Info
                    VStack(spacing: 8) {
                        Image(systemName: "cat.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.appCoral.opacity(0.5))
                        
                        Text("PokiPomo")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.appCream.opacity(0.5))
                        
                        Text("Version \(appVersion) (\(buildNumber))")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.appCream.opacity(0.3))
                    }
                    .padding(.bottom, 32)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
