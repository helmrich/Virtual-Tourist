//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Tobias Helmrich on 11.11.16.
//  Copyright © 2016 Tobias Helmrich. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var id: String
    @NSManaged public var imageData: NSData?
    @NSManaged public var pin: Pin?

}
