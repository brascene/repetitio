//
//  CheckBoxManager.swift
//  YRepeat
//
//  Created for Check feature
//

import Foundation
import Combine
import SwiftUI
internal import CoreData

struct CheckBox: Identifiable {
    let id: UUID
    let sectionNumber: Int
    let boxNumber: Int
    var isChecked: Bool
}

class CheckBoxManager: ObservableObject {
    @Published var sections: [[CheckBox]] = []
    @Published var numberOfSections: Int = 0
    @Published var boxesPerSection: Int = 0
    @Published var hasStarted: Bool = false

    private let persistenceController: PersistenceController
    private let context: NSManagedObjectContext

    private let configKey = "checkBoxConfig"

    init(persistenceController: PersistenceController = PersistenceController.shared) {
        self.persistenceController = persistenceController
        self.context = persistenceController.container.viewContext

        loadConfiguration()
        loadBoxes()
    }

    // MARK: - Configuration

    private func loadConfiguration() {
        if let data = UserDefaults.standard.data(forKey: configKey),
           let config = try? JSONDecoder().decode(CheckBoxConfig.self, from: data) {
            numberOfSections = config.numberOfSections
            boxesPerSection = config.boxesPerSection
            hasStarted = config.hasStarted
        }
    }

    private func saveConfiguration() {
        let config = CheckBoxConfig(
            numberOfSections: numberOfSections,
            boxesPerSection: boxesPerSection,
            hasStarted: hasStarted
        )
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: configKey)
        }
    }

    func startWithConfiguration(sections: Int, boxes: Int) {
        numberOfSections = sections
        boxesPerSection = boxes
        hasStarted = true
        saveConfiguration()

        // Create all boxes
        createAllBoxes()
        loadBoxes()
    }

    // MARK: - Box Management

    private func createAllBoxes() {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "CheckBoxEntity", in: context) else {
            print("Failed to get CheckBoxEntity description")
            return
        }

        for section in 0..<numberOfSections {
            for box in 0..<boxesPerSection {
                let entity = NSManagedObject(entity: entityDescription, insertInto: context)
                entity.setValue(UUID(), forKey: "id")
                entity.setValue(Int32(section), forKey: "sectionNumber")
                entity.setValue(Int32(box), forKey: "boxNumber")
                entity.setValue(false, forKey: "isChecked")
                entity.setValue(Date(), forKey: "createdAt")
            }
        }

        try? context.save()
    }

    private func loadBoxes() {
        guard hasStarted else {
            sections = []
            return
        }

        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CheckBoxEntity")
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "sectionNumber", ascending: true),
            NSSortDescriptor(key: "boxNumber", ascending: true)
        ]

        do {
            let entities = try context.fetch(fetchRequest)

            // Group by section
            var sectionDict: [Int: [CheckBox]] = [:]
            for entity in entities {
                let box = CheckBox(
                    id: entity.value(forKey: "id") as? UUID ?? UUID(),
                    sectionNumber: Int((entity.value(forKey: "sectionNumber") as? Int32) ?? 0),
                    boxNumber: Int((entity.value(forKey: "boxNumber") as? Int32) ?? 0),
                    isChecked: entity.value(forKey: "isChecked") as? Bool ?? false
                )
                sectionDict[box.sectionNumber, default: []].append(box)
            }

            // Convert to sorted array
            sections = (0..<numberOfSections).map { sectionDict[$0] ?? [] }
        } catch {
            print("Failed to load boxes: \(error)")
        }
    }

    func toggleBox(id: UUID) {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "CheckBoxEntity")
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        fetchRequest.fetchLimit = 1

        do {
            if let entity = try context.fetch(fetchRequest).first {
                let currentState = entity.value(forKey: "isChecked") as? Bool ?? false
                entity.setValue(!currentState, forKey: "isChecked")
                try context.save()
                loadBoxes()
            }
        } catch {
            print("Failed to toggle box: \(error)")
        }
    }

    func deleteAll() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "CheckBoxEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try context.execute(deleteRequest)
            try context.save()

            // Reset configuration
            numberOfSections = 0
            boxesPerSection = 0
            hasStarted = false
            saveConfiguration()

            sections = []
        } catch {
            print("Failed to delete all boxes: \(error)")
        }
    }

    // MARK: - Statistics

    var totalBoxes: Int {
        sections.flatMap { $0 }.count
    }

    var checkedBoxes: Int {
        sections.flatMap { $0 }.filter { $0.isChecked }.count
    }

    var progress: Double {
        guard totalBoxes > 0 else { return 0 }
        return Double(checkedBoxes) / Double(totalBoxes)
    }
}

// MARK: - Configuration Model

struct CheckBoxConfig: Codable {
    let numberOfSections: Int
    let boxesPerSection: Int
    let hasStarted: Bool
}
