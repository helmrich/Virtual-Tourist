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
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Model")
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
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                fatalError("Error when trying to save context: \(error.localizedDescription)")
            }
        }
    }
}
