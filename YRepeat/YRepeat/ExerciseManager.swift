//
//  ExerciseManager.swift
//  YRepeat
//
//  Created for Health feature
//

import Foundation
import HealthKit
import Combine
import SwiftUI
internal import CoreData

class ExerciseManager: ObservableObject {
    @Published var ellipticalMinutesThisWeek: Double = 0
    @Published var boxingMinutesThisWeek: Double = 0
    @Published var totalCardioMinutesThisWeek: Double = 0
    @Published var statusMessage: String = "Initializing..."
    @AppStorage("weeklyEllipticalGoal") var weeklyGoalMinutes: Double = 150
    @AppStorage("lastTrackedWeek") private var lastTrackedWeek: Int = 0
    @AppStorage("lastTrackedYear") private var lastTrackedYear: Int = 0
    @Published var isAuthorized = false
    @Published var isNewWeek = false

    // Heart Rate Zones (minutes)
    @Published var zone1Minutes: Double = 0  // < 60% max HR
    @Published var zone2Minutes: Double = 0  // 60-70% max HR
    @Published var zone3Minutes: Double = 0  // 70-80% max HR
    @Published var zone4Minutes: Double = 0  // 80-90% max HR
    @Published var zone5Minutes: Double = 0  // 90-100% max HR

    // Heart Rate Stats
    @Published var averageHeartRate: Double = 0
    @Published var maxHeartRate: Double = 0

    // Body Weight
    @Published var currentWeight: Double = 0
    @Published var todayWeightLogged: Bool = false

    private let healthStore = HKHealthStore()
    private let workoutType = HKObjectType.workoutType()
    private let viewContext: NSManagedObjectContext

    // Motivational reminder manager
    let motivationalManager = MotivationalReminderManager()

    // Weightlifting manager
    let weightliftingManager: WeightliftingManager

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
        self.weightliftingManager = WeightliftingManager(context: context)

        // Delay all initialization to prevent crash on some devices
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else { return }

