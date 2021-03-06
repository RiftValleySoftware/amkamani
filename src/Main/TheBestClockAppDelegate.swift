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
    /// This is a special variable that holds the screen brightness level from just before we first change it from the app. We will use this to restore the original screen brightness.
    static var originalScreenBrightness: CGFloat!
    
    /// This refers to the main controller
    var theMainController: MainScreenViewController!
    /// Used to possibly force orientation for the Alarm Editor Screen.
    var orientationLock = UIInterfaceOrientationMask.all
    /// This is the required app window object.
    var window: UIWindow?

    /* ##################################################################################################################################*/
    /**
     This returns the application delegate object. Nil if an error (should never happen).
     */
    class var delegateObject: TheBestClockAppDelegate! {
        precondition(UIApplication.shared.delegate is TheBestClockAppDelegate)
        return UIApplication.shared.delegate as? TheBestClockAppDelegate
    }
    
    /* ################################################################## */
    /**
     This is a class function to display an error.
     
     - parameter heading: The heading. It will be localized.
     - parameter text: Detailed text to be displayed under the heading. It, too, will be localized.
     - parameter presentedBy: The presenting ViewController. It can be omitted. If nil (omitted), the alert will use whatever top controller the app delegate can find.
     */
    class func reportError(heading inHeadingKey: String, text inDetailedTextKey: String, presentedBy inPresentingViewController: UIViewController! = nil) {
        DispatchQueue.main.async {
            var presentedBy = inPresentingViewController
            
            if nil == presentedBy {
                if let navController = delegateObject.window?.rootViewController as? UINavigationController {
                    presentedBy = navController.topViewController
                } else {
                    if let tabController = delegateObject.window?.rootViewController as? UITabBarController {
                        if let navController = tabController.selectedViewController as? UINavigationController {
                            presentedBy = navController.topViewController
                        } else {
                            presentedBy = tabController.selectedViewController
                        }
                    } else {
                        presentedBy = delegateObject.window?.rootViewController
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
     If the brightness level has not already been recorded, we do so now.
     */
    class func recordOriginalBrightness() {
        if nil == originalScreenBrightness {
            originalScreenBrightness = UIScreen.main.brightness
            assert(0 <= originalScreenBrightness && 1.0 >= originalScreenBrightness)
        }
        
        // If the app had backgrounded while an editor was open, then the screen brightness needs to go all the way up again.
        if let mainController = delegateObject.theMainController, -1 < mainController.currentlyEditingAlarmIndex || !mainController.mainPickerContainerView.isHidden {
            UIScreen.main.brightness = 1.0
        }
    }
    
    /* ################################################################## */
    /**
     This restores our recorded brightness level to the screen.
     */
    class func restoreOriginalBrightness() {
        if nil != originalScreenBrightness {
            assert(0 <= originalScreenBrightness && 1.0 >= originalScreenBrightness)
            UIScreen.main.brightness = originalScreenBrightness
            originalScreenBrightness = nil
        }
    }
    
    /* ################################################################## */
    /**
     This will force the screen to ignore the accelerometer setting.
     
     - parameter orientation: The orientation that should be locked.
     */
    class func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        delegateObject.orientationLock = orientation
    }
    
    /* ################################################################## */
    /**
     This will force the screen to ignore the accelerometer setting and force the screen into that orientation.
     
     - parameter orientation: The orientation that should be locked.
     - parameter andRotateTo: The orientation that should be forced.
     */
    class func lockOrientation(_ orientation: UIInterfaceOrientationMask, andRotateTo rotateOrientation: UIInterfaceOrientation) {
        lockOrientation(orientation)
        UIDevice.current.setValue(rotateOrientation.rawValue, forKey: "orientation")
    }

    /* ################################################################## */
    /**
     */
    func applicationDidFinishLaunching(_ application: UIApplication) {
        Self.recordOriginalBrightness()
        TheBestClockPrefs.registerDefaults()
    }
    
    /* ################################################################## */
    /**
     We force the main controller to lay out its subviews, which will restore its internal brightness level.
     */
    func applicationDidBecomeActive(_ application: UIApplication) {
        Self.recordOriginalBrightness()
        UIApplication.shared.isIdleTimerDisabled = true // This makes sure that we stay awake while this window is up.
        theMainController.startTicker()
        theMainController.view.setNeedsLayout()
    }

    /* ################################################################## */
    /**
     We force the main controller to lay out its subviews, which will restore its internal brightness level.
     */
    func applicationWillEnterForeground(_ application: UIApplication) {
        Self.recordOriginalBrightness()
        UIApplication.shared.isIdleTimerDisabled = true // This makes sure that we stay awake while this window is up.
        theMainController.startTicker()
        theMainController.view.setNeedsLayout()
    }

    /* ################################################################## */
    /**
     We restore the screen to its original recorded level.
     */
    func applicationWillTerminate(_ application: UIApplication) {
        UIApplication.shared.isIdleTimerDisabled = false // Put things back the way we found them.
        theMainController.turnOffDeactivations()
        theMainController.stopTicker()
        theMainController.stopAudioPlayer()
        Self.restoreOriginalBrightness()
    }
    
    /* ################################################################## */
    /**
     We restore the screen to its original recorded level.
     */
    func applicationWillResignActive(_ application: UIApplication) {
        UIApplication.shared.isIdleTimerDisabled = false // Put things back the way we found them.
        theMainController.turnOffDeactivations()
        theMainController.stopTicker()
        theMainController.stopAudioPlayer()
        Self.restoreOriginalBrightness()
    }

    /* ################################################################## */
    /**
     We restore the screen to its original recorded level.
     */
    func applicationDidEnterBackground(_ application: UIApplication) {
        UIApplication.shared.isIdleTimerDisabled = false // Put things back the way we found them.
        theMainController.stopTicker()
        theMainController.stopAudioPlayer()
        Self.restoreOriginalBrightness()
    }
}
