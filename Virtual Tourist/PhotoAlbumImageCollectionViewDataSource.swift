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
        
        // Check if the number of images is higher than the indexPath's row property
        // which means that there is at least one more image that can be shown in a cell
        if images.count > indexPath.row {
            // Hide the activity indicator and stop its animation
            cell.activityIndicatorView.isHidden = true
            cell.activityIndicatorView.stopAnimating()
            
            // Get the image ID and the image itself
            for (imageId, image) in images[indexPath.row] {
                // and set the cell's properties to the values
                cell.imageId = imageId
                cell.imageView.image = image
            }
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
