//
//  FirebaseSyncManager.swift
//  YRepeat
//
//  Created for Firebase Cloud Sync
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore
import FirebaseAuth
internal import CoreData

enum FirebaseSyncError: LocalizedError {
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to sync data"
        }
    }
}

class FirebaseSyncManager: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncStatus: String = "Not synced"
    @Published var syncError: String?

    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()

    // Reference to Core Data context
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    // MARK: - Helper to get current user ID

    private func getCurrentUserId() throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirebaseSyncError.notAuthenticated
        }
        return userId
    }

    // MARK: - Main Sync Function

    func syncAllData() async {
        guard let userId = try? getCurrentUserId() else {
            await MainActor.run {
                syncError = FirebaseSyncError.notAuthenticated.localizedDescription
                syncStatus = "Not signed in"
            }
            return
        }

        await syncAllData(userId: userId)
    }

    private func syncAllData(userId: String) async {
        await MainActor.run {
            isSyncing = true
            syncStatus = "Syncing..."
            syncError = nil
        }

        do {
            // Sync each data type
            try await syncFasts(userId: userId)
            try await syncDailyRepeats(userId: userId)
            try await syncHabits(userId: userId)
            try await syncCalendarEvents(userId: userId)

            await MainActor.run {
                isSyncing = false
                lastSyncDate = Date()
                syncStatus = "Synced successfully"
            }
        } catch {
            await MainActor.run {
                isSyncing = false
                syncError = error.localizedDescription
                syncStatus = "Sync failed"
            }
        }
    }

    // MARK: - Upload to Cloud

    func uploadAllData() async throws {
        let userId = try getCurrentUserId()
        try await uploadAllData(userId: userId)
    }

    private func uploadAllData(userId: String) async throws {
        await MainActor.run {
            isSyncing = true
            syncStatus = "Uploading..."
        }

        try await uploadFasts(userId: userId)
        try await uploadDailyRepeats(userId: userId)
        try await uploadHabits(userId: userId)
        try await uploadCalendarEvents(userId: userId)

        await MainActor.run {
            isSyncing = false
            lastSyncDate = Date()
            syncStatus = "Upload complete"
        }
    }

    // MARK: - Download from Cloud

    func downloadAllData() async throws {
        let userId = try getCurrentUserId()
        try await downloadAllData(userId: userId)
    }

    private func downloadAllData(userId: String) async throws {
        await MainActor.run {
            isSyncing = true
            syncStatus = "Downloading..."
        }

        try await downloadFasts(userId: userId)
        try await downloadDailyRepeats(userId: userId)
        try await downloadHabits(userId: userId)
        try await downloadCalendarEvents(userId: userId)

        await MainActor.run {
            isSyncing = false
            lastSyncDate = Date()
            syncStatus = "Download complete"
        }
    }

    // MARK: - Fasts Sync

    private func syncFasts(userId: String) async throws {
        // TODO: Implement bidirectional sync with conflict resolution
        try await uploadFasts(userId: userId)
    }

    private func uploadFasts(userId: String) async throws {
        let fetchRequest: NSFetchRequest<FastEntity> = FastEntity.fetchRequest()
        let fasts = try context.fetch(fetchRequest)

        let collection = db.collection("users").document(userId).collection("fasts")

        for fast in fasts {
            guard let id = fast.id else { continue }

            let data: [String: Any] = [
                "id": id.uuidString,
                "startTime": Timestamp(date: fast.startTime ?? Date()),
                "endTime": fast.endTime != nil ? Timestamp(date: fast.endTime!) : NSNull(),
                "goalHours": Int(fast.goalHours),
                "fastType": fast.fastType ?? "",
                "createdAt": Timestamp(date: fast.createdAt ?? Date()),
                "updatedAt": Timestamp(date: Date())
            ]

            try await collection.document(id.uuidString).setData(data, merge: true)
        }
    }

    private func downloadFasts(userId: String) async throws {
        let collection = db.collection("users").document(userId).collection("fasts")
        let snapshot = try await collection.getDocuments()

        for document in snapshot.documents {
            let data = document.data()

            guard let idString = data["id"] as? String,
                  let id = UUID(uuidString: idString) else { continue }

            // Check if fast already exists locally
            let fetchRequest: NSFetchRequest<FastEntity> = FastEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

            let existingFasts = try context.fetch(fetchRequest)

            if existingFasts.isEmpty {
                // Create new fast
                let fast = FastEntity(context: context)
                fast.id = id
                fast.startTime = (data["startTime"] as? Timestamp)?.dateValue()
                fast.endTime = (data["endTime"] as? Timestamp)?.dateValue()
                fast.goalHours = Int32((data["goalHours"] as? Int) ?? 16)
                fast.fastType = data["fastType"] as? String
                fast.createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
            }
        }

        try context.save()
    }

    // MARK: - Daily Repeats Sync

    private func syncDailyRepeats(userId: String) async throws {
        try await uploadDailyRepeats(userId: userId)
    }

    private func uploadDailyRepeats(userId: String) async throws {
        let fetchRequest: NSFetchRequest<DailyRepeatItemEntity> = DailyRepeatItemEntity.fetchRequest()
        let repeats = try context.fetch(fetchRequest)

        let collection = db.collection("users").document(userId).collection("dailyRepeats")

        for repeatItem in repeats {
            guard let id = repeatItem.id else { continue }

            let data: [String: Any] = [
                "id": id.uuidString,
                "name": repeatItem.name ?? "",
                "targetValue": repeatItem.targetValue,
                "incrementAmount": repeatItem.incrementAmount,
                "iconName": repeatItem.iconName ?? "",
                "color": repeatItem.color ?? "",
                "currentValue": repeatItem.currentValue,
                "createdAt": Timestamp(date: repeatItem.createdAt ?? Date()),
                "updatedAt": Timestamp(date: Date())
            ]

            try await collection.document(id.uuidString).setData(data, merge: true)
        }
    }

    private func downloadDailyRepeats(userId: String) async throws {
        let collection = db.collection("users").document(userId).collection("dailyRepeats")
        let snapshot = try await collection.getDocuments()

        for document in snapshot.documents {
            let data = document.data()

            guard let idString = data["id"] as? String,
                  let id = UUID(uuidString: idString) else { continue }

            let fetchRequest: NSFetchRequest<DailyRepeatItemEntity> = DailyRepeatItemEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

            let existingRepeats = try context.fetch(fetchRequest)

            if existingRepeats.isEmpty {
                let dailyRepeat = DailyRepeatItemEntity(context: context)
                dailyRepeat.id = id
                dailyRepeat.name = data["name"] as? String
                dailyRepeat.targetValue = data["targetValue"] as? Int32 ?? 0
                dailyRepeat.incrementAmount = data["incrementAmount"] as? Int32 ?? 1
                dailyRepeat.iconName = data["iconName"] as? String
                dailyRepeat.color = data["color"] as? String
                dailyRepeat.currentValue = data["currentValue"] as? Int32 ?? 0
                dailyRepeat.createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
            }
        }

        try context.save()
    }

    // MARK: - Habits Sync

    private func syncHabits(userId: String) async throws {
        try await uploadHabits(userId: userId)
    }

    private func uploadHabits(userId: String) async throws {
        let fetchRequest: NSFetchRequest<HabitEntity> = HabitEntity.fetchRequest()
        let habits = try context.fetch(fetchRequest)

        let collection = db.collection("users").document(userId).collection("habits")

        for habit in habits {
            guard let id = habit.id else { continue }

            let data: [String: Any] = [
                "id": id.uuidString,
                "name": habit.name ?? "",
                "isGoodHabit": habit.isGoodHabit,
                "currentStreak": habit.currentStreak,
                "longestStreak": habit.longestStreak,
                "iconName": habit.iconName ?? "",
                "color": habit.color ?? "",
                "createdAt": Timestamp(date: habit.createdAt ?? Date()),
                "updatedAt": Timestamp(date: Date())
            ]

            try await collection.document(id.uuidString).setData(data, merge: true)
        }
    }

    private func downloadHabits(userId: String) async throws {
        let collection = db.collection("users").document(userId).collection("habits")
        let snapshot = try await collection.getDocuments()

        for document in snapshot.documents {
            let data = document.data()

            guard let idString = data["id"] as? String,
                  let id = UUID(uuidString: idString) else { continue }

            let fetchRequest: NSFetchRequest<HabitEntity> = HabitEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

            let existingHabits = try context.fetch(fetchRequest)

            if existingHabits.isEmpty {
                let habit = HabitEntity(context: context)
                habit.id = id
                habit.name = data["name"] as? String
                habit.isGoodHabit = data["isGoodHabit"] as? Bool ?? true
                habit.currentStreak = data["currentStreak"] as? Int32 ?? 0
                habit.longestStreak = data["longestStreak"] as? Int32 ?? 0
                habit.iconName = data["iconName"] as? String
                habit.color = data["color"] as? String
                habit.createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
            }
        }

        try context.save()
    }

    // MARK: - Calendar Events Sync

    private func syncCalendarEvents(userId: String) async throws {
        try await uploadCalendarEvents(userId: userId)
    }

    private func uploadCalendarEvents(userId: String) async throws {
        let fetchRequest: NSFetchRequest<CalendarEventEntity> = CalendarEventEntity.fetchRequest()
        let events = try context.fetch(fetchRequest)

        let collection = db.collection("users").document(userId).collection("calendarEvents")

        for event in events {
            guard let id = event.id else { continue }

            let data: [String: Any] = [
                "id": id.uuidString,
                "date": Timestamp(date: event.date ?? Date()),
                "createdAt": Timestamp(date: event.createdAt ?? Date()),
                "updatedAt": Timestamp(date: Date())
            ]

            try await collection.document(id.uuidString).setData(data, merge: true)
        }
    }

    private func downloadCalendarEvents(userId: String) async throws {
        let collection = db.collection("users").document(userId).collection("calendarEvents")
        let snapshot = try await collection.getDocuments()

        for document in snapshot.documents {
            let data = document.data()

            guard let idString = data["id"] as? String,
                  let id = UUID(uuidString: idString) else { continue }

            let fetchRequest: NSFetchRequest<CalendarEventEntity> = CalendarEventEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)

            let existingEvents = try context.fetch(fetchRequest)

            if existingEvents.isEmpty {
                let event = CalendarEventEntity(context: context)
                event.id = id
                event.date = (data["date"] as? Timestamp)?.dateValue()
                event.createdAt = (data["createdAt"] as? Timestamp)?.dateValue()
            }
        }

        try context.save()
    }

    // MARK: - Helper Functions

    func clearAllCloudData() async throws {
        let userId = try getCurrentUserId()
        try await clearAllCloudData(userId: userId)
    }

    private func clearAllCloudData(userId: String) async throws {
        // Delete all user data from Firestore (for sign out or account deletion)
        let userDoc = db.collection("users").document(userId)

        let collections = ["fasts", "dailyRepeats", "habits", "calendarEvents"]

        for collectionName in collections {
            let snapshot = try await userDoc.collection(collectionName).getDocuments()
            for document in snapshot.documents {
                try await document.reference.delete()
            }
        }
    }

    // MARK: - Clear Daily Data

    func clearDailyData() async throws {
        let userId = try getCurrentUserId()
        try await clearDailyData(userId: userId)
    }

    private func clearDailyData(userId: String) async throws {
        // Delete only daily repeats (these reset daily)
        // Keep habits, fasts, and calendar events (these are persistent)
        let userDoc = db.collection("users").document(userId)

        let snapshot = try await userDoc.collection("dailyRepeats").getDocuments()
        for document in snapshot.documents {
            try await document.reference.delete()
        }

        print("✅ Firestore: Cleared daily repeats")
    }
}
