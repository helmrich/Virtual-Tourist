//
//  Pin+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Tobias Helmrich on 25.10.16.
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
}
