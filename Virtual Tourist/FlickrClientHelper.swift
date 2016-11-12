//
//  FlickrClientHelper.swift
//  Virtual Tourist
//
//  Created by Tobias Helmrich on 12.11.16.
//  Copyright © 2016 Tobias Helmrich. All rights reserved.
//

import Foundation

extension FlickrClient {
    // This function creates a Flickr URL by taking a dictionary of parameters
    func createFlickrUrl(fromParameters parameters: [String:Any]) -> URL? {
        
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
    
    func deserializeJson(from data: Data) -> [String:Any]? {
        let jsonObject: [String:Any]
        do {
            jsonObject = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String:Any]
            return jsonObject
        } catch {
            return nil
        }
    }
}
