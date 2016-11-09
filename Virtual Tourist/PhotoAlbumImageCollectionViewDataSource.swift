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
        return numberOfImages
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        print("CELL INDEX PATH: \(indexPath)")
        
        // Dequeue a reusable cell and cast it to the ImageCollectionViewCell type
        let cell = imageCollectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageCollectionViewCell
        cell.imageId = nil
        cell.imageView.image = nil
        
        // Set the cell's imageView's alpha value to 1 as it could be
        // 0.2 because it was selected before
        cell.imageView.alpha = 1
        
        // Show the indicator view and let it start animating
        cell.activityIndicatorView.isHidden = false
        cell.activityIndicatorView.startAnimating()
        
        if let fetchedResultsController = fetchedResultsController,
            let fetchedObjects = fetchedResultsController.fetchedObjects {
            
            if fetchedObjects.count > indexPath.row,
            let currentPhoto = fetchedObjects[indexPath.row] as? Photo {
                
                // Hide the activity indicator and stop its animation
                cell.activityIndicatorView.isHidden = true
                cell.activityIndicatorView.stopAnimating()
                
                // and set the cell's properties to the values
                cell.imageId = currentPhoto.id
                cell.imageView.image = UIImage(data: currentPhoto.imageData as Data)
            }
            
            if fetchedObjects.count == numberOfImages {
                imageCollectionViewIsDownloading = false
            }
        } else {
        
        }
        
        
        // Check if the selectedImageIds array contains the current cell's image ID
        if let imageId = cell.imageId,
            selectedImageIds.contains(imageId) {
            // and if it does: Set the alpha value to 0.2 so that it seems selected
            cell.imageView.alpha = 0.2
        }
        
        return cell
    }
}
