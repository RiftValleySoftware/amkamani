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
class MainScreenViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    /// This is a list of a subset of fonts likely to be on the device. We want to reduce the choices for the user.
    private let _screenForThese: [String] = ["AmericanTypewriter-Bold",
                                             "AmericanTypewriter-Light",
                                             "AppleColorEmoji",
                                             "AppleSDGothicNeo-Bold",
                                             "AppleSDGothicNeo-Thin",
                                             "AppleSDGothicNeo-UltraLight",
                                             "Arial-BoldItalicMT",
                                             "Arial-BoldMT",
                                             "Arial-ItalicMT",
                                             "ArialMT",
                                             "Avenir-Black",
                                             "Avenir-Light",
                                             "AvenirNextCondensed-UltraLight",
                                             "Baskerville",
                                             "Baskerville-Bold",
                                             "Baskerville-BoldItalic",
                                             "Baskerville-Italic",
                                             "BodoniSvtyTwoITCTT-Bold",
                                             "BradleyHandITCTT-Bold",
                                             "ChalkboardSE-Bold",
                                             "Chalkduster",
                                             "Cochin-Bold",
                                             "Copperplate-Bold",
                                             "Copperplate-Light",
                                             "Courier",
                                             "Courier-Bold",
                                             "Didot",
                                             "Didot-Bold",
                                             "EuphemiaUCAS-Bold",
                                             "Futura-CondensedExtraBold",
                                             "Futura-Medium",
                                             "GeezaPro-Bold",
                                             "Georgia-Bold",
                                             "GillSans-Light",
                                             "GillSans-UltraBold",
                                             "Helvetica",
                                             "Helvetica-Bold",
                                             "HelveticaNeue-UltraLight",
                                             "HoeflerText-Black",
                                             "Let's Go Digital",
                                             "MarkerFelt-Thin",
                                             "MarkerFelt-Wide",
                                             "Menlo-Bold",
                                             "Menlo-Regular",
                                             "Noteworthy-Bold",
                                             "Noteworthy-Light",
                                             "Palatino-Roman",
                                             "Papyrus",
                                             "SavoyeLetPlain",
                                             "Thonburi-Bold",
                                             "Thonburi-Light",
                                             "TimesNewRomanPS-BoldMT",
                                             "TimesNewRomanPS-ItalicMT",
                                             "TimesNewRomanPSMT",
                                             "TrebuchetMS",
                                             "TrebuchetMS-Bold",
                                             "TrebuchetMS-Italic",
                                             "Verdana",
                                             "Verdana-Bold"]
    
    private var _fontSelection: [String] = ["Let's Go Digital"] // We'll have our embedded "digital" font as the initial one.

    @IBOutlet weak var mainPickerView: UIPickerView!
    
    /* ################################################################## */
    /**
     */
    private func _getFontSize(_ inFontName: String) -> CGFloat {
        var frame = self.mainPickerView.bounds
        frame.size.height = self.pickerView(self.mainPickerView, rowHeightForComponent: 0)
        let text = "88:88"
        var fontSize: CGFloat = frame.size.width * 2
        while fontSize > 0 {
            if let font = UIFont(name: inFontName, size: fontSize) {
                let fitSize = CGSize(width: frame.size.width, height: frame.size.height)
                let rect = text.boundingRect(with: fitSize, options: [.usesDeviceMetrics], attributes: [NSAttributedString.Key.font: font], context: nil)
                
                if rect.size.height <= frame.size.height, rect.size.width <= frame.size.width {
                    break
                }
                
                fontSize -= 1
            }
        }
        
        return fontSize
    }

    private var _currentTimeString: (time: String, amPm: String) {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        let dateString = formatter.string(from: Date())
        let amRange = dateString.range(of: formatter.amSymbol)
        let pmRange = dateString.range(of: formatter.pmSymbol)
        
        let is24 = (pmRange == nil && amRange == nil)

        formatter.dateFormat = is24 ? "H:mm" : "h:mm"
        
        let timeString = formatter.string(from: Date())
        formatter.dateFormat = "a"
        let amPMString = is24 ? "" : formatter.string(from: Date())
        
        return (time: timeString, amPm: amPMString)
    }
    
    /* ################################################################## */
    /**
     */
    override func viewDidLoad() {
        for fontFamilyName in UIFont.familyNames {
            for fontName in UIFont.fontNames(forFamilyName: fontFamilyName) {
                if self._screenForThese.contains(fontName) {
                    self._fontSelection.append(fontName)
                }
            }
        }
        
        self._fontSelection.sort()
        
        for index in 0..<self._fontSelection.count {
            if "Let's Go Digital" == self._fontSelection[index] {
                self.mainPickerView.selectRow(index, inComponent: 0, animated: false)
                break
            }
        }
    }
    
    /* ################################################################## */
    /**
     */
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    /* ################################################################## */
    /**
     */
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self._fontSelection.count
    }
    
    /* ################################################################## */
    /**
     */
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        let frame = pickerView.bounds
        return frame.size.height * 0.75
    }
    
    /* ################################################################## */
    /**
     */
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let fontName = self._fontSelection[row]
        let fontSize = self._getFontSize(fontName)
        
        var frame = pickerView.bounds
        frame.size.height = self.pickerView(pickerView, rowHeightForComponent: component)
        let ret = UIView(frame:frame)
        
        if 0 < fontSize, let font = UIFont(name: fontName, size: fontSize) {
            let text = self._currentTimeString.time

            let displayLabel = UILabel(frame: frame)
            
            displayLabel.font = font
            displayLabel.adjustsFontSizeToFitWidth = true
            displayLabel.textAlignment = .center
            displayLabel.baselineAdjustment = .alignCenters
            displayLabel.text = text
            ret.addSubview(displayLabel)
        }
        
        return ret
    }
}

