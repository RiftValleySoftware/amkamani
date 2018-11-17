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
class TheBestClockSpeakerButton: UIButton {
    /* ################################################################## */
    // MARK: - Instance Superclass Overrides
    /* ################################################################## */
    /**
     */
    override func draw(_ rect: CGRect) {
        //// Speaker Drawing
        let speakerPath = UIBezierPath()
        speakerPath.move(to: CGPoint(x: 520.2, y: 116.4))
        speakerPath.addLine(to: CGPoint(x: 520.2, y: 887.1))
        speakerPath.addCurve(to: CGPoint(x: 510.2, y: 903.1), controlPoint1: CGPoint(x: 520.2, y: 893.9), controlPoint2: CGPoint(x: 516.3, y: 900.1))
        speakerPath.addCurve(to: CGPoint(x: 502.5, y: 904.9), controlPoint1: CGPoint(x: 507.8, y: 904.3), controlPoint2: CGPoint(x: 505.1, y: 904.9))
        speakerPath.addCurve(to: CGPoint(x: 491.4, y: 901), controlPoint1: CGPoint(x: 498.6, y: 904.9), controlPoint2: CGPoint(x: 494.6, y: 903.6))
        speakerPath.addLine(to: CGPoint(x: 202.2, y: 670.2))
        speakerPath.addLine(to: CGPoint(x: 48.1, y: 670.2))
        speakerPath.addCurve(to: CGPoint(x: 0.4, y: 622.5), controlPoint1: CGPoint(x: 21.8, y: 670.2), controlPoint2: CGPoint(x: 0.4, y: 648.8))
        speakerPath.addLine(to: CGPoint(x: 0.4, y: 381.2))
        speakerPath.addCurve(to: CGPoint(x: 48.1, y: 333.5), controlPoint1: CGPoint(x: 0.4, y: 354.9), controlPoint2: CGPoint(x: 21.8, y: 333.5))
        speakerPath.addLine(to: CGPoint(x: 202.2, y: 333.5))
        speakerPath.addLine(to: CGPoint(x: 491.4, y: 102.6))
        speakerPath.addCurve(to: CGPoint(x: 510.2, y: 100.5), controlPoint1: CGPoint(x: 496.7, y: 98.3), controlPoint2: CGPoint(x: 504, y: 97.5))
        speakerPath.addCurve(to: CGPoint(x: 520.2, y: 116.4), controlPoint1: CGPoint(x: 516.3, y: 103.4), controlPoint2: CGPoint(x: 520.2, y: 109.6))
        speakerPath.close()
        
        
        //// Waves Drawing
        let wavesPath = UIBezierPath()
        wavesPath.move(to: CGPoint(x: 585.5, y: 261))
        wavesPath.addCurve(to: CGPoint(x: 552.8, y: 261), controlPoint1: CGPoint(x: 576.5, y: 252), controlPoint2: CGPoint(x: 561.8, y: 252))
        wavesPath.addCurve(to: CGPoint(x: 552.8, y: 293.7), controlPoint1: CGPoint(x: 543.8, y: 270), controlPoint2: CGPoint(x: 543.8, y: 284.7))
        wavesPath.addCurve(to: CGPoint(x: 639.1, y: 501.8), controlPoint1: CGPoint(x: 608.4, y: 349.3), controlPoint2: CGPoint(x: 639.1, y: 423.2))
        wavesPath.addCurve(to: CGPoint(x: 552.8, y: 709.9), controlPoint1: CGPoint(x: 639.1, y: 580.4), controlPoint2: CGPoint(x: 608.5, y: 654.3))
        wavesPath.addCurve(to: CGPoint(x: 552.8, y: 742.6), controlPoint1: CGPoint(x: 543.8, y: 718.9), controlPoint2: CGPoint(x: 543.8, y: 733.6))
        wavesPath.addCurve(to: CGPoint(x: 569.2, y: 749.4), controlPoint1: CGPoint(x: 557.3, y: 747.1), controlPoint2: CGPoint(x: 563.2, y: 749.4))
        wavesPath.addCurve(to: CGPoint(x: 585.6, y: 742.6), controlPoint1: CGPoint(x: 575.2, y: 749.4), controlPoint2: CGPoint(x: 581, y: 747.1))
        wavesPath.addCurve(to: CGPoint(x: 685.4, y: 501.8), controlPoint1: CGPoint(x: 650, y: 678.2), controlPoint2: CGPoint(x: 685.4, y: 592.7))
        wavesPath.addCurve(to: CGPoint(x: 585.5, y: 261), controlPoint1: CGPoint(x: 685.4, y: 410.9), controlPoint2: CGPoint(x: 649.8, y: 325.4))
        wavesPath.close()
        wavesPath.move(to: CGPoint(x: 644.8, y: 130))
        wavesPath.addCurve(to: CGPoint(x: 612.1, y: 130), controlPoint1: CGPoint(x: 635.8, y: 121), controlPoint2: CGPoint(x: 621.1, y: 121))
        wavesPath.addCurve(to: CGPoint(x: 612.1, y: 162.7), controlPoint1: CGPoint(x: 603.1, y: 139), controlPoint2: CGPoint(x: 603.1, y: 153.7))
        wavesPath.addCurve(to: CGPoint(x: 752.7, y: 501.8), controlPoint1: CGPoint(x: 702.7, y: 253.3), controlPoint2: CGPoint(x: 752.7, y: 373.8))
        wavesPath.addCurve(to: CGPoint(x: 612.1, y: 840.9), controlPoint1: CGPoint(x: 752.7, y: 629.8), controlPoint2: CGPoint(x: 702.8, y: 750.2))
        wavesPath.addCurve(to: CGPoint(x: 612.1, y: 873.6), controlPoint1: CGPoint(x: 603.1, y: 849.9), controlPoint2: CGPoint(x: 603.1, y: 864.6))
        wavesPath.addCurve(to: CGPoint(x: 628.5, y: 880.4), controlPoint1: CGPoint(x: 616.6, y: 878.1), controlPoint2: CGPoint(x: 622.5, y: 880.4))
        wavesPath.addCurve(to: CGPoint(x: 644.9, y: 873.6), controlPoint1: CGPoint(x: 634.5, y: 880.4), controlPoint2: CGPoint(x: 640.3, y: 878.1))
        wavesPath.addCurve(to: CGPoint(x: 799, y: 501.8), controlPoint1: CGPoint(x: 744.3, y: 774.2), controlPoint2: CGPoint(x: 799, y: 642.2))
        wavesPath.addCurve(to: CGPoint(x: 644.8, y: 130), controlPoint1: CGPoint(x: 799, y: 361.4), controlPoint2: CGPoint(x: 744.2, y: 229.4))
        wavesPath.close()
        wavesPath.move(to: CGPoint(x: 859.7, y: 238.4))
        wavesPath.addCurve(to: CGPoint(x: 705.8, y: 6.7), controlPoint1: CGPoint(x: 824.5, y: 151.6), controlPoint2: CGPoint(x: 772.7, y: 73.6))
        wavesPath.addCurve(to: CGPoint(x: 673.1, y: 6.7), controlPoint1: CGPoint(x: 696.8, y: -2.3), controlPoint2: CGPoint(x: 682.1, y: -2.3))
        wavesPath.addCurve(to: CGPoint(x: 673.1, y: 39.4), controlPoint1: CGPoint(x: 664.1, y: 15.7), controlPoint2: CGPoint(x: 664.1, y: 30.4))
        wavesPath.addCurve(to: CGPoint(x: 816.8, y: 255.7), controlPoint1: CGPoint(x: 735.6, y: 101.9), controlPoint2: CGPoint(x: 783.9, y: 174.7))
        wavesPath.addCurve(to: CGPoint(x: 864.7, y: 501.7), controlPoint1: CGPoint(x: 848.6, y: 334), controlPoint2: CGPoint(x: 864.7, y: 416.8))
        wavesPath.addCurve(to: CGPoint(x: 816.8, y: 747.7), controlPoint1: CGPoint(x: 864.7, y: 586.6), controlPoint2: CGPoint(x: 848.6, y: 669.3))
        wavesPath.addCurve(to: CGPoint(x: 673.1, y: 964), controlPoint1: CGPoint(x: 783.9, y: 828.8), controlPoint2: CGPoint(x: 735.5, y: 901.6))
        wavesPath.addCurve(to: CGPoint(x: 673.1, y: 996.7), controlPoint1: CGPoint(x: 664.1, y: 973), controlPoint2: CGPoint(x: 664.1, y: 987.7))
        wavesPath.addCurve(to: CGPoint(x: 689.5, y: 1003.5), controlPoint1: CGPoint(x: 677.6, y: 1001.2), controlPoint2: CGPoint(x: 683.5, y: 1003.5))
        wavesPath.addCurve(to: CGPoint(x: 705.9, y: 996.7), controlPoint1: CGPoint(x: 695.5, y: 1003.5), controlPoint2: CGPoint(x: 701.3, y: 1001.2))
        wavesPath.addCurve(to: CGPoint(x: 859.7, y: 765.2), controlPoint1: CGPoint(x: 772.7, y: 930), controlPoint2: CGPoint(x: 824.4, y: 852))
        wavesPath.addCurve(to: CGPoint(x: 911, y: 501.8), controlPoint1: CGPoint(x: 893.7, y: 681.3), controlPoint2: CGPoint(x: 911, y: 592.7))
        wavesPath.addCurve(to: CGPoint(x: 859.7, y: 238.4), controlPoint1: CGPoint(x: 911, y: 410.9), controlPoint2: CGPoint(x: 893.7, y: 322.3))
        wavesPath.close()
    }
}
