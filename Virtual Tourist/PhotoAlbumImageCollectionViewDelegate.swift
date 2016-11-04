//
//  PhotoAlbumImageCollectionViewDelegate.swift
//  Virtual Tourist
//
//  Created by Tobias Helmrich on 04.11.16.
//  Copyright © 2016 Tobias Helmrich. All rights reserved.
//

import UIKit

extension PhotoAlbumViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedCell = collectionView.cellForItem(at: indexPath) as! ImageCollectionViewCell
        if let selectedCellImageId = selectedCell.imageId {
            // Add the selected cell's image ID to the selectedImageIds array after checking
            // if it's not already in the selectedImageIds array (which normally shouldn't be possible
            // as image IDs are unique)
            if !(selectedImageIds.contains(selectedCellImageId)) {
                selectedImageIds.append(selectedCellImageId)
            }
        }
        selectedCell.imageView.alpha = 0.2
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let deselectedCell = collectionView.cellForItem(at: indexPath) as! ImageCollectionViewCell
        if let deselectedCellImageId = deselectedCell.imageId {
            // Overwrite the selectedImageIds array with a filtered version that removes all the image IDs (actually it should only be one)
            // from the array that match the deselected cell's image ID
            selectedImageIds = selectedImageIds.filter { $0 != deselectedCellImageId }
        }
        deselectedCell.imageView.alpha = 1
    }
}
