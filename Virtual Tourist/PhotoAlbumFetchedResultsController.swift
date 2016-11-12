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
    
    // This function initializes a fetched results controller and sets the
    // PhotoAlbumViewController's fetched results controller property
    // to it. The fetched results controller should fetch all of the photos
    // associated to the selected pin.
    func initializeFetchedResultsController() {
        let predicate = NSPredicate(format: "pin == %@", argumentArray: [pin])
        
        // Create a fetch request for the Pin entity and assign the predicate
        // to its predicate property
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.shared.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController!.delegate = self
        
        do {
            try fetchedResultsController!.performFetch()
        } catch {
            fatalError("Error when trying to perform fetch with fetched results controller: \(error.localizedDescription)")
        }
    }

    // When the controller will change content the arrays used to store the indices
    // of altered items should be instantiated
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        imageCollectionView.performBatchUpdates({
            switch type {
            case .insert:
                self.imageCollectionView.insertSections(IndexSet(integer: sectionIndex))
            case .delete:
                self.imageCollectionView.deleteSections(IndexSet(integer: sectionIndex))
            case .move:
                break
            case .update:
                break
            }
        }, completion: nil)
    }
    
    // Every time an object is changed, its index path should be stored in the appropriate array
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            if let newIndexPath = newIndexPath {
                insertedIndexPaths.append(newIndexPath)
            }
            break
        case .delete:
            if let indexPath = indexPath {
                deletedIndexPaths.append(indexPath)
            }
            break
        case .update:
            if let indexPath = indexPath {
                updatedIndexPaths.append(indexPath)
            }
            break
        case .move:
            break
        }
    }
    
    // When the fetched results controller changed the content, the image collection view
    // should be modified by iterating over all index paths and alter the collection view
    // appropriately
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        imageCollectionView.performBatchUpdates({ 
            for indexPath in self.insertedIndexPaths {
                self.imageCollectionView.insertItems(at: [indexPath])
            }
            
            for indexPath in self.deletedIndexPaths {
                self.imageCollectionView.deleteItems(at: [indexPath])
            }
            
            for indexPath in self.updatedIndexPaths {
                self.imageCollectionView.reloadItems(at: [indexPath])
            }
        }, completion: nil)
    }
}
