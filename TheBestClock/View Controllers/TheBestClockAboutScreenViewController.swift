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
    @IBOutlet weak var versionLabel: UILabel!
    var baseColor: UIColor = UIColor.white
    var baseFont: UIFont!
    
    override func viewWillAppear(_ animated: Bool) {
        self.logoImageControl.baseColor = self.baseColor
        self.logoImageControl.moonColor = self.baseColor
        var appVersion = ""
        
        if let plistPath = Bundle.main.path(forResource: "Info", ofType: "plist") {
            if let plistDictionary = NSDictionary(contentsOfFile: plistPath) as? [String: Any] {
                if let versionTemp = plistDictionary["CFBundleShortVersionString"] as? NSString {
                    appVersion = versionTemp as String
                }
            }
        }
        
        self.versionLabel.font = self.baseFont
        self.versionLabel.textColor = self.baseColor
        self.versionLabel.text = "LOCAL-APP-NAME".localizedVariant + " " + appVersion
    }
    
    @IBAction func dismissTapped(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func logoTapped(_ sender: Any) {
    }
}
