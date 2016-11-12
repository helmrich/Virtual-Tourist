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
    var insertedIndexPaths: [IndexPath]!
    var updatedIndexPaths: [IndexPath]!
    var deletedIndexPaths: [IndexPath]!
    var selectedIndexPaths = [IndexPath]() {
        didSet {
            // If there are selected photos, the button's appearance should change
            // to show that the selected photos can be removed from the album
            if selectedIndexPaths.count > 0 {
                toggleNewAlbumButton(delete: true)
            } else {
                toggleNewAlbumButton(delete: false)
            }
        }
    }
    
    var imagesAreBeingDownloaded = false {
        didSet {
            DispatchQueue.main.async {
                self.imageCollectionView.allowsSelection = !self.imagesAreBeingDownloaded
                self.imageCollectionView.allowsMultipleSelection = !self.imagesAreBeingDownloaded
                self.loadNewAlbumButton.isEnabled = !self.imagesAreBeingDownloaded
            }
        }
    }
    
    var annotation: MKAnnotation? {
        // When the annotation property is set try to get a pin managed
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
        // Check whether a new photo album should be loaded or if selected images should be deleted
        // by checking the button's title
        if loadNewAlbumButton.title! == "Load New Album" {
            imagesAreBeingDownloaded = true
            getNewPhotos(fromRandomPage: true)
        } else if loadNewAlbumButton.title! == "Remove Selected Images" {
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
        
        loadingCollectionViewActivityIndicatorView.startAnimating()
        imagesAreBeingDownloaded = true
        
        // Check if the photo album view controller has an annotation
        if let annotation = annotation {
            // Add the annotation to the photo album view controller's map view and
            // set the region with the annotation's coordinate as a center
            mapView.addAnnotation(annotation)
            let region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, 1000, 1000)
            mapView.setRegion(region, animated: true)
            
            // Try to get the pin's photos and check if there are any
            // photos associated to the pin already...
            if let photos = pin.getAllPhotos(),
                photos.count > 0 {
                loadingCollectionViewActivityIndicatorView.stopAnimating()
                imagesAreBeingDownloaded = false
            } else {
                // If there are no photos associated with the pin get new images
                getNewPhotos()
            }
        }
    }
    
}


// MARK: - Functions

extension PhotoAlbumViewController {
    // Get image informations for the pin's coordinate, if there are image URLs, download
    // the data for all images, create a Photo object for each image and add it to the pin
    func getNewPhotos(fromRandomPage randomPage: Bool = false) {
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
            
            // If image informations should be requested from a random page
            // make another request to Flickr but with the FlickrClient's method
            // that gets images from a random page. If the image informations
            // shouldn't come from a random page, take the initial image informations
            // that were received from the first request
            if randomPage {
                FlickrClient.shared.getImageInformationsForRandomPage(forLatitude: self.pin.latitude, andLongitude: self.pin.longitude, withNumberOfPages: numberOfPages) { (imageInformationsFromRandomPage, errorMessage) in
                    
                    guard errorMessage == nil else {
                        self.presentAlertController(withMessage: errorMessage!)
                        return
                    }
                    
                    guard let imageInformationsFromRandomPage = imageInformationsFromRandomPage else {
                        self.presentAlertController(withMessage: "Couldn't get image informations from random page")
                        return
                    }

                    self.preparePhotos(withImageInformations: imageInformationsFromRandomPage)
                    self.downloadPhotos(fromImageInformations: imageInformationsFromRandomPage)
                }
            } else {
                self.preparePhotos(withImageInformations: initialImageInformations)
                self.downloadPhotos(fromImageInformations: initialImageInformations)
            }
        }
    }
    
    // This function "prepares photos" by taking a dictionary with image
    // informations as a parameter and sets up the interface depending on the
    // number of image informations that are available.
    
    // If there are existing photos it also deletes all the photos from the
    // managed object context in order to empty the collection view before
    // filling it with new photos.
    
    // After that it iterates over all the image IDs in the imageInformations
    // dictionary and creates photo objects from them. The imageData will
    // be set to nil initially as it will be filled with data later, when
    // the data is actually downloaded.
    func preparePhotos(withImageInformations imageInformations: [String:URL]) {
        DispatchQueue.main.async {
            self.checkAvailable(imageInformations: imageInformations)
        }
        
        // Deletion of old photos
        if imageInformations.count > 0 {
            CoreDataStack.stack.persistentContainer.viewContext.performAndWait {
                for photo in self.fetchedResultsController.fetchedObjects! {
                    CoreDataStack.stack.persistentContainer.viewContext.delete(photo)
                    CoreDataStack.stack.save()
                }
            }
            self.numberOfDownloadedImages = 0
        }
        
        // Creation of new photos
        for (id, _) in imageInformations {
            CoreDataStack.stack.persistentContainer.viewContext.performAndWait {
                let photo = Photo(withImageData: nil, andId: id, intoContext: CoreDataStack.stack.persistentContainer.viewContext)
                photo.pin = self.pin
                CoreDataStack.stack.save()
            }
        }
    }
    
    // This function takes a dictionary (ID String:URL) of image informations
    // as a parameter and tries to download the images' data by looping over all
    // key-value pairs in the dictionary. If data for an image could be downloaded,
    // the imageData property of the photo managed object with the matching
    // image ID should be set
    func downloadPhotos(fromImageInformations imageInformations: [String:URL]) {
        imagesAreBeingDownloaded = true
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
                    if let photo = self.pin.getPhoto(withId: imageId) {
                        photo.imageData = imageData
                        CoreDataStack.stack.save()
                        self.numberOfDownloadedImages += 1
                        if self.numberOfDownloadedImages >= imageInformations.count {
                            self.imagesAreBeingDownloaded = false
                        }
                    }
                }
            }
        }
    }
}


// MARK: - Helper functions

extension PhotoAlbumViewController {
    // This function takes an image information dictionary, checks the number
    // of items in the dictionary and sets the user interface
    func checkAvailable(imageInformations: [String:URL]) {
        // If there are no image URLs available a label indicating that no
        // images were found should be displayed
        if imageInformations.count <= 0 {
            // In this app it can be assumed that there is only one section
            if self.imageCollectionView.numberOfItems(inSection: 0) <= 0 {
                // Show a label that indicates that no images were found
                self.noImagesFoundLabel.isHidden = false
            }
            self.imagesAreBeingDownloaded = false
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
