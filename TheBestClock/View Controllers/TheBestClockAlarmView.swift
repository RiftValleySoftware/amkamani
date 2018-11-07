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
    var desiredFontSize: CGFloat = 0 {  // This is the only one to generate a redraw in order to improve efficiency, so always call this last.
        didSet {
            DispatchQueue.main.async {
                self.setNeedsDisplay()
            }
        }
    }
    
    @IBOutlet var displayLabel: UILabel!
    
    /* ################################################################## */
    /**
     */
    init(   frame inFrame: CGRect = CGRect.zero,
            alarmRecord inAlarmRecord: TheBestClockPrefs.TheBestClockAlarmSetting
        ) {
        super.init(frame: inFrame)
        self.alarmRecord = inAlarmRecord
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
        let frame = self.bounds.insetBy(dx: self.bounds.size.width / 40, dy: 0)
        if nil == self.displayLabel {
            self.displayLabel = UILabel(frame: frame)
            self.displayLabel.adjustsFontSizeToFitWidth = true
            self.displayLabel.textAlignment = .center
            self.displayLabel.baselineAdjustment = .alignCenters
            self.displayLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            self.displayLabel.backgroundColor = UIColor.clear
        }
        self.backgroundColor = UIColor.clear
        self.displayLabel.frame = frame
        self.addSubview(self.displayLabel)
    }
    
    /* ################################################################## */
    /**
     */
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.displayLabel.font = UIFont(name: self.fontName, size: self.desiredFontSize)
        self.displayLabel.text = "12:00AM"
        var textColor: UIColor
        let brightness = self.brightness
        var alpha: CGFloat
        
        let activeAlpha = CGFloat(1.0)
        let inactiveAlpha = CGFloat(0.25)
        
        if self.isTracking, self.isHighlighted {
            alpha = self.alarmRecord.isActive ? inactiveAlpha : activeAlpha
        } else {
            alpha = self.alarmRecord.isActive ? activeAlpha : inactiveAlpha
        }
        
        if nil == self.fontColor {
            textColor = UIColor(white: brightness, alpha: alpha)
        } else {
            textColor = UIColor(hue: self.fontColor.hsba.h, saturation: 1.0, brightness: 1.3 * brightness, alpha: alpha)
        }
        self.displayLabel.textColor = textColor
    }
    
    /* ################################################################## */
    /**
     */
    override func beginTracking(_ inTouch: UITouch, with inEvent: UIEvent?) -> Bool {
        let ret = super.beginTracking(inTouch, with: inEvent)
        self.isHighlighted = true

        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }
        
        return ret
    }
    
    /* ################################################################## */
    /**
     */
    override func continueTracking(_ inTouch: UITouch, with inEvent: UIEvent?) -> Bool {
        let touchLocation = inTouch.location(in: self)
        
        self.isHighlighted = self.bounds.contains(touchLocation)

        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }

        return super.continueTracking(inTouch, with: inEvent)
    }
    
    /* ################################################################## */
    /**
     */
    override func endTracking(_ inTouch: UITouch?, with inEvent: UIEvent?) {
        if let touchLocation = inTouch?.location(in: self) {
            if self.bounds.contains(touchLocation) {
                self.alarmRecord.isActive = !self.alarmRecord.isActive
                DispatchQueue.main.async {
                    self.sendActions(for: .valueChanged)
                }
            }
        }
        
        self.isHighlighted = false
        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }
        
        super.endTracking(inTouch, with: inEvent)
    }
    
    /* ################################################################## */
    /**
     */
    override func cancelTracking(with inEvent: UIEvent?) {
        self.isHighlighted = false
        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }
        
        super.cancelTracking(with: inEvent)
    }
}
