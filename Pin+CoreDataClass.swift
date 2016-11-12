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
    
    func getAllPhotos() -> [Photo]? {
        // Create a predicate with the condition that the photo's pin relation matches
        // the pin this method is called on
        let predicate = NSPredicate(format: "pin == %@", argumentArray: [self])
        
        // Create the fetch request and set its predicate property
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.predicate = predicate
        
        // Try to fetch the photos and return them if there are photos
        do {
            let photos = try CoreDataStack.stack.persistentContainer.viewContext.fetch(fetchRequest)
            if photos.count > 0 {
                return photos
            } else {
                return nil
            }
        } catch {
            print("Error when trying to get pin's photos")
            return nil
        }
    }
    
    func getPhoto(withId id: String) -> Photo? {
        // Create a predicate with the condition that the photo's pin relation matches
        // the pin this method is called on
        let predicate = NSPredicate(format: "pin == %@ AND id == %@", argumentArray: [self, id])
        
        // Create the fetch request and set its predicate property
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.predicate = predicate
        
        // Try to fetch the photos and return them if there are photos
        do {
            let photos = try CoreDataStack.stack.persistentContainer.viewContext.fetch(fetchRequest)
            if photos.count > 0 {
                return photos[0]
            } else {
                return nil
            }
        } catch {
            print("Error when trying to get pin's photos")
            return nil
        }
    }
    
}
