//
//  YRepeatWidget.swift
//  YRepeatWidget
//
//  Created by Dino Pelic on 24. 12. 2025..
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> DailyProgressEntry {
        DailyProgressEntry(
            date: Date(),
            totalItems: 5,
            completedItems: 2,
            totalProgress: 0.4,
            items: [
                WidgetDailyItem(name: "Workout", progress: 0.5, iconName: "figure.run", color: "blue"),
                WidgetDailyItem(name: "Read", progress: 0.75, iconName: "book.fill", color: "green")
            ]
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyProgressEntry) -> Void) {
        let entry: DailyProgressEntry

        if let progressData = DailyRepeatSharedData.loadProgress() {
            entry = DailyProgressEntry(
                date: progressData.lastUpdated,
                totalItems: progressData.totalItems,
                completedItems: progressData.completedItems,
                totalProgress: progressData.totalProgress,
                items: progressData.items
            )
        } else {
            entry = DailyProgressEntry(
                date: Date(),
                totalItems: 0,
                completedItems: 0,
                totalProgress: 0,
                items: []
            )
        }

        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DailyProgressEntry>) -> Void) {
        let currentDate = Date()
        let entry: DailyProgressEntry

        if let progressData = DailyRepeatSharedData.loadProgress() {
            entry = DailyProgressEntry(
                date: currentDate,
                totalItems: progressData.totalItems,
                completedItems: progressData.completedItems,
                totalProgress: progressData.totalProgress,
                items: progressData.items
            )
        } else {
            entry = DailyProgressEntry(
                date: currentDate,
                totalItems: 0,
                completedItems: 0,
                totalProgress: 0,
                items: []
            )
        }

        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct DailyProgressEntry: TimelineEntry {
    let date: Date
    let totalItems: Int
    let completedItems: Int
    let totalProgress: Double
    let items: [WidgetDailyItem]

    var itemsRemaining: Int {
        return totalItems - completedItems
    }

    var progressPercentage: Int {
        return Int(totalProgress * 100)
    }
}

struct YRepeatWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget

struct SmallWidgetView: View {
    let entry: DailyProgressEntry

    var body: some View {
        VStack(spacing: 12) {
            // Title
            Text("Daily Repeat")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.9))

            // Progress Ring
            ZStack {
                // Background Circle
                Circle()
                    .stroke(Color.white.opacity(0.3), lineWidth: 8)
                    .frame(width: 80, height: 80)

                // Progress Circle
                Circle()
                    .trim(from: 0, to: entry.totalProgress)
                    .stroke(
                        Color.white,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))

                // Percentage Text
                VStack(spacing: 2) {
                    Text("\(entry.progressPercentage)%")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }

            // Items Count
            if entry.totalItems > 0 {
                Text("\(entry.completedItems)/\(entry.totalItems) done")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
            } else {
                Text("No items")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: DailyProgressEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Daily Repeat")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("\(entry.completedItems)/\(entry.totalItems)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)

            // Tasks List
            if entry.items.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checklist")
                        .font(.system(size: 32))
                        .foregroundColor(.white.opacity(0.4))
                    Text("No tasks yet")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 6) {
                    ForEach(entry.items.prefix(4), id: \.name) { item in
                        TaskRowView(item: item)
                    }
                    if entry.items.count > 4 {
                        Text("+ \(entry.items.count - 4) more")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct TaskRowView: View {
    let item: WidgetDailyItem

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: item.iconName)
                .font(.system(size: 12))
                .foregroundColor(colorFromString(item.color))
                .frame(width: 20)

            Text(item.name)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer(minLength: 4)

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(height: 4)

                    Capsule()
                        .fill(colorFromString(item.color))
                        .frame(width: geometry.size.width * item.progress, height: 4)
                }
            }
            .frame(width: 50, height: 4)

            Text("\(item.progressPercentage)%")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 35, alignment: .trailing)
        }
    }

    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "mint": return .mint
        case "cyan": return .cyan
        default: return .blue
        }
    }
}

struct YRepeatWidget: Widget {
    let kind: String = "YRepeatWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            YRepeatWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    LinearGradient(
                        colors: [Color.blue.opacity(0.7), Color.purple.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
        }
        .configurationDisplayName("Daily Progress")
        .description("Track your daily repeat goals at a glance")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    YRepeatWidget()
} timeline: {
    DailyProgressEntry(
        date: .now,
        totalItems: 5,
        completedItems: 2,
        totalProgress: 0.4,
        items: [
            WidgetDailyItem(name: "Workout", progress: 0.5, iconName: "figure.run", color: "blue"),
            WidgetDailyItem(name: "Read", progress: 0.75, iconName: "book.fill", color: "green")
        ]
    )
    DailyProgressEntry(
        date: .now,
        totalItems: 5,
        completedItems: 4,
        totalProgress: 0.8,
        items: [
            WidgetDailyItem(name: "Workout", progress: 1.0, iconName: "figure.run", color: "blue"),
            WidgetDailyItem(name: "Read", progress: 0.9, iconName: "book.fill", color: "green")
        ]
    )
}

#Preview(as: .systemMedium) {
    YRepeatWidget()
} timeline: {
    DailyProgressEntry(
        date: .now,
        totalItems: 5,
        completedItems: 2,
        totalProgress: 0.4,
        items: [
            WidgetDailyItem(name: "Workout", progress: 0.5, iconName: "figure.run", color: "blue"),
            WidgetDailyItem(name: "Read", progress: 0.75, iconName: "book.fill", color: "green"),
            WidgetDailyItem(name: "Meditate", progress: 0.33, iconName: "moon.fill", color: "purple"),
            WidgetDailyItem(name: "Water", progress: 0.6, iconName: "drop.fill", color: "cyan")
        ]
    )
    DailyProgressEntry(
        date: .now,
        totalItems: 5,
        completedItems: 4,
        totalProgress: 0.8,
        items: [
            WidgetDailyItem(name: "Workout", progress: 1.0, iconName: "figure.run", color: "blue"),
            WidgetDailyItem(name: "Read", progress: 0.9, iconName: "book.fill", color: "green"),
            WidgetDailyItem(name: "Meditate", progress: 0.8, iconName: "moon.fill", color: "purple"),
            WidgetDailyItem(name: "Water", progress: 1.0, iconName: "drop.fill", color: "cyan")
        ]
    )
}
