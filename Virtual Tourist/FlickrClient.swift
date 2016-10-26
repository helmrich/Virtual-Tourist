//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Tobias Helmrich on 25.10.16.
//  Copyright © 2016 Tobias Helmrich. All rights reserved.
//

import Foundation

class FlickrClient {
    
    // MARK: - Properties
    
    // Create a singleton and make sure that the FlickrClient class can't be instantiated anywhere else
    // by setting its init to the fileprivate access level
    static let shared = FlickrClient()
    fileprivate init() {}
    
    
    // MARK: - Methods
    
    func getImageData(forLatitude latitude: Double, andLongitude longitude: Double, withRadius radius: Double, completionHandlerForImageData: @escaping (_ imageData: [NSData]?, _ errorMessage: String?) -> Void) {
        
        // Set the parameters
        let parameters: [String:Any] = [
            FlickrConstant.ParameterKey.apiKey: FlickrConstant.ParameterValue.apiKey,
            FlickrConstant.ParameterKey.format: FlickrConstant.ParameterValue.jsonFormat,
            FlickrConstant.ParameterKey.noJSONCallback: 1,
            FlickrConstant.ParameterKey.method: FlickrConstant.Method.photosSearch,
            FlickrConstant.ParameterKey.extras: FlickrConstant.ParameterValue.imageMediumUrl,
            FlickrConstant.ParameterKey.photosPerPage: 21,
            FlickrConstant.ParameterKey.lat: latitude,
            FlickrConstant.ParameterKey.lon: longitude,
            FlickrConstant.ParameterKey.radius: radius
        ]
        
        // Get the Flickr URL
        guard let url = createFlickrUrl(fromParameters: parameters) else {
            completionHandlerForImageData(nil, "Couldn't create Flickr URL")
            return
        }
        
        // Create the request
        let request = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            // Check if there was an error
            guard error == nil else {
                completionHandlerForImageData(nil, "Error: \(error!.localizedDescription)")
                return
            }
            
            // Check if the status code implies a successful response
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
                statusCode >= 200 && statusCode <= 299 else {
                    completionHandlerForImageData(nil, "Received unsuccessful status code")
                    return
            }
            
            // Check if data was received
            guard let data = data else {
                completionHandlerForImageData(nil, "No data received")
                return
            }
            
            // Deserialize the received data into a usable JSON object
            let jsonData: [String:Any]
            do {
                jsonData = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
            } catch {
                completionHandlerForImageData(nil, "JSON deserialization error: \(error.localizedDescription)")
                return
            }
            
            // Get the array of photo dictionaries by extracting them from the JSON object
            guard let photos = jsonData[FlickrConstant.JSONResponseKey.photos] as? [String:Any],
            let photoArray = photos[FlickrConstant.JSONResponseKey.photoArray] as? [[String:Any]] else {
                    completionHandlerForImageData(nil, "Error when parsing JSON")
                    return
            }
            
            // Create an empty array of NSData objects and fill it by iterating over all the received image dictionaries
            // and using the images' URL string to create NSData objects from URLs
            var imageData = [NSData]()
            for photo in photoArray {
                guard let currentImageUrlString = photo[FlickrConstant.JSONResponseKey.imageMediumUrl] as? String,
                    let currentImageUrl = URL(string: currentImageUrlString),
                    let currentImageData = NSData(contentsOf: currentImageUrl) else {
                        completionHandlerForImageData(nil, "Couldn't create data for image")
                        return
                }
                
                imageData.append(currentImageData)
                
            }
            
            // Call the completion handler and pass it the image data
            completionHandlerForImageData(imageData, nil)
            
        }
        
        task.resume()
        
    }
    
}


// MARK: - Helper Methods

extension FlickrClient {
    // This function creates a Flickr URL by taking a dictionary of parameters
    fileprivate func createFlickrUrl(fromParameters parameters: [String:Any]) -> URL? {
        
        // Create a URLComponents object and set its properties
        var urlComponents = URLComponents()
        urlComponents.scheme = FlickrConstant.Url.scheme
        urlComponents.host = FlickrConstant.Url.host
        urlComponents.path = FlickrConstant.Url.restApiPath
        
        
        // Create an empty array of URL query items and fill it with all the given parameters
        var queryItems = [URLQueryItem]()
        
        for (parameterKey, parameterValue) in parameters {
            let queryItem = URLQueryItem(name: parameterKey, value: "\(parameterValue)")
            queryItems.append(queryItem)
        }

        urlComponents.queryItems = queryItems
        return urlComponents.url
        
    }
}
