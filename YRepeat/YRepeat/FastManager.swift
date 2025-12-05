//
//  FastManager.swift
//  YRepeat
//
//  Created for Fasting feature
//

import Foundation
import Combine
import HealthKit
import SwiftUI
internal import CoreData

enum FastType: String, CaseIterable, Codable {
    case custom = "Custom"
    case sixteenEight = "16:8"
    case eighteenSix = "18:6"
    case twentyFour = "24:0"
    case thirtySix = "36:0"
    case fortyEight = "48:0"
    case seventyTwo = "72:0"
    
    var hours: Int {
        switch self {
        case .custom:
            return 16
        case .sixteenEight:
            return 16
        case .eighteenSix:
            return 18
        case .twentyFour:
            return 24
        case .thirtySix:
            return 36
        case .fortyEight:
            return 48
        case .seventyTwo:
            return 72
        }
    }
    
    var displayName: String {
        return self.rawValue
    }
}

enum FastingPhase: String, CaseIterable {
    case fed = "Fed State"
    case earlyFasting = "Early Fasting"
    case ketosisBegins = "Ketosis Begins"
    case fullKetosis = "Full Ketosis"
    case autophagyBegins = "Autophagy Begins"
    case deepAutophagy = "Deep Autophagy"
    case growthHormonePeak = "Growth Hormone Peak"
    
    var hoursStart: Double {
        switch self {
        case .fed:
            return 0
        case .earlyFasting:
            return 4
        case .ketosisBegins:
            return 12
        case .fullKetosis:
            return 18
        case .autophagyBegins:
            return 24
        case .deepAutophagy:
            return 48
        case .growthHormonePeak:
            return 72
        }
    }
    
    var hoursEnd: Double? {
        switch self {
        case .fed:
            return 4
        case .earlyFasting:
            return 12
        case .ketosisBegins:
            return 18
        case .fullKetosis:
            return 24
        case .autophagyBegins:
            return 48
        case .deepAutophagy:
            return 72
        case .growthHormonePeak:
            return nil // No end for growth hormone peak
        }
    }
    
    var icon: String {
        switch self {
        case .fed:
            return "fork.knife"
        case .earlyFasting:
            return "hourglass"
        case .ketosisBegins:
            return "flame.fill"
        case .fullKetosis:
            return "flame"
        case .autophagyBegins:
            return "sparkles"
        case .deepAutophagy:
            return "star.fill"
        case .growthHormonePeak:
            return "crown.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .fed:
            return .gray
        case .earlyFasting:
            return .blue
        case .ketosisBegins:
            return .orange
        case .fullKetosis:
            return .red
        case .autophagyBegins:
            return .purple
        case .deepAutophagy:
            return .pink
        case .growthHormonePeak:
            return .yellow
        }
    }
    
    var description: String {
        switch self {
        case .fed:
            return "Body is using glucose from recent meals"
        case .earlyFasting:
            return "Glycogen stores are being broken down"
        case .ketosisBegins:
            return "Ketone production starts - fat burning begins!"
        case .fullKetosis:
            return "Full ketosis achieved - maximum fat burning!"
        case .autophagyBegins:
            return "Cellular repair and recycling activated"
        case .deepAutophagy:
            return "Enhanced cellular repair and regeneration"
        case .growthHormonePeak:
            return "Peak growth hormone - stem cell regeneration"
        }
    }
    
    var motivationalMessage: String {
        switch self {
        case .fed:
            return "Just getting started!"
        case .earlyFasting:
            return "You're doing great! Keep going!"
        case .ketosisBegins:
            return "Fat burning mode activated! 🔥"
        case .fullKetosis:
            return "You're in the zone! Maximum benefits!"
        case .autophagyBegins:
            return "Your cells are repairing themselves! ✨"
        case .deepAutophagy:
            return "Deep healing in progress! 🌟"
        case .growthHormonePeak:
            return "Peak performance! You're amazing! 👑"
        }
    }
    
    static func phase(for hours: Double) -> FastingPhase {
        if hours <= 4 {
            return .fed
        } else if hours <= 12 {
            return .earlyFasting
        } else if hours <= 18 {
            return .ketosisBegins
        } else if hours <= 24 {
            return .fullKetosis
        } else if hours <= 48 {
            return .autophagyBegins
        } else if hours <= 72 {
            return .deepAutophagy
        } else {
            return .growthHormonePeak
        }
    }
    
