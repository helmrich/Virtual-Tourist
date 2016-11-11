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
        let predicate = NSPredicate(format: "pin == %@", argumentArray: [pin])
        
        // Create a fetch request for the Pin entity and assign the predicate to its predicate property
        let fetchRequest = NSFetchRequest<Photo>(entityName: "Photo")
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataStack.stack.persistentContainer.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController!.delegate = self
        
        do {
            try fetchedResultsController!.performFetch()
        } catch {
            fatalError("Error when trying to perform fetch with fetched results controller: \(error.localizedDescription)")
        }
    }
    
    

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
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
        switch type {
        case .insert:
            print("Inserting item...")
            if let newIndexPath = newIndexPath {
                insertedIndexPaths.append(newIndexPath)
            }
            break
        case .delete:
            print("Deleting item...")
            if let indexPath = indexPath {
                deletedIndexPaths.append(indexPath)
            }
            break
        case .update:
            print("Updating cell...")
            if let indexPath = indexPath {
                updatedIndexPaths.append(indexPath)
            }
            break
        case .move:
            print("Moving item...")
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("Controller did change content...")
        
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
