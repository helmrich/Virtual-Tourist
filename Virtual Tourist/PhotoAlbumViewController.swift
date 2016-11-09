//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Tobias Helmrich on 23.10.16.
//  Copyright © 2016 Tobias Helmrich. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    // MARK: - Properties
    
    var pin: Pin?
    var numberOfImagePages: Int?
    var numberOfImages = 0
    
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>?
    
    var imageCollectionViewIsDownloading = false {
        didSet {
            DispatchQueue.main.async {
                self.imageCollectionView.allowsSelection = !self.imageCollectionViewIsDownloading
                self.imageCollectionView.allowsMultipleSelection = !self.imageCollectionViewIsDownloading
                self.loadNewAlbumButton.isEnabled = !self.imageCollectionViewIsDownloading
            }
        }
    }
    
    var annotation: MKAnnotation? {
        // Every time the annotation property is set try to get a pin managed
        // object for its latitude and longitude values
        didSet {
            if let annotation = annotation {
                pin = CoreDataStack.stack.getPin(forLatitude: annotation.coordinate.latitude, andLongitude: annotation.coordinate.longitude)
            }
        }
    }
    
    var selectedImageIds = [String]() {
        // Every time the selectedImageIds property is set check if there are IDs,
        // depending on that the loadNewAlbumButton bar button should be changed accordingly
        didSet {
            if selectedImageIds.count > 0 {
                toggleNewAlbumButton(delete: true)
            } else {
                toggleNewAlbumButton(delete: false)
            }
        }
    }
    
    // MARK: - Outlets and Actions
    
    // MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var imageCollectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var loadNewAlbumButton: UIBarButtonItem!
    @IBOutlet weak var noImagesFoundLabel: UILabel!
    @IBOutlet weak var loadingCollectionViewActivityIndicatorView: UIActivityIndicatorView!
    
    // MARK: - Actions
    @IBAction func changePhotoAlbum() {
        guard let title = loadNewAlbumButton.title else {
            return
        }
        
        // Check if there is a Pin managed object
        guard let pin = pin else {
            self.presentAlertController(withMessage: "No pin available")
            return
        }
        
        if title == "Load New Album" {
            imageCollectionViewIsDownloading = true
            getNewImages(forPin: pin, randomPage: true)
        } else if title == "Remove Selected Images" {
            // Check if there are selected images
            guard selectedImageIds.count > 0 else {
                self.presentAlertController(withMessage: "No images are selected")
                return
            }
            
            // Remove the photos from the Pin managed object
            if let fetchedResultsController = fetchedResultsController,
                let removingPhotos = pin.getRemovingPhotos(withIds: selectedImageIds) {
                for removingPhoto in removingPhotos {
                    fetchedResultsController.managedObjectContext.delete(removingPhoto)
                    pin.removeFromPhotos(removingPhoto)
                    CoreDataStack.stack.save()
                }
            }
            
            // Reset the toggle loadNewAlbum bar button
            toggleNewAlbumButton(delete: false)
        }
    }
    
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the flow layout
        flowLayout.itemSize = CGSize(width: view.frame.width * 0.33, height: view.frame.width * 0.33)
        flowLayout.minimumInteritemSpacing = 1
        flowLayout.minimumLineSpacing = 1
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Show the navigation bar
        navigationController?.setNavigationBarHidden(false, animated: true)
        
        loadingCollectionViewActivityIndicatorView.startAnimating()
        
        // Check if the photo album view controller has an annotation
        if let annotation = annotation {
            // Add the annotation to the photo album view controller's map view and set the region with
            // the annotation's coordinate as a center
            mapView.addAnnotation(annotation)
            let region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, 4000, 4000)
            mapView.setRegion(region, animated: true)
            
            
            // Try to get a pin with the current annotation's latitude and longitude, if there is a matching pin object,
            if let pin = pin {
                // try to get its photos and check if there are any photos associated to the pin already...
                if let photos = pin.getAllPinPhotos(),
                    photos.count > 0 {
                    print(photos)
                    numberOfImages = photos.count
                    loadingCollectionViewActivityIndicatorView.stopAnimating()
                    initializeFetchedResultsController()
                    print(fetchedResultsController!.fetchedObjects!.count)
                } else {
                    // If there are no photos associated with the pin get new images
                    getNewImages(forPin: pin)
                }
            }
        }
    }
    
}


// MARK: - Functions

