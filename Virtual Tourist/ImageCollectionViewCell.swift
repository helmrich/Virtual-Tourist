//
//  ImageCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Tobias Helmrich on 27.10.16.
//  Copyright © 2016 Tobias Helmrich. All rights reserved.
//

import UIKit

class ImageCollectionViewCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    var imageId: String? = nil
    
    
    // MARK: - Outlets
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicatorView: UIActivityIndicatorView!
}
