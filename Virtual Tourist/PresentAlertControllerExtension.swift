//
//  PresentAlertControllerExtension.swift
//  Virtual Tourist
//
//  Created by Tobias Helmrich on 07.11.16.
//  Copyright © 2016 Tobias Helmrich. All rights reserved.
//

import UIKit

extension UIViewController {
    func presentAlertController(withMessage message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
