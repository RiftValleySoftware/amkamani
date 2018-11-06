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
class TheBestClockAlarmView: UIControl {
    /// This holds our state for the alarm we're displaying.
    var alarmRecord: TheBestClockPrefs.TheBestClockAlarmSetting!
    var fontName: String = ""
    var fontColor: UIColor!
    var brightness: CGFloat = 1.0
    var desiredFontSize: CGFloat = 0
    
    @IBOutlet var displayLabel: UILabel!
    
    /* ################################################################## */
    /**
     */
    init(   frame inFrame: CGRect = CGRect.zero,
            alarmRecord inAlarmRecord: TheBestClockPrefs.TheBestClockAlarmSetting,
            fontName inFontName: String,
            fontColor inFontColor: UIColor!,
            brightness inBrightness: CGFloat,
            desiredFontSize inDesiredFontSize: CGFloat
        ) {
        super.init(frame: inFrame)
        
        self.alarmRecord = inAlarmRecord
        self.fontName = inFontName
        self.fontColor = inFontColor
        self.brightness = inBrightness
        self.desiredFontSize = inDesiredFontSize
        self.backgroundColor = UIColor.clear
    }
    
    /* ################################################################## */
    /**
     */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /* ################################################################## */
    /**
     */
    override func layoutSubviews() {
        super.layoutSubviews()
        // First, make sure we don't have any dingleberries.
        for subview in self.subviews {
            subview.removeFromSuperview()
        }
        
        let frame = self.bounds.insetBy(dx: self.bounds.size.width / 40, dy: 0)
        let label = UILabel(frame: frame)
        label.font = UIFont(name: self.fontName, size: frame.size.height)
        label.text = "12:00AM"
        label.adjustsFontSizeToFitWidth = true
        label.textAlignment = .center
        label.baselineAdjustment = .alignCenters
        var textColor: UIColor
        let brightness = self.brightness
        let alpha = CGFloat(self.alarmRecord.isActive ? 1.0 : 0.25)
        
        if nil == self.fontColor {
            textColor = UIColor(white: brightness, alpha: alpha)
        } else {
            textColor = UIColor(hue: self.fontColor.hsba.h, saturation: 1.0, brightness: 1.3 * brightness, alpha: alpha)
        }
        label.textColor = textColor
        
        self.addSubview(label)
    }
}
