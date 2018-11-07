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
// MARK: - Main Class -
/* ###################################################################################################################################### */
/**
 */
class MainScreenViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, TheBestClockAlarmViewDelegate {
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
    private let _alarmsFontSize: CGFloat = 40

    private var _prefs: TheBestClockPrefs!
    private var _alarmButtons: [TheBestClockAlarmView] = []

    private var _fontSelection: [String] = []
    private var _colorSelection: [UIColor] = []
    private var _backgroundColor: UIColor = UIColor.gray
    private var _ticker: Timer!
    private var _fontSizeCache: CGFloat = 0
    private var _currentlyEditingAlarmIndex: Int = -1

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
        self._alarmButtons = []
        
        if !alarms.isEmpty {
            let percentage = CGFloat(1) / CGFloat(alarms.count)   // THis will be used for our auto-layout stuff.
            var prevButton: TheBestClockAlarmView!
            var index = 0
            
            for alarm in alarms {
                let alarmButton = TheBestClockAlarmView(alarmRecord: alarm)
                self.addAlarmView(alarmButton, percentage: percentage, previousView: prevButton)
                alarmButton.delegate = self
                alarmButton.index = index
                index += 1
                prevButton = alarmButton
            }
            
            self._updateAlarms()
        }
    }
    
    /* ################################################################## */
    /**
     */
    private func _updateAlarms() {
        let alarms = self._alarmButtons
        
        for alarm in alarms {
            alarm.brightness = self.selectedBrightness
            alarm.fontColor = 0 == self.selectedColorIndex ? nil : self._colorSelection[self.selectedColorIndex]
            alarm.fontName = self._fontSelection[self.selectedFontIndex]
            alarm.desiredFontSize = self._alarmsFontSize
        }
    }

    /* ################################################################## */
    /**
     */
    func addAlarmView(_ inSubView: TheBestClockAlarmView, percentage inPercentage: CGFloat, previousView inPreviousView: TheBestClockAlarmView!) {
        self.alarmContainerView.addSubview(inSubView)
        self._alarmButtons.append(inSubView)
        inSubView.addTarget(self, action: #selector(type(of: self).alarmStateChanged(_:)), for: .valueChanged)
        
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
    
    /* ################################################################## */
    /**
     This sets (or clears) the ante meridian label. We use a solid bright text color.
     */
    private func _setAMPMLabel() {
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
    private func _setDateDisplayLabel() {
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
     */
    private func _checkAlarmStatus() {
        var index = 0
        // If we have an active alarm, then we throw the switch, iGor.
        for alarm in self._prefs.alarms {
            if alarm.alarming {
                self._aooGah(index)
            } else if alarm.snoozing {
                self._zzzz(index)
            }
            
            index += 1
        }
    }
    
    /* ################################################################## */
    /**
     */
    private func _aooGah(_ inIndex: Int) {
        self.alarmDisplayView.backgroundColor = self._colorSelection[self.selectedColorIndex]
        self.alarmDisplayView.isHidden = false
    }
    
    /* ################################################################## */
    /**
     */
    private func _zzzz(_ inIndex: Int) {
        print("zzzz-zzzz-zzzzz")
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
    /// This is a view that will cover the screen if the user wants to edit an alarm.
    @IBOutlet weak var editAlarmScreenContainer: UIView!
    /// This is the date picker in the alarm time editor.
    @IBOutlet weak var editAlarmTimeDatePicker: UIDatePicker!
    /// This will be the flashing view that appears when there's an alarm.
    @IBOutlet weak var alarmDisplayView: UIView!
    
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
    @IBAction func hitTheSnooze(_ inGestureRecognizer: UITapGestureRecognizer) {
        for index in 0..<self._prefs.alarms.count where self._prefs.alarms[index].alarming {
            self._prefs.alarms[index].snoozing = true
        }
        self.alarmDisplayView.isHidden = true
    }

    /* ################################################################## */
    /**
     */
    @IBAction func alarmTimeDatePickerChanged(_ inDatePicker: UIDatePicker) {
        if 0 <= self._currentlyEditingAlarmIndex, self._prefs.alarms.count > self._currentlyEditingAlarmIndex {
            let date = inDatePicker.date
            
            let calendar = Calendar.current
            
            let hour = calendar.component(.hour, from: date)
            let minutes = calendar.component(.minute, from: date)
            
            let time = hour * 100 + minutes
            self._alarmButtons[self._currentlyEditingAlarmIndex].alarmRecord.alarmTime = time
            self._prefs.alarms[self._currentlyEditingAlarmIndex] = self._alarmButtons[self._currentlyEditingAlarmIndex].alarmRecord
        }
    }

    /* ################################################################## */
    /**
     */
    @IBAction func alarmStateChanged(_ sender: TheBestClockAlarmView) {
        for index in 0..<self._alarmButtons.count where self._alarmButtons[index] == sender {
            if let alarmRecord = sender.alarmRecord {
                self._prefs.alarms[index] = alarmRecord
            }
        }
        
        if 0 <= sender.index, self._prefs.alarms.count > sender.index {
            // If we are activating an alarm that is set for midnight, we will open the editor.
            if self._prefs.alarms[sender.index].isActive, 0 == self._prefs.alarms[sender.index].alarmTime {
                self.openAlarmEditor(sender.index)
            }
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
        self.mainPickerContainerView.isHidden = true
        self.updateMainTime()
        self.startTicker()
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func closeAlarmEditorScreen(_ sender: Any) {
        if 0 <= self._currentlyEditingAlarmIndex, self._prefs.alarms.count > self._currentlyEditingAlarmIndex {
            self._prefs.alarms[self._currentlyEditingAlarmIndex].isActive = true
            self._alarmButtons[self._currentlyEditingAlarmIndex].alarmRecord.isActive = true
            self._currentlyEditingAlarmIndex = -1
            self.editAlarmScreenContainer.isHidden = true
            self.updateMainTime()
            self.startTicker()
        }
    }

    /* ################################################################## */
    /**
     */
    func openAlarmEditorScreen() {
        self.stopTicker()
        if 0 <= self._currentlyEditingAlarmIndex, self._prefs.alarms.count > self._currentlyEditingAlarmIndex {
            let time = self._prefs.alarms[self._currentlyEditingAlarmIndex].alarmTime
            let hours = time / 100
            let minutes = time - (hours * 100)
            
            var dateComponents = DateComponents()
            dateComponents.hour = hours
            dateComponents.minute = minutes
            
            let userCalendar = Calendar.current
            if let pickerDate = userCalendar.date(from: dateComponents) {
                self.editAlarmTimeDatePicker.setDate(pickerDate, animated: false)
            }
            self.editAlarmScreenContainer.isHidden = false
        }
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func openAppearanceEditor(_ sender: Any) {
        self.stopTicker()
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
        self.startTicker()
    }
    
    /* ################################################################## */
    /**
     When the view will disappear, we stop the caffiene drip, and the timer.
     */
    override func viewWillDisappear(_ animated: Bool) {
        self.stopTicker()
        super.viewWillDisappear(animated)
    }

    /* ################################################################## */
    /**
     This starts our regular 1-second ticker.
     */
    func startTicker() {
        UIApplication.shared.isIdleTimerDisabled = true // This makes sure that we stay awake while this window is up.
        self._ticker = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [unowned self] _ in
            DispatchQueue.main.async {
                self.updateMainTime()
                self._checkAlarmStatus()
            }
        }
    }

    /* ################################################################## */
    /**
     This stops our regular 1-second ticker.
     */
    func stopTicker() {
        if nil != self._ticker {
            UIApplication.shared.isIdleTimerDisabled = false
            self._ticker.invalidate()
            self._ticker = nil
        }
    }

    /* ################################################################## */
    /**
     This simply redraws the main time and the two adjacent labels.
     */
    func updateMainTime() {
        _ = self.createDisplayView(self.mainNumberDisplayView, index: self.selectedFontIndex)
        self._setAMPMLabel()
        self._setDateDisplayLabel()
        self._updateAlarms()
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
        return self.colorDisplayPickerView == inPickerView ? self._colorSelection.count : (self.fontDisplayPickerView == inPickerView) ? self._fontSelection.count : 0
    }

    /* ################################################################## */
    /**
     This will send the proper height for the picker row. The color picker is small squares.
     
     - parameter inPickerView: The UIPickerView being queried.
     */
    func pickerView(_ inPickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return self.colorDisplayPickerView == inPickerView ? 80 : (self.fontDisplayPickerView == inPickerView) ? inPickerView.bounds.size.height * 0.4 : 0
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
        } else if self.fontDisplayPickerView == inPickerView {    // We send generated times for the font selector.
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
        } else if self.fontDisplayPickerView == inPickerView {
            self.selectedFontIndex = row
        }
    }
    
    /* ################################################################## */
    /**
     */
    func openAlarmEditor(_ inAlarmIndex: Int) {
        if 0 <= inAlarmIndex, self._prefs.alarms.count > inAlarmIndex {
            self._currentlyEditingAlarmIndex = inAlarmIndex
            self._prefs.alarms[self._currentlyEditingAlarmIndex].isActive = true
            self._alarmButtons[self._currentlyEditingAlarmIndex].alarmRecord.isActive = true
            self.openAlarmEditorScreen()
        }
    }
}
