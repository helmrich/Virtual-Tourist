//
//  TravelLocationsMapViewController.swift
//  Virtual Tourist
//
//  Created by Tobias Helmrich on 23.10.16.
//  Copyright © 2016 Tobias Helmrich. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController {

    // MARK: - Properties
    
    let coreDataStack: CoreDataStack?
    
    // MARK: - Initializers
    
    required init?(coder aDecoder: NSCoder) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        coreDataStack = appDelegate.coreDataStack
        super.init(coder: aDecoder)
    }
    
    
    // MARK: - Outlets and Actions
    
    @IBOutlet weak var travelLocationsMapView: MKMapView!
    
    
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add long press gesture recognizer to map view in order to place an annotation
        // after the user taps the map view with a long tap
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(placeAnnotation))
        travelLocationsMapView.addGestureRecognizer(longPressGestureRecognizer)
        
        setStartRegion()
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        do {
            let pins = try coreDataStack?.context.fetch(fetchRequest) as! [Pin]
            for pin in pins {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                travelLocationsMapView.addAnnotation(annotation)
            }
        } catch {
            print("Error when fetching data from persisting context: \(error)")
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    
    // MARK: - Functions

    func placeAnnotation(sender: UILongPressGestureRecognizer) {
        // The annotation should be placed on the map only when the long press
        // gesture began, but not when the long press ends
        if sender.state == UIGestureRecognizerState.began {
            // Get the point on the travelLocationsMapView that was tapped with a long press
            let touchPoint = sender.location(in: travelLocationsMapView)
            
            // Convert the position of the long press to a coordinate on the travelLocationsMapView and
            // create a point annotation with this coordinate
            let tappedCoordinate = travelLocationsMapView.convert(touchPoint, toCoordinateFrom: travelLocationsMapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = tappedCoordinate
            
            if let coreDataStack = coreDataStack {
                let pin = Pin(withLatitude: annotation.coordinate.latitude, andLongitude: annotation.coordinate.longitude, intoContext: coreDataStack.context)
                coreDataStack.save()
            }
            
            travelLocationsMapView.addAnnotation(annotation)
        }
    }
    
    // This function should be used to set the region of the travelLocationsMapView after starting the application
    // The region could look slightly different compared to how it looked when the app was closed as the "zoom" snaps to the closest "zoom level"
    func setStartRegion() {
        // Get the values needed to create a coordinate and coordinate span from the user defaults
        let startCenterLatitude = UserDefaults.standard.double(forKey: UserDefaultKey.currentCenterLatitude.rawValue)
        let startCenterLongitude = UserDefaults.standard.double(forKey: UserDefaultKey.currentCenterLongitude.rawValue)
        let startSpanLatitudeDelta = UserDefaults.standard.double(forKey: UserDefaultKey.currentSpanLatitudeDelta.rawValue)
        let startSpanLongitudeDelta = UserDefaults.standard.double(forKey: UserDefaultKey.currentSpanLongitudeDelta.rawValue)

        // Create center coordinate and coordinate span
        let centerCoordinate = CLLocationCoordinate2D(latitude: startCenterLatitude, longitude: startCenterLongitude)
        let span = MKCoordinateSpan(latitudeDelta: startSpanLatitudeDelta, longitudeDelta: startSpanLongitudeDelta)
        
        // Create and set the region from the center coordinate and span
        let startRegion = MKCoordinateRegion(center: centerCoordinate, span: span)
        travelLocationsMapView.setRegion(startRegion, animated: false)
    }
    
}

// MARK: - Map View delegate

extension TravelLocationsMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // Every time the region changes (when the user scrolls or zooms for example) the values needed to set a region
        // (center, span) should be set in the user defaults so that the region is the same when the app is started again
        let currentRegion = mapView.region
        UserDefaults.standard.set(currentRegion.center.latitude, forKey: UserDefaultKey.currentCenterLatitude.rawValue)
        UserDefaults.standard.set(currentRegion.center.longitude, forKey: UserDefaultKey.currentCenterLongitude.rawValue)
        UserDefaults.standard.set(currentRegion.span.latitudeDelta, forKey: UserDefaultKey.currentSpanLatitudeDelta.rawValue)
        UserDefaults.standard.set(currentRegion.span.longitudeDelta, forKey: UserDefaultKey.currentSpanLongitudeDelta.rawValue)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        // Get the tapped annotation view's annotation
        guard let annotation = view.annotation else {
            print("Tapped annotation view doesn't have an annotation")
            return
        }
        
        let photoAlbumViewController = storyboard?.instantiateViewController(withIdentifier: "photoAlbumViewController") as! PhotoAlbumViewController
        photoAlbumViewController.annotation = annotation
        
        // Deselect the selected annotation before the photo album view controller gets pushed on the navigation controller's stack
        // so that the same annotation can be selected again after the user goes back to the TravelLocationsMapViewController
        travelLocationsMapView.deselectAnnotation(annotation, animated: true)
        
        navigationController?.pushViewController(photoAlbumViewController, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "pin") else {
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            let pinImage = UIImage(named: "VTPin")
            let pinImageSize = CGSize(width: 30, height: 40)
            UIGraphicsBeginImageContext(pinImageSize)
            pinImage!.draw(in: CGRect(x: 0, y: 0, width: pinImageSize.width, height: pinImageSize.height))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            annotationView.image = resizedImage
            annotationView.centerOffset = CGPoint(x: 0, y: -(pinImageSize.height / 2))
            return annotationView
        }
        
        return annotationView
        
    }
    
}
