//
//  TravelLocationsMapViewController.swift
//  Virtual Tourist
//
//  Created by Tobias Helmrich on 23.10.16.
//  Copyright © 2016 Tobias Helmrich. All rights reserved.
//

import UIKit
import MapKit

class TravelLocationsMapViewController: UIViewController {

    // MARK: - Properties
    
    
    
    
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
        
    }
    
    
    // MARK: - Functions

    func placeAnnotation(sender: UILongPressGestureRecognizer) {
        // The annotation should be placed on the map only when the long press
        // gesture began, but not when the long press ends
        if sender.state == UIGestureRecognizerState.began {
            let touchPoint = sender.location(in: travelLocationsMapView)
            print(touchPoint)
            let tappedCoordinate = travelLocationsMapView.convert(touchPoint, toCoordinateFrom: travelLocationsMapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = tappedCoordinate
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
        let currentRegion = mapView.region
        print(currentRegion)
        UserDefaults.standard.set(currentRegion.center.latitude, forKey: UserDefaultKey.currentCenterLatitude.rawValue)
        UserDefaults.standard.set(currentRegion.center.longitude, forKey: UserDefaultKey.currentCenterLongitude.rawValue)
        UserDefaults.standard.set(currentRegion.span.latitudeDelta, forKey: UserDefaultKey.currentSpanLatitudeDelta.rawValue)
        UserDefaults.standard.set(currentRegion.span.longitudeDelta, forKey: UserDefaultKey.currentSpanLongitudeDelta.rawValue)
    }
}