extension PhotoAlbumViewController {
    // Get image informations for the pin's coordinate, if there are image URLs, download
    // the data for all images, create a Photo object for each image and add it to the pin
    func getNewImages(forPin pin: Pin, randomPage: Bool = false) {
        FlickrClient.shared.getImageInformations(forLatitude: pin.latitude, andLongitude: pin.longitude) { (imageInformations, numberOfPages, errorMessage) in
            
            // Check if there was an error
            guard errorMessage == nil else {
                self.presentAlertController(withMessage: errorMessage!)
                return
            }
            
            // Check if the number of pages was received
            guard let numberOfPages = numberOfPages else {
                self.presentAlertController(withMessage: "Couldn't get number of pages")
                return
            }
            
            // Check if image URLs were received
            guard let initialImageInformations = imageInformations else {
                self.presentAlertController(withMessage: "Couldn't get image informations")
                return
            }
            
            // Create a variable that holds the image informations that will be used to
            // download images and set its value to the image informations that were already received
            var imageInformations: [String:URL] = initialImageInformations
            
            if randomPage {
                FlickrClient.shared.getImageInformationsForRandomPage(forLatitude: pin.latitude, andLongitude: pin.longitude, withNumberOfPages: numberOfPages) { (imageInformationsFromRandomPage, errorMessage) in
                    
                    // Check if there was an error
                    guard errorMessage == nil else {
                        self.presentAlertController(withMessage: errorMessage!)
                        return
                    }
                    
                    // Check if image informations were received with the specified page number
                    guard let imageInformationsFromRandomPage = imageInformationsFromRandomPage else {
                        self.presentAlertController(withMessage: "Couldn't get image informations from random page")
                        return
                    }
                    
                    imageInformations = imageInformationsFromRandomPage
                    self.numberOfImages = imageInformations.count
                    self.downloadImages(fromImageInformations: imageInformations, forPin: pin)
                }
            } else {
                self.numberOfImages = imageInformations.count
                self.downloadImages(fromImageInformations: imageInformations, forPin: pin)
            }
            
            
            
        }
    }
    
    func downloadImages(fromImageInformations imageInformations: [String:URL], forPin pin: Pin) {
        imageCollectionViewIsDownloading = true
        DispatchQueue.main.async {
            self.loadingCollectionViewActivityIndicatorView.stopAnimating()
        }
        
        // If there are no image URLs available a label indicating that no
        // images were found should be displayed
        if imageInformations.count <= 0 {
            DispatchQueue.main.async {
                // In this app it can be assumed that there is only one section
                if self.imageCollectionView.numberOfItems(inSection: 0) <= 0 {
                    self.noImagesFoundLabel.isHidden = false
                }
                self.imageCollectionViewIsDownloading = false
            }
        } else {
            DispatchQueue.main.async {
                self.noImagesFoundLabel.isHidden = true
            }
            // If image URLs are available the photos associated to the pin should be removed as they will be replaced by new photos
            pin.removePhotos()
//            DispatchQueue.main.async {
//                self.imageCollectionView.reloadData()
//            }
        }
        
        initializeFetchedResultsController()
        
        for (imageId, imageUrl) in imageInformations {
            FlickrClient.shared.downloadImageData(fromUrl: imageUrl) { (imageData, errorMessage) in
                
                guard errorMessage == nil else {
                    self.presentAlertController(withMessage: errorMessage!)
                    return
                }
                
                guard let imageData = imageData as? Data else {
                    self.presentAlertController(withMessage: "Couldn't get image data")
                    return
                }
                
                // Create a Photo managed object from the image data and ID and insert it into the fetchedResultsController's context
                if let fetchedResultsController = self.fetchedResultsController {
                    let photo = Photo(withImageData: imageData, andId: imageId, intoContext: fetchedResultsController.managedObjectContext)
                    // Set the photo's pin relation to the current pin
                    photo.pin = pin
                    CoreDataStack.stack.save()
                }
            }
        }
    }
}


// MARK: - Helper functions

extension PhotoAlbumViewController {
    func toggleNewAlbumButton(delete: Bool) {
        if delete {
            loadNewAlbumButton.title = "Remove Selected Images"
            loadNewAlbumButton.tintColor = .cancelRed
        } else {
            loadNewAlbumButton.title = "Load New Album"
            loadNewAlbumButton.tintColor = view.tintColor
        }
    }
}
