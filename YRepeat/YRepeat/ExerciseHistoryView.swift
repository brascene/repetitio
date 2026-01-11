//
//  ExerciseHistoryView.swift
//  YRepeat
//
//  Created for Exercise history and insights
//

import SwiftUI
import Charts
internal import CoreData

struct ExerciseHistoryView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var isMenuShowing: Bool
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: NSEntityDescription.entity(forEntityName: "WeeklyExerciseRecordEntity", in: PersistenceController.shared.container.viewContext)!,
        sortDescriptors: [NSSortDescriptor(keyPath: \WeeklyExerciseRecordEntity.weekStartDate, ascending: false)],
        animation: .default)
    private var weeklyRecords: FetchedResults<NSManagedObject>

    @FetchRequest(
        entity: NSEntityDescription.entity(forEntityName: "BodyWeightEntity", in: PersistenceController.shared.container.viewContext)!,
        sortDescriptors: [NSSortDescriptor(keyPath: \BodyWeightEntity.date, ascending: true)],
        animation: .default)
    private var weightRecords: FetchedResults<NSManagedObject>

    @State private var animateContent = false
    @State private var selectedPeriod: TimePeriod = .lastMonth
    @State private var selectedExerciseType: ExerciseComparisonType = .both

    enum TimePeriod: String, CaseIterable {
        case lastWeek = "Last Week"
        case lastMonth = "4 Weeks"
        case last6Months = "6 Months"
        case lastYear = "Year"
    }

    enum ExerciseComparisonType: String, CaseIterable {
        case elliptical = "Elliptical"
        case boxing = "Boxing"
        case both = "Both"
    }

    var body: some View {
        ZStack {
            LiquidBackgroundView()
                .environmentObject(themeManager)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    headerView

                    // Stats Cards
                    statsCardsView

                    // Period Selector
                    periodSelector

                    // Weekly Chart
                    weeklyChartView

                    // Breakdown Chart
                    breakdownChartView

                    // Weight Tracking Chart
                    weightTrackingChartView

                    // Weekly List
                    weeklyListView
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateContent = true
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            MenuButton(isMenuShowing: $isMenuShowing)

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: themeManager.backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 44, height: 44)
                        .shadow(color: themeManager.backgroundColors.first?.opacity(0.3) ?? .clear, radius: 8, x: 0, y: 4)

                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text("Insights")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }

            Spacer()
        }
        .padding(.top, 20)
        .padding(.bottom, 10)
        .scaleEffect(animateContent ? 1 : 0.9)
        .opacity(animateContent ? 1 : 0)
    }

    // MARK: - Stats Cards

    private var statsCardsView: some View {
        HStack(spacing: 12) {
            statCard(
                title: "Total Workouts",
                value: "\(filteredRecords.count)",
                icon: "flame.fill",
                color: .orange
            )

            statCard(
                title: "Avg Per Week",
                value: "\(avgMinutesPerWeek)m",
                icon: "chart.bar.fill",
                color: .green
            )

            statCard(
                title: "Best Week",
                value: "\(bestWeekMinutes)m",
                icon: "trophy.fill",
                color: .yellow
            )
        }
        .scaleEffect(animateContent ? 1 : 0.9)
        .opacity(animateContent ? 1 : 0)
        .animation(.spring(response: 0.7, dampingFraction: 0.8).delay(0.1), value: animateContent)
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        GlassmorphicCard {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)

                Text(value)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }

    // MARK: - Period Selector

    private var periodSelector: some View {
        HStack(spacing: 8) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedPeriod = period
                    }
                }) {
                    Text(period.rawValue)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(selectedPeriod == period ? .white : .white.opacity(0.5))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            selectedPeriod == period ?
                            LinearGradient(colors: themeManager.backgroundColors, startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [Color.white.opacity(0.1)], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(20)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .scaleEffect(animateContent ? 1 : 0.9)
        .opacity(animateContent ? 1 : 0)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: animateContent)
    }

    // MARK: - Weekly Chart

    private var weeklyChartView: some View {
        GlassmorphicCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.green)

                    Text("Weekly Progress")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()
                }

                if filteredRecords.isEmpty {
                    emptyStateView
                } else {
                    Chart {
                        ForEach(Array(filteredRecords.reversed().enumerated()), id: \.offset) { index, record in
                            let elliptical = record.value(forKey: "ellipticalMinutes") as? Double ?? 0
                            let boxing = record.value(forKey: "boxingMinutes") as? Double ?? 0
                            let weightlifting = record.value(forKey: "weightliftingMinutes") as? Double ?? 0
                            let weekNum = record.value(forKey: "weekNumber") as? Int ?? 0

                            BarMark(
                                x: .value("Week", "W\(weekNum)"),
                                y: .value("Elliptical", elliptical)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                            BarMark(
                                x: .value("Week", "W\(weekNum)"),
                                y: .value("Boxing", boxing)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                            BarMark(
                                x: .value("Week", "W\(weekNum)"),
                                y: .value("Weightlifting", weightlifting)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(.white.opacity(0.1))
                            AxisValueLabel()
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel()
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }

                    // Legend
                    HStack(spacing: 16) {
                        legendItem(color: .blue, text: "Elliptical")
                        legendItem(color: .orange, text: "Boxing")
                        legendItem(color: .purple, text: "Weights")
                    }
                }
            }
            .padding(20)
        }
        .scaleEffect(animateContent ? 1 : 0.9)
        .opacity(animateContent ? 1 : 0)
        .animation(.spring(response: 0.9, dampingFraction: 0.8).delay(0.3), value: animateContent)
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(text)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: - Breakdown Chart

    private var breakdownChartView: some View {
        GlassmorphicCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "chart.pie.fill")
                        .foregroundColor(.purple)

                    Text("Workout Breakdown")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()
                }

                if !filteredRecords.isEmpty {
                    HStack(spacing: 24) {
                        // Elliptical
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 10)
                                    .frame(width: 100, height: 100)

                                Circle()
                                    .trim(from: 0, to: ellipticalPercentage)
                                    .stroke(
                                        LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing),
                                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                    )
                                    .frame(width: 100, height: 100)
                                    .rotationEffect(.degrees(-90))

                                VStack(spacing: 4) {
                                    Text("\(Int(ellipticalPercentage * 100))%")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)

                                    Text("\(totalEllipticalMinutes)m")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }

                            Text("Elliptical")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }

                        Spacer()

                        // Boxing
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.1), lineWidth: 10)
                                    .frame(width: 100, height: 100)

                                Circle()
                                    .trim(from: 0, to: boxingPercentage)
                                    .stroke(
                                        LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing),
                                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                    )
                                    .frame(width: 100, height: 100)
                                    .rotationEffect(.degrees(-90))

                                VStack(spacing: 4) {
                                    Text("\(Int(boxingPercentage * 100))%")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.white)

                                    Text("\(totalBoxingMinutes)m")
                                        .font(.system(size: 12))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }

                            Text("Boxing")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 20)

                    // Weightlifting (if there's any data)
                    if totalWeightliftingMinutes > 0 {
                        HStack(spacing: 24) {
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 10)
                                        .frame(width: 100, height: 100)

                                    Circle()
                                        .trim(from: 0, to: weightliftingPercentage)
                                        .stroke(
                                            LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing),
                                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                                        )
                                        .frame(width: 100, height: 100)
                                        .rotationEffect(.degrees(-90))

                                    VStack(spacing: 4) {
                                        Text("\(Int(weightliftingPercentage * 100))%")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(.white)

                                        Text("\(totalWeightliftingMinutes)m")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }

                                Text("Weights")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                }
            }
            .padding(20)
        }
        .scaleEffect(animateContent ? 1 : 0.9)
        .opacity(animateContent ? 1 : 0)
        .animation(.spring(response: 1.0, dampingFraction: 0.8).delay(0.4), value: animateContent)
    }

    // MARK: - Weight Tracking Chart

    private var weightTrackingChartView: some View {
        GlassmorphicCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "scalemass.fill")
                        .foregroundColor(.blue)

                    Text("Weight vs Exercise")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()
                }

                // Exercise type picker
                Picker("Exercise Type", selection: $selectedExerciseType) {
                    ForEach(ExerciseComparisonType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 8)

                if filteredWeightRecords.isEmpty {
                    Text("No weight data logged yet")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 40)
                } else {
                    Chart {
                        // Exercise bars (background layer)
                        ForEach(Array(filteredRecords.enumerated()), id: \.offset) { index, record in
                            let weekStart = record.value(forKey: "weekStartDate") as? Date ?? Date()
                            let ellipticalMins = record.value(forKey: "ellipticalMinutes") as? Double ?? 0
                            let boxingMins = record.value(forKey: "boxingMinutes") as? Double ?? 0

                            switch selectedExerciseType {
                            case .elliptical:
                                BarMark(
                                    x: .value("Week", weekStart, unit: .weekOfYear),
                                    y: .value("Elliptical", ellipticalMins)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.cyan.opacity(0.3), .cyan.opacity(0.1)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            case .boxing:
                                BarMark(
                                    x: .value("Week", weekStart, unit: .weekOfYear),
                                    y: .value("Boxing", boxingMins)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange.opacity(0.3), .orange.opacity(0.1)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )

                            case .both:
                                BarMark(
                                    x: .value("Week", weekStart, unit: .weekOfYear),
                                    y: .value("Total", ellipticalMins + boxingMins)
                                )
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green.opacity(0.3), .green.opacity(0.1)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            }
                        }

                        // Weight line (foreground layer)
                        ForEach(Array(filteredWeightRecords.enumerated()), id: \.offset) { index, weightRecord in
                            let date = weightRecord.value(forKey: "date") as? Date ?? Date()
                            let weight = weightRecord.value(forKey: "weight") as? Double ?? 0

                            LineMark(
                                x: .value("Date", date, unit: .day),
                                y: .value("Weight", weight)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 3))

                            PointMark(
                                x: .value("Date", date, unit: .day),
                                y: .value("Weight", weight)
                            )
                            .foregroundStyle(.blue)
                            .symbolSize(80)
                        }
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(.white.opacity(0.1))
                            AxisValueLabel()
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .chartXAxis {
                        AxisMarks { value in
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }

                    // Legend
                    HStack(spacing: 16) {
                        legendItem(color: .blue, text: "Weight (kg)")
                        legendItem(
                            color: selectedExerciseType == .elliptical ? .cyan :
                                   selectedExerciseType == .boxing ? .orange : .green,
                            text: "\(selectedExerciseType.rawValue) (min)"
                        )
                    }

                    // Weight trend insights
                    if let weightTrend = calculateWeightTrend() {
                        HStack(spacing: 12) {
                            Image(systemName: weightTrend.isIncreasing ? "arrow.up.right" : "arrow.down.right")
                                .foregroundColor(weightTrend.isIncreasing ? .orange : .green)
                                .font(.system(size: 20))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(weightTrend.message)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.white)

                                Text("Avg \(selectedExerciseTypeLabel): \(Int(avgSelectedExerciseMinutes)) min/week")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            Spacer()
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.05))
                        )
                    }
                }
            }
            .padding(20)
        }
        .scaleEffect(animateContent ? 1 : 0.9)
        .opacity(animateContent ? 1 : 0)
        .animation(.spring(response: 1.1, dampingFraction: 0.8).delay(0.45), value: animateContent)
    }

    // MARK: - Weekly List

    private var weeklyListView: some View {
        GlassmorphicCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "list.bullet")
                        .foregroundColor(.blue)

                    Text("Weekly History")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()
                }

                if filteredRecords.isEmpty {
                    emptyStateView
                } else {
                    ForEach(Array(filteredRecords.enumerated()), id: \.offset) { index, record in
                        weeklyRow(record: record)
                            .opacity(animateContent ? 1 : 0)
                            .offset(y: animateContent ? 0 : 20)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5 + Double(index) * 0.05), value: animateContent)
                    }
                }
            }
            .padding(20)
        }
    }

    private func weeklyRow(record: NSManagedObject) -> some View {
        let weekStart = record.value(forKey: "weekStartDate") as? Date ?? Date()
        let weekEnd = record.value(forKey: "weekEndDate") as? Date ?? Date()
        let totalMinutes = record.value(forKey: "totalMinutes") as? Double ?? 0
        let ellipticalMinutes = record.value(forKey: "ellipticalMinutes") as? Double ?? 0
        let boxingMinutes = record.value(forKey: "boxingMinutes") as? Double ?? 0
        let weightliftingMinutes = record.value(forKey: "weightliftingMinutes") as? Double ?? 0
        let goalMinutes = record.value(forKey: "goalMinutes") as? Double ?? 0
        let goalAchieved = record.value(forKey: "goalAchieved") as? Bool ?? false

        let df = DateFormatter()
        df.dateFormat = "MMM d"
        let dateRange = "\(df.string(from: weekStart)) - \(df.string(from: weekEnd))"

        return VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(dateRange)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        if ellipticalMinutes > 0 {
                            Text("🏃 \(Int(ellipticalMinutes))m")
                                .font(.system(size: 13))
                                .foregroundColor(.cyan)
                        }

                        if boxingMinutes > 0 {
                            Text("🥊 \(Int(boxingMinutes))m")
                                .font(.system(size: 13))
                                .foregroundColor(.orange)
                        }

                        if weightliftingMinutes > 0 {
                            Text("💪 \(Int(weightliftingMinutes))m")
                                .font(.system(size: 13))
                                .foregroundColor(.purple)
                        }
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(totalMinutes))m")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    if goalAchieved {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                            Text("Goal")
                                .font(.system(size: 12, weight: .medium))
                        }
                        .foregroundColor(.green)
                    } else {
                        Text("\(Int((totalMinutes / goalMinutes) * 100))%")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: goalAchieved ? [.green, .green.opacity(0.7)] : themeManager.backgroundColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(totalMinutes / goalMinutes, 1.0), height: 6)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))

            Text("No workout history yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.6))

            Text("Complete workouts to see insights")
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    // MARK: - Computed Properties

    private var filteredRecords: [NSManagedObject] {
        let records = Array(weeklyRecords)
        let now = Date()
        let calendar = Calendar.current

        switch selectedPeriod {
        case .lastWeek:
            // Get last complete week (not current week)
            let lastWeekDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
            let lastWeekComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: lastWeekDate)

            return records.filter { record in
                let weekNum = record.value(forKey: "weekNumber") as? Int ?? 0
                let year = record.value(forKey: "year") as? Int ?? 0
                return weekNum == lastWeekComponents.weekOfYear && year == lastWeekComponents.yearForWeekOfYear
            }
        case .lastMonth:
            let cutoffDate = Calendar.current.date(byAdding: .weekOfYear, value: -4, to: now) ?? now
            return records.filter { record in
                if let weekStart = record.value(forKey: "weekStartDate") as? Date {
                    return weekStart >= cutoffDate
                }
                return false
            }
        case .last6Months:
            let cutoffDate = Calendar.current.date(byAdding: .month, value: -6, to: now) ?? now
            return records.filter { record in
                if let weekStart = record.value(forKey: "weekStartDate") as? Date {
                    return weekStart >= cutoffDate
                }
                return false
            }
        case .lastYear:
            let cutoffDate = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
            return records.filter { record in
                if let weekStart = record.value(forKey: "weekStartDate") as? Date {
                    return weekStart >= cutoffDate
                }
                return false
            }
        }
    }

    private var avgMinutesPerWeek: Int {
        guard !filteredRecords.isEmpty else { return 0 }
        let total = filteredRecords.reduce(0.0) { sum, record in
            sum + (record.value(forKey: "totalMinutes") as? Double ?? 0)
        }
        return Int(total / Double(filteredRecords.count))
    }

    private var bestWeekMinutes: Int {
        guard !filteredRecords.isEmpty else { return 0 }
        let maxMinutes = filteredRecords.map { record in
            record.value(forKey: "totalMinutes") as? Double ?? 0
        }.max() ?? 0
        return Int(maxMinutes)
    }

    private var totalEllipticalMinutes: Int {
        let total = filteredRecords.reduce(0.0) { sum, record in
            sum + (record.value(forKey: "ellipticalMinutes") as? Double ?? 0)
        }
        return Int(total)
    }

    private var totalBoxingMinutes: Int {
        let total = filteredRecords.reduce(0.0) { sum, record in
            sum + (record.value(forKey: "boxingMinutes") as? Double ?? 0)
        }
        return Int(total)
    }

    private var totalWeightliftingMinutes: Int {
        let total = filteredRecords.reduce(0.0) { sum, record in
            sum + (record.value(forKey: "weightliftingMinutes") as? Double ?? 0)
        }
        return Int(total)
    }

    private var ellipticalPercentage: CGFloat {
        let total = Double(totalEllipticalMinutes + totalBoxingMinutes + totalWeightliftingMinutes)
        guard total > 0 else { return 0 }
        return CGFloat(Double(totalEllipticalMinutes) / total)
    }

    private var boxingPercentage: CGFloat {
        let total = Double(totalEllipticalMinutes + totalBoxingMinutes + totalWeightliftingMinutes)
        guard total > 0 else { return 0 }
        return CGFloat(Double(totalBoxingMinutes) / total)
    }

    private var weightliftingPercentage: CGFloat {
        let total = Double(totalEllipticalMinutes + totalBoxingMinutes + totalWeightliftingMinutes)
        guard total > 0 else { return 0 }
        return CGFloat(Double(totalWeightliftingMinutes) / total)
    }

    // Weight tracking computed properties
    private var filteredWeightRecords: [NSManagedObject] {
        let records = Array(weightRecords)
        let now = Date()
        let calendar = Calendar.current

        var cutoffDate: Date
        switch selectedPeriod {
        case .lastWeek:
            cutoffDate = calendar.date(byAdding: .weekOfYear, value: -1, to: now) ?? now
        case .lastMonth:
            cutoffDate = calendar.date(byAdding: .weekOfYear, value: -4, to: now) ?? now
        case .last6Months:
            cutoffDate = calendar.date(byAdding: .month, value: -6, to: now) ?? now
        case .lastYear:
            cutoffDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }

        return records.filter { record in
            if let date = record.value(forKey: "date") as? Date {
                return date >= cutoffDate
            }
            return false
        }
    }

    private var selectedExerciseTypeLabel: String {
        switch selectedExerciseType {
        case .elliptical:
            return "elliptical"
        case .boxing:
            return "boxing"
        case .both:
            return "total cardio"
        }
    }

    private var avgSelectedExerciseMinutes: Double {
        guard !filteredRecords.isEmpty else { return 0 }
        let total = filteredRecords.reduce(0.0) { sum, record in
            let elliptical = record.value(forKey: "ellipticalMinutes") as? Double ?? 0
            let boxing = record.value(forKey: "boxingMinutes") as? Double ?? 0

            switch selectedExerciseType {
            case .elliptical:
                return sum + elliptical
            case .boxing:
                return sum + boxing
            case .both:
                return sum + elliptical + boxing
            }
        }
        return total / Double(filteredRecords.count)
    }

    private func calculateWeightTrend() -> (isIncreasing: Bool, message: String)? {
        guard filteredWeightRecords.count >= 2 else { return nil }

        let firstWeight = filteredWeightRecords.first?.value(forKey: "weight") as? Double ?? 0
        let lastWeight = filteredWeightRecords.last?.value(forKey: "weight") as? Double ?? 0

        let change = lastWeight - firstWeight
        let isIncreasing = change > 0

        let message: String
        if abs(change) < 0.5 {
            message = "Weight stable (\(String(format: "%.1f", abs(change))) kg)"
        } else if isIncreasing {
            message = "Weight up \(String(format: "%.1f", change)) kg"
        } else {
            message = "Weight down \(String(format: "%.1f", abs(change))) kg"
        }

        return (isIncreasing: isIncreasing, message: message)
    }
}

#Preview {
    ExerciseHistoryView(isMenuShowing: .constant(false))
        .environmentObject(ThemeManager())
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
