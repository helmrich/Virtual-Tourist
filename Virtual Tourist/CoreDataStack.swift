//
//  CoreDataStack.swift
//  Virtual Tourist
//
//  Created by Tobias Helmrich on 24.10.16.
//  Copyright © 2016 Tobias Helmrich. All rights reserved.
//

import UIKit
import CoreData
class CoreDataStack: NSObject {
    
    // MARK: - Properties
    
    // Singleton, overwrite the init with fileprivate access control to make sure it can only be
    // instantiated in this file
    static let shared = CoreDataStack()
    fileprivate override init() {}
    
    // Create a persistent container that contains the Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Model")
        
        // If another context changes the changes should be merged into this context automatically
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            guard error == nil else {
                fatalError("Error when trying to load persistent store: \(error!.localizedDescription)")
            }
        })
        
        return container
        
    }()
    
}


// MARK: - Methods

extension CoreDataStack {
    func save() {
        // Check if the context has any changes and try to save it if it has
        if self.persistentContainer.viewContext.hasChanges {
            do {
                try self.persistentContainer.viewContext.save()
            } catch let error as NSError {
                fatalError("\(error), \(error.userInfo)")
            }
        }
    }
    
    // Should only be used in development. This function destroys a persistent store and
    // adds a persistent store of same type at the same URL in order to have an empty
    // persistent store
    func deleteAllData() {
        if let persistentStoreUrl = persistentContainer.persistentStoreCoordinator.persistentStores.first?.url {
            do {
                try persistentContainer.persistentStoreCoordinator.destroyPersistentStore(at: persistentStoreUrl, ofType: NSSQLiteStoreType, options: nil)
                try persistentContainer.persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: persistentStoreUrl, options: nil)
            } catch {
                fatalError("Failed when trying to delete data from persistent store: \(error.localizedDescription)")
            }
        }
    }
    
    func getPin(forLatitude latitude: Double, andLongitude longitude: Double) -> Pin? {
        // Set the predicates for latitude and longitude
        let predicates = [
            NSPredicate(format: "latitude == %@", argumentArray: [latitude]),
            NSPredicate(format: "longitude == %@", argumentArray: [longitude])
        ]
        
        // Create a compound predicate from the latitude and longitude predicates connected with "AND"
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        
        // Create a fetch request for the Pin entity and assign the predicate to its predicate property
        let fetchRequest = NSFetchRequest<Pin>(entityName: "Pin")
        fetchRequest.predicate = compoundPredicate
        
        let pin: Pin?
        do {
            // Make a fetch request and get the pin at index 0 if there is at least one pin at the specified coordinate
            let pins = try CoreDataStack.shared.persistentContainer.viewContext.fetch(fetchRequest)
            if pins.count > 0 {
                pin = pins[0]
            } else {
                pin = nil
            }
        } catch {
            pin = nil
        }
        
        return pin
        
    }
    
    func deletePin(forLatitude latitude: Double, andLongitude longitude: Double) {
        // Create a predicate with conditions for latitude and longitude connected with AND
        let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", argumentArray: [latitude, longitude])
        
        // Create a fetch request for the Pin entity and set its predicate property
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        fetchRequest.predicate = predicate
        
        // Create and execute a batch delete request from the fetch request
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try CoreDataStack.shared.persistentContainer.viewContext.execute(batchDeleteRequest)
        } catch {
            fatalError("Error when trying to delete pin: \(error.localizedDescription)")
        }
    }
    
    
}
