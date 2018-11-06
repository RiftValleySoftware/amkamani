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
 This is a special control that is normally invisible, and apprears when the user starts a pan.
 We use this to act as a brigthness slider for the clock. The top is the brightest, the bottom is the darkest.
 The view is updated with the current color from the main controller as it is panned.
 */
@IBDesignable
class TheBestClockVerticalBrightnessSliderView: UIControl {
    @IBInspectable var endColor: UIColor = UIColor.white
    @IBInspectable var brightness: CGFloat = 1.0
    
    @IBAction func longPressGestureReconizerHit(_ sender: Any) {
    }
    
    /* ################################################################## */
    /**
     We make sure that the control has no subviews and no sublayers, and that we are transparent.
     */
    override func layoutSubviews() {
        self.backgroundColor = UIColor.clear    // Make sure that our background color is clear.
        super.layoutSubviews()
    }
    
    /* ################################################################## */
    /**
     This draws an "elongated upside-down teardrop" that appears while the control is being manipulated.
     The fill color is the current selected value.
     
     - parameter inRect: ignored
     */
    override func draw(_ inRect: CGRect) {
        if let sublayers = self.layer.sublayers {
            for subLayer in sublayers {
                subLayer.removeFromSuperlayer()
            }
        }

        if self.isTracking {
            let topLeftPoint = CGPoint(x: 0, y: self.bounds.midX)
            let arcCenterPoint = CGPoint(x: self.bounds.midX, y: self.bounds.midX)
            let topRightPoint = CGPoint(x: self.bounds.size.width, y: self.bounds.midX)
            let bottomPoint = CGPoint(x: self.bounds.midX, y: bounds.size.height)
            let path = UIBezierPath()
            path.move(to: topLeftPoint)
            path.addLine(to: bottomPoint)
            path.addLine(to: topRightPoint)
            path.addArc(withCenter: arcCenterPoint, radius: self.bounds.midX, startAngle: 0, endAngle: CGFloat.pi, clockwise: false)
            
            let gradient = CAGradientLayer()
            let endColor = UIColor.white == self.endColor ? UIColor(white: self.brightness, alpha: 1.0) : UIColor(hue: self.endColor.hsba.h, saturation: 1.0, brightness: self.brightness, alpha: 1.0)
            gradient.colors = [UIColor.black.cgColor, endColor.cgColor]
            gradient.startPoint = CGPoint(x: 0.5, y: 1.0)
            gradient.endPoint = CGPoint(x: 0.5, y: 0)
            gradient.frame = self.bounds

            let shape = CAShapeLayer()
            shape.path = path.cgPath
            gradient.mask = shape
            
            self.layer.addSublayer(gradient)
        }
    }
    
    /* ################################################################## */
    /**
     */
    override func touchesBegan(_ inTouches: Set<UITouch>, with inEvent: UIEvent?) {
        if let touchLocation = inTouches.first?.location(in: self) {
            self.brightness = (self.bounds.size.height - touchLocation.y) / self.bounds.size.height
            DispatchQueue.main.async {
                self.sendActions(for: .valueChanged)
                self.setNeedsDisplay()
            }
        }
        
        super.touchesBegan(inTouches, with: inEvent)
    }
    
    /* ################################################################## */
    /**
     */
    override func beginTracking(_ inTouch: UITouch, with inEvent: UIEvent?) -> Bool {
        let touchLocation = inTouch.location(in: self)
        self.brightness = (self.bounds.size.height - touchLocation.y) / self.bounds.size.height
        
        let ret = super.beginTracking(inTouch, with: inEvent)
        
        DispatchQueue.main.async {
            self.sendActions(for: .valueChanged)
            self.setNeedsDisplay()
        }
        
        return ret
    }
    
    /* ################################################################## */
    /**
     */
    override func continueTracking(_ inTouch: UITouch, with inEvent: UIEvent?) -> Bool {
        
        let touchLocation = inTouch.location(in: self)
        self.brightness = (self.bounds.size.height - touchLocation.y) / self.bounds.size.height

        let ret = super.continueTracking(inTouch, with: inEvent)
        
        DispatchQueue.main.async {
            self.sendActions(for: .valueChanged)
            self.setNeedsDisplay()
        }
        
        return ret
    }
    
    /* ################################################################## */
    /**
     */
    override func endTracking(_ inTouch: UITouch?, with inEvent: UIEvent?) {
        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }
    
        super.endTracking(inTouch, with: inEvent)
    }
    
    /* ################################################################## */
    /**
     */
    override func cancelTracking(with inEvent: UIEvent?) {
        DispatchQueue.main.async {
            self.sendActions(for: .valueChanged)
            self.setNeedsDisplay()
        }
        
        super.cancelTracking(with: inEvent)
    }
}
