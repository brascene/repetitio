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
    @Published var isAuthorized = false

    private let healthStore = HKHealthStore()
    private var hasRequestedAuthThisSession = false

    init() {
        // Request authorization once per app session
        requestHealthKitAuthorizationIfNeeded()
    }

    private func requestHealthKitAuthorizationIfNeeded() {
        // Only request once per app session to avoid showing dialog repeatedly
        guard !hasRequestedAuthThisSession else {
            // Already requested this session, just fetch data
            fetchEllipticalMinutes()
            return
        }

        hasRequestedAuthThisSession = true
        requestHealthKitAuthorization()
    }
    
    func requestHealthKitAuthorization() {
        statusMessage = "Requesting permission..."
        guard HKHealthStore.isHealthDataAvailable() else {
            statusMessage = "HealthKit not available"
            return
        }

        let workoutType = HKObjectType.workoutType()

        healthStore.requestAuthorization(toShare: nil, read: [workoutType]) { [weak self] success, error in
            DispatchQueue.main.async {
                guard let self = self else { return }

                if let error = error {
                    self.statusMessage = "Error: \(error.localizedDescription)"
                    self.isAuthorized = false
                    return
                }

                // For READ permissions, HealthKit doesn't reveal if user granted/denied for privacy
                // We always try to fetch data - if permission was denied, we'll get no results
                self.isAuthorized = true
                self.fetchEllipticalMinutes()
            }
        }
    }
    
    func forceAuthorization() {
        // Force a fresh authorization request even if already requested this session
        // This is called when user explicitly taps the "Force Authorization Request" button
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
        
        // Calculate start of week (Sunday or Monday depending on locale)
        // Reset time to 00:00:00 to ensure we catch everything from the start of the first day
        let startOfWeekComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        guard let startOfWeek = calendar.date(from: startOfWeekComponents) else { return }
        
        // Look back 7 days for debugging if startOfWeek fails, but we rely on startOfWeek for the count
        
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
                
                if workouts.isEmpty {
                    self.statusMessage = "No workouts found in last 30 days. Check Permissions > Read > Workouts."
                } else if ellipticalWorkoutsThisWeek.isEmpty {
                    // Show what we found but why it didn't match
                    let topTypes = typeCounts.sorted { $0.value > $1.value }.prefix(2).map { "\($0.key)(\($0.value))" }.joined(separator: ", ")

                    // Show all elliptical-like workouts with dates to help diagnose
                    if !allEllipticalLike.isEmpty {
                        let df = DateFormatter()
                        df.dateFormat = "MM/dd"
                        let weekStart = df.string(from: startOfWeek)
                        let details = allEllipticalLike.sorted { $0.date > $1.date }.prefix(3).map { w in
                            "\(w.type) \(w.mins)m on \(df.string(from: w.date))"
                        }.joined(separator: ", ")
                        let totalMins = allEllipticalLike.reduce(0) { $0 + $1.mins }
                        self.statusMessage = "Found \(totalMins)m total: \(details). Week starts \(weekStart). No matches this week."
                    } else {
                        self.statusMessage = "Found: \(topTypes). No Elliptical/Other/Mixed workouts."
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

                    self.statusMessage = "Synced. \(count) workouts: \(breakdown)"
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
        // If we've already requested auth this session, just fetch data
        // Otherwise request auth first (only happens once per session)
        requestHealthKitAuthorizationIfNeeded()
    }
}

