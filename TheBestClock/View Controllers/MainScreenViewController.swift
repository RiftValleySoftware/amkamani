/**
© Copyright 2018, The Great Rift Valley Software Company. All rights reserved.
    
    This code is proprietary and confidential code,
    It is NOT to be reused or combined into any application,
    unless done so, specifically under written license from The Great Rift Valley Software Company.
    
    The Great Rift Valley Software Company: https://riftvalleysoftware.com
*/

import UIKit
import MediaPlayer

/* ###################################################################################################################################### */
// MARK: - Extensions -
/* ###################################################################################################################################### */
/**
 */
extension UIColor {
    /* ################################################################## */
    /**
     This just allows us to get an HSB color from a standard UIColor.
     From here: https://stackoverflow.com/a/30713456/879365
     
     - returns: A tuple, containing the HSBA color.
     */
    var hsba:(h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat) {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (h: h, s: s, b: b, a: a)
    }
}

/* ###################################################################################################################################### */
// MARK: - Main Class -
/* ###################################################################################################################################### */
/**
 */
class MainScreenViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    /// This is a list of a subset of fonts likely to be on the device. We want to reduce the choices for the user.
    private let _screenForThese: [String] = ["AmericanTypewriter-Bold",
                                             "AppleColorEmoji",
                                             "AppleSDGothicNeo-Bold",
                                             "AppleSDGothicNeo-Thin",
                                             "Arial-BoldItalicMT",
                                             "Avenir-Black",
                                             "AvenirNextCondensed-UltraLight",
                                             "Baskerville",
                                             "Baskerville-BoldItalic",
                                             "BodoniSvtyTwoITCTT-Bold",
                                             "BradleyHandITCTT-Bold",
                                             "ChalkboardSE-Bold",
                                             "Chalkduster",
                                             "Cochin-Bold",
                                             "Copperplate-Bold",
                                             "Copperplate-Light",
                                             "Courier-Bold",
                                             "Didot-Bold",
                                             "EuphemiaUCAS-Bold",
                                             "Futura-CondensedExtraBold",
                                             "Futura-Medium",
                                             "GeezaPro-Bold",
                                             "Georgia-Bold",
                                             "GillSans-Light",
                                             "GillSans-UltraBold",
                                             "Helvetica-Bold",
                                             "HelveticaNeue-UltraLight",
                                             "HoeflerText-Black",
                                             "MarkerFelt-Wide",
                                             "Menlo-Bold",
                                             "Noteworthy-Bold",
                                             "Palatino-Roman",
                                             "Papyrus",
                                             "Thonburi-Bold",
                                             "TimesNewRomanPS-BoldMT",
                                             "TimesNewRomanPS-ItalicMT",
                                             "TrebuchetMS-Bold",
                                             "Verdana-Bold"]
    private let _minimumBrightness: CGFloat = 0.05
    private let _amPmLabelFontSize: CGFloat = 30
    private let _dateLabelFontSize: CGFloat = 50

    private var _fontSelection: [String] = []
    private var _colorSelection: [UIColor] = []
    private var _backgroundColor: UIColor = UIColor.gray
    private var _ticker: Timer!
    private var _fontSizeCache: CGFloat = 0

    /* ################################################################## */
    /**
     */
    private func _requestAccessToMediaLibrary() {
        MPMediaLibrary.requestAuthorization { status in
            switch status {
            case.authorized:
                break
                
            case .denied:
                TheBestClockAppDelegate.reportError(heading: "ERROR_HEADER_MEDIA", text: "ERROR_TEXT_MEDIA_PERMISSION_DENIED")
                
            default:
                break
            }
        }
    }
    
    /* ################################################################## */
    /**
     */
    private func _getFontSize(_ inFontName: String, size inSize: CGSize) -> CGFloat {
        return self.mainNumberDisplayView.bounds.size.height
    }

    @IBOutlet weak var mainDisplayPickerView: UIPickerView!
    @IBOutlet weak var colorDisplayPickerView: UIPickerView!
    @IBOutlet weak var mainNumberDisplayView: UIView!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var mainPickerContainerView: UIView!
    @IBOutlet weak var brightnessSlider: TheBestClockVerticalBrightnessSliderView!
    @IBOutlet weak var amPmLabel: UILabel!
    @IBOutlet weak var dateDisplayLabel: UILabel!
    
    var selectedFontIndex: Int = 0
    var selectedColorIndex: Int = 0
    var selectedBrightness: CGFloat = 1.0

    /* ################################################################## */
    /**
     */
    @IBAction func brightnessSliderChanged(_ sender: TheBestClockVerticalBrightnessSliderView) {
        self.selectedBrightness = max(self._minimumBrightness, sender.brightness)
        self.updateMainTime()
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func doneButtonHit(_ sender: Any) {
        self._fontSizeCache = 0
        mainPickerContainerView.isHidden = true
        self.updateMainTime()
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func openAppearanceEditor(_ sender: Any) {
        self.mainPickerContainerView.isHidden = false
        self.mainPickerContainerView.backgroundColor = self._backgroundColor
        self.mainDisplayPickerView.backgroundColor = self._backgroundColor
        self.colorDisplayPickerView.backgroundColor = self._backgroundColor
        self.mainDisplayPickerView.reloadComponent(0)
    }
    
    /* ################################################################## */
    /**
     */
    @objc(_TtCC12TheBestClock24MainScreenViewController24TheBestClockAlarmSetting)class TheBestClockAlarmSetting: NSObject, NSCoding {
        var alarmTimeInSeconds: Int = 0
        var playlistID: UUID = UUID()
        var snoozing: Bool = false
        
        func encode(with aCoder: NSCoder) {
        }
        
        required init?(coder aDecoder: NSCoder) {
            super.init()
        }
    }
    
    /* ################################################################## */
    /**
     This struct will contain all the info we need to display our time and date.
     */
    struct TimeDateContainer {
        /// This is the time, as a locale-adjusted string. It will always use a colon separator between hours and seconds.
        var time: String
        /// If the time is ante meridian, then this will contain the locale-adjusted "AM" or "PM".
        var amPm: String
        /// This will contain the date, as abbreviated weekday abbreviated month name, day of the month, year.
        var date: String
    }
    
    /* ################################################################## */
    /**
     This calculates all the time and date information when it is called.
     */
    var currentTimeString: TimeDateContainer {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        let test = formatter.string(from: Date())
        let amRange = test.range(of: formatter.amSymbol)
        let pmRange = test.range(of: formatter.pmSymbol)
        
        let is24 = (pmRange == nil && amRange == nil)

        formatter.dateFormat = is24 ? "H:mm" : "h:mm"
        
        let timeString = formatter.string(from: Date())
        formatter.dateFormat = "a"
        let amPMString = is24 ? "" : formatter.string(from: Date())
        
        formatter.dateFormat = "EEE, MMM d, y"

        let dateString = formatter.string(from: Date())
        
        return TimeDateContainer(time: timeString, amPm: amPMString, date: dateString)
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
        self._fontSelection.insert(contentsOf: ["Let's Go Digital", "AnonymousProMinus-Bold"], at: 0)
        
        self._colorSelection = [UIColor.white]
        // We generate a series of colors, fully saturated, from orange to red, and include white.
        for hue: CGFloat in stride(from: 0.05, to: 1.0, by: 0.05) {
            let color = UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
            self._colorSelection.append(color)
        }
        
        self.updateMainTime()
        
        self.mainDisplayPickerView.backgroundColor = UIColor.darkGray
        self.mainDisplayPickerView.selectRow(self.selectedFontIndex, inComponent: 0, animated: false)
        self.colorDisplayPickerView.backgroundColor = UIColor.darkGray
        self.colorDisplayPickerView.selectRow(self.selectedColorIndex, inComponent: 0, animated: false)
    }
    
    /* ################################################################## */
    /**
     */
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self._fontSizeCache = 0
        self.updateMainTime()
    }
    
    /* ################################################################## */
    /**
     */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self._fontSizeCache = 0
        UIApplication.shared.isIdleTimerDisabled = true // This makes sure that we stay awake while this window is up.
        self._ticker = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [unowned self] _ in
            DispatchQueue.main.async {
                self.updateMainTime()
            }
        }
    }
    
    /* ################################################################## */
    /**
     */
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = false
        self._ticker.invalidate()
        self._ticker = nil
        super.viewWillDisappear(animated)
    }

    /* ################################################################## */
    /**
     */
    func updateMainTime() {
        _ = self.createDisplayView(self.mainNumberDisplayView, index: self.selectedFontIndex)
        self.setAMPMLabel()
        self.setDateDisplayLabel()
    }
    
    /* ################################################################## */
    /**
     */
    func setAMPMLabel() {
        self.amPmLabel.backgroundColor = UIColor.clear
        var textColor: UIColor
        if 0 == self.selectedColorIndex {
            textColor = UIColor(white: self.selectedBrightness, alpha: 1.0)
        } else {
            let hue = self._colorSelection[self.selectedColorIndex].hsba.h
            textColor = UIColor(hue: hue, saturation: 1.0, brightness: 1.4 * self.selectedBrightness, alpha: 1.0)
        }
        
        self.amPmLabel.font = UIFont(name: self._fontSelection[self.selectedFontIndex], size: self._amPmLabelFontSize)
        self.amPmLabel.text = self.currentTimeString.amPm
        self.amPmLabel.adjustsFontSizeToFitWidth = true
        self.amPmLabel.textAlignment = .right
        self.amPmLabel.baselineAdjustment = .alignCenters
        self.amPmLabel.textColor = textColor
    }
    
    /* ################################################################## */
    /**
     */
    func setDateDisplayLabel() {
        self.dateDisplayLabel.backgroundColor = UIColor.clear
        var textColor: UIColor
        if 0 == self.selectedColorIndex {
            textColor = UIColor(white: self.selectedBrightness, alpha: 1.0)
        } else {
            let hue = self._colorSelection[self.selectedColorIndex].hsba.h
            textColor = UIColor(hue: hue, saturation: 1.0, brightness: 1.4 * self.selectedBrightness, alpha: 1.0)
        }
        
        self.dateDisplayLabel.font = UIFont(name: self._fontSelection[self.selectedFontIndex], size: self._dateLabelFontSize)
        self.dateDisplayLabel.text = self.currentTimeString.date
        self.dateDisplayLabel.adjustsFontSizeToFitWidth = true
        self.dateDisplayLabel.textAlignment = .center
        self.dateDisplayLabel.baselineAdjustment = .alignCenters
        self.dateDisplayLabel.textColor = textColor
    }

    /* ################################################################## */
    /**
     */
    func createDisplayView(_ inContainerView: UIView, index inIndex: Int) -> UIView {
        for subView in inContainerView.subviews {
            subView.removeFromSuperview()
        }
        
        if let sublayers = inContainerView.layer.sublayers {
            for subLayer in sublayers {
                subLayer.removeFromSuperlayer()
            }
        }

        self.brightnessSlider.endColor = self._colorSelection[self.selectedColorIndex]
        self.brightnessSlider.brightness = self.selectedBrightness
        self.brightnessSlider.setNeedsDisplay()
        
        var frame = inContainerView.bounds
        frame.size.height = inContainerView.bounds.height
        let fontName = self._fontSelection[inIndex]
        let fontSize = 0 == self._fontSizeCache ? self.mainNumberDisplayView.bounds.size.height : self._fontSizeCache
        self._fontSizeCache = fontSize
        
        if 0 < fontSize, let font = UIFont(name: fontName, size: fontSize) {
            let text = self.currentTimeString.time
            
            var endColor: UIColor
            var startColor: UIColor
            
            if 0 == self.selectedColorIndex {
                endColor = UIColor(white: 0.9 * self.selectedBrightness, alpha: 1.0)
                startColor = UIColor(white: 1.25 * self.selectedBrightness, alpha: 1.0)
            } else {
                let hue = self._colorSelection[self.selectedColorIndex].hsba.h
                endColor = UIColor(hue: hue, saturation: 1.0, brightness: 0.9 * self.selectedBrightness, alpha: 1.0)
                startColor = UIColor(hue: hue, saturation: 0.85, brightness: 1.25 * self.selectedBrightness, alpha: 1.0)
            }
            
            // The background can get darker than the text.
            self._backgroundColor = (self.selectedBrightness == self._minimumBrightness) ? UIColor.black : UIColor(white: 0.25 * self.selectedBrightness, alpha: 1.0)
            
            self.view.backgroundColor = self._backgroundColor
            let displayLabelGradient = UIView(frame: frame)
            let gradient = CAGradientLayer()
            gradient.colors = [startColor.cgColor, endColor.cgColor]
            gradient.startPoint = CGPoint(x: 0.5, y: 0)
            gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
            gradient.frame = frame
            displayLabelGradient.layer.addSublayer(gradient)
            
            let displayLabel = UILabel(frame: frame)
            displayLabel.font = font
            displayLabel.adjustsFontSizeToFitWidth = true
            displayLabel.textAlignment = .center
            displayLabel.baselineAdjustment = .alignCenters
            displayLabel.text = text
            
            displayLabelGradient.addContainedView(displayLabel)
            inContainerView.addContainedView(displayLabelGradient)
            
            inContainerView.mask = displayLabel
        }

        return inContainerView
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
        return self.colorDisplayPickerView == pickerView ? self._colorSelection.count : self._fontSelection.count
    }

    /* ################################################################## */
    /**
     */
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return self.colorDisplayPickerView == pickerView ? 80 : pickerView.bounds.size.height * 0.4
    }
    
    /* ################################################################## */
    /**
     */
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing inView: UIView?) -> UIView {
        let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: pickerView.bounds.size.width, height: self.pickerView(pickerView, rowHeightForComponent: component)))
        var ret = UIView(frame: frame)

        if self.colorDisplayPickerView == pickerView {
            let insetView = UIView(frame: frame.insetBy(dx: pickerView.bounds.size.width * 0.01, dy: pickerView.bounds.size.width * 0.01))
            insetView.backgroundColor = self._colorSelection[row]
            ret.addSubview(insetView)
        } else {
            let frame = CGRect(x: 0, y: 0, width: pickerView.bounds.size.width, height: self.pickerView(pickerView, rowHeightForComponent: component))
            let reusingView = nil != inView ? inView!: UIView(frame: frame)
            self._fontSizeCache = self.pickerView(pickerView, rowHeightForComponent: 0)
            ret = self.createDisplayView(reusingView, index: row)
        }
        ret.backgroundColor = UIColor.clear
        return ret
    }
    
    /* ################################################################## */
    /**
     */
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if self.colorDisplayPickerView == pickerView {
            self.selectedColorIndex = row
            self.mainDisplayPickerView.reloadComponent(0)
        } else {
            self.selectedFontIndex = row
        }
    }
}