            // Setup notification observer for app becoming active using block-based API
            NotificationCenter.default.addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleAppBecameActive()
            }

            // Check if we need to request authorization, then fetch data
            self.checkAndRequestAuthorizationIfNeeded()

            // Backfill historical data if database is empty (delay to allow auth)
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.backfillHistoricalDataIfNeeded()
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func handleAppBecameActive() {
        // Auto-refresh when app becomes active if week has changed
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)

        if let currentWeek = components.weekOfYear,
           let currentYear = components.yearForWeekOfYear {
            if currentWeek != lastTrackedWeek || currentYear != lastTrackedYear {
                // Save previous week's data before resetting
                if lastTrackedWeek != 0 && lastTrackedYear != 0 {
                    saveWeeklyRecord(
                        weekNumber: lastTrackedWeek,
                        year: lastTrackedYear,
                        ellipticalMinutes: ellipticalMinutesThisWeek,
                        boxingMinutes: boxingMinutesThisWeek,
                        weightliftingMinutes: weightliftingManager.totalMinutesThisWeek
                    )
                }

                // New week detected - refresh data
                isNewWeek = true
                weightliftingManager.resetWeeklyData()
                refreshData()
            }
        }
    }

    // MARK: - Save Weekly Record

    private func saveWeeklyRecord(weekNumber: Int, year: Int, ellipticalMinutes: Double, boxingMinutes: Double, weightliftingMinutes: Double) {
        // Run on background queue to avoid blocking main thread
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }

            // Check if record already exists for this week
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "WeeklyExerciseRecordEntity")
            fetchRequest.predicate = NSPredicate(format: "weekNumber == %d AND year == %d", weekNumber, year)

            do {
                let existingRecords = try self.viewContext.fetch(fetchRequest)
                if !existingRecords.isEmpty {
                    // Already saved this week
                    print("ℹ️ Weekly record already exists for week \(weekNumber)/\(year)")
                    return
                }

                // Calculate week start and end dates
                let calendar = Calendar.current
                var components = DateComponents()
                components.weekOfYear = weekNumber
                components.yearForWeekOfYear = year

                guard let weekStart = calendar.date(from: components),
                      let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
                    print("⚠️ Could not calculate week dates for \(weekNumber)/\(year)")
                    return
                }

                // Create new record on main thread
                DispatchQueue.main.async {
                    do {
                        guard let entity = NSEntityDescription.entity(forEntityName: "WeeklyExerciseRecordEntity", in: self.viewContext) else {
                            print("❌ Could not find WeeklyExerciseRecordEntity")
                            return
                        }

                        let record = NSManagedObject(entity: entity, insertInto: self.viewContext)

                        let totalMinutes = ellipticalMinutes + boxingMinutes + weightliftingMinutes
                        let goalAchieved = totalMinutes >= self.weeklyGoalMinutes

                        record.setValue(UUID(), forKey: "id")
                        record.setValue(weekStart, forKey: "weekStartDate")
                        record.setValue(weekEnd, forKey: "weekEndDate")
                        record.setValue(weekNumber, forKey: "weekNumber")
                        record.setValue(year, forKey: "year")
                        record.setValue(totalMinutes, forKey: "totalMinutes")
                        record.setValue(ellipticalMinutes, forKey: "ellipticalMinutes")
                        record.setValue(boxingMinutes, forKey: "boxingMinutes")
                        record.setValue(weightliftingMinutes, forKey: "weightliftingMinutes")
                        record.setValue(self.weeklyGoalMinutes, forKey: "goalMinutes")
                        record.setValue(0, forKey: "workoutCount")
                        record.setValue(goalAchieved, forKey: "goalAchieved")
                        record.setValue(Date(), forKey: "createdAt")

                        try self.viewContext.save()
                        print("✅ Saved weekly record: Week \(weekNumber)/\(year) - Total: \(totalMinutes) min (Elliptical: \(Int(ellipticalMinutes))m, Boxing: \(Int(boxingMinutes))m, Weightlifting: \(Int(weightliftingMinutes))m)")
                    } catch {
                        print("❌ Error saving weekly record on main thread: \(error.localizedDescription)")
                    }
                }
            } catch {
                print("❌ Error fetching existing weekly records: \(error.localizedDescription)")
            }
        }
    }

    private func checkAndRequestAuthorizationIfNeeded() {
        guard HKHealthStore.isHealthDataAvailable() else {
            statusMessage = "HealthKit not available"
            return
        }

        // Use iOS 15+ API to check if we should request authorization
        if #available(iOS 15.0, *) {
            let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
            let bodyWeightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
            let typesToCheck: Set<HKObjectType> = [workoutType, heartRateType, bodyWeightType]

            healthStore.getRequestStatusForAuthorization(toShare: [bodyWeightType], read: typesToCheck) { [weak self] status, error in
                DispatchQueue.main.async {
                    guard let self = self else { return }

                    switch status {
                    case .shouldRequest:
                        // We haven't requested yet - show the permission dialog
                        self.requestHealthKitAuthorization()
                    case .unnecessary:
                        // Already requested before - just fetch data
                        self.isAuthorized = true
                        self.fetchEllipticalMinutes()
                    case .unknown:
                        // Fallback - try to fetch anyway
                        self.isAuthorized = true
                        self.fetchEllipticalMinutes()
                    @unknown default:
                        self.isAuthorized = true
                        self.fetchEllipticalMinutes()
                    }
                }
            }
        } else {
            // For older iOS versions, request authorization (it will no-op if already requested)
            requestHealthKitAuthorization()
        }
    }

    private func requestHealthKitAuthorization() {
        statusMessage = "Requesting permission..."

        // Request READ access for workouts and heart rate
        // Request WRITE access for body weight (so we can log it)
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let bodyWeightType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let typesToRead: Set<HKObjectType> = [workoutType, heartRateType, bodyWeightType]
        let typesToWrite: Set<HKSampleType> = [bodyWeightType]

        // This will only show the UI ONCE per app lifetime
        // Subsequent calls do nothing (no-op) unless user uninstalls
        healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead) { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.statusMessage = "Error: \(error.localizedDescription)"
                    return
                }

                // Don't try to check if permission was granted - Apple doesn't tell us for Read permissions
                // Just try to fetch data. If denied, we'll get empty results.
                self.isAuthorized = true
                self.fetchEllipticalMinutes()
            }
        }
    }

    func forceAuthorization() {
        // Manually trigger authorization request
        requestHealthKitAuthorization()
    }

    func fetchEllipticalMinutes() {
        statusMessage = "Syncing..."

        guard HKHealthStore.isHealthDataAvailable() else {
            statusMessage = "HealthKit unavailable on this device."
            return
        }

        let workoutType = HKObjectType.workoutType()
        let now = Date()
        let calendar = Calendar.current

        // Calculate start of current calendar week
        // Reset time to 00:00:00 to ensure we catch everything from the start of the first day
        let startOfWeekComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        guard let startOfWeek = calendar.date(from: startOfWeekComponents) else { return }

        // Update tracked week/year
        if let currentWeek = startOfWeekComponents.weekOfYear,
           let currentYear = startOfWeekComponents.yearForWeekOfYear {

            // Check if this is a new week
            if lastTrackedWeek == 0 && lastTrackedYear == 0 {
                // First time running
                lastTrackedWeek = currentWeek
                lastTrackedYear = currentYear
            } else if currentWeek != lastTrackedWeek || currentYear != lastTrackedYear {
                // New week started!
                isNewWeek = true
                lastTrackedWeek = currentWeek
                lastTrackedYear = currentYear
            } else {
                isNewWeek = false
            }
        }

        // Predicate for last 30 days to ensure we find *something* if permissions are on
        let searchStart = now.addingTimeInterval(-30*24*3600)
        let predicate = HKQuery.predicateForSamples(withStart: searchStart, end: nil, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { [weak self] (query, samples, error) in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    self.statusMessage = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let workouts = samples as? [HKWorkout] else {
                    self.statusMessage = "No workouts found. Check: Settings > Health > Data Access & Devices > YRepeat > Turn On All"
                    self.ellipticalMinutesThisWeek = 0
                    return
                }
                
                // Debug info: Count types and gather details
                var typeCounts: [String: Int] = [:]
                var allEllipticalLike: [(type: String, date: Date, mins: Int)] = []

                for w in workouts {
                    let key = self.getWorkoutTypeName(w.workoutActivityType)
                    typeCounts[key, default: 0] += 1

                    // Track all cardio workouts regardless of date
                    let isElliptical = w.workoutActivityType == .elliptical
                    let isBoxing = w.workoutActivityType == .boxing
                    let isKickboxing = w.workoutActivityType == .kickboxing

                    if isElliptical || isBoxing || isKickboxing {
                        let sourceName = w.sourceRevision.source.name
                        if !sourceName.contains("YRepeat") {
                            allEllipticalLike.append((
                                type: key,
                                date: w.startDate,
                                mins: Int(w.duration / 60)
                            ))
                        }
                    }
                }

                // Filter for cardio workouts (Elliptical, Boxing, Kickboxing only)
                let cardioWorkoutsThisWeek = workouts.filter { workout in
                    let isElliptical = workout.workoutActivityType == .elliptical
                    let isBoxing = workout.workoutActivityType == .boxing
                    let isKickboxing = workout.workoutActivityType == .kickboxing

                    // Filter out workouts from "YRepeat" to prevent double counting our own fasts
                    let sourceName = workout.sourceRevision.source.name
                    if sourceName.contains("YRepeat") {
                        return false
                    }

                    return (isElliptical || isBoxing || isKickboxing) && workout.startDate >= startOfWeek
                }

                // Separate elliptical and boxing minutes
                var ellipticalMinutes: Double = 0
                var boxingMinutes: Double = 0

                for workout in cardioWorkoutsThisWeek {
                    let minutes = workout.duration / 60.0

                    if workout.workoutActivityType == .elliptical {
                        ellipticalMinutes += minutes
                    } else if workout.workoutActivityType == .boxing || workout.workoutActivityType == .kickboxing {
                        boxingMinutes += minutes
                    }
                }

                self.ellipticalMinutesThisWeek = ellipticalMinutes
                self.boxingMinutesThisWeek = boxingMinutes
                self.totalCardioMinutesThisWeek = ellipticalMinutes + boxingMinutes

                // Check if user needs motivational reminder
                self.motivationalManager.checkIfNeedsMotivation(
                    ellipticalMinutes: self.totalCardioMinutesThisWeek,
                    goalMinutes: self.weeklyGoalMinutes,
                    startOfWeek: startOfWeek
                )

                // Update last workout date if we have any workouts
                if let latestWorkout = cardioWorkoutsThisWeek.max(by: { $0.startDate < $1.startDate }) {
                    self.motivationalManager.updateLastWorkoutDate(latestWorkout.startDate)
                }

                // Format week date range for display
                let df = DateFormatter()
                df.dateFormat = "MMM d"
                let weekStartStr = df.string(from: startOfWeek)

                // Calculate end of week (6 days after start)
                let weekEnd = calendar.date(byAdding: .day, value: 6, to: startOfWeek) ?? startOfWeek
                let weekEndStr = df.string(from: weekEnd)

                let weekRange = "\(weekStartStr) - \(weekEndStr)"
                let newWeekBadge = self.isNewWeek ? " 🆕" : ""

                if workouts.isEmpty {
                    self.statusMessage = "Calendar Week \(weekRange)\(newWeekBadge)\nNo workouts found in last 30 days. Check Permissions > Read > Workouts."
                } else if cardioWorkoutsThisWeek.isEmpty {
                    // Show what we found but why it didn't match
                    let topTypes = typeCounts.sorted { $0.value > $1.value }.prefix(2).map { "\($0.key)(\($0.value))" }.joined(separator: ", ")

                    // Show all tracked cardio workouts with dates to help diagnose
                    if !allEllipticalLike.isEmpty {
                        let details = allEllipticalLike.sorted { $0.date > $1.date }.prefix(2).map { w in
                            "\(w.type) \(w.mins)m on \(df.string(from: w.date))"
                        }.joined(separator: ", ")
                        let totalMins = allEllipticalLike.reduce(0) { $0 + $1.mins }
                        self.statusMessage = "Week \(weekRange)\(newWeekBadge)\nFound \(totalMins)m total: \(details). No matches this week."
                    } else {
                        self.statusMessage = "Week \(weekRange)\(newWeekBadge)\nFound: \(topTypes). No Elliptical/Boxing workouts."
                    }
                } else {
                    // Show breakdown of what makes up the minutes
                    let count = cardioWorkoutsThisWeek.count

                    // Create breakdown string with type breakdown
                    var breakdownParts: [String] = []
                    if ellipticalMinutes > 0 {
                        breakdownParts.append("Elliptical: \(Int(ellipticalMinutes))m")
                    }
                    if boxingMinutes > 0 {
                        breakdownParts.append("Boxing: \(Int(boxingMinutes))m")
                    }
                    let breakdownStr = breakdownParts.joined(separator: ", ")

                    self.statusMessage = "Week \(weekRange)\(newWeekBadge)\n\(count) workouts: \(breakdownStr)"
                }

                // Fetch heart rate data for these workouts
                self.fetchHeartRateData(for: cardioWorkoutsThisWeek)
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Heart Rate Data

    private func fetchHeartRateData(for workouts: [HKWorkout]) {
        guard !workouts.isEmpty else {
            DispatchQueue.main.async {
                self.zone1Minutes = 0
                self.zone2Minutes = 0
                self.zone3Minutes = 0
                self.zone4Minutes = 0
                self.zone5Minutes = 0
                self.averageHeartRate = 0
                self.maxHeartRate = 0
            }
            return
        }

        print("🔍 Fetching heart rate data for \(workouts.count) workouts...")

        // Estimate max heart rate (220 - age, or use a default of 180)
        let estimatedMaxHR: Double = 180

        // Use a serial queue for thread-safe accumulation
        let syncQueue = DispatchQueue(label: "com.yrepeat.heartrate.sync")
        var totalHRSamples: Double = 0
        var totalSampleCount: Int = 0
        var maxHRRecorded: Double = 0
        var zone1Seconds: Double = 0
        var zone2Seconds: Double = 0
        var zone3Seconds: Double = 0
        var zone4Seconds: Double = 0
        var zone5Seconds: Double = 0

        let group = DispatchGroup()

        for workout in workouts {
            group.enter()

            // Query for heart rate samples during this workout
            let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
            let predicate = HKQuery.predicateForSamples(
                withStart: workout.startDate,
                end: workout.endDate,
                options: .strictStartDate
            )

            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, error in
                defer { group.leave() }

                if let error = error {
                    print("❌ Error fetching heart rate for workout: \(error.localizedDescription)")
                    return
                }

                guard let heartRateSamples = samples as? [HKQuantitySample], !heartRateSamples.isEmpty else {
                    print("⚠️ No heart rate samples found for workout at \(workout.startDate)")
                    return
                }

                print("✅ Found \(heartRateSamples.count) HR samples for workout")

                // Thread-safe accumulation
                syncQueue.sync {
                    for sample in heartRateSamples {
                        let bpm = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                        totalHRSamples += bpm
                        totalSampleCount += 1

                        if bpm > maxHRRecorded {
                            maxHRRecorded = bpm
                        }

                        // Calculate zones based on percentage of max HR
                        let percentage = (bpm / estimatedMaxHR) * 100

                        // Each sample represents some duration (estimate 5 seconds between samples)
                        let sampleDuration: Double = 5

                        if percentage < 60 {
                            zone1Seconds += sampleDuration
                        } else if percentage < 70 {
                            zone2Seconds += sampleDuration
                        } else if percentage < 80 {
                            zone3Seconds += sampleDuration
                        } else if percentage < 90 {
                            zone4Seconds += sampleDuration
                        } else {
                            zone5Seconds += sampleDuration
                        }
                    }
                }
            }

            self.healthStore.execute(query)
        }

        group.notify(queue: .main) {
            self.averageHeartRate = totalSampleCount > 0 ? totalHRSamples / Double(totalSampleCount) : 0
            self.maxHeartRate = maxHRRecorded

            self.zone1Minutes = zone1Seconds / 60.0
            self.zone2Minutes = zone2Seconds / 60.0
            self.zone3Minutes = zone3Seconds / 60.0
            self.zone4Minutes = zone4Seconds / 60.0
            self.zone5Minutes = zone5Seconds / 60.0

            print("💓 Heart Rate Summary:")
            print("   Avg HR: \(Int(self.averageHeartRate)) bpm, Max HR: \(Int(self.maxHeartRate)) bpm")
            print("   Zone 1: \(Int(self.zone1Minutes))m, Zone 2: \(Int(self.zone2Minutes))m")
            print("   Zone 3: \(Int(self.zone3Minutes))m, Zone 4: \(Int(self.zone4Minutes))m")
            print("   Zone 5: \(Int(self.zone5Minutes))m")
        }
    }
    
    private func getWorkoutTypeName(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .elliptical: return "Elliptical"
        case .boxing: return "Boxing"
        case .kickboxing: return "Kickboxing"
        case .running: return "Run"
        case .walking: return "Walk"
        case .cycling: return "Cycle"
        case .functionalStrengthTraining: return "Strength"
        case .traditionalStrengthTraining: return "Strength"
        case .crossTraining: return "CrossTrain"
        case .mixedCardio: return "MixedCardio"
        default: return "Other(\(type.rawValue))"
        }
    }
    
    // Call this when view appears to refresh data
    func refreshData() {
        // Never request authorization here - just fetch data
        // Authorization is only requested once in init() using getRequestStatusForAuthorization
        fetchEllipticalMinutes()
    }

    // MARK: - Backfill Historical Data

    func backfillHistoricalDataIfNeeded() {
        // Check if we already have any records
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "WeeklyExerciseRecordEntity")
        fetchRequest.fetchLimit = 1

        do {
            let count = try viewContext.count(for: fetchRequest)
            if count > 0 {
                print("ℹ️ Weekly records already exist, skipping backfill")
                return
            }

            print("🔄 Starting backfill of last 3 weeks...")
            backfillLastThreeWeeks()
        } catch {
            print("❌ Error checking for existing records: \(error.localizedDescription)")
        }
    }

    private func backfillLastThreeWeeks() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("⚠️ HealthKit not available for backfill")
            return
        }

        let calendar = Calendar.current
        let now = Date()

        // Calculate the last 3 complete weeks
        for weekOffset in 1...3 {
            // Go back weekOffset weeks from current week
            let targetDate = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) ?? now

            let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: targetDate)
            guard let weekNumber = components.weekOfYear,
                  let year = components.yearForWeekOfYear else {
                continue
            }

            // Calculate week start and end
            var weekStartComponents = DateComponents()
            weekStartComponents.weekOfYear = weekNumber
            weekStartComponents.yearForWeekOfYear = year

            guard let weekStart = calendar.date(from: weekStartComponents),
                  let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
                continue
            }

            // Fetch workouts for this specific week
            fetchWorkoutsForWeek(weekStart: weekStart, weekEnd: weekEnd, weekNumber: weekNumber, year: year)
        }
    }

    private func fetchWorkoutsForWeek(weekStart: Date, weekEnd: Date, weekNumber: Int, year: Int) {
        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: weekStart, end: weekEnd, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] (_, samples, error) in
            guard let self = self else { return }

            if let error = error {
                print("❌ Error fetching workouts for week \(weekNumber)/\(year): \(error.localizedDescription)")
                return
            }

            guard let workouts = samples as? [HKWorkout] else {
                print("⚠️ No workouts found for week \(weekNumber)/\(year)")
                return
            }

            // Filter for our cardio types (Elliptical, Boxing, Kickboxing)
            var ellipticalMinutes: Double = 0
            var boxingMinutes: Double = 0

            for workout in workouts {
                let isElliptical = workout.workoutActivityType == .elliptical
                let isBoxing = workout.workoutActivityType == .boxing
                let isKickboxing = workout.workoutActivityType == .kickboxing

                // Filter out YRepeat workouts
                let sourceName = workout.sourceRevision.source.name
                if sourceName.contains("YRepeat") {
                    continue
                }

                let minutes = workout.duration / 60.0

                if isElliptical {
                    ellipticalMinutes += minutes
                } else if isBoxing || isKickboxing {
                    boxingMinutes += minutes
                }
            }

            // Only save if there's data
            if ellipticalMinutes > 0 || boxingMinutes > 0 {
                DispatchQueue.main.async {
                    self.saveBackfilledWeek(
                        weekStart: weekStart,
                        weekEnd: weekEnd,
                        weekNumber: weekNumber,
                        year: year,
                        ellipticalMinutes: ellipticalMinutes,
                        boxingMinutes: boxingMinutes
                    )
                }
            }
        }

        healthStore.execute(query)
    }

    private func saveBackfilledWeek(weekStart: Date, weekEnd: Date, weekNumber: Int, year: Int, ellipticalMinutes: Double, boxingMinutes: Double) {
        do {
            guard let entity = NSEntityDescription.entity(forEntityName: "WeeklyExerciseRecordEntity", in: viewContext) else {
                print("❌ Could not find WeeklyExerciseRecordEntity")
                return
            }

            let record = NSManagedObject(entity: entity, insertInto: viewContext)

            // Note: Backfill doesn't include weightlifting data since we're only fetching cardio workouts
            let totalMinutes = ellipticalMinutes + boxingMinutes
            let goalAchieved = totalMinutes >= weeklyGoalMinutes

            record.setValue(UUID(), forKey: "id")
            record.setValue(weekStart, forKey: "weekStartDate")
            record.setValue(weekEnd, forKey: "weekEndDate")
            record.setValue(weekNumber, forKey: "weekNumber")
            record.setValue(year, forKey: "year")
            record.setValue(totalMinutes, forKey: "totalMinutes")
            record.setValue(ellipticalMinutes, forKey: "ellipticalMinutes")
            record.setValue(boxingMinutes, forKey: "boxingMinutes")
            record.setValue(0.0, forKey: "weightliftingMinutes")
            record.setValue(weeklyGoalMinutes, forKey: "goalMinutes")
            record.setValue(0, forKey: "workoutCount")
            record.setValue(goalAchieved, forKey: "goalAchieved")
            record.setValue(Date(), forKey: "createdAt")

            try viewContext.save()

            let df = DateFormatter()
            df.dateFormat = "MMM d"
            print("✅ Backfilled Week \(weekNumber)/\(year) (\(df.string(from: weekStart))-\(df.string(from: weekEnd))): \(Int(totalMinutes))m (Elliptical: \(Int(ellipticalMinutes))m, Boxing: \(Int(boxingMinutes))m)")
        } catch {
            print("❌ Error saving backfilled week: \(error.localizedDescription)")
        }
    }

    // MARK: - Body Weight Tracking

    func loadTodayWeight() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "BodyWeightEntity")
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        fetchRequest.fetchLimit = 1

        do {
            let results = try viewContext.fetch(fetchRequest)
            if let record = results.first as? NSManagedObject {
                currentWeight = record.value(forKey: "weight") as? Double ?? 0
                todayWeightLogged = true
            } else {
                // Try to get last logged weight
                let lastWeightRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "BodyWeightEntity")
                lastWeightRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
                lastWeightRequest.fetchLimit = 1

                let lastResults = try viewContext.fetch(lastWeightRequest)
                if let lastRecord = lastResults.first as? NSManagedObject {
                    currentWeight = lastRecord.value(forKey: "weight") as? Double ?? 0
                } else {
                    currentWeight = 0
                }
                todayWeightLogged = false
            }
        } catch {
            print("❌ Error loading today's weight: \(error.localizedDescription)")
        }
    }

    func saveWeight(_ weight: Double) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()

        // Check if already logged today
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "BodyWeightEntity")
        fetchRequest.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)

        do {
            let results = try viewContext.fetch(fetchRequest)

            if let existingRecord = results.first as? NSManagedObject {
                // Update existing record
                existingRecord.setValue(weight, forKey: "weight")
                existingRecord.setValue(Date(), forKey: "date")
            } else {
                // Create new record
                guard let entity = NSEntityDescription.entity(forEntityName: "BodyWeightEntity", in: viewContext) else {
                    print("❌ Could not find BodyWeightEntity")
                    return
                }

                let record = NSManagedObject(entity: entity, insertInto: viewContext)
                record.setValue(UUID(), forKey: "id")
                record.setValue(weight, forKey: "weight")
                record.setValue(Date(), forKey: "date")
                record.setValue(Date(), forKey: "createdAt")
            }

            try viewContext.save()
            currentWeight = weight
            todayWeightLogged = true
            print("✅ Saved weight: \(weight) kg")
        } catch {
            print("❌ Error saving weight: \(error.localizedDescription)")
        }
    }
}

