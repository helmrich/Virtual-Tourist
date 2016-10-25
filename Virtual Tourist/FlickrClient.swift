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
    
    
    
}


// MARK: - Helper Methods

extension FlickrClient {
    func createFlickrUrl(fromParameters parameters: [String:Any]) -> URL? {
        var urlComponents = URLComponents()
        urlComponents.scheme = FlickrConstant.Url.scheme
        urlComponents.host = FlickrConstant.Url.host
        urlComponents.path = FlickrConstant.Url.restApiPath
        
        var queryItems = [URLQueryItem]()
        
        for (parameterKey, parameterValue) in parameters {
            let queryItem = URLQueryItem(name: parameterKey, value: "\(parameterValue)")
            queryItems.append(queryItem)
        }
        
        urlComponents.queryItems = queryItems
        
        return urlComponents.url
        
    }
}
