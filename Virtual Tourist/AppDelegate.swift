//
//  AppDelegate.swift
//  Virtual Tourist
//
//  Created by Tobias Helmrich on 23.10.16.
//  Copyright © 2016 Tobias Helmrich. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Properties
    
    var window: UIWindow?
    let coreDataStack = CoreDataStack()

    
    // MARK: - Functions
    
    func checkIfFirstStart() {
        // Check if it's the app's first start by checking if the a value for the "wasStartedBefore" was set
        if let _ = UserDefaults.standard.value(forKey: "wasStartedBefore") { } else {
            // If it's the first start set initial values for the keys that will be used to set a region
            UserDefaults.standard.setValue(true, forKey: "wasStartedBefore")
            UserDefaults.standard.set(20, forKey: UserDefaultKey.currentCenterLatitude.rawValue)
            UserDefaults.standard.set(20, forKey: UserDefaultKey.currentCenterLongitude.rawValue)
            UserDefaults.standard.set(180, forKey: UserDefaultKey.currentSpanLatitudeDelta.rawValue)
            UserDefaults.standard.set(360, forKey: UserDefaultKey.currentSpanLongitudeDelta.rawValue)
        }
    }

    
    // MARK: - Application methods
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        checkIfFirstStart()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        coreDataStack.save()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        coreDataStack.save()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        coreDataStack.save()
    }


}

