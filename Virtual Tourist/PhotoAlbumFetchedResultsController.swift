//
//  PhotoAlbumFetchedResultsController.swift
//  Virtual Tourist
//
//  Created by Tobias Helmrich on 05.11.16.
//  Copyright © 2016 Tobias Helmrich. All rights reserved.
//

// MARK: - Fetched Results Controller

import UIKit
import CoreData

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    func initializeFetchedResultsController() {
        guard let pin = pin else {
            print("No pin available")
            return
        }
        
        let predicate = NSPredicate(format: "pin == %@", argumentArray: [pin])
        
        // Create a fetch request for the Pin entity and assign the predicate to its predicate property
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.stack.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Error when trying to perform fetch with fetched results controller: \(error.localizedDescription)")
        }
        
        imageCollectionView.reloadData()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        imageCollectionView.performBatchUpdates({
            switch type {
            case .insert:
                print("Inserting section...")
                self.imageCollectionView.insertSections(IndexSet(integer: sectionIndex))
            case .delete:
                print("Deleting section...")
                self.imageCollectionView.deleteSections(IndexSet(integer: sectionIndex))
            case .move:
                break
            case .update:
                break
            }
        }, completion: nil)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        imageCollectionView.performBatchUpdates({
            switch type {
            case .insert:
                print("Inserting item...")
                self.imageCollectionView.insertItems(at: [newIndexPath!])
            case .delete:
                print("Deleting item...")
                self.imageCollectionView.deleteItems(at: [indexPath!])
            case .move:
                print("Moving item...")
                self.imageCollectionView.moveItem(at: indexPath!, to: newIndexPath!)
            case .update:
                print("Updating cell...")
                if let updatedCell = self.imageCollectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath!) as? ImageCollectionViewCell,
                    let currentPhoto = self.fetchedResultsController.object(at: indexPath!) as? Photo
                {
                    updatedCell.imageId = currentPhoto.id
                    updatedCell.imageView.image = UIImage(data: currentPhoto.imageData as Data)
                }
            }
        }, completion: nil)
    }
}
