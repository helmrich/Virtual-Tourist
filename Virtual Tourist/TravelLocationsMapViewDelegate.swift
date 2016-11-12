//
//  TravelLocationsMapViewDelegate.swift
//  Virtual Tourist
//
//  Created by Tobias Helmrich on 07.11.16.
//  Copyright © 2016 Tobias Helmrich. All rights reserved.
//

import MapKit

extension TravelLocationsMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        // Every time the region changes (when the user scrolls or zooms for example)
        // the values needed to set a region (center, span) should be set in the user
        // defaults so that the region is the same when the app is started again
        let currentRegion = mapView.region
        UserDefaults.standard.set(currentRegion.center.latitude, forKey: UserDefaultKey.currentCenterLatitude.rawValue)
        UserDefaults.standard.set(currentRegion.center.longitude, forKey: UserDefaultKey.currentCenterLongitude.rawValue)
        UserDefaults.standard.set(currentRegion.span.latitudeDelta, forKey: UserDefaultKey.currentSpanLatitudeDelta.rawValue)
        UserDefaults.standard.set(currentRegion.span.longitudeDelta, forKey: UserDefaultKey.currentSpanLongitudeDelta.rawValue)
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        // Get the tapped annotation view's annotation
        guard let annotation = view.annotation else {
            self.presentAlertController(withMessage: "Tapped annotation view doesn't have an annotation")
            return
        }
        
        // Check if the view controller is not in delete mode
        guard !isInDeleteMode else {
            // if it is, remove the annotation from the map view and delete the pin at the
            // annotation's coordinate from Core Data
            mapView.removeAnnotation(annotation)
            CoreDataStack.shared.deletePin(forLatitude: annotation.coordinate.latitude, andLongitude: annotation.coordinate.longitude)
            return
        }
        
        // Instantiate a photo album view controller from the storyboard and pass it the selected annotation view's annotation
        let photoAlbumViewController = storyboard?.instantiateViewController(withIdentifier: "photoAlbumViewController") as! PhotoAlbumViewController
        photoAlbumViewController.annotation = annotation
        
        // Deselect the selected annotation before the photo album view controller gets pushed on the navigation controller's stack
        // so that the same annotation can be selected again after the user goes back to the TravelLocationsMapViewController
        travelLocationsMapView.deselectAnnotation(annotation, animated: true)
        
        navigationController?.pushViewController(photoAlbumViewController, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Check if a reusable annotation view with the "pin" identifier can be dequeued from the map view
        guard let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "pin") else {
            // If not, create an annotation view with the "pin" reuse identifier,
            let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "pin")
            
            // Get the custom pin image
            let pinImage = #imageLiteral(resourceName: "VTPin")
            
            // Set the annotation view's image property to the custom image and set
            // a center offset with a y-value of negative the half of the pin image's
            // height so that the bottom of the image points to the annotation view's
            // coordinate
            annotationView.image = pinImage
            annotationView.centerOffset = CGPoint(x: 0, y: -(pinImage.size.height / 2))
            return annotationView
        }
        
        return annotationView
        
    }
    
}
