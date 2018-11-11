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
 */
@UIApplicationMain
class TheBestClockAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    /* ##################################################################################################################################*/
    /**
     This returns the application delegate object.
     */
    class var delegateObject: TheBestClockAppDelegate {
        return (UIApplication.shared.delegate as? TheBestClockAppDelegate)!
    }
    
    /* ################################################################## */
    /**
     */
    class func reportError(heading inHeadingKey: String, text inDetailedTextKey: String, presentedBy inPresentingViewController: UIViewController! = nil) {
        DispatchQueue.main.async {
            var presentedBy = inPresentingViewController
            
            if nil == presentedBy {
                if let navController = self.delegateObject.window?.rootViewController as? UINavigationController {
                    presentedBy = navController.topViewController
                } else {
                    if let tabController = self.delegateObject.window?.rootViewController as? UITabBarController {
                        if let navController = tabController.selectedViewController as? UINavigationController {
                            presentedBy = navController.topViewController
                        } else {
                            presentedBy = tabController.selectedViewController
                        }
                    } else {
                        presentedBy = self.delegateObject.window?.rootViewController
                    }
                }
            }
            
            if nil != presentedBy {
                let alertController = UIAlertController(title: inHeadingKey.localizedVariant, message: inDetailedTextKey.localizedVariant, preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "BASIC-OK-BUTTON".localizedVariant, style: UIAlertAction.Style.cancel, handler: nil)
                
                alertController.addAction(okAction)
                
                presentedBy?.present(alertController, animated: true, completion: nil)
            }
        }
    }
}