    var progressInPhase: Double {
        // This will be calculated based on current hours within the phase range
        return 0.0
    }
}

struct Fast: Identifiable {
    let id: UUID
    let startTime: Date
    let endTime: Date?
    let goalHours: Int
    let fastType: FastType
    let createdAt: Date
    
    var isActive: Bool {
        return endTime == nil
    }
    
    var elapsedHours: Double {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime) / 3600.0
    }
    
    var remainingHours: Double {
        guard isActive else { return 0 }
        return max(0, Double(goalHours) - elapsedHours)
    }
    
    var progress: Double {
        guard isActive else {
            // For completed fasts, show 100% if goal was reached
            return elapsedHours >= Double(goalHours) ? 1.0 : min(1.0, elapsedHours / Double(goalHours))
        }
        return min(1.0, elapsedHours / Double(goalHours))
    }
    
    var isCompleted: Bool {
        guard let endTime = endTime else { return false }
        let duration = endTime.timeIntervalSince(startTime) / 3600.0
        return duration >= Double(goalHours)
    }
    
    var durationHours: Double {
        elapsedHours
    }
    
    var currentPhase: FastingPhase {
        guard isActive else {
            // For completed fasts, return phase at completion
            return FastingPhase.phase(for: elapsedHours)
        }
        return FastingPhase.phase(for: elapsedHours)
    }
    
    var phaseProgress: Double {
        guard isActive else { return 0 }
        let currentPhase = self.currentPhase
        let phaseStart = currentPhase.hoursStart
        
        // Handle infinity case for growth hormone peak
        if currentPhase == .growthHormonePeak {
            // For growth hormone peak, show progress based on hours beyond 72
            let hoursBeyond72 = elapsedHours - 72
            // Cap at 100% after 24 more hours (96 total)
            return min(1.0, hoursBeyond72 / 24.0)
        }
        
        guard let phaseEnd = currentPhase.hoursEnd else {
            return 0
        }
        let progress = (elapsedHours - phaseStart) / (phaseEnd - phaseStart)
        return min(1.0, max(0.0, progress))
    }
}

class FastManager: ObservableObject {
    @Published var activeFast: Fast?
    @Published var fastHistory: [Fast] = []
    
    private let persistenceController: PersistenceController
    private let context: NSManagedObjectContext
    private var timer: Timer?
    private let healthStore = HKHealthStore()
    
    init(persistenceController: PersistenceController = PersistenceController.shared) {
        self.persistenceController = persistenceController
        self.context = persistenceController.container.viewContext
        
        loadFasts()
        startTimer()
        requestHealthKitAuthorization()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // MARK: - HealthKit
    
    private func requestHealthKitAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        // Use HKWorkoutType to represent fasting periods
        // Apple doesn't have a native fasting category, so we use workouts with metadata
        let workoutType = HKObjectType.workoutType()
        
        // Request write authorization for workout data (which we'll use for fasting)
        healthStore.requestAuthorization(toShare: [workoutType], read: nil) { success, error in
            if let error = error {
                print("HealthKit authorization error: \(error.localizedDescription)")
            } else if success {
                print("HealthKit authorization granted for fasting data")
            } else {
                print("HealthKit authorization denied")
            }
        }
    }
    
