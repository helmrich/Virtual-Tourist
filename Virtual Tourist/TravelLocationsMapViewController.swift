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
    
    // This property keeps track of whether the pins on the map should be
    // deleted when they're tapped or not
    var isInDeleteMode = false
    
    
    // MARK: - Outlets and Actions
    
    @IBOutlet weak var travelLocationsMapView: MKMapView!
    @IBOutlet weak var deleteInformationLabel: UILabel!
    
    @IBAction func toggleDeleteMode() {
        // Reverse isInDeleteMode's value, set the visibility of the deleteInformationLabel and
        // the right bar button item depending on its value
        isInDeleteMode = !isInDeleteMode
        deleteInformationLabel.isHidden = !isInDeleteMode
        if isInDeleteMode {
            navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(toggleDeleteMode))
        } else {
            navigationController?.navigationBar.topItem?.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(toggleDeleteMode))
        }
    }
    
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add a long press gesture recognizer to the map view in order to place an annotation
        // on the map after the user taps the map view with a long tap
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(placeAnnotation))
        travelLocationsMapView.addGestureRecognizer(longPressGestureRecognizer)
        
        // Set the map's region
        setStartRegion()
        
        // Get all pins from the view context and place them on the travel locations map view
        let fetchRequest = NSFetchRequest<Pin>(entityName: "Pin")
        do {
            let pins = try CoreDataStack.stack.persistentContainer.viewContext.fetch(fetchRequest)
            for pin in pins {
                let annotation = MKPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude)
                travelLocationsMapView.addAnnotation(annotation)
            }
        } catch {
            print("Error when fetching pins from persisting context: \(error)")
        }
        
    }
    
    // MARK: - Functions

    func placeAnnotation(sender: UILongPressGestureRecognizer) {
        // The annotation should be placed on the map only when the long press
        // gesture began, but not when the long press ends
        if sender.state == UIGestureRecognizerState.began && !isInDeleteMode {
            // Get the point on the travelLocationsMapView that was tapped with a long press
            let touchPoint = sender.location(in: travelLocationsMapView)
            
            // Convert the position of the long press to a coordinate on the travelLocationsMapView,
            // create a point annotation with this coordinate,
            let tappedCoordinate = travelLocationsMapView.convert(touchPoint, toCoordinateFrom: travelLocationsMapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = tappedCoordinate
            
            // add the annotation to the map view,
            travelLocationsMapView.addAnnotation(annotation)
            
            // create a Pin object with the annotation's coordinate and save the context
            let _ = Pin(withLatitude: annotation.coordinate.latitude, andLongitude: annotation.coordinate.longitude, intoContext: CoreDataStack.stack.persistentContainer.viewContext)
            CoreDataStack.stack.save()
        }
    }
    
    // This function should be used to set the region of the travelLocationsMapView
    // after starting the application
    // Note: The region could look slightly different compared to how it looked when
    // the app was closed as the "zoom" snaps to the closest "zoom level"
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
