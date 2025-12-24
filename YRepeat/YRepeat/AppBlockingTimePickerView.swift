//
//  AppBlockingTimePickerView.swift
//  YRepeat
//
//  Created for App Blocking feature
//

import SwiftUI

struct AppBlockingTimePickerView: View {
    @ObservedObject var manager: AppBlockingManager
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var themeManager: ThemeManager
    @State private var startTime: Date
    @State private var endTime: Date

    init(manager: AppBlockingManager) {
        self.manager = manager
        _startTime = State(initialValue: manager.startTime)
        _endTime = State(initialValue: manager.endTime)
    }

    var body: some View {
        ZStack {
            // Theme-aware background
            LiquidBackgroundView()

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(Color.white.opacity(0.2)))
                    }

                    Spacer()

                    Text("Set Time Range")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    // Placeholder for visual balance
                    Color.clear
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        // Instructions
                        VStack(spacing: 8) {
                            Text("Set your daily blocking window")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)

                            Text("Apps will be blocked every day during this time range")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 30)

                        // Time Pickers Card
                        GlassmorphicCard {
                            VStack(spacing: 24) {
                                // Start Time
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "moon.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.indigo)
                                        Text("Start Time")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                        Spacer()
                                    }

                                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                                        .datePickerStyle(.wheel)
                                        .labelsHidden()
                                        .colorScheme(.dark)
                                }

                                Divider()
                                    .background(Color.white.opacity(0.2))

                                // End Time
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        Image(systemName: "sun.max.fill")
                                            .font(.system(size: 18))
                                            .foregroundColor(.orange)
                                        Text("End Time")
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                        Spacer()
                                    }

                                    DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                                        .datePickerStyle(.wheel)
                                        .labelsHidden()
                                        .colorScheme(.dark)
                                }
                            }
                        }
                        .padding(.horizontal, 20)

                        // Preview
                        VStack(spacing: 12) {
                            Text("Preview")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))

                            Text(previewText)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.white.opacity(0.1))
                                .cornerRadius(16)
                        }
                        .padding(.horizontal, 30)

                        // Save Button
                        Button(action: {
                            manager.startTime = startTime
                            manager.endTime = endTime
                            manager.saveSettings()
                            if manager.isBlockingEnabled {
                                manager.applySchedule()
                            }
                            dismiss()
                        }) {
                            Text("Save Time Range")
                        }
                        .buttonStyle(PremiumButton(color: .blue, isProminent: true))
                        .padding(.horizontal, 40)
                        .padding(.bottom, 30)
                    }
                }
            }
        }
    }

    private var previewText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let start = formatter.string(from: startTime)
        let end = formatter.string(from: endTime)
        return "Blocking: \(start) - \(end)"
    }
}
