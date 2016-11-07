//
//  Pin+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Tobias Helmrich on 03.11.16.
//  Copyright © 2016 Tobias Helmrich. All rights reserved.
//

import Foundation
import CoreData


public class Pin: NSManagedObject {
    convenience init(withLatitude latitude: Double, andLongitude longitude: Double, intoContext context: NSManagedObjectContext) {
        guard let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context) else {
            fatalError("Unable to find entity with name Pin")
        }
        
        self.init(entity: entity, insertInto: context)
        self.latitude = latitude
        self.longitude = longitude
        
    }
    
    func removePhotos() {
        let predicate = NSPredicate(format: "pin == %@", argumentArray: [self])
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.predicate = predicate
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try CoreDataStack.stack.persistentContainer.viewContext.execute(batchDeleteRequest)
            CoreDataStack.stack.save()
            print("Deleted photos from pin...")
        } catch {
            fatalError("Error when trying to delete pin's photos: \(error.localizedDescription)")
        }
    }
    
    func removePhotos(withIds ids: [String]) {
        // Create a fetch request for the Photo entity
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        
        // Instantiate an empty array of NSPredicate
        var predicates = [NSPredicate]()
        
        // Create a predicate for each ID in the array that was passed in as an array and append it to the array created above
        for id in ids {
            let predicate = NSPredicate(format: "id == %@", argumentArray: [id])
            predicates.append(predicate)
        }
        
        // Create a compound predicate that connects all the ID predicates with "OR"
        let idCompoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        
        // Create a pin predicate which should check if the photos actually belong to the pin and create a compound predicate by
        // connecting the pin predicate and the ID compound predicate with "AND"
        let pinPredicate = NSPredicate(format: "pin == %@", argumentArray: [self])
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [idCompoundPredicate, pinPredicate])
        
        // Assign the resulting predicate to the fetch request's predicate property and create a batch delete request from the fetch request
        fetchRequest.predicate = compoundPredicate
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        // Try to execute the batch delete request and save it to the context
        do {
            try CoreDataStack.stack.persistentContainer.viewContext.execute(batchDeleteRequest)
            CoreDataStack.stack.save()
        } catch {
            print("Error when trying to delete photos from database: \(error)")
        }
    }
    
    func getRemovingPhotos(withIds ids: [String]) -> [Photo]? {
        // Create a fetch request for the Photo entity
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        
        // Instantiate an empty array of NSPredicate
        var predicates = [NSPredicate]()
        
        // Create a predicate for each ID in the array that was passed in as an array and append it to the array created above
        for id in ids {
            let predicate = NSPredicate(format: "id == %@", argumentArray: [id])
            predicates.append(predicate)
        }
        
        // Create a compound predicate that connects all the ID predicates with "OR"
        let idCompoundPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        
        // Create a pin predicate which should check if the photos actually belong to the pin and create a compound predicate by
        // connecting the pin predicate and the ID compound predicate with "AND"
        let pinPredicate = NSPredicate(format: "pin == %@", argumentArray: [self])
        let compoundPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [idCompoundPredicate, pinPredicate])
        
        // Assign the resulting predicate to the fetch request's predicate property
        fetchRequest.predicate = compoundPredicate
        
        // Try to execute the fetch request
        do {
            let removalPhotos = try CoreDataStack.stack.persistentContainer.viewContext.fetch(fetchRequest) as? [Photo]
            return removalPhotos
        } catch {
            print("Error when trying to delete photos from database: \(error)")
            return nil
        }
    }
    
    func getAllPinPhotos() -> [Photo]? {
        // Create a predicate with the condition that the photo's pin relation matches the pin this method is called on
        let predicate = NSPredicate(format: "pin == %@", argumentArray: [self])
        
        // Create the fetch request and set its predicate property
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.predicate = predicate
        
        // Try to fetch the photos and return them if there are photos
        do {
            let photos = try CoreDataStack.stack.persistentContainer.viewContext.fetch(fetchRequest) as? [Photo]
            return photos
        } catch {
            print("Error when trying to get pin's photos")
            return nil
        }
    }
    
}
