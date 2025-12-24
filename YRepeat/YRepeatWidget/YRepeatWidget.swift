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
            totalProgress: 0.4
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (DailyProgressEntry) -> Void) {
        let entry: DailyProgressEntry

        if let progressData = DailyRepeatSharedData.loadProgress() {
            entry = DailyProgressEntry(
                date: progressData.lastUpdated,
                totalItems: progressData.totalItems,
                completedItems: progressData.completedItems,
                totalProgress: progressData.totalProgress
            )
        } else {
            entry = DailyProgressEntry(
                date: Date(),
                totalItems: 0,
                completedItems: 0,
                totalProgress: 0
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
                totalProgress: progressData.totalProgress
            )
        } else {
            entry = DailyProgressEntry(
                date: currentDate,
                totalItems: 0,
                completedItems: 0,
                totalProgress: 0
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
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

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
            .padding()
        }
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    let entry: DailyProgressEntry

    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            HStack(spacing: 20) {
                // Progress Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 10)
                        .frame(width: 100, height: 100)

                    Circle()
                        .trim(from: 0, to: entry.totalProgress)
                        .stroke(
                            Color.white,
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .frame(width: 100, height: 100)
                        .rotationEffect(.degrees(-90))

                    Text("\(entry.progressPercentage)%")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                // Info Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Daily Repeat")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.green.opacity(0.9))
                            Text("\(entry.completedItems) completed")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "circle")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                            Text("\(entry.itemsRemaining) remaining")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                            Text("\(entry.totalItems) total items")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
    }
}

struct YRepeatWidget: Widget {
    let kind: String = "YRepeatWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            YRepeatWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Daily Progress")
        .description("Track your daily repeat goals at a glance")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

#Preview(as: .systemSmall) {
    YRepeatWidget()
} timeline: {
    DailyProgressEntry(date: .now, totalItems: 5, completedItems: 2, totalProgress: 0.4)
    DailyProgressEntry(date: .now, totalItems: 5, completedItems: 4, totalProgress: 0.8)
}

#Preview(as: .systemMedium) {
    YRepeatWidget()
} timeline: {
    DailyProgressEntry(date: .now, totalItems: 5, completedItems: 2, totalProgress: 0.4)
    DailyProgressEntry(date: .now, totalItems: 5, completedItems: 4, totalProgress: 0.8)
}
