/**
 © Copyright 2018, The Great Rift Valley Software Company. All rights reserved.
 
 This code is proprietary and confidential code,
 It is NOT to be reused or combined into any application,
 unless done so, specifically under written license from The Great Rift Valley Software Company.
 
 The Great Rift Valley Software Company: https://riftvalleysoftware.com
 */

import UIKit
import MediaPlayer
import AVKit

/* ###################################################################################################################################### */
// MARK: - Main Functions Extension -
/* ###################################################################################################################################### */
/**
 This extension breaks out the main functions and Appearance Editor into a separate file.
 */
extension MainScreenViewController {
    /* ################################################################## */
    // MARK: - Instance Main Display Methods
    /* ################################################################## */
    /**
     */
    func showLargeLookupThrobber() {
        self.wholeScreenThrobber.color = self.selectedColor
        self.wholeScreenThrobberView.backgroundColor = self.backgroundColor
        self.wholeScreenThrobberView.isHidden = false
    }
    
    /* ################################################################## */
    /**
     */
    func hideLargeLookupThrobber() {
        self.wholeScreenThrobberView.isHidden = true
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
        
        self.leftBrightnessSlider?.endColor = self.selectedColor
        self.leftBrightnessSlider?.brightness = self.selectedBrightness
        self.leftBrightnessSlider?.setNeedsDisplay()
        
        self.rightBrightnessSlider?.endColor = self.selectedColor
        self.rightBrightnessSlider?.brightness = self.selectedBrightness
        self.rightBrightnessSlider?.setNeedsDisplay()
        
        var frame = inContainerView.bounds
        frame.size.height = inContainerView.bounds.height
        let fontName = self.fontSelection[inIndex]
        let fontSize = 0 == self.fontSizeCache ? self.mainNumberDisplayView.bounds.size.height : self.fontSizeCache
        self.fontSizeCache = fontSize
        
        if 0 < fontSize, let font = UIFont(name: fontName, size: fontSize) {
            let text = self.currentTimeString.time
            
            // We'll have a couple of different colors for our gradient.
            var endColor: UIColor
            var startColor: UIColor
            
            if 0 == self.selectedColorIndex {   // White just uses...white. No need to get fancy.
                endColor = UIColor(white: 0.9 * self.selectedBrightness, alpha: 1.0)
                startColor = UIColor(white: 1.25 * self.selectedBrightness, alpha: 1.0)
            } else {    // We use HSB to change the brightness, without changing the color.
                let hue = self.selectedColor.hsba.h
                endColor = UIColor(hue: hue, saturation: 1.0, brightness: 0.9 * self.selectedBrightness, alpha: 1.0)
                startColor = UIColor(hue: hue, saturation: 0.85, brightness: 1.25 * self.selectedBrightness, alpha: 1.0)
            }
            
            // The background can get darker than the text.
            self.backgroundColor = (self.selectedBrightness == self.minimumBrightness) ? UIColor.black : UIColor(white: 0.25 * self.selectedBrightness, alpha: 1.0)
            if self.mainPickerContainerView.isHidden, -1 == self.currentlyEditingAlarmIndex { // We don't do this if we are in the appearance or alarm editor.
                TheBestClockAppDelegate.recordOriginalBrightness()
                UIScreen.main.brightness = self.selectedBrightness    // Also dim the screen.
            }
            
            // We create a gradient layer, with our color going from slightly darker, to full brightness.
            self.view.backgroundColor = self.backgroundColor
            let displayLabelGradient = UIView(frame: frame)
            let gradient = CAGradientLayer()
            gradient.colors = [startColor.cgColor, endColor.cgColor]
            gradient.startPoint = CGPoint(x: 0.5, y: 0)
            gradient.endPoint = CGPoint(x: 0.5, y: 1.0)
            gradient.frame = frame
            displayLabelGradient.layer.addSublayer(gradient)
            
            // The label will actually be used as a pass-through mask, against our gradient. That's how we can show text as a gradient.
            let displayLabel = UILabel(frame: frame)
            displayLabel.setContentCompressionResistancePriority(.required, for: .vertical)
            displayLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            displayLabel.font = font
            displayLabel.adjustsFontSizeToFitWidth = true
            displayLabel.textAlignment = .center
            displayLabel.baselineAdjustment = .alignCenters
            displayLabel.text = text
            
            // We use our auto-layout method to add the subview, so it has AL constraints.
            displayLabelGradient.addContainedView(displayLabel)
            inContainerView.addContainedView(displayLabelGradient)
            
            inContainerView.mask = displayLabel // This is where the gradient magic happens. The label is used as a mask.
        }
        
        return inContainerView
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
            let hue = self.selectedColor.hsba.h
            textColor = UIColor(hue: hue, saturation: 1.0, brightness: 1.3 * self.selectedBrightness, alpha: 1.0)
        }
        
