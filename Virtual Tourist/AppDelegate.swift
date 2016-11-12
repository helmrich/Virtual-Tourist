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

    
    // MARK: - Functions
    
    func checkIfFirstStart() {
        // Check if it's the app's first start by checking if a value for the "wasStartedBefore" key was set
        // in the user defaults
        guard let _ = UserDefaults.standard.value(forKey: "wasStartedBefore") else {
            // If it's the first start set initial values for the keys in the user defaults
            // that will be used to set a region
            UserDefaults.standard.setValue(true, forKey: "wasStartedBefore")
            UserDefaults.standard.set(20, forKey: UserDefaultKey.currentCenterLatitude.rawValue)
            UserDefaults.standard.set(20, forKey: UserDefaultKey.currentCenterLongitude.rawValue)
            UserDefaults.standard.set(180, forKey: UserDefaultKey.currentSpanLatitudeDelta.rawValue)
            UserDefaults.standard.set(360, forKey: UserDefaultKey.currentSpanLongitudeDelta.rawValue)
            return
        }
    }

    
    // MARK: - Application methods
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        checkIfFirstStart()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        CoreDataStack.shared.save()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        CoreDataStack.shared.save()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        CoreDataStack.shared.save()
    }
}

