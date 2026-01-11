import Foundation
import Combine
internal import CoreData

class PersistenceController: ObservableObject {
    static let shared = PersistenceController()

    let container = NSPersistentContainer(name: "YRepeat")

    init() {
        // Enable automatic lightweight migration
        let storeDescription = container.persistentStoreDescriptions.first
        storeDescription?.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        storeDescription?.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)

        container.loadPersistentStores { description, error in
            if let error = error {
                print("Core Data failed to load: \(error.localizedDescription)")
            } else {
                print("✅ Core Data loaded successfully")
            }
        }
    }
}
