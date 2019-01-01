/**
 © Copyright 2018, The Great Rift Valley Software Company. All rights reserved.
 
 This code is proprietary and confidential code,
 It is NOT to be reused or combined into any application,
 unless done so, specifically under written license from The Great Rift Valley Software Company.
 
 The Great Rift Valley Software Company: https://riftvalleysoftware.com
 */

import UIKit

/* ###################################################################################################################################### */
// MARK: - Delegate -
/* ###################################################################################################################################### */
/**
 The delegate is very simple. We just call it to open the alarm editor.
 */
protocol TheBestClockAlarmViewDelegate: class {
    /* ################################################################## */
    /**
     This will be called to open the alarm editor if the button is activated.
     
     - parameter alarmIndex: The 0-based index of the alarm to be edited (0-2).
     */
    func openAlarmEditor(_ alarmIndex: Int)
}

/* ###################################################################################################################################### */
// MARK: - Main Class -
/* ###################################################################################################################################### */
/**
 This is the view class for each alarm button. It is a button with a label in it. The label contains the alarm time and state.
 
 It has a pulsing "snore" for sleeping.
 */
class TheBestClockAlarmView: UIControl {
    /// Our delegate
    weak var delegate: TheBestClockAlarmViewDelegate!
    /// Which alarm this is. 0-based index.
    var index: Int = 0
    /// This holds our state for the alarm we're displaying.
    var alarmRecord: TheBestClockAlarmSetting!
    /// The name of the font to be used for the alarm display.
    var fontName: String = ""
    /// The color to display the alarm.
    var fontColor: UIColor!
    /// The brightness to use for active alarm display.
    var brightness: CGFloat = 1.0
    /// This is set to true while the Alarm Editor is up. It tells us to ignore the set brightness, and display an active alarm as 1.0.
    var fullBright: Bool = false
    /// This is the gesture recognizer we use to detect a long-press.
    var longPressGestureRecognizer: UILongPressGestureRecognizer!
    /// This is the size we want the display to be.
    var desiredFontSize: CGFloat = 0 {  // This is the only one to generate a redraw in order to improve efficiency, so always call this last.
        didSet {
            DispatchQueue.main.async {
                self.setNeedsDisplay()
            }
        }
    }
    
    /// This is the label object for the alarm.
    @IBOutlet var displayLabel: UILabel!
    
    /* ################################################################## */
    /**
     Basic initializer.
     
     - parameter frame: The frame for the control.
     - parameter alarmRecord: The alarm object to be associated with this button.
     */
    init(   frame inFrame: CGRect = CGRect.zero,
            alarmRecord inAlarmRecord: TheBestClockAlarmSetting
        ) {
        super.init(frame: inFrame)
        self.alarmRecord = inAlarmRecord
    }
    
    /* ################################################################## */
    /**
     Coder initializer.
     
     - parameter coder: The coder that contains our state.
     */
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /* ################################################################## */
    /**
     Called when we will lay out the subviews.
     
     We use this to set up most of our control state.
     */
    override func layoutSubviews() {
        super.layoutSubviews()
        // We inset slightly horizontally.
        let frame = self.bounds.insetBy(dx: self.bounds.size.width / 40, dy: 0)
        
        // See if we need to add a label.
        if nil == self.displayLabel {
            self.displayLabel = UILabel(frame: frame)
            self.displayLabel.adjustsFontSizeToFitWidth = true
            self.displayLabel.textAlignment = .center
            self.displayLabel.baselineAdjustment = .alignCenters
            self.displayLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            self.displayLabel.backgroundColor = UIColor.clear
        }
        
        // See if we need to add a gesture recognizer.
        if nil == self.longPressGestureRecognizer {
            self.longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(type(of: self).longPressGesture(_:)))
            self.addGestureRecognizer(self.longPressGestureRecognizer)
        }
        
        // Add any accessibility hint. This is static for the button.
        self.displayLabel.accessibilityHint = "LOCAL-ACCESSIBILITY-ALARM-CONTAINER-HINT".localizedVariant
        self.backgroundColor = UIColor.clear
        self.displayLabel.frame = frame
        self.addSubview(self.displayLabel)
    }
    
    /* ################################################################## */
    /**
     The drawing routine. The display is rendered here.
     
     - parameter inRect: The rect in which the drawing is to be done.
     */
    override func draw(_ inRect: CGRect) {
        super.draw(inRect)
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
        
        // We use the text to create a relevant accessibility label.
        if let displayText = self.displayLabel?.text {
            self.displayLabel.accessibilityLabel = displayText + ". " + ("LOCAL-ACCESSIBILITY-ALARM-CONTAINER-O" + (self.alarmRecord.isActive ? "N" : "FF")).localizedVariant
        }

        self.displayLabel.textColor = textColor
    }
    
    /* ################################################################## */
    /**
     Called as tracking starts.
     
     - parameter inTouch: The current touch.
     - with: The event for the touch. It is optional.
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
     Called repeatedly as tracking continues.
     
     - parameter inTouch: The current touch.
     - with: The event for the touch. It is optional.
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
     Called when tracking is done.
     
     - parameter inTouch: The current touch. It is optional.
     - with: The event for the touch. It is optional.
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
     Called to cancel tracking.
     
     - parameter with: The cancel event. It is optional.
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
     Called upon a long press. We use this to open the Alarm Editor.
     
     - parameter: ignored.
     */
    @IBAction func longPressGesture(_: UILongPressGestureRecognizer) {
        self.delegate?.openAlarmEditor(self.index)
    }
    
    /* ################################################################## */
    /**
     This animates a "snore."
     
     This is a pulsing of brightness.
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
