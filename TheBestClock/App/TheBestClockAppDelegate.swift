/**
 © Copyright 2018, The Great Rift Valley Software Company. All rights reserved.
 
 This code is proprietary and confidential code,
 It is NOT to be reused or combined into any application,
 unless done so, specifically under written license from The Great Rift Valley Software Company.
 
 The Great Rift Valley Software Company: https://riftvalleysoftware.com
 */

import UIKit

/* ###################################################################################################################################### */
// MARK: - Extensions -
/* ###################################################################################################################################### */
/**
 */
extension String {
    /* ################################################################## */
    /**
     - returns: the localized string (main bundle) for this string.
     */
    var localizedVariant: String {
        return NSLocalizedString(self, comment: "")
    }

    /* ################################################################## */
    /**
     This extension lets us uppercase only the first letter of the string (used for weekdays).
     From here: https://stackoverflow.com/a/28288340/879365
     
     - returns: The string, with only the first letter uppercased.
     */
    var firstUppercased: String {
        guard let first = first else { return "" }
        return String(first).uppercased() + dropFirst()
    }
}

/* ###################################################################################################################################### */
/**
 */
extension UIView {
    /* ################################################################## */
    /**
     */
    func addContainedView(_ inSubView: UIView) {
        self.addSubview(inSubView)
        
        inSubView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addConstraints([
            NSLayoutConstraint(item: inSubView,
                               attribute: .top,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .top,
                               multiplier: 1.0,
                               constant: 0),
            NSLayoutConstraint(item: inSubView,
                               attribute: .left,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .left,
                               multiplier: 1.0,
                               constant: 0),
            NSLayoutConstraint(item: inSubView,
                               attribute: .bottom,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .bottom,
                               multiplier: 1.0,
                               constant: 0),
            NSLayoutConstraint(item: inSubView,
                               attribute: .right,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .right,
                               multiplier: 1.0,
                               constant: 0)])
    }
    
    /* ################################################################## */
    /**
     - returns: the first responder view. Nil, if no view is a first responder.
     */
    var currentFirstResponder: UIResponder! {
        if self.isFirstResponder {
            return self
        }
        
        for view in self.subviews {
            if let responder = view.currentFirstResponder {
                return responder
            }
        }
        
        return nil
    }
}

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

    /* ################################################################## */
    /**
     */
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    /* ################################################################## */
    /**
     */
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    /* ################################################################## */
    /**
     */
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    /* ################################################################## */
    /**
     */
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    /* ################################################################## */
    /**
     */
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    /* ################################################################## */
    /**
     */
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}
