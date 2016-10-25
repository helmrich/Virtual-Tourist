//
//  Photo+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Tobias Helmrich on 25.10.16.
//  Copyright © 2016 Tobias Helmrich. All rights reserved.
//

import Foundation
import CoreData


public class Photo: NSManagedObject {
    convenience init(withImageData imageData: Data, intoContext context: NSManagedObjectContext) {
        guard let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context) else {
            fatalError("Couldn't find entity with name Photo")
        }
        
        self.init(entity: entity, insertInto: context)
        self.imageData = imageData as NSData
        
    }
}
