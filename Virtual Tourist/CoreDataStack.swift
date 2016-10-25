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
    
    var persistingContext: NSManagedObjectContext
    var context: NSManagedObjectContext
    var backgroundContext: NSManagedObjectContext

    
    // MARK: - Initializer
    
    override init() {
        
        // Check if the model exists in the app's main bundle, if it doesn't it's a fatal error
        guard let modelUrl = Bundle.main.url(forResource: "Model", withExtension: "momd") else {
            fatalError("Error loading model from bundle")
        }
        
        // Try to create the managed object model from the modelUrl, if it can't be created it's a fatal error
        guard let managedObjectModel = NSManagedObjectModel(contentsOf: modelUrl) else {
            fatalError("Error initializing managed object model from URL: \(modelUrl)")
        }
        
        // Create the persistent store coordinator
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        // Create three managed object contexts:
        // - Persisting context that runs in a private queue and saves to the persistent store coordinator
        persistingContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        persistingContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        // - "Main" Context that reads from the database and displays the managed object's data in the UI, is a child of
        // the persisting context
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.parent = persistingContext
        
        // - Background context that also runs in a private queue and is used for getting data in the background
        // (e.g. by getting data from the Flickr API), is a child of the "main" context
        backgroundContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        backgroundContext.parent = context
        
        // Add the persistent store to the persistent store coordinator in a background queue:
        DispatchQueue.global(qos: .background).async {
            
            // Get the URL for the Documents directory
            let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            guard let documentsUrl = urls.last else {
                fatalError("Error migrating store: Couldn't get URL for Documents directory")
            }
            
            // Create the persistent store's URL by appending the name of the model followed by the .sqlite suffix to the Documents directory's URL
            let persistentStoreUrl = documentsUrl.appendingPathComponent("Model.sqlite")
            
            // Create a SQLite persistent store at this URL
            do {
                try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: persistentStoreUrl, options: nil)
            } catch {
                fatalError("Error migrating store: \(error)")
            }
        }
        
    }
}


// MARK: - Methods

extension CoreDataStack {
    func save() {
        // Only if the "main" context has changes saving is necessary
        if context.hasChanges {
            // Save the main context synchronously
            do {
                try context.save()
                print("Saved main context...")
            } catch {
                fatalError("Couldn't save context")
            }
            
            // Save the persisting context asynchronously after the main context was saved
            persistingContext.perform {
                do {
                    try self.persistingContext.save()
                    print("Saved persisting context")
                } catch {
                    fatalError("Couldn't save persisting context")
                }
            }
        }
    }
}