    func saveFastToHealthKit(_ fast: Fast) {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        // Calculate end time (use actual end time if available, otherwise use goal time)
        let endTime: Date
        if let fastEndTime = fast.endTime {
            endTime = fastEndTime
        } else {
            endTime = fast.startTime.addingTimeInterval(TimeInterval(fast.goalHours * 3600))
        }
        
        // Calculate duration
        let duration = endTime.timeIntervalSince(fast.startTime)
        
        // Create workout to represent fasting period
        // Note: Using deprecated initializer for historical workouts (completed fasts)
        // HKWorkoutBuilder is designed for live workouts, not historical data
        // This is the appropriate approach for saving completed fasting sessions
        let workout = HKWorkout(
            activityType: .other,
            start: fast.startTime,
            end: endTime,
            duration: duration,
            totalEnergyBurned: nil,
            totalDistance: nil,
            metadata: [
                HKMetadataKeyWorkoutBrandName: "YRepeat",
                "fastType": fast.fastType.rawValue,
                "goalHours": "\(fast.goalHours)",
                "durationHours": String(format: "%.2f", fast.durationHours),
                "isCompleted": fast.isCompleted ? "true" : "false",
                "isFasting": "true" // Mark this as a fasting workout
            ]
        )
        
        // Save to HealthKit
        healthStore.save(workout) { success, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to save fast to HealthKit: \(error.localizedDescription)")
                } else if success {
                    print("Fast saved to HealthKit successfully: \(fast.fastType.rawValue) for \(fast.goalHours) hours")
                }
            }
        }
    }
    
    // MARK: - Timer
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }
    }
    
    // MARK: - Fast Management
    
    func startFast(type: FastType, customHours: Int? = nil) {
        // End any existing active fast first
        if let existingFast = activeFast,
           let entity = getFastEntity(for: existingFast.id) {
            entity.setValue(Date(), forKey: "endTime")
            try? context.save()
        }
        
        let goalHours = customHours ?? type.hours
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "FastEntity", in: context) else {
            print("Failed to get FastEntity description")
            return
        }
        let entity = NSManagedObject(entity: entityDescription, insertInto: context)
        entity.setValue(UUID(), forKey: "id")
        entity.setValue(Date(), forKey: "startTime")
        entity.setValue(nil, forKey: "endTime") // Active fast has no end time
        entity.setValue(Int32(goalHours), forKey: "goalHours")
        entity.setValue(type.rawValue, forKey: "fastType")
        entity.setValue(Date(), forKey: "createdAt")
        
        try? context.save()
        loadFasts()
    }
    
    func stopFast() {
        guard let fast = activeFast,
              let entity = getFastEntity(for: fast.id) else { return }
        
        entity.setValue(Date(), forKey: "endTime")
        try? context.save()
        
        // Save to HealthKit if completed
        let updatedFast = getFast(from: entity)
        if updatedFast.isCompleted {
            saveFastToHealthKit(updatedFast)
        }
        
        loadFasts()
    }
    
    func deleteFast(_ fast: Fast) {
        guard let entity = getFastEntity(for: fast.id) else { return }
        context.delete(entity)
        try? context.save()
        loadFasts()
    }
    
    func deleteAllFasts() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "FastEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            loadFasts()
        } catch {
            print("Failed to delete all fasts: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Core Data Helpers
    
    private func loadFasts() {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FastEntity")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        do {
            let entities = try context.fetch(fetchRequest)
            
            // Find active fast (endTime is nil)
            activeFast = entities
                .first { $0.value(forKey: "endTime") == nil }
                .map { getFast(from: $0) }
            
            // Load history (completed fasts)
            fastHistory = entities
                .filter { $0.value(forKey: "endTime") != nil }
                .compactMap { getFast(from: $0) }
            
            // If active fast expired (over 50% past goal), end it
            if let fast = activeFast,
               fast.elapsedHours > Double(fast.goalHours) * 1.5 {
                if let entity = getFastEntity(for: fast.id) {
                    entity.setValue(Date(), forKey: "endTime")
                    try? context.save()
                    loadFasts() // Reload
                }
            }
        } catch {
            print("Failed to load fasts: \(error.localizedDescription)")
        }
    }
    
    private func getFast(from entity: NSManagedObject) -> Fast {
        let fastTypeString = entity.value(forKey: "fastType") as? String ?? FastType.sixteenEight.rawValue
        let fastType = FastType(rawValue: fastTypeString) ?? .sixteenEight
        let endTimeValue = entity.value(forKey: "endTime")
        let endTime = endTimeValue as? Date
        return Fast(
            id: entity.value(forKey: "id") as? UUID ?? UUID(),
            startTime: entity.value(forKey: "startTime") as? Date ?? Date(),
            endTime: endTime,
            goalHours: (entity.value(forKey: "goalHours") as? Int32).map { Int($0) } ?? 16,
            fastType: fastType,
            createdAt: entity.value(forKey: "createdAt") as? Date ?? Date()
        )
    }
    
    private func getFastEntity(for id: UUID) -> NSManagedObject? {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "FastEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1
        
        return try? context.fetch(fetchRequest).first
    }
}

