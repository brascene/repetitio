//
//  HistoryManager.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import Foundation
import Combine
internal import CoreData

class HistoryManager: ObservableObject {
    @Published var items: [HistoryItem] = []
    
    private let persistenceController: PersistenceController
    private let context: NSManagedObjectContext
    
    init(persistenceController: PersistenceController = PersistenceController.shared) {
        self.persistenceController = persistenceController
        self.context = persistenceController.container.viewContext
        loadHistory()
    }

    func saveItem(videoURL: String, videoId: String, startTime: Double, endTime: Double, repeatCount: Int, videoTitle: String? = nil) {
        let entity = HistoryItemEntity(context: context)
        entity.id = UUID()
        entity.url = videoURL
        entity.videoID = videoId
        entity.title = videoTitle
        entity.startTime = String(startTime)
        entity.endTime = String(endTime)
        entity.repeatCount = Int32(repeatCount)
        entity.createdAt = Date()
        
        try? context.save()
        loadHistory()
    }

    func deleteItem(at offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            if let entity = getEntity(for: item) {
                context.delete(entity)
            }
        }
        try? context.save()
        loadHistory()
    }

    func deleteItem(_ item: HistoryItem) {
        if let entity = getEntity(for: item) {
            context.delete(entity)
            try? context.save()
            loadHistory()
        }
    }

    func clearAll() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = HistoryItemEntity.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            try? context.save()
            loadHistory()
        } catch {
            print("Failed to clear history: \(error)")
        }
    }

    private func loadHistory() {
        let fetchRequest: NSFetchRequest<HistoryItemEntity> = HistoryItemEntity.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(keyPath: \HistoryItemEntity.createdAt, ascending: false)]
        
        do {
            let entities = try context.fetch(fetchRequest)
            items = entities.compactMap { entity in
                guard let id = entity.id,
                      let url = entity.url,
                      let videoID = entity.videoID,
                      let startTimeString = entity.startTime,
                      let endTimeString = entity.endTime,
                      let startTime = Double(startTimeString),
                      let endTime = Double(endTimeString) else {
                    return nil
                }
                
                return HistoryItem(
                    id: id,
                    videoURL: url,
                    videoId: videoID,
                    videoTitle: entity.title,
                    startTime: startTime,
                    endTime: endTime,
                    repeatCount: Int(entity.repeatCount),
                    savedAt: entity.createdAt ?? Date()
                )
            }
        } catch {
            print("Failed to load history: \(error)")
            items = []
        }
    }
    
    private func getEntity(for item: HistoryItem) -> HistoryItemEntity? {
        let fetchRequest: NSFetchRequest<HistoryItemEntity> = HistoryItemEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", item.id as CVarArg)
        
        do {
            let entities = try context.fetch(fetchRequest)
            return entities.first
        } catch {
            print("Failed to fetch entity: \(error)")
            return nil
        }
    }
}
