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
        wholeScreenThrobber.color = selectedColor
        wholeScreenThrobberView.backgroundColor = backgroundColor
        wholeScreenThrobberView.isHidden = false
    }
    
    /* ################################################################## */
    /**
     */
    func hideLargeLookupThrobber() {
        wholeScreenThrobberView.isHidden = true
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
        
        leftBrightnessSlider?.endColor = selectedColor
        leftBrightnessSlider?.brightness = selectedBrightness
        leftBrightnessSlider?.setNeedsDisplay()
        
        rightBrightnessSlider?.endColor = selectedColor
        rightBrightnessSlider?.brightness = selectedBrightness
        rightBrightnessSlider?.setNeedsDisplay()
        
        var frame = inContainerView.bounds
        frame.size.height = inContainerView.bounds.height
        let fontName = fontSelection[inIndex]
        let fontSize = 0 == fontSizeCache ? mainNumberDisplayView.bounds.size.height : fontSizeCache
        fontSizeCache = fontSize
        
        if 0 < fontSize, let font = UIFont(name: fontName, size: fontSize) {
            let text = currentTimeString.time
            
            // We'll have a couple of different colors for our gradient.
            var endColor: UIColor
            var startColor: UIColor
            
            let brightness = mainPickerContainerView.isHidden ? selectedBrightness : 1.0
            
            if 0 == selectedColorIndex {   // White just uses...white. No need to get fancy.
                endColor = UIColor(white: 0.6 * brightness, alpha: 1.0)
                startColor = UIColor(white: 1.25 * brightness, alpha: 1.0)
            } else {    // We use HSB to change the brightness, without changing the color.
                let hue = selectedColor.hsba.h
                endColor = UIColor(hue: hue, saturation: 1.0, brightness: 0.6 * brightness, alpha: 1.0)
                startColor = UIColor(hue: hue, saturation: 0.85, brightness: 1.25 * brightness, alpha: 1.0)
            }
            
            // The background can get darker than the text.
            backgroundColor = (selectedBrightness <= TheBestClockPrefs.minimumBrightness) ? UIColor.black : UIColor(white: 0.25 * selectedBrightness, alpha: 1.0)
            if mainPickerContainerView.isHidden, -1 == currentlyEditingAlarmIndex { // We don't do this if we are in the appearance or alarm editor.
                TheBestClockAppDelegate.recordOriginalBrightness()
                UIScreen.main.brightness = brightness    // Also dim the screen.
            } else if !mainPickerContainerView.isHidden {
                UIScreen.main.brightness = 1.0    // If we are editing, we get full brightness.
            }
            
            // We create a gradient layer, with our color going from slightly darker, to full brightness.
            view.backgroundColor = backgroundColor
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
            inContainerView.accessibilityLabel = currentTimeString.time + " " + currentTimeString.amPm
        }
        
        return inContainerView
    }
    
    /* ################################################################## */
    /**
     This sets (or clears) the ante meridian label. We use a solid bright text color.
     */
    func setAMPMLabel() {
        amPmLabel.backgroundColor = UIColor.clear
        var textColor: UIColor
        if 0 == selectedColorIndex {
            textColor = UIColor(white: selectedBrightness, alpha: 1.0)
        } else {
            let hue = selectedColor.hsba.h
            textColor = UIColor(hue: hue, saturation: 1.0, brightness: 1.3 * selectedBrightness, alpha: 1.0)
        }
        
        if !currentTimeString.amPm.isEmpty {
            amPmLabel.isHidden = false
            amPmLabel.font = UIFont(name: selectedFontName, size: amPmLabelFontSize)
            amPmLabel.text = currentTimeString.amPm
            amPmLabel.adjustsFontSizeToFitWidth = true
            amPmLabel.textAlignment = .right
            amPmLabel.baselineAdjustment = .alignCenters
            amPmLabel.textColor = textColor
            amPmLabel.accessibilityLabel = "LOCAL-ACCESSIBILITY-AMPM-LABEL".localizedVariant + " " + currentTimeString.amPm
        } else {
            amPmLabel.isHidden = true
        }
    }
    
    /* ################################################################## */
    /**
     This sets the date label. We use a solid bright text color.
     */
    func setDateDisplayLabel() {
        dateDisplayLabel.backgroundColor = UIColor.clear
        var textColor: UIColor
        if 0 == selectedColorIndex {
            textColor = UIColor(white: selectedBrightness, alpha: 1.0)
        } else {
            let hue = selectedColor.hsba.h
            textColor = UIColor(hue: hue, saturation: 1.0, brightness: 1.4 * selectedBrightness, alpha: 1.0)
        }
        
        dateDisplayLabel.font = UIFont(name: selectedFontName, size: dateLabelFontSize)
        dateDisplayLabel.text = currentTimeString.date
        dateDisplayLabel.adjustsFontSizeToFitWidth = true
        dateDisplayLabel.textAlignment = .center
        dateDisplayLabel.textColor = textColor
    }
    
    /* ################################################################## */
    // MARK: - Alarm Strip Methods
    /* ################################################################## */
    /**
     This creates and links up the row of buttons along the bottom of the screen.
     */
    func setUpAlarms() {
        // Take out the trash.
        alarmContainerView.subviews.forEach {
            $0.removeFromSuperview()
        }
        
        let alarms = prefs.alarms
        alarmButtons = []
        
        if !alarms.isEmpty {
            alarmContainerView.isAccessibilityElement = false  // This prevents the container from interfering with the alarm buttons.
            let percentage = CGFloat(1) / CGFloat(alarms.count)   // This will be used for our auto-layout stuff.
            var prevButton: TheBestClockAlarmView!
            var index = 0
            
            alarms.forEach {
                let alarmButton = TheBestClockAlarmView(alarmRecord: $0)
                addAlarmView(alarmButton, percentage: percentage, previousView: prevButton)
                alarmButton.delegate = self
                alarmButton.index = index
                alarmButton.alarmRecord.deferred = true  // We start off deactivated, so we don't start blaring immediately.
                index += 1
                prevButton = alarmButton
            }
            
            updateAlarms()
        }
    }
    
    /* ################################################################## */
    /**
     This updates the alarm buttons to reflect the brightness, color and font.
     */
    func updateAlarms() {
        alarmButtons.forEach {
            $0.brightness = selectedBrightness
            $0.fontColor = 0 == selectedColorIndex ? nil : selectedColor
            $0.fontName = selectedFontName
            $0.desiredFontSize = alarmsFontSize
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
        alarmContainerView.addSubview(inSubView)
        alarmButtons.append(inSubView)
        inSubView.addTarget(self, action: #selector(type(of: self).alarmActiveStateChanged(_:)), for: .valueChanged)
        
        inSubView.translatesAutoresizingMaskIntoConstraints = false
        
        var leftConstraint: NSLayoutConstraint!
        
        if nil == inPreviousView {
            leftConstraint = NSLayoutConstraint(item: inSubView,
                                                attribute: .left,
                                                relatedBy: .equal,
                                                toItem: alarmContainerView,
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
        
        alarmContainerView.addConstraints([leftConstraint,
                                                NSLayoutConstraint(item: inSubView,
                                                                   attribute: .top,
                                                                   relatedBy: .equal,
                                                                   toItem: alarmContainerView,
                                                                   attribute: .top,
                                                                   multiplier: 1.0,
                                                                   constant: 0),
                                                NSLayoutConstraint(item: inSubView,
                                                                   attribute: .bottom,
                                                                   relatedBy: .equal,
                                                                   toItem: alarmContainerView,
                                                                   attribute: .bottom,
                                                                   multiplier: 1.0,
                                                                   constant: 0),
                                                NSLayoutConstraint(item: inSubView,
                                                                   attribute: .width,
                                                                   relatedBy: .equal,
                                                                   toItem: alarmContainerView,
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
        prefs.alarms.forEach {
            if $0.isActive, $0.isAlarming, (prefs.noSnoozeLimit || !$0.snoozing || ($0.snoozing && snoozeCount <= prefs.snoozeCount)) {
                noAlarms = false
                alarmSounded = true
                alarmDisableScreenView.isHidden = false
                if !soundOnly { // See if we want to be a flasher.
                    flashDisplay(selectedColor)
                }
                aooGah(index) // Play a sound and/or vibrate.
            } else if $0.isActive, $0.snoozing {  // If we have a snoozing alarm, then it will "snore."
                if !prefs.noSnoozeLimit, snoozeCount > prefs.snoozeCount {
                    snoozeCount = 0
                    $0.snoozing = false
                    $0.deferred = true
                } else {
                    alarmButtons[index].snore()
                }
            }
            
            index += 1
        }
        
        // If we are in hush time, then we shouldn't be talking. We don't do this if we are in the Alarm Editor (where the test would be running).
        if noAlarms, alarmSounded, 0 > currentlyEditingAlarmIndex {
            alarmSounded = false
            stopAudioPlayer()
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
        alarmDisplayView.isHidden = false
        if prefs.alarms[inIndex].isVibrateOn {
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        }
        
        playSound(inIndex)
    }
    
    /* ################################################################## */
    /**
     This flashes the display in a fading animation.
     
     - parameter inUIColor: This is the color to flash.
     */
    func flashDisplay(_ inUIColor: UIColor) {
        if let targetView = flasherView {
            selectedBrightness = 1.0
            UIScreen.main.brightness = selectedBrightness
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
        updateMainTime()
        checkTicker() // This just makes sure we get "instant on," if that's what we selected.
        if nil == timer {
            timer = RVS_BasicGCDTimer(timeIntervalInSeconds: timeIntervalInSeconds, delegate: self, leewayInMilliseconds: leewayInMilliseconds, onlyFireOnce: false, context: nil, queue: nil, isWallTime: true)
            timer.isRunning = true
        }
    }
    
    /* ################################################################## */
    /**
     This stops our regular 1-second ticker.
     */
    func stopTicker() {
        if nil != timer {
            timer.invalidate()
            timer = nil
        }
    }
    
    /* ################################################################## */
    /**
     This simply redraws the main time and the two adjacent labels.
     */
    func updateMainTime() {
        _ = createDisplayView(mainNumberDisplayView, index: selectedFontIndex)
        setAMPMLabel()
        setDateDisplayLabel()
        updateAlarms()
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
        mainNumberDisplayView.accessibilityHint = "LOCAL-ACCESSIBILITY-HINT-MAIN-TIME".localizedVariant
        dateDisplayLabel.accessibilityLabel = dateDisplayLabel.text ?? ""
        leftBrightnessSlider.accessibilityLabel = "LOCAL-ACCESSIBILITY-BRIGHTNESS-SLIDER".localizedVariant
        leftBrightnessSlider.accessibilityHint = "LOCAL-ACCESSIBILITY-BRIGHTNESS-SLIDER-HINT".localizedVariant
        rightBrightnessSlider.accessibilityLabel = "LOCAL-ACCESSIBILITY-BRIGHTNESS-SLIDER".localizedVariant
        rightBrightnessSlider.accessibilityHint = "LOCAL-ACCESSIBILITY-BRIGHTNESS-SLIDER-HINT".localizedVariant
        alarmContainerView.accessibilityLabel = "LOCAL-ACCESSIBILITY-ALARM-CONTAINER".localizedVariant
        alarmContainerView.accessibilityHint = "LOCAL-ACCESSIBILITY-ALARM-CONTAINER-HINT".localizedVariant
        alarmDisplayView.accessibilityLabel = "LOCAL-ACCESSIBILITY-ALARM-DISPLAY".localizedVariant
        alarmDisplayView.accessibilityHint = "LOCAL-ACCESSIBILITY-ALARM-DISPLAY-HINT".localizedVariant
    }
    
    /* ################################################################## */
    /**
     This is called at load time, to add the various localized accessibility labels and hints to our elements in the Appearance Editor screen.
     */
    func setUpAppearanceEditorAccessibility() {
        colorDisplayPickerView.accessibilityLabel = "LOCAL-ACCESSIBILITY-COLOR-PICKER-LABEL".localizedVariant
        colorDisplayPickerView.accessibilityHint = "LOCAL-ACCESSIBILITY-COLOR-PICKER-HINT".localizedVariant
        fontDisplayPickerView.accessibilityLabel = "LOCAL-ACCESSIBILITY-FONT-SELECTOR-LABEL".localizedVariant
        fontDisplayPickerView.accessibilityHint = "LOCAL-ACCESSIBILITY-FONT-SELECTOR-HINT".localizedVariant
        infoButton.accessibilityLabel = "LOCAL-ACCESSIBILITY-INFO-BUTTON-LABEL".localizedVariant
        infoButton.accessibilityHint = "LOCAL-ACCESSIBILITY-INFO-BUTTON-HINT".localizedVariant
    }
    
    /* ################################################################## */
    /**
     This is called at load time, to add the various localized accessibility labels and hints to our elements in the Alarm Editor screen.
     */
    func setUpAlarmEditorAccessibility() {
        alarmEditorActiveSwitch.accessibilityLabel = "LOCAL-ACCESSIBILITY-ALARM-ENABLE-SWITCH-LABEL".localizedVariant
        alarmEditorActiveSwitch.accessibilityHint = "LOCAL-ACCESSIBILITY-ALARM-ENABLE-SWITCH-HINT".localizedVariant
        alarmEditorActiveButton.accessibilityLabel = "LOCAL-ACCESSIBILITY-ALARM-ENABLE-SWITCH-LABEL".localizedVariant
        alarmEditorActiveButton.accessibilityHint = "LOCAL-ACCESSIBILITY-ALARM-ENABLE-SWITCH-HINT".localizedVariant
        alarmEditorVibrateBeepSwitch.accessibilityLabel = "LOCAL-ACCESSIBILITY-ALARM-VIBRATE-SWITCH-LABEL".localizedVariant
        alarmEditorVibrateBeepSwitch.accessibilityHint = "LOCAL-ACCESSIBILITY-ALARM-VIBRATE-SWITCH-HINT".localizedVariant
        alarmEditorVibrateButton.accessibilityLabel = "LOCAL-ACCESSIBILITY-ALARM-VIBRATE-SWITCH-LABEL".localizedVariant
        alarmEditorVibrateButton.accessibilityHint = "LOCAL-ACCESSIBILITY-ALARM-VIBRATE-SWITCH-HINT".localizedVariant
        editAlarmTimeDatePicker.accessibilityLabel = "LOCAL-ACCESSIBILITY-ALARM-DATE-PICKER-LABEL".localizedVariant
        editAlarmTimeDatePicker.accessibilityHint = "LOCAL-ACCESSIBILITY-ALARM-DATE-PICKER-HINT".localizedVariant
        alarmEditSoundModeSelector.accessibilityLabel = "LOCAL-ACCESSIBILITY-ALARM-MODE-LABEL".localizedVariant
        alarmEditSoundModeSelector.accessibilityHint = "LOCAL-ACCESSIBILITY-ALARM-MODE-HINT".localizedVariant
        editAlarmPickerView.accessibilityLabel = "LOCAL-ACCESSIBILITY-EDIT-PICKER-LABEL".localizedVariant
        editAlarmPickerView.accessibilityHint = "LOCAL-ACCESSIBILITY-EDIT-PICKER-HINT".localizedVariant
        songSelectionPickerView.accessibilityLabel = "LOCAL-ACCESSIBILITY-EDIT-SONG-PICKER-LABEL".localizedVariant
        songSelectionPickerView.accessibilityHint = "LOCAL-ACCESSIBILITY-EDIT-SONG-PICKER-HINT".localizedVariant
        editAlarmTestSoundButton.accessibilityLabel = "LOCAL-ACCESSIBILITY-EDIT-SOUND-TEST-BUTTON-LABEL".localizedVariant
        editAlarmTestSoundButton.accessibilityHint = "LOCAL-ACCESSIBILITY-EDIT-SOUND-TEST-BUTTON-HINT".localizedVariant
        musicTestButton.accessibilityLabel = "LOCAL-ACCESSIBILITY-EDIT-SONG-TEST-BUTTON-LABEL".localizedVariant
        musicTestButton.accessibilityHint = "LOCAL-ACCESSIBILITY-EDIT-SONG-TEST-BUTTON-HINT".localizedVariant
        
        for trailer in ["Speaker", "Music", "Nothing"].enumerated() {
            let imageName = trailer.element
            if let image = UIImage(named: imageName) {
                image.accessibilityLabel = ("LGV_TIMER-ACCESSIBILITY-SEGMENTED-AUDIO-MODE-" + trailer.element + "-LABEL").localizedVariant
                alarmEditSoundModeSelector.setImage(image, forSegmentAt: trailer.offset)
            }
        }
    }

    /* ################################################################## */
    /**
     This is called to update the color of the "info" button in the Appearance Editor.
     */
    func setInfoButtonColor() {
        var textColor: UIColor
        if 0 == selectedColorIndex {
            textColor = UIColor(white: 1.0, alpha: 1.0)
        } else {
            let hue = selectedColor.hsba.h
            textColor = UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
        }
        
        infoButton.tintColor = textColor
    }
    
    /* ################################################################## */
    /**
     This is called when the app is reactivated.
     
     It resets all the "deactivations" snoozes.
     */
    func turnOffDeactivations() {
        alarmDisableScreenView.isHidden = true
        for i in prefs.alarms.enumerated() {
            if prefs.alarms[i.offset].snoozing || !prefs.alarms[i.offset].isActive {
                prefs.alarms[i.offset].deferred = false
                prefs.alarms[i.offset].snoozing = false
            }
        }
        snoozeCount = 0
    }

    /* ################################################################## */
    // MARK: - Instance IBAction Methods
    /* ################################################################## */
    /**
     This is called when the user taps in an alarm active screen.
     
     - parameter: ignored
     */
    @IBAction func hitTheSnooze(_: UITapGestureRecognizer) {
        alarmDisableScreenView.isHidden = true
        if !prefs.noSnoozeLimit, snoozeCount == prefs.snoozeCount {
            shutUpAlready()
        } else {
            impactFeedbackGenerator?.prepare()
            impactFeedbackGenerator?.impactOccurred()
            
            for i in prefs.alarms.enumerated() where prefs.alarms[i.offset].isAlarming {
                prefs.alarms[i.offset].snoozing = true
            }
            
            snoozeCount += 1
            stopAudioPlayer()
            alarmDisplayView.isHidden = true
            selectedBrightness = Swift.max(TheBestClockPrefs.minimumBrightness, prefs.brightnessLevel)
            brightnessSliderChanged()
            for i in prefs.alarms.enumerated() where prefs.alarms[i.offset].snoozing {
                alarmButtons[i.offset].snore()
            }
        }
    }
    
    /* ################################################################## */
    /**
     This is called when the user long-presses in an alarm active screen.
     
     - parameter: ignored (Can be omitted)
     */
    @IBAction func shutUpAlready(_: Any! = nil) {
        impactFeedbackGenerator?.impactOccurred()
        impactFeedbackGenerator?.prepare()
        impactFeedbackGenerator?.impactOccurred()
        impactFeedbackGenerator?.prepare()
        alarmDisableScreenView.isHidden = true
        for i in prefs.alarms.enumerated() where prefs.alarms[i.offset].isAlarming {
            prefs.alarms[i.offset].deferred = true
            prefs.alarms[i.offset].isActive = false
            prefs.savePrefs()
            alarmButtons[i.offset].alarmRecord.isActive = false
        }
        snoozeCount = 0
        stopAudioPlayer()
        alarmDisplayView.isHidden = true
    }
    
    /* ################################################################## */
    /**
     This is called when the user taps in an alarm on the main screen, toggling it.
     
     - parameter inSender: The alarm button that was hit.
     */
    @IBAction func alarmActiveStateChanged(_ inSender: TheBestClockAlarmView) {
        if -1 == currentlyEditingAlarmIndex {
            selectionFeedbackGenerator?.selectionChanged()
            selectionFeedbackGenerator?.prepare()
            for i in alarmButtons.enumerated() where alarmButtons[i.offset] == inSender {
                if let alarmRecord = inSender.alarmRecord {
                    if !alarmRecord.isActive || prefs.alarms[i.offset].snoozing {
                        prefs.alarms[i.offset].deferred = true
                    }
                    prefs.alarms[i.offset].isActive = alarmRecord.isActive
                    alarmRecord.deferred = prefs.alarms[i.offset].deferred
                    prefs.savePrefs()
                }
            }
            checkTicker() // This just makes sure we get "instant on," if that's what we selected.
        }
    }
    
    /* ################################################################## */
    /**
     This is called when a brightness slider is changed.
     
     - parameter inSlider: The brightness slider being manipulated.
     */
    @IBAction func brightnessSliderChanged(_ inSlider: TheBestClockVerticalBrightnessSliderView! = nil) {
        var newBrightness: CGFloat = 1.0
        let oldBrighness = selectedBrightness
        
        if nil != inSlider {
            selectedBrightness = Swift.max(TheBestClockPrefs.minimumBrightness, Swift.min(inSlider.brightness, 1.0))
        }
        
        if Int(oldBrighness * 100) != Int(selectedBrightness * 100) {  // Only tick for fairly significant changes.
            selectionFeedbackGenerator?.selectionChanged()
            selectionFeedbackGenerator?.prepare()
        }
        
        newBrightness = Swift.min(1.0, Swift.max(TheBestClockPrefs.minimumBrightness, selectedBrightness))
        prefs?.brightnessLevel = newBrightness
        TheBestClockAppDelegate.recordOriginalBrightness()
        UIScreen.main.brightness = newBrightness    // Also dim the screen.
        updateMainTime()
    }
    
    /* ################################################################## */
    /**
     This is called when a slider opens, so we don't have the situation where both are open at once.
     
     - parameter inSlider: The slider object that called this
     */
    @IBAction func brightnessSliderOpened(_ inSlider: TheBestClockVerticalBrightnessSliderView) {
        impactFeedbackGenerator?.impactOccurred()
        impactFeedbackGenerator?.prepare()
        if inSlider == rightBrightnessSlider {
            leftBrightnessSlider.isEnabled = false
        } else {
            rightBrightnessSlider.isEnabled = false
        }
    }
    
    /* ################################################################## */
    /**
     This is called when an open slider closes. We re-enable both sliders.
     
     - parameter: ignored
     */
    @IBAction func brightnessSliderClosed(_: Any) {
        impactFeedbackGenerator?.impactOccurred()
        impactFeedbackGenerator?.prepare()
        leftBrightnessSlider.isEnabled = true
        rightBrightnessSlider.isEnabled = true
    }
    
    /* ################################################################## */
    // MARK: - Appearance Editor Methods
    /* ################################################################## */
    /**
     This is called when we first open the Appearance (font and color) Editor.
     
     - parameter: ignored
     */
    @IBAction func openAppearanceEditor(_: Any) {
        stopTicker()
        impactFeedbackGenerator?.impactOccurred()
        impactFeedbackGenerator?.prepare()
        fontDisplayPickerView.delegate = self
        fontDisplayPickerView.dataSource = self
        colorDisplayPickerView.delegate = self
        colorDisplayPickerView.dataSource = self
        mainPickerContainerView.backgroundColor = backgroundColor
        fontDisplayPickerView.backgroundColor = backgroundColor
        colorDisplayPickerView.backgroundColor = backgroundColor
        fontDisplayPickerView.selectRow(selectedFontIndex, inComponent: 0, animated: false)
        colorDisplayPickerView.selectRow(selectedColorIndex, inComponent: 0, animated: false)
        mainPickerContainerView.isHidden = false
        
        // Need to do this because of the whacky way we are presenting the editor screen. The underneath controls can "bleed through."
        mainNumberDisplayView.isAccessibilityElement = false
        dateDisplayLabel.isAccessibilityElement = false
        amPmLabel.isAccessibilityElement = false
        leftBrightnessSlider.isAccessibilityElement = false
        rightBrightnessSlider.isAccessibilityElement = false
    }
    
    /* ################################################################## */
    /**
     This is called when the user taps in the info button.
     
     - parameter: ignored
     */
    @IBAction func openInfo(_: Any) {
        performSegue(withIdentifier: "open-info", sender: nil)
    }
    
    /* ################################################################## */
    /**
     This is called to close the Appearance Editor.
     
     - parameter: ignored
     */
    @IBAction func closeAppearanceEditor(_: Any) {
        impactFeedbackGenerator?.impactOccurred()
        impactFeedbackGenerator?.prepare()
        fontDisplayPickerView.delegate = nil
        fontDisplayPickerView.dataSource = nil
        colorDisplayPickerView.delegate = nil
        colorDisplayPickerView.dataSource = nil
        fontSizeCache = 0
        mainPickerContainerView.isHidden = true
        
        mainNumberDisplayView.isAccessibilityElement = true
        dateDisplayLabel.isAccessibilityElement = true
        amPmLabel.isAccessibilityElement = true
        leftBrightnessSlider.isAccessibilityElement = true
        rightBrightnessSlider.isAccessibilityElement = true
        
        startTicker()
    }
    
    /* ################################################################## */
    // MARK: - Instance Methods
    /* ################################################################## */
    /**
     */
    func setProperScreenBrightness() {
        if -1 < currentlyEditingAlarmIndex || !mainPickerContainerView.isHidden {
            UIScreen.main.brightness = 1.0  // Brighten the screen all the way for the editors.
        } else {
            updateMainTime()   // Otherwise, just use the set brightness.
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
                if screenForThese.contains(fName) {
                    fontSelection.append(fName)
                }
            }
        }
        
        // So we have a predictable order.
        fontSelection.sort()
        
        // We add this to the beginning.
        fontSelection.insert(contentsOf: ["Let's Go Digital"], at: 0)
        fontSelection.append(contentsOf: ["AnglicanText", "Canterbury", "CelticHand"])
        
        // Pick up our beeper sounds.
        soundSelection = Bundle.main.paths(forResourcesOfType: "mp3", inDirectory: nil)
        
        // The first index is white.
        colorSelection = [UIColor.white]
        // We generate a series of colors, fully saturated, from red (orangeish) to red (purpleish).
        for hue: CGFloat in stride(from: 0.0, to: 1.0, by: 0.05) {
            let color = UIColor(hue: hue, saturation: 1.0, brightness: 1.0, alpha: 1.0)
            colorSelection.append(color)
        }
        
        // Set up our persistent prefs, reading in any previously stored prefs.
        prefs = TheBestClockPrefs()
        selectedFontIndex = prefs.selectedFont
        selectedColorIndex = prefs.selectedColor
        selectedBrightness = Swift.max(TheBestClockPrefs.minimumBrightness, prefs.brightnessLevel)
        updateMainTime()   // This will update the time. It will also set up our various labels and background colors.
        setInfoButtonColor()
        noMusicAvailableLabel.text = noMusicAvailableLabel.text?.localizedVariant
        alarmDeactivatedLabel.text = alarmDeactivatedLabel.text?.localizedVariant
        musicLookupLabel.text = musicLookupLabel.text?.localizedVariant
        alarmEditorActiveButton.setTitle(alarmEditorActiveButton.title(for: .normal)?.localizedVariant, for: .normal)
        alarmEditorVibrateButton.setTitle(alarmEditorVibrateButton.title(for: .normal)?.localizedVariant, for: .normal)
        snoozeGestureRecogninzer.require(toFail: shutUpAlreadyDoubleTapRecognizer)
        snoozeGestureRecogninzer.require(toFail: shutUpAlreadyLongPressGestureRecognizer)
        // Set up accessibility labels and hints.
        setUpMainScreenAccessibility()
        setUpAppearanceEditorAccessibility()
        setUpAlarmEditorAccessibility()
        setUpAlarms()
        alarmDisableScreenView.isHidden = true
        impactFeedbackGenerator = UIImpactFeedbackGenerator(style: .light)
        impactFeedbackGenerator?.prepare()
        selectionFeedbackGenerator = UISelectionFeedbackGenerator()
        selectionFeedbackGenerator?.prepare()
        setNeedsUpdateOfHomeIndicatorAutoHidden()
    }
    
    /* ################################################################## */
    /**
     This is called when we are about to layout our views (like when we rotate).
     We redraw everything, and force a new font size setting by zeroing the "cache."
     */
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        fontSizeCache = 0
        setProperScreenBrightness()
        if mainPickerContainerView.isHidden, -1 == currentlyEditingAlarmIndex { // We don't do this if we are in the appearance editor.
            UIScreen.main.brightness = selectedBrightness    // Dim the screen.
        } else {
            if 0 <= currentlyEditingAlarmIndex, prefs.alarms.count > currentlyEditingAlarmIndex {
                if alarmEditorMinimumHeight > UIScreen.main.bounds.size.height || alarmEditorMinimumHeight > UIScreen.main.bounds.size.width {
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
        fontSizeCache = 0
        startTicker()
        updateMainTime()
        setProperScreenBrightness()
    }
    
    /* ################################################################## */
    /**
     When the view will disappear, we stop the caffiene drip, and the timer.
     */
    override func viewWillDisappear(_ animated: Bool) {
        stopTicker()
        super.viewWillDisappear(animated)
    }
    
    /* ################################################################## */
    /**
     When the view will disappear, we stop the caffiene drip, and the timer.
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? TheBestClockAboutScreenViewController {
            destination.view.backgroundColor = view.backgroundColor
            destination.baseColor = selectedColor
            destination.baseFont = UIFont(name: selectedFontName, size: 30)
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
        if 0 <= inAlarmIndex, prefs.alarms.count > inAlarmIndex {
            if -1 == currentlyEditingAlarmIndex {
                currentlyEditingAlarmIndex = inAlarmIndex
                prefs.alarms[currentlyEditingAlarmIndex].isActive = true
                alarmButtons[currentlyEditingAlarmIndex].alarmRecord.isActive = true
                openAlarmEditorScreen()
            }
        }
    }
}

/* ###################################################################################################################################### */
// MARK: - RVS_BasicGCDTimerDelegate Conformance
/* ###################################################################################################################################### */
/* ################################################################## */
/**
 This is the callback that is made by the repeating timer.
 
 - parameter: ignored
 */
extension MainScreenViewController: RVS_BasicGCDTimerDelegate {
    func basicGCDTimerCallback(_: RVS_BasicGCDTimer) {
        checkTicker()
    }
}
