/**
 © Copyright 2018, The Great Rift Valley Software Company. All rights reserved.
 
 This code is proprietary and confidential code,
 It is NOT to be reused or combined into any application,
 unless done so, specifically under written license from The Great Rift Valley Software Company.
 
 The Great Rift Valley Software Company: https://riftvalleysoftware.com
 */

import UIKit

protocol TheBestClockAlarmViewDelegate: class {
    /* ################################################################## */
    /**
     This will be called to open the alarm editor if the button is activated.
     */
    func openAlarmEditor(_ alarmIndex: Int)
}

/* ###################################################################################################################################### */
// MARK: - Main Class -
/* ###################################################################################################################################### */
/**
 */
class TheBestClockAlarmView: UIControl {
    weak var delegate: TheBestClockAlarmViewDelegate!
    var index: Int = 0
    /// This holds our state for the alarm we're displaying.
    var alarmRecord: TheBestClockAlarmSetting!
    var fontName: String = ""
    var fontColor: UIColor!
    var brightness: CGFloat = 1.0
    /// This is set to true while the Alarm Editor is up. It tells us to ignore the set brightness, and display an active alarm as 1.0.
    var fullBright: Bool = false
    var desiredFontSize: CGFloat = 0 {  // This is the only one to generate a redraw in order to improve efficiency, so always call this last.
        didSet {
            DispatchQueue.main.async {
                self.setNeedsDisplay()
            }
        }
    }
    
    @IBOutlet var displayLabel: UILabel!
    var longPressGestureRecognizer: UILongPressGestureRecognizer!
    
    /* ################################################################## */
    /**
     */
    init(   frame inFrame: CGRect = CGRect.zero,
            alarmRecord inAlarmRecord: TheBestClockAlarmSetting
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
        
        if nil == self.longPressGestureRecognizer {
            self.longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(type(of: self).longPressGesture(_:)))
            self.addGestureRecognizer(self.longPressGestureRecognizer)
        }

        self.displayLabel.accessibilityHint = "LOCAL-ACCESSIBILITY-ALARM-CONTAINER-HINT".localizedVariant
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
        self.displayLabel.text = ""
        var textColor: UIColor
        let brightness = self.fullBright ? 1.0 : self.brightness
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
            textColor = UIColor(hue: self.fontColor.hsba.h, saturation: 1.0, brightness: brightness, alpha: alpha)
        }
        
        let time = self.alarmRecord.alarmTime
        let hours = time / 100
        let minutes = time - (hours * 100)
        
        var dateComponents = DateComponents()
        dateComponents.hour = hours
        dateComponents.minute = minutes
        
        let userCalendar = Calendar.current
        if let pickerDate = userCalendar.date(from: dateComponents) {
            let dateFormatter = DateFormatter()
            dateFormatter.timeStyle = .short
            dateFormatter.dateStyle = .none
            
            self.displayLabel.text = dateFormatter.string(from: pickerDate)
        }
        
        if let displayText = self.displayLabel?.text {
            self.displayLabel.accessibilityLabel = displayText + ". " + ("LOCAL-ACCESSIBILITY-ALARM-CONTAINER-O" + (self.alarmRecord.isActive ? "N" : "FF")).localizedVariant
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
                if !self.alarmRecord.isActive {
                    self.alarmRecord.snoozing = false
                }
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
    
    /* ################################################################## */
    /**
     */
    @IBAction func longPressGesture(_ inGestureRecognizer: UILongPressGestureRecognizer) {
        self.delegate?.openAlarmEditor(self.index)
    }
    
    /* ################################################################## */
    /**
     */
    func snore() {
        let oldAlpha = self.displayLabel.alpha
        self.displayLabel.alpha = 0.125
        UIView.animate(withDuration: 0.75,
                       delay: 0,
                       usingSpringWithDamping: 1.0,
                       initialSpringVelocity: 0,
                       options: .allowUserInteraction,
                       animations: { [unowned self, oldAlpha] in
                        self.displayLabel.alpha = oldAlpha
            }, completion: nil)
    }
}