        self.amPmLabel.font = UIFont(name: self.selectedFontName, size: self.amPmLabelFontSize)
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
            let hue = self.selectedColor.hsba.h
            textColor = UIColor(hue: hue, saturation: 1.0, brightness: 1.4 * self.selectedBrightness, alpha: 1.0)
        }
        
        self.dateDisplayLabel.font = UIFont(name: self.selectedFontName, size: self.dateLabelFontSize)
        self.dateDisplayLabel.text = self.currentTimeString.date
        self.dateDisplayLabel.adjustsFontSizeToFitWidth = true
        self.dateDisplayLabel.textAlignment = .center
        self.dateDisplayLabel.textColor = textColor
    }
    
    /* ################################################################## */
    // MARK: - Alarm Strip Methods
    /* ################################################################## */
    /**
     This creates and links up the row of buttons along the bottom of the screen.
     */
    func setUpAlarms() {
        // Take out the trash.
        for subview in self.alarmContainerView.subviews {
            subview.removeFromSuperview()
        }
        
        let alarms = self.prefs.alarms
        self.alarmButtons = []
        
        if !alarms.isEmpty {
            let percentage = CGFloat(1) / CGFloat(alarms.count)   // This will be used for our auto-layout stuff.
            var prevButton: TheBestClockAlarmView!
            var index = 0
            
            for alarm in alarms {
                let alarmButton = TheBestClockAlarmView(alarmRecord: alarm)
                self.addAlarmView(alarmButton, percentage: percentage, previousView: prevButton)
                alarmButton.delegate = self
                alarmButton.index = index
                alarmButton.alarmRecord.deactivated = true  // We start off deactivated, so we don't start blaring immediately.
                index += 1
                prevButton = alarmButton
            }
            
            self.updateAlarms()
        }
    }
    
    /* ################################################################## */
    /**
     This updates the alarm buttons to reflect the brightness, color and font.
     */
    func updateAlarms() {
        let alarms = self.alarmButtons
        
        for alarm in alarms {
            alarm.brightness = self.selectedBrightness
            alarm.fontColor = 0 == self.selectedColorIndex ? nil : self.selectedColor
            alarm.fontName = self.selectedFontName
            alarm.desiredFontSize = self.alarmsFontSize
        }
    }
    
    /* ################################################################## */
    /**
     This adds a single new alarm button to the bottom strip.
     
     We use this, so the buttons get autolayout constraints.
     
     - parameter inSubView: The button to add.
     - parameter percentage: The width, as a percentage (0 -> 1.0) of the total strip width, of the subview.
     - parameter previousView: If there was a view to the left, this is it.
     */
    func addAlarmView(_ inSubView: TheBestClockAlarmView, percentage inPercentage: CGFloat, previousView inPreviousView: TheBestClockAlarmView!) {
        self.alarmContainerView.addSubview(inSubView)
        self.alarmButtons.append(inSubView)
        inSubView.addTarget(self, action: #selector(type(of: self).alarmActiveStateChanged(_:)), for: .valueChanged)
        
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
    // MARK: - Running Clock and Alarm Methods
    /* ################################################################## */
    /**
     This scans the alarms, and looks for anyone that wants to ring their bell.
     
     - parameter soundOnly: IOf true (default is false), then this will not flash the display, and will only trigger the sound.
     */
    func checkAlarmStatus(soundOnly: Bool = false) {
        var index = 0
        var noAlarms = true // If we find an active alarm, this is made false.
        // If we have an active alarm, then we throw the switch, iGor.
        for alarm in self.prefs.alarms {
            if alarm.isAlarming {
                noAlarms = false
                if !soundOnly { // See if we want to be a flasher.
                    self.flashDisplay(self.selectedColor)
                }
                self.aooGah(index) // Play a sound and/or vibrate.
            } else if alarm.snoozing {  // If we have a snozing alarm, then it will "snore."
                self.zzzz(index)
            }
            
            index += 1
        }
        
        // If we are in hush time, then we shouldn't be talking.
        if noAlarms {
            self.stopAudioPlayer()
        }
    }
    
    /* ################################################################## */
    /**
     This plays whatever alarm is supposed to be alarming. This will vibrate, if we are set to do that.
     
     - parameter inIndex: This is the index of the alarm to be played.
     */
    func aooGah(_ inIndex: Int) {
        self.alarmDisplayView.isHidden = false
        if self.prefs.alarms[inIndex].isVibrateOn {
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        }
        
        if self.wholeScreenThrobberView.isHidden, .denied != MPMediaLibrary.authorizationStatus(), .music == self.prefs.alarms[inIndex].selectedSoundMode, self.artists.isEmpty {
            self.loadMediaLibrary(displayWholeScreenThrobber: true)
        }
        
        self.playSound(inIndex)
    }
    
    /* ################################################################## */
    /**
     This flashes the display in a fading animation.
     
     - parameter inUIColor: This is the color to flash.
     */
    func flashDisplay(_ inUIColor: UIColor) {
        self.flasherView.backgroundColor = inUIColor
        self.flasherView.alpha = 0
        UIView.animate(withDuration: 0.05, animations: { [unowned self] in
            self.flasherView.alpha = 1.0
        })
        UIView.animate(withDuration: 0.7, animations: { [unowned self] in
            self.flasherView.alpha = 0.0
        })
    }
    
    /* ################################################################## */
    /**
     - This is called periodically to tell a snoozing alarm to "snore" (visibly pulse).
     */
    func zzzz(_ inIndex: Int) {
        self.alarmButtons[inIndex].snore()
    }
    
    /* ################################################################## */
    /**
     This starts our regular 1-second ticker.
     */
    func startTicker() {
        self.updateMainTime()
        self.checkAlarmStatus() // This just makes sure we get "instant on," if that's what we selected.
        if nil == self.ticker {
            self.ticker = RepeatingGCDTimer(timeInterval: 1)
            self.ticker.eventHandler = self.checkTicker
            self.ticker.resume()
        }
    }
    
    /* ################################################################## */
    /**
     This stops our regular 1-second ticker.
     */
    func stopTicker() {
        if nil != self.ticker {
            self.ticker.eventHandler = nil
            self.ticker = nil
        }
    }
    
    /* ################################################################## */
    /**
     This simply redraws the main time and the two adjacent labels.
     */
    func updateMainTime() {
        _ = self.createDisplayView(self.mainNumberDisplayView, index: self.selectedFontIndex)
        self.setAMPMLabel()
        self.setDateDisplayLabel()
        self.updateAlarms()
    }
    
    /* ################################################################## */
    /**
     This is called from the timer.
     */
    func checkTicker() {
        DispatchQueue.main.sync {
            #if DEBUG
            print("Checking Timer: " + String(describing: Date()))
            #endif
            self.updateMainTime()
            self.checkAlarmStatus()
        }
    }
    
    /* ################################################################## */
    /**
     This is called at load time, to add the various localized accessibility labels and hints to our elements on the main display screen.
     */
    func setUpMainScreenAccessibility() {
        self.mainNumberDisplayView.accessibilityLabel = "LOCAL-ACCESSIBILITY-LABEL-MAIN-TIME".localizedVariant
        self.mainNumberDisplayView.accessibilityHint = "LOCAL-ACCESSIBILITY-HINT-MAIN-TIME".localizedVariant
        self.dateDisplayLabel.accessibilityLabel = "LOCAL-ACCESSIBILITY-LABEL-MAIN-DATE".localizedVariant
        self.amPmLabel.accessibilityLabel = "LOCAL-ACCESSIBILITY-AMPM-LABEL".localizedVariant
        self.rightBrightnessSlider.accessibilityLabel = "LOCAL-ACCESSIBILITY-BRIGHTNESS-SLIDER".localizedVariant
        self.rightBrightnessSlider.accessibilityHint = "LOCAL-ACCESSIBILITY-BRIGHTNESS-SLIDER-HINT".localizedVariant
        self.alarmContainerView.accessibilityLabel = "LOCAL-ACCESSIBILITY-ALARM-CONTAINER".localizedVariant
        self.alarmContainerView.accessibilityHint = "LOCAL-ACCESSIBILITY-ALARM-CONTAINER-HINT".localizedVariant
        self.alarmDisplayView.accessibilityLabel = "LOCAL-ACCESSIBILITY-ALARM-DISPLAY".localizedVariant
        self.alarmDisplayView.accessibilityHint = "LOCAL-ACCESSIBILITY-ALARM-DISPLAY-HINT".localizedVariant
    }
    
    /* ################################################################## */
    /**
     This is called at load time, to add the various localized accessibility labels and hints to our elements in the Appearance Editor screen.
     */
    func setUpAppearanceEditorAccessibility() {
        self.colorDisplayPickerView.accessibilityLabel = "LOCAL-ACCESSIBILITY-COLOR-PICKER-LABEL".localizedVariant
        self.colorDisplayPickerView.accessibilityHint = "LOCAL-ACCESSIBILITY-COLOR-PICKER-HINT".localizedVariant
        self.fontDisplayPickerView.accessibilityLabel = "LOCAL-ACCESSIBILITY-FONT-PICKER-LABEL".localizedVariant
        self.fontDisplayPickerView.accessibilityHint = "LOCAL-ACCESSIBILITY-FONT-PICKER-HINT".localizedVariant
        self.infoButton.accessibilityLabel = "LOCAL-ACCESSIBILITY-INFO-BUTTON-LABEL".localizedVariant
        self.infoButton.accessibilityHint = "LOCAL-ACCESSIBILITY-INFO-BUTTON-HINT".localizedVariant
    }
    
    /* ################################################################## */
    /**
     This is called to update the color of the "info" button in the Appearance Editor.
     */
    func setInfoButtonColor() {
        var textColor: UIColor
        if 0 == self.selectedColorIndex {
            textColor = UIColor(white: 1.0, alpha: 1.0)
        } else {
            let hue = self.selectedColor.hsba.h
            textColor = UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        }
        
        self.infoButton.tintColor = textColor
    }

    /* ################################################################## */
    // MARK: - Instance IBAction Methods
    /* ################################################################## */
    /**
     This is called when the user taps in an alarm active screen.
     
     - parameter: ignored
     */
    @IBAction func hitTheSnooze(_: UITapGestureRecognizer) {
        for index in 0..<self.prefs.alarms.count where self.prefs.alarms[index].isAlarming {
            self.prefs.alarms[index].snoozing = true
        }
        self.stopAudioPlayer()
        self.alarmDisplayView.isHidden = true
    }
    
    /* ################################################################## */
    /**
     This is called when the user long-presses in an alarm active screen.
     
     - parameter: ignored
     */
    @IBAction func shutUpAlready(_: UILongPressGestureRecognizer) {
        for index in 0..<self.prefs.alarms.count where self.prefs.alarms[index].isAlarming {
            self.prefs.alarms[index].deactivated = true
            self.prefs.alarms[index].isActive = false
            self.prefs.savePrefs()
            self.alarmButtons[index].alarmRecord.isActive = false
        }
        self.stopAudioPlayer()
        self.alarmDisplayView.isHidden = true
    }
    
    /* ################################################################## */
    /**
     This is called when the user taps in an alarm on the main screen, toggling it.
     
     - parameter inSender: The alarm button that was hit.
     */
    @IBAction func alarmActiveStateChanged(_ inSender: TheBestClockAlarmView) {
        if -1 == self.currentlyEditingAlarmIndex {
            for index in 0..<self.alarmButtons.count where self.alarmButtons[index] == inSender {
                if let alarmRecord = inSender.alarmRecord {
                    if alarmRecord.isActive {
                        self.prefs.alarms[index].deactivated = true
                    }
                    self.prefs.alarms[index].isActive = alarmRecord.isActive
                    self.prefs.savePrefs()
                }
            }
            self.checkAlarmStatus() // This just makes sure we get "instant on," if that's what we selected.
        }
    }
    
    /* ################################################################## */
    /**
     This is called when a brightness slider is changed.
     
     - parameter inSlider: The brightness slider being manipulated.
     */
    @IBAction func brightnessSliderChanged(_ inSlider: TheBestClockVerticalBrightnessSliderView) {
        self.selectedBrightness = max(self.minimumBrightness, min(inSlider.brightness, 1.0))
        let newBrightness = min(1.0, self.selectedBrightness)
        self.prefs?.brightnessLevel = newBrightness
        TheBestClockAppDelegate.recordOriginalBrightness()
        UIScreen.main.brightness = newBrightness    // Also dim the screen.
        self.updateMainTime()
    }
    
    /* ################################################################## */
    /**
     This is called when a slider opens, so we don't have the situation where both are open at once.
     
     - parameter inSlider: The slider object that called this
     */
    @IBAction func brightnessSliderOpened(_ inSlider: TheBestClockVerticalBrightnessSliderView) {
        if inSlider == self.rightBrightnessSlider {
            self.leftBrightnessSlider.isEnabled = false
        } else {
            self.rightBrightnessSlider.isEnabled = false
        }
    }
    
    /* ################################################################## */
    /**
     This is called when an open slider closes. We re-enable both sliders.
     
     - parameter: ignored
     */
    @IBAction func brightnessSliderClosed(_: Any) {
        self.leftBrightnessSlider.isEnabled = true
        self.rightBrightnessSlider.isEnabled = true
    }
    
    /* ################################################################## */
    // MARK: - Appearance Editor Methods
    /* ################################################################## */
    /**
     This is called when we first open the Appearance (font and color) Editor.
     
     - parameter: ignored
     */
    @IBAction func openAppearanceEditor(_: Any) {
        self.stopTicker()
        self.fontDisplayPickerView.delegate = self
        self.fontDisplayPickerView.dataSource = self
        self.colorDisplayPickerView.delegate = self
        self.colorDisplayPickerView.dataSource = self
        self.mainPickerContainerView.backgroundColor = self.backgroundColor
        self.fontDisplayPickerView.backgroundColor = self.backgroundColor
        self.colorDisplayPickerView.backgroundColor = self.backgroundColor
        self.fontDisplayPickerView.selectRow(self.selectedFontIndex, inComponent: 0, animated: false)
        self.colorDisplayPickerView.selectRow(self.selectedColorIndex, inComponent: 0, animated: false)
        TheBestClockAppDelegate.restoreOriginalBrightness()
        self.mainPickerContainerView.isHidden = false
    }
    
    /* ################################################################## */
    /**
     This is called when the user taps in the info button.
     
     - parameter: ignored
     */
    @IBAction func openInfo(_: Any) {
        self.performSegue(withIdentifier: "open-info", sender: nil)
    }
    
    /* ################################################################## */
    /**
     This is called to close the Appearance Editor.
     
     - parameter: ignored
     */
    @IBAction func closeAppearanceEditor(_: Any) {
        self.fontDisplayPickerView.delegate = nil
        self.fontDisplayPickerView.dataSource = nil
        self.colorDisplayPickerView.delegate = nil
        self.colorDisplayPickerView.dataSource = nil
        self.fontSizeCache = 0
        self.mainPickerContainerView.isHidden = true
        self.startTicker()
    }
    
    /* ################################################################## */
    // MARK: - Instance Superclass Overrides
    /* ################################################################## */
    /**
     This is called when the resources and storyboard are all loaded up for the first time.
     We use this to initialize most of our settings.
     */
    override func viewDidLoad() {
        TheBestClockAppDelegate.delegateObject.theMainController = self
        // We start by setting up our font and color Arrays.
        for fontFamilyName in UIFont.familyNames {
            for fontName in UIFont.fontNames(forFamilyName: fontFamilyName) {
                if self.screenForThese.contains(fontName) {
                    self.fontSelection.append(fontName)
                }
            }
        }
        // So we have a predictable order.
        self.fontSelection.sort()
        
        // We add this to the beginning.
        self.fontSelection.insert(contentsOf: ["Let's Go Digital"], at: 0)
        self.fontSelection.append(contentsOf: ["AnglicanText", "Canterbury", "CelticHand"])
        
        // Pick up our beeper sounds.
        self.soundSelection = Bundle.main.paths(forResourcesOfType: "mp3", inDirectory: nil)
        
        // The first index is white.
        self.colorSelection = [UIColor.white]
        // We generate a series of colors, fully saturated, from red (orangeish) to red (purpleish).
        for hue: CGFloat in stride(from: 0.0, to: 1.0, by: 0.05) {
            let color = UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
            self.colorSelection.append(color)
        }
        
        // Set up our persistent prefs, reading in any previously stored prefs.
        self.prefs = TheBestClockPrefs()
        self.selectedFontIndex = self.prefs.selectedFont
        self.selectedColorIndex = self.prefs.selectedColor
        self.selectedBrightness = self.prefs.brightnessLevel
        self.updateMainTime()   // This will update the time. It will also set up our various labels and background colors.
        self.setInfoButtonColor()
        self.noMusicAvailableLabel.text = self.noMusicAvailableLabel.text?.localizedVariant
        self.alarmDeactivatedLabel.text = self.alarmDeactivatedLabel.text?.localizedVariant
        self.alarmEditorActiveButton.setTitle(self.alarmEditorActiveButton.title(for: .normal)?.localizedVariant, for: .normal)
        self.alarmEditorVibrateButton.setTitle(self.alarmEditorVibrateButton.title(for: .normal)?.localizedVariant, for: .normal)
        self.editAlarmTestSoundButton.setTitle("LOCAL-TEST-SOUND".localizedVariant, for: .normal)
        self.musicTestButton.setTitle("LOCAL-TEST-SONG".localizedVariant, for: .normal)
        self.snoozeGestureRecogninzer.require(toFail: self.shutUpAlreadyGestureRecognizer)
        // Set up accessibility labels and hints.
        self.setUpMainScreenAccessibility()
        self.setUpAppearanceEditorAccessibility()
        self.setUpAlarmEditorAccessibility()
        self.setUpAlarms()
    }
    
    /* ################################################################## */
    /**
     This is called when we are about to layout our views (like when we rotate).
     We redraw everything, and force a new font size setting by zeroing the "cache."
     */
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.fontSizeCache = 0
        self.updateMainTime()
        if self.mainPickerContainerView.isHidden, -1 == self.currentlyEditingAlarmIndex { // We don't do this if we are in the appearance editor.
            UIScreen.main.brightness = self.selectedBrightness    // Dim the screen.
        } else {
            if 0 <= self.currentlyEditingAlarmIndex, self.prefs.alarms.count > self.currentlyEditingAlarmIndex {
                if self.alarmEditorMinimumHeight > UIScreen.main.bounds.size.height || self.alarmEditorMinimumHeight > UIScreen.main.bounds.size.width {
                    TheBestClockAppDelegate.lockOrientation(.portrait, andRotateTo: .portrait)
                }
            }
        }
    }
    
    /* ################################################################## */
    /**
     This is called when the view is about to appear.
     We make sure that we redraw everything with a zeroed cache, and start the "don't sleep" thingy.
     We also start a one-second timer.
     */
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.fontSizeCache = 0
        self.startTicker()
        self.updateMainTime()
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
     When the view will disappear, we stop the caffiene drip, and the timer.
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? TheBestClockAboutScreenViewController {
            destination.view.backgroundColor = self.view.backgroundColor
            destination.baseColor = self.selectedColor
            destination.baseFont = UIFont(name: self.selectedFontName, size: 30)
        }
    }
    
    /* ################################################################## */
    // MARK: - Instance Alarm Editor Delegate Methods
    /* ################################################################## */
    /**
     This is called to open the Alarm Editor for an indexed alarm.
     
     - parameter inAlarmIndex: 0-2. The index of the alarm to be edited.
     */
    func openAlarmEditor(_ inAlarmIndex: Int) {
        if 0 <= inAlarmIndex, self.prefs.alarms.count > inAlarmIndex {
            if -1 == self.currentlyEditingAlarmIndex {
                self.currentlyEditingAlarmIndex = inAlarmIndex
                self.prefs.alarms[self.currentlyEditingAlarmIndex].isActive = true
                self.alarmButtons[self.currentlyEditingAlarmIndex].alarmRecord.isActive = true
                self.openAlarmEditorScreen()
            }
        }
    }
}
