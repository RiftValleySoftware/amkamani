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
                                             "Georgia-Bold",
                                             "GillSans-Light",
                                             "GillSans-UltraBold",
                                             "Helvetica-Bold",
                                             "HelveticaNeue-UltraLight",
                                             "HoeflerText-Black",
                                             "MarkerFelt-Wide",
                                             "Noteworthy-Bold",
                                             "Palatino-Roman",
                                             "Papyrus",
                                             "TimesNewRomanPS-BoldMT",
                                             "TimesNewRomanPS-ItalicMT",
                                             "TrebuchetMS-Bold",
                                             "Verdana-Bold"]
    private let _minimumBrightness: CGFloat = 0.05
    private let _amPmLabelFontSize: CGFloat = 30
    private let _dateLabelFontSize: CGFloat = 40
    
    private var _prefs: TheBestClockPrefs!

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
    private func _setUpAlarms() {
        // Take out the trash.
        for subview in self.alarmContainerView.subviews {
            subview.removeFromSuperview()
        }
        
        let alarms = self._prefs.alarms
        if !alarms.isEmpty {
            let percentage = CGFloat(1) / CGFloat(alarms.count)   // THis will be used for our auto-layout stuff.
            var prevButton: TheBestClockAlarmView!
            for alarm in alarms {
                let alarmButton = TheBestClockAlarmView(alarmRecord: alarm,
                                                        fontName: self._fontSelection[self.selectedFontIndex],
                                                        fontColor: 0 == self.selectedColorIndex ? nil : self._colorSelection[self.selectedColorIndex],
                                                        brightness: self.selectedBrightness,
                                                        desiredFontSize: 40,
                                                        controller: self)
                self.addAlarmView(alarmButton, percentage: percentage, previousView: prevButton)
                prevButton = alarmButton
            }
        }
    }
    
    /* ################################################################## */
    /**
     */
    func addAlarmView(_ inSubView: TheBestClockAlarmView, percentage inPercentage: CGFloat, previousView inPreviousView: TheBestClockAlarmView!) {
        self.alarmContainerView.addSubview(inSubView)
        
        inSubView.translatesAutoresizingMaskIntoConstraints = false
        
        var leftConstraint: NSLayoutConstraint!

        if nil == inPreviousView {
            leftConstraint = NSLayoutConstraint(item: inSubView,
                                                attribute: .left,
                                                relatedBy: .equal,
                                                toItem: self.alarmContainerView,
                                                attribute: .left,
                                                multiplier: 1.0,
                                                constant: 0)
        } else {
            leftConstraint = NSLayoutConstraint(item: inSubView,
                                                attribute: .left,
                                                relatedBy: .equal,
                                                toItem: inPreviousView,
                                                attribute: .right,
                                                multiplier: 1.0,
                                                constant: 0)
        }
        
        self.alarmContainerView.addConstraints([leftConstraint,
            NSLayoutConstraint(item: inSubView,
                               attribute: .top,
                               relatedBy: .equal,
                               toItem: self.alarmContainerView,
                               attribute: .top,
                               multiplier: 1.0,
                               constant: 0),
            NSLayoutConstraint(item: inSubView,
                               attribute: .bottom,
                               relatedBy: .equal,
                               toItem: self.alarmContainerView,
                               attribute: .bottom,
                               multiplier: 1.0,
                               constant: 0),
            NSLayoutConstraint(item: inSubView,
                               attribute: .width,
                               relatedBy: .equal,
                               toItem: self.alarmContainerView,
                               attribute: .width,
                               multiplier: inPercentage,
                               constant: 1)])
    }

    /* ################################################################## */
    /**
     */
    private func _getFontSize(_ inFontName: String, size inSize: CGSize) -> CGFloat {
        return self.mainNumberDisplayView.bounds.size.height
    }

    /// This is the UIPickerView that is used to select the font.
    @IBOutlet weak var fontDisplayPickerView: UIPickerView!
    /// This is the UIPickerView that is used to select the color.
    @IBOutlet weak var colorDisplayPickerView: UIPickerView!
    /// This is the main view, holding the standard display items.
    @IBOutlet weak var mainNumberDisplayView: UIView!
    /// This is a normally hidden view that holds the color and font selection UIPickerViews
    @IBOutlet weak var mainPickerContainerView: UIView!
    /// This is the hidden slider for changing the brightness.
    @IBOutlet weak var brightnessSlider: TheBestClockVerticalBrightnessSliderView!
    /// This is the label that displays ante meridian (AM/PM).
    @IBOutlet weak var amPmLabel: UILabel!
    /// This is the label that displays today's date.
    @IBOutlet weak var dateDisplayLabel: UILabel!
    /// This view will hold our alarm displays.
    @IBOutlet weak var alarmContainerView: UIView!
    
    /* ################################################################## */
    /**
     */
    var selectedFontIndex: Int = 0 {
        didSet {
            self._prefs?.selectedFont = self.selectedFontIndex
        }
    }
    
    /* ################################################################## */
    /**
     */
    var selectedColorIndex: Int = 0 {
        didSet {
            self._prefs?.selectedColor = self.selectedColorIndex
        }
    }
    
    /* ################################################################## */
    /**
     */
    var selectedBrightness: CGFloat = 1.0 {
        didSet {
            self._prefs?.brightnessLevel = min(1.0, self.selectedBrightness)
        }
    }

    /* ################################################################## */
    /**
     */
    @IBAction func brightnessSliderChanged(_ sender: TheBestClockVerticalBrightnessSliderView) {
        self.selectedBrightness = max(self._minimumBrightness, min(sender.brightness, 1.0))
        self.updateMainTime()
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func closeAppearanceEditor(_ sender: Any) {
        self.fontDisplayPickerView.delegate = nil
        self.fontDisplayPickerView.dataSource = nil
        self.colorDisplayPickerView.delegate = nil
        self.colorDisplayPickerView.dataSource = nil
        self._fontSizeCache = 0
        mainPickerContainerView.isHidden = true
        self.updateMainTime()
        self._setUpAlarms()
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func openAppearanceEditor(_ sender: Any) {
        self.mainPickerContainerView.isHidden = false
        self.fontDisplayPickerView.delegate = self
        self.fontDisplayPickerView.dataSource = self
        self.colorDisplayPickerView.delegate = self
        self.colorDisplayPickerView.dataSource = self
        self.mainPickerContainerView.backgroundColor = self._backgroundColor
        self.fontDisplayPickerView.backgroundColor = self._backgroundColor
        self.colorDisplayPickerView.backgroundColor = self._backgroundColor
        self.fontDisplayPickerView.selectRow(self.selectedFontIndex, inComponent: 0, animated: false)
        self.colorDisplayPickerView.selectRow(self.selectedColorIndex, inComponent: 0, animated: false)
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
        
        let stringFormatter = DateFormatter()
        stringFormatter.locale = Locale.current
        stringFormatter.timeStyle = .none
        stringFormatter.dateStyle = .full

        let dateString = stringFormatter.string(from: Date())
        
        return TimeDateContainer(time: timeString, amPm: amPMString, date: dateString)
    }

    /* ################################################################## */
    /**
     This is called when the resources and storyboard are all loaded up for the first time.
     We use this to initialize most of our settings.
     */
    override func viewDidLoad() {
        // We start by setting up our font and color Arrays.
        for fontFamilyName in UIFont.familyNames {
            for fontName in UIFont.fontNames(forFamilyName: fontFamilyName) {
                if self._screenForThese.contains(fontName) {
                    self._fontSelection.append(fontName)
                }
            }
        }
        // So we have a predictable order.
        self._fontSelection.sort()
        
        // We add this to the beginning.
        self._fontSelection.insert(contentsOf: ["Let's Go Digital"], at: 0)
        
        // The first index is white.
        self._colorSelection = [UIColor.white]
        // We generate a series of colors, fully saturated, from red (orangeish) to red (purpleish).
        for hue: CGFloat in stride(from: 0.0, to: 1.0, by: 0.05) {
            let color = UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
            self._colorSelection.append(color)
        }

        // Set up our persistent prefs, reading in any previously stored prefs.
        self._prefs = TheBestClockPrefs()
        self.selectedFontIndex = self._prefs.selectedFont
        self.selectedColorIndex = self._prefs.selectedColor
        self.selectedBrightness = self._prefs.brightnessLevel
        self.updateMainTime()   // This will update the time. It will also set up our various labels and background colors.
        self._setUpAlarms()
    }
    
    /* ################################################################## */
    /**
     This is called when we are about to layout our views (like when we rotate).
     We redraw everything, and force a new font size setting by zeroing the "cache."
     */
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self._fontSizeCache = 0
        self.updateMainTime()
    }
    
    /* ################################################################## */
    /**
     This is called when the view is about to appear.
     We make sure that we redraw everything with a zeroed cache, and start the "don't sleep" thingy.
     We also start a one-second timer.
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
     When the view will disappear, we stop the caffiene drip, and the timer.
     */
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = false
        self._ticker.invalidate()
        self._ticker = nil
        super.viewWillDisappear(animated)
    }

    /* ################################################################## */
    /**
     This simply redraws the main time and the two adjacent labels.
     */
    func updateMainTime() {
        _ = self.createDisplayView(self.mainNumberDisplayView, index: self.selectedFontIndex)
        self.setAMPMLabel()
        self.setDateDisplayLabel()
    }
    
    /* ################################################################## */
    /**
     This sets (or clears) the ante meridian label. We use a solid bright text color.
     */
    func setAMPMLabel() {
        self.amPmLabel.backgroundColor = UIColor.clear
        var textColor: UIColor
        if 0 == self.selectedColorIndex {
            textColor = UIColor(white: self.selectedBrightness, alpha: 1.0)
        } else {
            let hue = self._colorSelection[self.selectedColorIndex].hsba.h
            textColor = UIColor(hue: hue, saturation: 1.0, brightness: 1.3 * self.selectedBrightness, alpha: 1.0)
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
     This sets the date label. We use a solid bright text color.
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
        self.dateDisplayLabel.textColor = textColor
    }

    /* ################################################################## */
    /**
     This creates the display, as a gradient-filled font.
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
            displayLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            displayLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
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
     There can only be one...
     
     - parameter in: The UIPickerView being queried.
     
     - returns: 1 (all the time)
     */
    func numberOfComponents(in inPickerView: UIPickerView) -> Int {
        return 1
    }

    /* ################################################################## */
    /**
     This simply returns the number of rows in the pickerview. It will switch on which picker is calling it.
     
     - parameter inPickerView: The UIPickerView being queried.
     */
    func pickerView(_ inPickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.colorDisplayPickerView == inPickerView ? self._colorSelection.count : self._fontSelection.count
    }

    /* ################################################################## */
    /**
     This will send the proper height for the picker row. The color picker is small squares.
     
     - parameter inPickerView: The UIPickerView being queried.
     */
    func pickerView(_ inPickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return self.colorDisplayPickerView == inPickerView ? 80 : inPickerView.bounds.size.height * 0.4
    }
    
    /* ################################################################## */
    /**
     This generates one row's content, depending on which picker is being specified.
     
     - parameter inPickerView: The UIPickerView being queried.
     */
    func pickerView(_ inPickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing inView: UIView?) -> UIView {
        let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: inPickerView.bounds.size.width, height: self.pickerView(inPickerView, rowHeightForComponent: component)))
        var ret = UIView(frame: frame)

        // Color picker is simple color squares.
        if self.colorDisplayPickerView == inPickerView {
            let insetView = UIView(frame: frame.insetBy(dx: inPickerView.bounds.size.width * 0.01, dy: inPickerView.bounds.size.width * 0.01))
            insetView.backgroundColor = self._colorSelection[row]
            ret.addSubview(insetView)
        } else {    // We send generated times for the font selector.
            let frame = CGRect(x: 0, y: 0, width: inPickerView.bounds.size.width, height: self.pickerView(inPickerView, rowHeightForComponent: component))
            let reusingView = nil != inView ? inView!: UIView(frame: frame)
            self._fontSizeCache = self.pickerView(inPickerView, rowHeightForComponent: 0)
            ret = self.createDisplayView(reusingView, index: row)
        }
        ret.backgroundColor = UIColor.clear
        return ret
    }
    
    /* ################################################################## */
    /**
     This is called when a picker row is selected, and sets the value for that picker.
     
     - parameter inPickerView: The UIPickerView being queried.
     */
    func pickerView(_ inPickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if self.colorDisplayPickerView == inPickerView {
            self.selectedColorIndex = row
            self.fontDisplayPickerView.reloadComponent(0)
        } else {
            self.selectedFontIndex = row
        }
    }
}
