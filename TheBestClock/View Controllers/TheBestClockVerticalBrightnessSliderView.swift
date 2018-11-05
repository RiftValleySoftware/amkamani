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
class TheBestClockVerticalBrightnessSliderView: UIControl {
    var endColor: UIColor = UIColor.white
    var brightness: CGFloat = 1.0

    /* ################################################################## */
    /**
     */
    override func layoutSubviews() {
        super.layoutSubviews()
        self.backgroundColor = UIColor.clear
    }
    
    /* ################################################################## */
    /**
     */
    override func draw(_ rect: CGRect) {
        if let sublayers = self.layer.sublayers {
            for subLayer in sublayers {
                subLayer.removeFromSuperlayer()
            }
        }

        let topLeftPoint = CGPoint(x: 0, y: 0)
        let topRightPoint = CGPoint(x: self.bounds.size.width, y: 0)
        let bottomPoint = CGPoint(x: self.bounds.midX, y: bounds.size.height)
        let path = UIBezierPath()
        path.move(to: topLeftPoint)
        path.addLine(to: bottomPoint)
        path.addLine(to: topRightPoint)
        path.addLine(to: topLeftPoint)
        let shape = CAShapeLayer()
        shape.path = path.cgPath
        if endColor == UIColor.white {
            shape.fillColor = UIColor(white: self.brightness, alpha: 1.0).cgColor
        } else {
            shape.fillColor = UIColor(hue: endColor.hsba.h, saturation: 1.0, brightness: self.brightness, alpha: 1.0).cgColor
        }
        self.layer.addSublayer(shape)
    }

    /* ################################################################## */
    /**
     */
    override public func beginTracking(_ inTouch: UITouch, with inEvent: UIEvent?) -> Bool {
        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }
        
        return super.beginTracking(inTouch, with: inEvent)
    }
    
    /* ################################################################## */
    /**
     */
    override public func continueTracking(_ inTouch: UITouch, with inEvent: UIEvent?) -> Bool {
        
        let touchLocation = inTouch.location(in: self)
        
        self.brightness = (self.bounds.size.height - touchLocation.y) / self.bounds.size.height
        self.sendActions(for: .valueChanged)

        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }
        
        return super.continueTracking(inTouch, with: inEvent)
    }
    
    /* ################################################################## */
    /**
     */
    override public func endTracking(_ inTouch: UITouch?, with inEvent: UIEvent?) {
        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }
    
        super.endTracking(inTouch, with: inEvent)
    }
    
    /* ################################################################## */
    /**
     */
    override public func cancelTracking(with inEvent: UIEvent?) {
        DispatchQueue.main.async {
            self.setNeedsDisplay()
        }
        
        super.cancelTracking(with: inEvent)
    }
}
