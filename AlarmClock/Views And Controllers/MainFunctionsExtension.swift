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
        inContainerView.subviews.forEach {
            $0.removeFromSuperview()
        }
        
        if let sublayers = inContainerView.layer.sublayers {
            sublayers.forEach {
                $0.removeFromSuperlayer()
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
            
            let brightness = self.mainPickerContainerView.isHidden ? self.selectedBrightness : 1.0
            
            if 0 == self.selectedColorIndex {   // White just uses...white. No need to get fancy.
                endColor = UIColor(white: 0.6 * brightness, alpha: 1.0)
                startColor = UIColor(white: 1.25 * brightness, alpha: 1.0)
            } else {    // We use HSB to change the brightness, without changing the color.
                let hue = self.selectedColor.hsba.h
                endColor = UIColor(hue: hue, saturation: 1.0, brightness: 0.6 * brightness, alpha: 1.0)
                startColor = UIColor(hue: hue, saturation: 0.85, brightness: 1.25 * brightness, alpha: 1.0)
            }
            
            // The background can get darker than the text.
            self.backgroundColor = (self.selectedBrightness <= TheBestClockPrefs.minimumBrightness) ? UIColor.black : UIColor(white: 0.25 * self.selectedBrightness, alpha: 1.0)
            if self.mainPickerContainerView.isHidden, -1 == self.currentlyEditingAlarmIndex { // We don't do this if we are in the appearance or alarm editor.
                TheBestClockAppDelegate.recordOriginalBrightness()
                UIScreen.main.brightness = brightness    // Also dim the screen.
            } else if !self.mainPickerContainerView.isHidden {
                UIScreen.main.brightness = 1.0    // If we are editing, we get full brightness.
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
            inContainerView.accessibilityLabel = self.currentTimeString.time + " " + self.currentTimeString.amPm
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
        
        if !self.currentTimeString.amPm.isEmpty {
            self.amPmLabel.isHidden = false
            self.amPmLabel.font = UIFont(name: self.selectedFontName, size: self.amPmLabelFontSize)
            self.amPmLabel.text = self.currentTimeString.amPm
            self.amPmLabel.adjustsFontSizeToFitWidth = true
            self.amPmLabel.textAlignment = .right
            self.amPmLabel.baselineAdjustment = .alignCenters
            self.amPmLabel.textColor = textColor
            self.amPmLabel.accessibilityLabel = "LOCAL-ACCESSIBILITY-AMPM-LABEL".localizedVariant + " " + self.currentTimeString.amPm
        } else {
            self.amPmLabel.isHidden = true
        }
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
        self.alarmContainerView.subviews.forEach {
            $0.removeFromSuperview()
        }
        
        let alarms = self.prefs.alarms
        self.alarmButtons = []
        
        if !alarms.isEmpty {
            self.alarmContainerView.isAccessibilityElement = false  // This prevents the container from interfering with the alarm buttons.
            let percentage = CGFloat(1) / CGFloat(alarms.count)   // This will be used for our auto-layout stuff.
            var prevButton: TheBestClockAlarmView!
            var index = 0
            
            alarms.forEach {
                let alarmButton = TheBestClockAlarmView(alarmRecord: $0)
                self.addAlarmView(alarmButton, percentage: percentage, previousView: prevButton)
                alarmButton.delegate = self
                alarmButton.index = index
                alarmButton.alarmRecord.deferred = true  // We start off deactivated, so we don't start blaring immediately.
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
        self.alarmButtons.forEach {
            $0.brightness = self.selectedBrightness
            $0.fontColor = 0 == self.selectedColorIndex ? nil : self.selectedColor
            $0.fontName = self.selectedFontName
            $0.desiredFontSize = self.alarmsFontSize
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
     
     - parameter soundOnly: If true (default is false), then this will not flash the display, and will only trigger the sound.
     */
    func checkAlarmStatus(soundOnly: Bool = false) {
        var index = 0
        var noAlarms = true // If we find an active alarm, this is made false.
        
        // If we have an active alarm, then we throw the switch, iGor.
        self.prefs.alarms.forEach {
            if $0.isActive, $0.isAlarming, (self.prefs.noSnoozeLimit || !$0.snoozing || ($0.snoozing && self.snoozeCount <= self.prefs.snoozeCount)) {
                noAlarms = false
                self.alarmSounded = true
                self.alarmDisableScreenView.isHidden = false
                if !soundOnly { // See if we want to be a flasher.
                    self.flashDisplay(self.selectedColor)
                }
                self.aooGah(index) // Play a sound and/or vibrate.
            } else if $0.isActive, $0.snoozing {  // If we have a snoozing alarm, then it will "snore."
                if !self.prefs.noSnoozeLimit, self.snoozeCount > self.prefs.snoozeCount {
                    self.snoozeCount = 0
                    $0.snoozing = false
                    $0.deferred = true
                } else {
                    self.alarmButtons[index].snore()
                }
            }
            
            index += 1
        }
        
        // If we are in hush time, then we shouldn't be talking. We don't do this if we are in the Alarm Editor (where the test would be running).
        if noAlarms, self.alarmSounded, 0 > self.currentlyEditingAlarmIndex {
            self.alarmSounded = false
            self.stopAudioPlayer()
        }
    }
    
    /* ################################################################## */
    /**
     This plays whatever alarm is supposed to be alarming. This will vibrate, if we are set to do that.
     
     - parameter inIndex: This is the index of the alarm to be played.
     */
    func aooGah(_ inIndex: Int) {
        UIApplication.shared.isIdleTimerDisabled = false // Toggle this to "wake" the touch sensor. The system can put it into a "resting" mode, so two touches are required.
        UIApplication.shared.isIdleTimerDisabled = true
        self.alarmDisplayView.isHidden = false
        if self.prefs.alarms[inIndex].isVibrateOn {
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        }
        
        self.playSound(inIndex)
    }
    
    /* ################################################################## */
    /**
     This flashes the display in a fading animation.
     
     - parameter inUIColor: This is the color to flash.
     */
    func flashDisplay(_ inUIColor: UIColor) {
        if let targetView = self.flasherView {
            self.selectedBrightness = 1.0
            UIScreen.main.brightness = self.selectedBrightness
            let oldBackground = targetView.backgroundColor
            let oldAlpha = targetView.alpha
            targetView.backgroundColor = inUIColor
            targetView.alpha = 0
            UIView.animate(withDuration: 0.05,
                           delay: 0,
                           usingSpringWithDamping: 1.0,
                           initialSpringVelocity: 0,
                           options: .allowUserInteraction,
                           animations: { targetView.alpha = 1.0 },
                           completion: nil)
            UIView.animate(withDuration: 0.7,
                           delay: 0,
                           usingSpringWithDamping: 1.0,
                           initialSpringVelocity: 0,
                           options: .allowUserInteraction,
                           animations: { targetView.alpha = 0.0 },
                           completion: { _ in
                            targetView.backgroundColor = oldBackground
                            targetView.alpha = oldAlpha
            })
        }
    }
    
    /* ################################################################## */
    /**
     This starts our regular 1-second ticker.
     */
    func startTicker() {
        self.updateMainTime()
        self.checkTicker() // This just makes sure we get "instant on," if that's what we selected.
        if nil == self.timer {
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [unowned self] (_) in
                self.checkTicker()
            })
            self.timer.tolerance = 0.1  // 100ms tolerance.
        }
    }
    
    /* ################################################################## */
    /**
     This stops our regular 1-second ticker.
     */
    func stopTicker() {
        if nil != self.timer {
            self.timer.invalidate()
            self.timer = nil
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
        DispatchQueue.main.async {
            self.checkAlarmStatus()
            self.updateMainTime()
        }
    }
    
    /* ################################################################## */
    /**
     This is called at load time, to add the various localized accessibility labels and hints to our elements on the main display screen.
     */
    func setUpMainScreenAccessibility() {
        self.mainNumberDisplayView.accessibilityHint = "LOCAL-ACCESSIBILITY-HINT-MAIN-TIME".localizedVariant
        self.dateDisplayLabel.accessibilityLabel = self.dateDisplayLabel.text ?? ""
        self.leftBrightnessSlider.accessibilityLabel = "LOCAL-ACCESSIBILITY-BRIGHTNESS-SLIDER".localizedVariant
        self.leftBrightnessSlider.accessibilityHint = "LOCAL-ACCESSIBILITY-BRIGHTNESS-SLIDER-HINT".localizedVariant
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
        self.fontDisplayPickerView.accessibilityLabel = "LOCAL-ACCESSIBILITY-FONT-SELECTOR-LABEL".localizedVariant
        self.fontDisplayPickerView.accessibilityHint = "LOCAL-ACCESSIBILITY-FONT-SELECTOR-HINT".localizedVariant
        self.infoButton.accessibilityLabel = "LOCAL-ACCESSIBILITY-INFO-BUTTON-LABEL".localizedVariant
        self.infoButton.accessibilityHint = "LOCAL-ACCESSIBILITY-INFO-BUTTON-HINT".localizedVariant
    }
    
    /* ################################################################## */
    /**
     This is called at load time, to add the various localized accessibility labels and hints to our elements in the Alarm Editor screen.
     */
    func setUpAlarmEditorAccessibility() {
        self.alarmEditorActiveSwitch.accessibilityLabel = "LOCAL-ACCESSIBILITY-ALARM-ENABLE-SWITCH-LABEL".localizedVariant
        self.alarmEditorActiveSwitch.accessibilityHint = "LOCAL-ACCESSIBILITY-ALARM-ENABLE-SWITCH-HINT".localizedVariant
        self.alarmEditorActiveButton.accessibilityLabel = "LOCAL-ACCESSIBILITY-ALARM-ENABLE-SWITCH-LABEL".localizedVariant
        self.alarmEditorActiveButton.accessibilityHint = "LOCAL-ACCESSIBILITY-ALARM-ENABLE-SWITCH-HINT".localizedVariant
        self.alarmEditorVibrateBeepSwitch.accessibilityLabel = "LOCAL-ACCESSIBILITY-ALARM-VIBRATE-SWITCH-LABEL".localizedVariant
        self.alarmEditorVibrateBeepSwitch.accessibilityHint = "LOCAL-ACCESSIBILITY-ALARM-VIBRATE-SWITCH-HINT".localizedVariant
        self.alarmEditorVibrateButton.accessibilityLabel = "LOCAL-ACCESSIBILITY-ALARM-VIBRATE-SWITCH-LABEL".localizedVariant
        self.alarmEditorVibrateButton.accessibilityHint = "LOCAL-ACCESSIBILITY-ALARM-VIBRATE-SWITCH-HINT".localizedVariant
        self.editAlarmTimeDatePicker.accessibilityLabel = "LOCAL-ACCESSIBILITY-ALARM-DATE-PICKER-LABEL".localizedVariant
        self.editAlarmTimeDatePicker.accessibilityHint = "LOCAL-ACCESSIBILITY-ALARM-DATE-PICKER-HINT".localizedVariant
        self.alarmEditSoundModeSelector.accessibilityLabel = "LOCAL-ACCESSIBILITY-ALARM-MODE-LABEL".localizedVariant
        self.alarmEditSoundModeSelector.accessibilityHint = "LOCAL-ACCESSIBILITY-ALARM-MODE-HINT".localizedVariant
        self.editAlarmPickerView.accessibilityLabel = "LOCAL-ACCESSIBILITY-EDIT-PICKER-LABEL".localizedVariant
        self.editAlarmPickerView.accessibilityHint = "LOCAL-ACCESSIBILITY-EDIT-PICKER-HINT".localizedVariant
        self.songSelectionPickerView.accessibilityLabel = "LOCAL-ACCESSIBILITY-EDIT-SONG-PICKER-LABEL".localizedVariant
        self.songSelectionPickerView.accessibilityHint = "LOCAL-ACCESSIBILITY-EDIT-SONG-PICKER-HINT".localizedVariant
        self.editAlarmTestSoundButton.accessibilityLabel = "LOCAL-ACCESSIBILITY-EDIT-SOUND-TEST-BUTTON-LABEL".localizedVariant
        self.editAlarmTestSoundButton.accessibilityHint = "LOCAL-ACCESSIBILITY-EDIT-SOUND-TEST-BUTTON-HINT".localizedVariant
        self.musicTestButton.accessibilityLabel = "LOCAL-ACCESSIBILITY-EDIT-SONG-TEST-BUTTON-LABEL".localizedVariant
        self.musicTestButton.accessibilityHint = "LOCAL-ACCESSIBILITY-EDIT-SONG-TEST-BUTTON-HINT".localizedVariant
        
        for trailer in ["Speaker", "Music", "Nothing"].enumerated() {
            let imageName = trailer.element
            if let image = UIImage(named: imageName) {
                image.accessibilityLabel = ("LGV_TIMER-ACCESSIBILITY-SEGMENTED-AUDIO-MODE-" + trailer.element + "-LABEL").localizedVariant
                self.alarmEditSoundModeSelector.setImage(image, forSegmentAt: trailer.offset)
            }
        }
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
    /**
     This is called when the app is reactivated.
     
     It resets all the "deactivations" snoozes.
     */
    func turnOffDeactivations() {
        self.alarmDisableScreenView.isHidden = true
        for i in self.prefs.alarms.enumerated() {
            if self.prefs.alarms[i.offset].snoozing || !self.prefs.alarms[i.offset].isActive {
                self.prefs.alarms[i.offset].deferred = false
                self.prefs.alarms[i.offset].snoozing = false
            }
        }
        self.snoozeCount = 0
    }

    /* ################################################################## */
    // MARK: - Instance IBAction Methods
    /* ################################################################## */
    /**
     This is called when the user taps in an alarm active screen.
     
     - parameter: ignored
     */
    @IBAction func hitTheSnooze(_: UITapGestureRecognizer) {
        self.alarmDisableScreenView.isHidden = true
        if !self.prefs.noSnoozeLimit, self.snoozeCount == self.prefs.snoozeCount {
            self.shutUpAlready()
        } else {
            self.impactFeedbackGenerator?.prepare()
            self.impactFeedbackGenerator?.impactOccurred()
            
            for i in self.prefs.alarms.enumerated() where self.prefs.alarms[i.offset].isAlarming {
                self.prefs.alarms[i.offset].snoozing = true
            }
            
            self.snoozeCount += 1
            self.stopAudioPlayer()
            self.alarmDisplayView.isHidden = true
            self.selectedBrightness = Swift.max(TheBestClockPrefs.minimumBrightness, self.prefs.brightnessLevel)
            self.brightnessSliderChanged()
            for i in self.prefs.alarms.enumerated() where self.prefs.alarms[i.offset].snoozing {
                self.alarmButtons[i.offset].snore()
            }
        }
    }
    
    /* ################################################################## */
    /**
     This is called when the user long-presses in an alarm active screen.
     
     - parameter: ignored (Can be omitted)
     */
    @IBAction func shutUpAlready(_: Any! = nil) {
        self.impactFeedbackGenerator?.impactOccurred()
        self.impactFeedbackGenerator?.prepare()
        self.impactFeedbackGenerator?.impactOccurred()
        self.impactFeedbackGenerator?.prepare()
        self.alarmDisableScreenView.isHidden = true
        for i in self.prefs.alarms.enumerated() where self.prefs.alarms[i.offset].isAlarming {
            self.prefs.alarms[i.offset].deferred = true
            self.prefs.alarms[i.offset].isActive = false
            self.prefs.savePrefs()
            self.alarmButtons[i.offset].alarmRecord.isActive = false
        }
        self.snoozeCount = 0
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
            self.selectionFeedbackGenerator?.selectionChanged()
            self.selectionFeedbackGenerator?.prepare()
            for i in self.alarmButtons.enumerated() where self.alarmButtons[i.offset] == inSender {
                if let alarmRecord = inSender.alarmRecord {
                    if !alarmRecord.isActive || self.prefs.alarms[i.offset].snoozing {
                        self.prefs.alarms[i.offset].deferred = true
                    }
                    self.prefs.alarms[i.offset].isActive = alarmRecord.isActive
                    alarmRecord.deferred = self.prefs.alarms[i.offset].deferred
                    self.prefs.savePrefs()
                }
            }
            self.checkTicker() // This just makes sure we get "instant on," if that's what we selected.
        }
    }
    
    /* ################################################################## */
    /**
     This is called when a brightness slider is changed.
     
     - parameter inSlider: The brightness slider being manipulated.
     */
    @IBAction func brightnessSliderChanged(_ inSlider: TheBestClockVerticalBrightnessSliderView! = nil) {
        var newBrightness: CGFloat = 1.0
        let oldBrighness = self.selectedBrightness
        
        if nil != inSlider {
            self.selectedBrightness = Swift.max(TheBestClockPrefs.minimumBrightness, Swift.min(inSlider.brightness, 1.0))
        }
        
        if Int(oldBrighness * 100) != Int(self.selectedBrightness * 100) {  // Only tick for fairly significant changes.
            self.selectionFeedbackGenerator?.selectionChanged()
            self.selectionFeedbackGenerator?.prepare()
        }
        
        newBrightness = Swift.min(1.0, Swift.max(TheBestClockPrefs.minimumBrightness, self.selectedBrightness))
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
        self.impactFeedbackGenerator?.impactOccurred()
        self.impactFeedbackGenerator?.prepare()
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
        self.impactFeedbackGenerator?.impactOccurred()
        self.impactFeedbackGenerator?.prepare()
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
        self.impactFeedbackGenerator?.impactOccurred()
        self.impactFeedbackGenerator?.prepare()
        self.fontDisplayPickerView.delegate = self
        self.fontDisplayPickerView.dataSource = self
        self.colorDisplayPickerView.delegate = self
        self.colorDisplayPickerView.dataSource = self
        self.mainPickerContainerView.backgroundColor = self.backgroundColor
        self.fontDisplayPickerView.backgroundColor = self.backgroundColor
        self.colorDisplayPickerView.backgroundColor = self.backgroundColor
        self.fontDisplayPickerView.selectRow(self.selectedFontIndex, inComponent: 0, animated: false)
        self.colorDisplayPickerView.selectRow(self.selectedColorIndex, inComponent: 0, animated: false)
        self.mainPickerContainerView.isHidden = false
        
        // Need to do this because of the whacky way we are presenting the editor screen. The underneath controls can "bleed through."
        self.mainNumberDisplayView.isAccessibilityElement = false
        self.dateDisplayLabel.isAccessibilityElement = false
        self.amPmLabel.isAccessibilityElement = false
        self.leftBrightnessSlider.isAccessibilityElement = false
        self.rightBrightnessSlider.isAccessibilityElement = false
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
        self.impactFeedbackGenerator?.impactOccurred()
        self.impactFeedbackGenerator?.prepare()
        self.fontDisplayPickerView.delegate = nil
        self.fontDisplayPickerView.dataSource = nil
        self.colorDisplayPickerView.delegate = nil
        self.colorDisplayPickerView.dataSource = nil
        self.fontSizeCache = 0
        self.mainPickerContainerView.isHidden = true
        
        self.mainNumberDisplayView.isAccessibilityElement = true
        self.dateDisplayLabel.isAccessibilityElement = true
        self.amPmLabel.isAccessibilityElement = true
        self.leftBrightnessSlider.isAccessibilityElement = true
        self.rightBrightnessSlider.isAccessibilityElement = true
        
        self.startTicker()
    }
    
    /* ################################################################## */
    // MARK: - Instance Methods
    /* ################################################################## */
    /**
     */
    func setProperScreenBrightness() {
        if -1 < self.currentlyEditingAlarmIndex || !self.mainPickerContainerView.isHidden {
            UIScreen.main.brightness = 1.0  // Brighten the screen all the way for the editors.
        } else {
            self.updateMainTime()   // Otherwise, just use the set brightness.
        }
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
        UIFont.familyNames.forEach {
            UIFont.fontNames(forFamilyName: $0).forEach { fName in
                if self.screenForThese.contains(fName) {
                    self.fontSelection.append(fName)
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
        self.selectedBrightness = Swift.max(TheBestClockPrefs.minimumBrightness, self.prefs.brightnessLevel)
        self.updateMainTime()   // This will update the time. It will also set up our various labels and background colors.
        self.setInfoButtonColor()
        self.noMusicAvailableLabel.text = self.noMusicAvailableLabel.text?.localizedVariant
        self.alarmDeactivatedLabel.text = self.alarmDeactivatedLabel.text?.localizedVariant
        self.musicLookupLabel.text = self.musicLookupLabel.text?.localizedVariant
        self.alarmEditorActiveButton.setTitle(self.alarmEditorActiveButton.title(for: .normal)?.localizedVariant, for: .normal)
        self.alarmEditorVibrateButton.setTitle(self.alarmEditorVibrateButton.title(for: .normal)?.localizedVariant, for: .normal)
        self.snoozeGestureRecogninzer.require(toFail: self.shutUpAlreadyDoubleTapRecognizer)
        self.snoozeGestureRecogninzer.require(toFail: self.shutUpAlreadyLongPressGestureRecognizer)
        // Set up accessibility labels and hints.
        self.setUpMainScreenAccessibility()
        self.setUpAppearanceEditorAccessibility()
        self.setUpAlarmEditorAccessibility()
        self.setUpAlarms()
        self.alarmDisableScreenView.isHidden = true
        self.impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        self.impactFeedbackGenerator?.prepare()
        self.selectionFeedbackGenerator = UISelectionFeedbackGenerator()
        self.selectionFeedbackGenerator?.prepare()
        self.setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
    
    /* ################################################################## */
    /**
     This is called when we are about to layout our views (like when we rotate).
     We redraw everything, and force a new font size setting by zeroing the "cache."
     */
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.fontSizeCache = 0
        self.setProperScreenBrightness()
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
        self.setProperScreenBrightness()
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
