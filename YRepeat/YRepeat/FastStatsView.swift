//
//  FastStatsView.swift
//  YRepeat
//
//  Created for Fasting feature
//

import SwiftUI

struct FastStatsView: View {
    let fast: Fast
    @ObservedObject var manager: FastManager
    @State private var showingStartTimePicker = false
    @State private var selectedStartTime: Date

    init(fast: Fast, manager: FastManager) {
        self.fast = fast
        self.manager = manager
        _selectedStartTime = State(initialValue: fast.startTime)
    }

    var body: some View {
        HStack(spacing: 12) {
            statCard(
                title: "Goal",
                value: "\(fast.goalHours)h",
                icon: "target",
                color: .blue,
                isClickable: false,
                action: {}
            )

            statCard(
                title: "Started",
                value: formatStartTime(fast.startTime),
                icon: "play.circle.fill",
                color: .purple,
                isClickable: true,
                action: {
                    selectedStartTime = fast.startTime
                    showingStartTimePicker = true
                }
            )

            statCard(
                title: "Ends",
                value: formatEndTime(start: fast.startTime, hours: fast.goalHours),
                icon: "stop.circle.fill",
                color: .orange,
                isClickable: false,
                action: {}
            )
        }
        .sheet(isPresented: $showingStartTimePicker) {
            startTimePickerSheet
        }
    }
    
    private func statCard(title: String, value: String, icon: String, color: Color, isClickable: Bool, action: @escaping () -> Void) -> some View {
        Group {
            if isClickable {
                Button(action: action) {
                    statCardContent(title: title, value: value, icon: icon, color: color)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                statCardContent(title: title, value: value, icon: icon, color: color)
            }
        }
    }

    private func statCardContent(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }

            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }

    private var startTimePickerSheet: some View {
        NavigationView {
            ZStack {
                LiquidBackgroundView()

                VStack(spacing: 30) {
                    Text("Edit Start Time")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 20)

                    GlassmorphicCard {
                        VStack(spacing: 20) {
                            DatePicker("Start Time", selection: $selectedStartTime, displayedComponents: [.date, .hourAndMinute])
                                .datePickerStyle(.graphical)
                                .colorScheme(.dark)
                                .accentColor(.purple)
                        }
                        .padding()
                    }
                    .padding(.horizontal, 20)

                    Button {
                        manager.updateStartTime(fast, newStartTime: selectedStartTime)
                        showingStartTimePicker = false
                    } label: {
                        Text("Update Start Time")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 40)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingStartTimePicker = false
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
    
    private func formatStartTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatEndTime(start: Date, hours: Int) -> String {
        let end = start.addingTimeInterval(TimeInterval(hours * 3600))
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: end)
    }
}

