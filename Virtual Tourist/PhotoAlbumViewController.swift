//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Tobias Helmrich on 23.10.16.
//  Copyright © 2016 Tobias Helmrich. All rights reserved.
//

import UIKit
import MapKit

class PhotoAlbumViewController: UIViewController {

    // MARK: - Properties
    
    var annotation: MKAnnotation?
    var imageUrls: [URL]? {
        didSet {
            DispatchQueue.main.async {
                self.imageCollectionView.reloadData()
            }
        }
    }
    var images = [UIImage]() {
        didSet {
            DispatchQueue.main.async {
                self.imageCollectionView.reloadData()
            }
        }
    }
    
    
    // MARK: - Outlets and Actions
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var imageCollectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var loadNewAlbumButton: UIBarButtonItem!
    @IBOutlet weak var noImagesFoundLabel: UILabel!
    
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        flowLayout.itemSize = CGSize(width: view.frame.width * 0.33, height: view.frame.width * 0.33)
        flowLayout.minimumInteritemSpacing = 1
        flowLayout.minimumLineSpacing = 1
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        if let annotation = annotation {
            mapView.addAnnotation(annotation)
            let region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, 4000, 4000)
            mapView.setRegion(region, animated: true)
            
            FlickrClient.shared.getImageUrls(forLatitude: annotation.coordinate.latitude, andLongitude: annotation.coordinate.longitude, withRadius: 1) { (imageUrls, errorMessage) in
                
                // Check if there was an error
                guard errorMessage == nil else {
                    print(errorMessage!)
                    return
                }
                
                // Check if image URLs were received
                guard let imageUrls = imageUrls else {
                    print("Couldn't get image URLs")
                    return
                }

                self.imageUrls = imageUrls
                
                // If there are no image URLs available a label indicating that no
                // images were found should be displayed
                if imageUrls.count <= 0 {
                    self.noImagesFoundLabel.isHidden = false
                }
                
                for imageUrl in imageUrls {
                    FlickrClient.shared.downloadImageData(fromUrl: imageUrl, completionHandlerForImageData: { (imageData, errorMessage) in
                        
                        // Check if there was an error
                        guard errorMessage == nil else {
                            print(errorMessage!)
                            return
                        }
                        
                        // Check if image data was received
                        guard let imageData = imageData as? Data else {
                            print("Couldn't get image data")
                            return
                        }
                        
                        // Check if the image data can be turned into an image
                        guard let image = UIImage(data: imageData) else {
                            print("Couldn't create image")
                            return
                        }
                        
                        self.images.append(image)
                        
                    })
                }
                
            }
        }
        
    }
    
    
    // MARK: - Functions
    
    
    

}


// MARK: - Collection View Data Source

extension PhotoAlbumViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let imageUrls = self.imageUrls {
            return imageUrls.count
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = imageCollectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageCollectionViewCell
        cell.activityIndicatorView.isHidden = false
        cell.activityIndicatorView.startAnimating()
        if images.count > indexPath.row {
            cell.activityIndicatorView.isHidden = true
            cell.activityIndicatorView.stopAnimating()
            cell.imageView.image = images[indexPath.row]
        }
        return cell
    }
}

// MARK: - Collection View Delegate

//extension PhotoAlbumViewController: UICollectionViewDelegate {
//
//}
