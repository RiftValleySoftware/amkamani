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
    var _gradientLayer: CAGradientLayer!
    
    @IBInspectable var endColor: UIColor = UIColor.white
    @IBInspectable var brightness: CGFloat = 1.0
    
    @IBAction func longPressGestureReconizerHit(_ sender: Any) {
    }
    
    /* ################################################################## */
    /**
     This draws an "elongated upside-down teardrop" that appears while the control is being manipulated.
     The fill color is the current selected value.
     
     - parameter inRect: ignored
     */
    override func draw(_ inRect: CGRect) {
        self._gradientLayer?.removeFromSuperlayer()
        self.backgroundColor = UIColor.clear    // Make sure that our background color is clear.
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
            
            self._gradientLayer = CAGradientLayer()
            let endColor = UIColor.white == self.endColor ? UIColor(white: self.brightness, alpha: 1.0) : UIColor(hue: self.endColor.hsba.h, saturation: 1.0, brightness: self.brightness, alpha: 1.0)
            self._gradientLayer.colors = [UIColor.black.cgColor, endColor.cgColor]
            self._gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
            self._gradientLayer.endPoint = CGPoint(x: 0.5, y: 0)
            self._gradientLayer.frame = self.bounds

            let shape = CAShapeLayer()
            shape.path = path.cgPath
            self._gradientLayer.mask = shape
            self.layer.addSublayer(self._gradientLayer)
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
