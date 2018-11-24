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
    private var _gradientLayer: CAGradientLayer!
    private var _firstTime: Bool = false
    
    @IBInspectable var endColor: UIColor = UIColor.white
    @IBInspectable var brightness: CGFloat = 1.0
    
    /* ################################################################## */
    /**
     This draws an "elongated upside-down teardrop" that appears while the control is being manipulated.
     The fill color is the current selected value.
     
     - parameter inRect: ignored
     */
    override func draw(_ inRect: CGRect) {
        self._gradientLayer?.removeFromSuperlayer()
        self.backgroundColor = UIColor.clear    // Make sure that our background color is clear.
        if self.isEnabled && self.isTracking {  // We don't draw the slider unless we are both enabled, and tracking.
            // We will draw a "blunt teardrop" shape, with a rounded top and bottom. Wide at the top, narrow at the bottom. Rounded on both the top and the bottom. No sharp edges.
            let topRightPoint = CGPoint(x: self.bounds.size.width, y: self.bounds.midX)
            let arcCenterPoint = CGPoint(x: self.bounds.midX, y: self.bounds.midX)
            let bottomLeftPoint = CGPoint(x: self.bounds.midX - 4, y: bounds.size.height - 4)
            let bottomArcCenterPoint = CGPoint(x: self.bounds.midX, y: bounds.size.height - 4)
            
            let path = UIBezierPath()
            path.move(to: topRightPoint)
            path.addArc(withCenter: arcCenterPoint, radius: self.bounds.midX, startAngle: 0, endAngle: CGFloat.pi, clockwise: false)
            path.addLine(to: bottomLeftPoint)
            path.addArc(withCenter: bottomArcCenterPoint, radius: 4, startAngle: CGFloat.pi, endAngle: 0, clockwise: false)
            path.addLine(to: topRightPoint)
            path.close()
            
            // We will fill it with a gradient, from whatever the most bright is at the top, to black, at the bottom.
            self._gradientLayer = CAGradientLayer()
            let endColor = UIColor.white == self.endColor ? UIColor(white: 1.0, alpha: 1.0) : UIColor(hue: self.endColor.hsba.h, saturation: 1.0, brightness: 1.0, alpha: 1.0)
            self._gradientLayer.colors = [UIColor.black.cgColor, endColor.cgColor]
            self._gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
            self._gradientLayer.endPoint = CGPoint(x: 0.5, y: 0)
            self._gradientLayer.frame = self.bounds

            let shape = CAShapeLayer()
            shape.path = path.cgPath
            self._gradientLayer.mask = shape
            self.layer.addSublayer(self._gradientLayer)
            
            if self._firstTime {    // When we first open, we have a little "sproing."
                self.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
                UIView.animate(withDuration: 0.125,
                               delay: 0,
                               usingSpringWithDamping: 0.75,
                               initialSpringVelocity: 20,
                               options: .allowUserInteraction,
                               animations: { [unowned self] in
                                    self.transform = .identity
                                },
                               completion: nil
                )
            }
            
            self._firstTime = false
        }
    }
    
    /* ################################################################## */
    /**
     This is called when the user first begins a slide.
     
     - parameter inTouch: The initial touch object.
     - parameter with: The event for this touch.
     
     -returns true, if the drag is approved.
     */
    override func beginTracking(_ inTouch: UITouch, with inEvent: UIEvent?) -> Bool {
        let touchLocation = inTouch.location(in: self)
        self.brightness = (self.bounds.size.height - touchLocation.y) / self.bounds.size.height
        
        let ret = super.beginTracking(inTouch, with: inEvent)
        
        DispatchQueue.main.async {
            self.sendActions(for: .editingDidBegin)
            self.sendActions(for: .valueChanged)
            self._firstTime = true  // This tells the drawinbg routine to animate the opening.
            self.setNeedsDisplay()
        }
        
        return ret
    }
    
    /* ################################################################## */
    /**
     This is called when there are touch (not necessarily pan) events on the slider.
     
     - parameter inTouches: The initial touch object[s].
     - parameter with: The event for this touch.
     */
    override func touchesBegan(_ inTouches: Set<UITouch>, with inEvent: UIEvent?) {
        if let touchLocation = inTouches.first?.location(in: self) {
            self.brightness = (self.bounds.size.height - touchLocation.y) / self.bounds.size.height
            DispatchQueue.main.async {
                self.sendActions(for: .editingDidBegin)
                self.sendActions(for: .valueChanged)
                self._firstTime = true
                self.setNeedsDisplay()
            }
        }
        
        super.touchesBegan(inTouches, with: inEvent)
    }
    
    /* ################################################################## */
    /**
     This is called repeatedly during a slide.
     
     - parameter inTouch: The initial touch object.
     - parameter with: The event for this touch.
     
     -returns true, if the drag is approved.
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
     This is called at the end of the pan.
     
     - parameter inTouch: The initial touch object.
     - parameter with: The event for this touch.
     */
    override func endTracking(_ inTouch: UITouch?, with inEvent: UIEvent?) {
        DispatchQueue.main.async {
            self.sendActions(for: .editingDidEnd)
            self.setNeedsDisplay()
        }
    
        super.endTracking(inTouch, with: inEvent)
    }
    
    /* ################################################################## */
    /**
     This is called if the tracking was canceled.
     
     - parameter with: The event for the cancel.
     */
    override func cancelTracking(with inEvent: UIEvent?) {
        DispatchQueue.main.async {
            self.sendActions(for: .editingDidEnd)
            self.sendActions(for: .valueChanged)
            self.setNeedsDisplay()
        }
        
        super.cancelTracking(with: inEvent)
    }
}
