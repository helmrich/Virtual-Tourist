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
    
    var pin: Pin!
    var numberOfImagePages: Int?
    var numberOfDownloadedImages = 0
    
    var fetchedResultsController: NSFetchedResultsController<Photo>!
    var selectedIndexPaths = [IndexPath]() {
        didSet {
            if selectedIndexPaths.count > 0 {
                toggleNewAlbumButton(delete: true)
            } else {
                toggleNewAlbumButton(delete: false)
            }
        }
    }
    var insertedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    
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
        
        if title == "Load New Album" {
            imageCollectionViewIsDownloading = true
            getNewImages(forPin: pin, randomPage: true)
        } else if title == "Remove Selected Images" {
            // Check if there are selected images
            guard selectedIndexPaths.count > 0 else {
                self.presentAlertController(withMessage: "No images are selected")
                return
            }
            
            // Remove the photos from the Pin managed object
            var removingPhotos = [Photo]()
            for selectedIndexPath in selectedIndexPaths {
                removingPhotos.append(fetchedResultsController.object(at: selectedIndexPath))
            }
        
            for removingPhoto in removingPhotos {
                CoreDataStack.stack.persistentContainer.viewContext.delete(removingPhoto)
            }
            
            selectedIndexPaths = [IndexPath]()
            
        }
    }
    
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the flow layout
        flowLayout.itemSize = CGSize(width: view.frame.width * 0.33, height: view.frame.width * 0.33)
        flowLayout.minimumInteritemSpacing = 1
        flowLayout.minimumLineSpacing = 1
        
        initializeFetchedResultsController()
        
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
            
            // Try to get the pin's photos and check if there are any photos associated to the pin already...
            if let photos = pin.getAllPinPhotos(),
                photos.count > 0 {
                loadingCollectionViewActivityIndicatorView.stopAnimating()
                imageCollectionViewIsDownloading = false
            } else {
                // If there are no photos associated with the pin get new images
                getNewImages(forPin: pin)
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
            
            guard errorMessage == nil else {
                self.presentAlertController(withMessage: errorMessage!)
                return
            }
            
            guard let numberOfPages = numberOfPages else {
                self.presentAlertController(withMessage: "Couldn't get number of pages")
                return
            }
            
            guard let initialImageInformations = imageInformations else {
                self.presentAlertController(withMessage: "Couldn't get image informations")
                return
            }
            
            // Create a variable that holds the image informations that will be used to
            // download images and set its value to the image informations that were already received
            var imageInformations: [String:URL] = initialImageInformations
            
            if randomPage {
                FlickrClient.shared.getImageInformationsForRandomPage(forLatitude: pin.latitude, andLongitude: pin.longitude, withNumberOfPages: numberOfPages) { (imageInformationsFromRandomPage, errorMessage) in
                    
                    guard errorMessage == nil else {
                        self.presentAlertController(withMessage: errorMessage!)
                        return
                    }
                    
                    guard let imageInformationsFromRandomPage = imageInformationsFromRandomPage else {
                        self.presentAlertController(withMessage: "Couldn't get image informations from random page")
                        return
                    }
                    
                    imageInformations = imageInformationsFromRandomPage

                    DispatchQueue.main.async {
                        self.checkAvailable(imageInformations: imageInformations)
                    }
                    
                    // Check if there are image informations, if there are, iterate over all photos
                    // in the fetched results controller and delete them
                    if imageInformations.count > 0 {
                        CoreDataStack.stack.persistentContainer.viewContext.performAndWait {
                            for photo in self.fetchedResultsController.fetchedObjects! as [Photo] {
                                CoreDataStack.stack.persistentContainer.viewContext.delete(photo)
                                CoreDataStack.stack.save()
                            }
                        }
                        self.numberOfDownloadedImages = 0
                    }
                    
                    // Get all IDs from the image informations and create Photo managed objects from them
                    for (id, _) in imageInformations {
                        CoreDataStack.stack.persistentContainer.viewContext.performAndWait {
                            let photo = Photo(withImageData: nil, andId: id, intoContext: CoreDataStack.stack.persistentContainer.viewContext)
                            photo.pin = pin
                            CoreDataStack.stack.save()
                        }
                    }
                    
                    self.downloadImages(fromImageInformations: imageInformations)
                }
            } else {
                
                DispatchQueue.main.async {
                    self.checkAvailable(imageInformations: imageInformations)
                }
                
                // Check if there are image informations, if there are, iterate over all photos
                // in the fetched results controller and delete them
                if imageInformations.count > 0 {
                    CoreDataStack.stack.persistentContainer.viewContext.performAndWait {
                        for photo in self.fetchedResultsController.fetchedObjects! {
                            CoreDataStack.stack.persistentContainer.viewContext.delete(photo)
                            CoreDataStack.stack.save()
                        }
                    }
                    self.numberOfDownloadedImages = 0
                }
                
                // Get all IDs from the image informations and create Photo managed objects from them
                for (id, _) in imageInformations {
                    CoreDataStack.stack.persistentContainer.viewContext.performAndWait {
                        let photo = Photo(withImageData: nil, andId: id, intoContext: CoreDataStack.stack.persistentContainer.viewContext)
                        photo.pin = pin
                        CoreDataStack.stack.save()
                    }
                }
                self.downloadImages(fromImageInformations: imageInformations)
            }
            
            
            
        }
    }
    
    // This function takes a dictionary (ID String:URL) of image informations as a parameter and tries to download the
    // images' data by looping over all key-value pairs in the dictionary. If data for an image could be downloaded,
    // the imageData property of the photo managed object with the matching image ID should be set
    func downloadImages(fromImageInformations imageInformations: [String:URL]) {
        imageCollectionViewIsDownloading = true
        DispatchQueue.main.async {
            self.loadingCollectionViewActivityIndicatorView.stopAnimating()
        }
        
        for (imageId, imageUrl) in imageInformations {
            FlickrClient.shared.downloadImageData(fromUrl: imageUrl) { (imageData, errorMessage) in
                
                guard errorMessage == nil else {
                    self.presentAlertController(withMessage: errorMessage!)
                    return
                }
                
                guard let imageData = imageData else {
                    self.presentAlertController(withMessage: "Couldn't get image data")
                    return
                }
                
                CoreDataStack.stack.persistentContainer.viewContext.performAndWait {
                // Create a Photo managed object from the image data and ID and insert it into the fetchedResultsController's context
                    if let photo = self.pin.getPhoto(withId: imageId) {
                        photo.imageData = imageData
                        CoreDataStack.stack.save()
                        self.numberOfDownloadedImages += 1
                        if self.numberOfDownloadedImages >= imageInformations.count {
                            self.imageCollectionViewIsDownloading = false
                        }
                    }
                }
            }
        }
    }
}


// MARK: - Helper functions

extension PhotoAlbumViewController {
    // This function takes an image information dictionary, checks the number of items in the dictionary and
    // sets the user interface accordingly
    func checkAvailable(imageInformations: [String:URL]) {
        // If there are no image URLs available a label indicating that no
        // images were found should be displayed
        if imageInformations.count <= 0 {
            // In this app it can be assumed that there is only one section
            if self.imageCollectionView.numberOfItems(inSection: 0) <= 0 {
                self.noImagesFoundLabel.isHidden = false
            }
            self.imageCollectionViewIsDownloading = false
        } else {
            self.noImagesFoundLabel.isHidden = true
        }
    }
    
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
