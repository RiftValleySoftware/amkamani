/**
 © Copyright 2018, The Great Rift Valley Software Company. All rights reserved.
 
 This code is proprietary and confidential code,
 It is NOT to be reused or combined into any application,
 unless done so, specifically under written license from The Great Rift Valley Software Company.
 
 The Great Rift Valley Software Company: https://riftvalleysoftware.com
 */

import UIKit
import RVS_Generic_Swift_Toolbox

/* ###################################################################################################################################### */
// MARK: - Main Class -
/* ###################################################################################################################################### */
/**
 This is a simple ViewController that manages the only other view controller in the app: The about box.
 */
class TheBestClockAboutScreenViewController: UIViewController {
    /// The size of the font we use for the URL button
    private let _urlButtonFontSize: CGFloat = 15
    /// This is the URI for the corporation. It is not localized.
    let corporateURI =   "https://riftvalleysoftware.com/work/ios-apps/amkamani/"
    /// This is the name of the corporation. It is not localized.
    let corporateName =   "The Great Rift Valley Software Company"

    ///  The big logo that takes the user to the Web site
    @IBOutlet var logoImageControl: TheGreatRiftValleyDrawing!
    /// The label for the version display
    @IBOutlet weak var versionLabel: UILabel!
    /// The button for the corporate URL display
    @IBOutlet weak var theURLButton: UIButton!
    /// The area where the long text is shown
    @IBOutlet weak var longTextTextarea: UITextView!
    
    /// The base color for the display
    var baseColor: UIColor = UIColor.white
    /// The base font for the display
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
        dismiss(animated: true, completion: nil)
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
        logoImageControl.baseColor = baseColor
        logoImageControl.moonColor = baseColor
        theURLButton.tintColor = baseColor
        versionLabel.textColor = baseColor
        longTextTextarea.textColor = baseColor
        // The two labels will also use the selected font. The text area will use the system font.
        versionLabel.font = baseFont
        theURLButton.titleLabel?.font = UIFont(name: baseFont.fontName, size: _urlButtonFontSize)
        // The button label will adjust it
        theURLButton.titleLabel?.adjustsFontSizeToFitWidth = true

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
        theURLButton.setTitle(corporateName, for: .normal)
        longTextTextarea.text = longTextTextarea.text.localizedVariant
        versionLabel.text = appName + " " + appVersion
    }
}
