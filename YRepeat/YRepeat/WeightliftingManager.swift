//
//  WeightliftingManager.swift
//  YRepeat
//
//  Created for Weightlifting tracking
//

import Foundation
import SwiftUI
import Combine
internal import CoreData
import HealthKit

class WeightliftingManager: ObservableObject {
    @Published var sessionsThisWeek: [WeightliftingSession] = []
    @Published var totalMinutesThisWeek: Double = 0

    private let viewContext: NSManagedObjectContext
    private let healthStore = HKHealthStore()

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = context
        loadSessionsForCurrentWeek()
        fetchFromHealthKit()
    }

    // MARK: - Load Sessions

    func loadSessionsForCurrentWeek() {
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)

        guard let weekNumber = components.weekOfYear,
              let year = components.yearForWeekOfYear else {
            return
        }

        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "WeightliftingSessionEntity")
        fetchRequest.predicate = NSPredicate(format: "weekNumber == %d AND year == %d", weekNumber, year)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "sessionDate", ascending: false)]

        do {
            let results = try viewContext.fetch(fetchRequest) as? [NSManagedObject] ?? []
            sessionsThisWeek = results.compactMap { object in
                guard let id = object.value(forKey: "id") as? UUID,
                      let date = object.value(forKey: "sessionDate") as? Date,
                      let duration = object.value(forKey: "durationMinutes") as? Double else {
                    return nil
                }

                let bodyParts = object.value(forKey: "bodyPartsWorked") as? String ?? ""

                return WeightliftingSession(
                    id: id,
                    sessionDate: date,
                    durationMinutes: duration,
                    bodyPartsWorked: bodyParts.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
                )
            }

            totalMinutesThisWeek = sessionsThisWeek.reduce(0) { $0 + $1.durationMinutes }
        } catch {
            print("❌ Error loading weightlifting sessions: \(error.localizedDescription)")
        }
    }

    // MARK: - Fetch from HealthKit

    func fetchFromHealthKit() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let calendar = Calendar.current
        let now = Date()

        // Get current week start
        let startOfWeekComponents = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        guard let startOfWeek = calendar.date(from: startOfWeekComponents) else { return }

        let workoutType = HKObjectType.workoutType()
        let predicate = HKQuery.predicateForSamples(withStart: startOfWeek, end: nil, options: .strictStartDate)

        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { [weak self] (_, samples, error) in
            guard let self = self else { return }

            if let error = error {
                print("❌ Error fetching weightlifting workouts: \(error.localizedDescription)")
                return
            }

            guard let workouts = samples as? [HKWorkout] else { return }

            // Filter for traditional strength training
            let strengthWorkouts = workouts.filter { workout in
                let isStrength = workout.workoutActivityType == .traditionalStrengthTraining ||
                                workout.workoutActivityType == .functionalStrengthTraining

                // Filter out YRepeat workouts
                let sourceName = workout.sourceRevision.source.name
                return isStrength && !sourceName.contains("YRepeat")
            }

            DispatchQueue.main.async {
                // Sync with Core Data
                for workout in strengthWorkouts {
                    self.syncWorkoutToCoreData(workout: workout)
                }
                self.loadSessionsForCurrentWeek()
            }
        }

        healthStore.execute(query)
    }

    private func syncWorkoutToCoreData(workout: HKWorkout) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: workout.startDate)

        guard let weekNumber = components.weekOfYear,
              let year = components.yearForWeekOfYear else {
            return
        }

        // Check if already exists
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "WeightliftingSessionEntity")
        fetchRequest.predicate = NSPredicate(format: "sessionDate == %@", workout.startDate as NSDate)

        do {
            let existing = try viewContext.fetch(fetchRequest)
            if !existing.isEmpty {
                return // Already synced
            }

            // Create new session
            guard let entity = NSEntityDescription.entity(forEntityName: "WeightliftingSessionEntity", in: viewContext) else {
                return
            }

            let session = NSManagedObject(entity: entity, insertInto: viewContext)
            session.setValue(UUID(), forKey: "id")
            session.setValue(workout.startDate, forKey: "sessionDate")
            session.setValue(workout.duration / 60.0, forKey: "durationMinutes")
            session.setValue("", forKey: "bodyPartsWorked") // User will edit
            session.setValue(weekNumber, forKey: "weekNumber")
            session.setValue(year, forKey: "year")
            session.setValue(Date(), forKey: "createdAt")

            try viewContext.save()
        } catch {
            print("❌ Error syncing workout: \(error.localizedDescription)")
        }
    }

    // MARK: - Update Body Parts

    func updateBodyParts(sessionId: UUID, bodyParts: [String]) {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "WeightliftingSessionEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", sessionId as CVarArg)

        do {
            if let session = try viewContext.fetch(fetchRequest).first as? NSManagedObject {
                session.setValue(bodyParts.joined(separator: ", "), forKey: "bodyPartsWorked")
                try viewContext.save()
                loadSessionsForCurrentWeek()
            }
        } catch {
            print("❌ Error updating body parts: \(error.localizedDescription)")
        }
    }

    // MARK: - Reset Weekly Data

    func resetWeeklyData() {
        // Called when new week starts - current sessions will be saved to weekly record
        // No need to delete, they stay for history
        loadSessionsForCurrentWeek()
    }
}

// MARK: - Models

struct WeightliftingSession: Identifiable {
    let id: UUID
    let sessionDate: Date
    let durationMinutes: Double
    var bodyPartsWorked: [String]
}

let availableBodyParts = [
    "Chest", "Back", "Shoulders", "Arms", "Legs", "Core", "Full Body"
]
