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

class ExerciseManager: ObservableObject {
    @Published var ellipticalMinutesThisWeek: Double = 0
    @Published var statusMessage: String = "Initializing..."
    @AppStorage("weeklyEllipticalGoal") var weeklyGoalMinutes: Double = 150
    @AppStorage("lastTrackedWeek") private var lastTrackedWeek: Int = 0
    @AppStorage("lastTrackedYear") private var lastTrackedYear: Int = 0
    @Published var isAuthorized = false
    @Published var isNewWeek = false

    private let healthStore = HKHealthStore()
    private let workoutType = HKObjectType.workoutType()

    // Motivational reminder manager
    let motivationalManager = MotivationalReminderManager()

    init() {
        // Check if we need to request authorization, then fetch data
        checkAndRequestAuthorizationIfNeeded()

        // Setup notification observer for app becoming active
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appBecameActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func appBecameActive() {
        // Auto-refresh when app becomes active if week has changed
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)

        if let currentWeek = components.weekOfYear,
           let currentYear = components.yearForWeekOfYear {
            if currentWeek != lastTrackedWeek || currentYear != lastTrackedYear {
                // New week detected - refresh data
                isNewWeek = true
                refreshData()
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
            healthStore.getRequestStatusForAuthorization(toShare: [], read: [workoutType]) { [weak self] status, error in
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

        // Only request READ access - we don't need write for viewing workouts
        let typesToRead: Set = [workoutType]

        // This will only show the UI ONCE per app lifetime
        // Subsequent calls do nothing (no-op) unless user uninstalls
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { [weak self] success, error in
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

                    // Track all elliptical-like workouts regardless of date
                    let isElliptical = w.workoutActivityType == .elliptical
                    let isOther = w.workoutActivityType == .other
                    let isMixedCardio = w.workoutActivityType == .mixedCardio

                    if isElliptical || isOther || isMixedCardio {
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

                // Filter for Elliptical specifically for the "This Week" count
                // ALSO INCLUDE 'OTHER' since user's device seems to log it as such
                let ellipticalWorkoutsThisWeek = workouts.filter { workout in
                    let isElliptical = workout.workoutActivityType == .elliptical
                    let isOther = workout.workoutActivityType == .other
                    let isMixedCardio = workout.workoutActivityType == .mixedCardio

                    // Filter out workouts from "YRepeat" to prevent double counting our own fasts
                    let sourceName = workout.sourceRevision.source.name
                    if sourceName.contains("YRepeat") {
                        return false
                    }

                    return (isElliptical || isOther || isMixedCardio) && workout.startDate >= startOfWeek
                }
                
                let totalDuration = ellipticalWorkoutsThisWeek.reduce(0) { $0 + $1.duration }
                let minutes = totalDuration / 60.0
                self.ellipticalMinutesThisWeek = minutes

                // Check if user needs motivational reminder
                self.motivationalManager.checkIfNeedsMotivation(
                    ellipticalMinutes: minutes,
                    goalMinutes: self.weeklyGoalMinutes,
                    startOfWeek: startOfWeek
                )

                // Update last workout date if we have any workouts
                if let latestWorkout = ellipticalWorkoutsThisWeek.max(by: { $0.startDate < $1.startDate }) {
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
                } else if ellipticalWorkoutsThisWeek.isEmpty {
                    // Show what we found but why it didn't match
                    let topTypes = typeCounts.sorted { $0.value > $1.value }.prefix(2).map { "\($0.key)(\($0.value))" }.joined(separator: ", ")

                    // Show all elliptical-like workouts with dates to help diagnose
                    if !allEllipticalLike.isEmpty {
                        let details = allEllipticalLike.sorted { $0.date > $1.date }.prefix(2).map { w in
                            "\(w.type) \(w.mins)m on \(df.string(from: w.date))"
                        }.joined(separator: ", ")
                        let totalMins = allEllipticalLike.reduce(0) { $0 + $1.mins }
                        self.statusMessage = "Week \(weekRange)\(newWeekBadge)\nFound \(totalMins)m total: \(details). No matches this week."
                    } else {
                        self.statusMessage = "Week \(weekRange)\(newWeekBadge)\nFound: \(topTypes). No Elliptical/Other/Mixed workouts."
                    }
                } else {
                    // Show breakdown of what makes up the minutes
                    let count = ellipticalWorkoutsThisWeek.count
                    let breakdown = ellipticalWorkoutsThisWeek.sorted { $0.duration > $1.duration }.prefix(3).map { w in
                        let type = self.getWorkoutTypeName(w.workoutActivityType)
                        let mins = Int(w.duration / 60)
                        let date = DateFormatter.localizedString(from: w.startDate, dateStyle: .short, timeStyle: .none)
                        return "\(type): \(mins)m (\(date))"
                    }.joined(separator: ", ")

                    self.statusMessage = "Week \(weekRange)\(newWeekBadge)\n\(count) workouts: \(breakdown)"
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func getWorkoutTypeName(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .elliptical: return "Elliptical"
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
}

