/**
 © Copyright 2018, The Great Rift Valley Software Company. All rights reserved.
 
 This code is proprietary and confidential code,
 It is NOT to be reused or combined into any application,
 unless done so, specifically under written license from The Great Rift Valley Software Company.
 
 The Great Rift Valley Software Company: https://riftvalleysoftware.com
 */

import UIKit

/* ###################################################################################################################################### */
// MARK: - Main Class -
/* ###################################################################################################################################### */
/**
 This is a simple ViewController that manages the only other view controller in the app: The about box.
 */
class TheBestClockAboutScreenViewController: UIViewController {
    private let _urlButtonFontSize: CGFloat = 15
    /// This is the URI for the corporation. It is not localized.
    let corporateURI =   "https://riftvalleysoftware.com/work/ios-apps/amkamani/"
    /// This is the name of the corporation. It is not localized.
    let corporateName =   "The Great Rift Valley Software Company"

    @IBOutlet var logoImageControl: TheGreatRiftValleyDrawing!
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var theURLButton: UIButton!
    @IBOutlet weak var longTextTextarea: UITextView!
    
    var baseColor: UIColor = UIColor.white
    var baseFont: UIFont!
    
    /* ################################################################## */
    /**
     This is called when the image is tapped, or the corporate name button is tapped.
     
     We will call home via Safari.
     
     - parameter: The item that called us. Ignored.
     */
    @IBAction func resolveURL(_: Any! = nil) {
        if let openLink = URL(string: corporateURI) {
            UIApplication.shared.open(openLink, options: [:], completionHandler: nil)
        }
    }
    
    /* ################################################################## */
    /**
     This is called when the user taps around the screen, closing the screen.
     
     - parameter: The item that called us. Ignored.
     */
    @IBAction func dismissTapped(_: Any) {
        self.dismiss(animated: true, completion: nil)
    }

    /* ################################################################## */
    /**
     This is called just prior to appearing.
     The reason that we do much stuff here that would normally be done in viewDidLoad(),
     is because the prepare from the main controller is called after the load, and we
     need to use the data it gives us.
     
     - parameter inAnimated: We ignore this, and pass it up to the superclass.
     */
    override func viewWillAppear(_ inAnimated: Bool) {
        super.viewWillAppear(inAnimated)
        // Set all the items to use our selected color.
        self.logoImageControl.baseColor = self.baseColor
        self.logoImageControl.moonColor = self.baseColor
        self.theURLButton.tintColor = self.baseColor
        self.versionLabel.textColor = self.baseColor
        self.longTextTextarea.textColor = self.baseColor
        // The two labels will also use the selected font. The text area will use the system font.
        self.versionLabel.font = self.baseFont
        self.theURLButton.titleLabel?.font = UIFont(name: self.baseFont.fontName, size: self._urlButtonFontSize)
        // The button label will adjust itself.
        self.theURLButton.titleLabel?.adjustsFontSizeToFitWidth = true

        // We fish the app version from the bundle.
        var appVersion = ""
        var appName = ""

        if let plistPath = Bundle.main.path(forResource: "Info", ofType: "plist") {
            if let plistDictionary = NSDictionary(contentsOfFile: plistPath) as? [String: Any] {
                if let versionTemp = plistDictionary["CFBundleShortVersionString"] as? NSString {
                    appVersion = versionTemp as String
                }
                if let versionTemp = plistDictionary["CFBundleName"] as? NSString {
                    appName = versionTemp as String
                }
            }
        }
        
        // Set up localized text.
        self.theURLButton.setTitle(corporateName, for: .normal)
        self.longTextTextarea.text = self.longTextTextarea.text.localizedVariant
        self.versionLabel.text = appName + " " + appVersion
    }
}
