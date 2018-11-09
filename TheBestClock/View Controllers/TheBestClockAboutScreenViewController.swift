//
//  TheBestClockAboutScreenViewController.swift
//  TheBestClock
//
//  Created by Chris Marshall on 11/8/18.
//  Copyright © 2018 The Great Rift Valley Software Company. All rights reserved.
//

import UIKit

class TheBestClockAboutScreenViewController: UIViewController {
    @IBOutlet var logoImageControl: TheGreatRiftValleyDrawing!
    var baseColor: UIColor = UIColor.white
    
    override func viewWillAppear(_ animated: Bool) {
        self.logoImageControl.baseColor = self.baseColor
        self.logoImageControl.moonColor = self.baseColor
    }
    
    @IBAction func dismissTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func logoTapped(_ sender: Any) {
    }
}
