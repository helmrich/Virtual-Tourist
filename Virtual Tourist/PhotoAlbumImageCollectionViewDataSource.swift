//
//  PhotoAlbumImageCollectionViewDataSource.swift
//  Virtual Tourist
//
//  Created by Tobias Helmrich on 04.11.16.
//  Copyright © 2016 Tobias Helmrich. All rights reserved.
//

import UIKit

extension PhotoAlbumViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections[section].numberOfObjects
        }
        
        return 0
        
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count
        }
        
        return 0
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = imageCollectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageCollectionViewCell
        configure(cell: cell, atIndexPath: indexPath)
        return cell
    }
    
    func configure(cell: ImageCollectionViewCell, atIndexPath indexPath: IndexPath) {
        // At first the cell's properties should be reset to prevent problems
        // with duplicate dequeued cells
        cell.imageId = nil
        cell.imageView.image = nil
        
        // Set the cell's imageView's alpha value to 1 as it could be
        // 0.2 because it was selected before
        if selectedIndexPaths.contains(indexPath) {
            cell.imageView.alpha = 0.2
        } else {
            cell.imageView.alpha = 1
        }
        
        // Show the indicator view and let it start animating
        cell.activityIndicatorView.isHidden = false
        cell.activityIndicatorView.startAnimating()
        
        // Get the fetched results controller's fetched objects and check if
        // the number of fetched objects is higher than the current index
        // path's row
        if let fetchedObjects = fetchedResultsController.fetchedObjects,
            fetchedObjects.count > indexPath.row {
            
            // Get the photo from the fetched results controller's objects that
            // is at the cell's index path and set the cell's image ID to this
            // photo's ID. If there is image data, also try to create an image
            // from the data and set the cell's image to it
            let currentPhoto = fetchedResultsController.object(at: indexPath)
            
            // and set the cell's properties to the values
            cell.imageId = currentPhoto.id
            
            if let imageData = currentPhoto.imageData {
                // Hide the activity indicator and stop its animation
                cell.activityIndicatorView.stopAnimating()
                cell.imageView.image = UIImage(data: imageData as Data)
            }
        }
    }
}
