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
// MARK: - Main Class -
/* ###################################################################################################################################### */
/**
 The entire app is basically handled by this one big fat View Controller. The idea is that users don't leave the context to do their settings.
 
 There are two "screens" that appear: The Appearance Editor (font, color), and the Alarm Editor (alarm time, activation, sound). These are actually
 hidden screens that appear over the main display screen.
 */
class MainScreenViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, TheBestClockAlarmViewDelegate {
    /* ################################################################## */
    // MARK: - Instance Types and Structs
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
     This struct will contain information about a song in our media library.
     */
    struct SongInfo {
        var songTitle: String
        var artistName: String
        var albumTitle: String
        var resourceURI: URL!
        
        var description: String {
            var ret: String = ""
            
            if !songTitle.isEmpty {
                ret = songTitle
            } else if !albumTitle.isEmpty {
                ret = albumTitle
            } else if !artistName.isEmpty {
                ret = artistName
            }

            return ret
        }
    }
    
    /* ################################################################## */
    // MARK: - Instance Private Constant Properties
    /* ################################################################## */
    /// This is a list of a subset of fonts likely to be on the device. We want to reduce the choices for the user.
    private let _screenForThese: [String] = ["AmericanTypewriter-Bold",
                                             "AppleSDGothicNeo-Thin",
                                             "Arial-BoldItalicMT",
                                             "Avenir-Black",
                                             "Baskerville",
                                             "Baskerville-BoldItalic",
                                             "BodoniSvtyTwoITCTT-Bold",
                                             "BradleyHandITCTT-Bold",
                                             "ChalkboardSE-Bold",
                                             "Chalkduster",
                                             "Cochin-Bold",
                                             "Copperplate-Bold",
                                             "Copperplate-Light",
                                             "Didot-Bold",
                                             "EuphemiaUCAS-Bold",
                                             "Futura-CondensedExtraBold",
                                             "Futura-Medium",
                                             "Georgia-Bold",
                                             "GillSans-Light",
                                             "GillSans-UltraBold",
                                             "HelveticaNeue-UltraLight",
                                             "HoeflerText-Black",
                                             "MarkerFelt-Wide",
                                             "Noteworthy-Bold",
                                             "Papyrus",
                                             "TrebuchetMS-Bold",
                                             "Verdana-Bold"]
    /// This is our minimum brightness threshold. We don't let the text and stuff quite make it to 0.
    private let _minimumBrightness: CGFloat = 0.05
    /// This is the base font size for the ante meridian label near the top of the screen.
    private let _amPmLabelFontSize: CGFloat = 30
    /// This is the base font size for the date display along the top.
    private let _dateLabelFontSize: CGFloat = 50
    /// This is the base font size for the row of alarm buttons along the bottom of the screen.
    private let _alarmsFontSize: CGFloat = 40
    /// This is the base font size for the various textual items in the Alarm Editor.
    private let _alarmEditorTopFontSize: CGFloat = 30
    /// This is the font size for the alarm sound/music selection picker.
    private let _alarmEditorSoundPickerFontSize: CGFloat = 24
    /// This is the base font size for the sound test button.
    private let _alarmEditorSoundButtonFontSize: CGFloat = 30

    /* ################################################################## */
    // MARK: - Instance Private Properties
    /* ################################################################## */
    /// These are the persistent prefs that store our settings.
    private var _prefs: TheBestClockPrefs!
    /// This is an Array of the button objects that we generated for the alarms along the bottom of the screen.
    private var _alarmButtons: [TheBestClockAlarmView] = []
    /// These are the names of the fonts that we have selected to be choices.
    private var _fontSelection: [String] = []
    /// These are all the UIColors that we have to choose from. They are dynamically generated.
    private var _colorSelection: [UIColor] = []
    /// These are URL Strings of the various sound files we have for the "sounds" setting.
    private var _soundSelection: [String] = []
    /// This is the basic background color for the whole kit and kaboodle. It gets darker as the brightness is reduced.
    private var _backgroundColor: UIColor = UIColor.gray
    /// This is the "heartbeat" of the clock. It's a 1-second repeating timer.
    private var _ticker: Timer!
    /// This is used to cache the selected main font size. We sort of use it as a semaphore.
    private var _fontSizeCache: CGFloat = 0
    /// If the Alarm Editor is open, then this is the index of the alarm being edited. It is -1 if the Alarm Editor is not open.
    private var _currentlyEditingAlarmIndex: Int = -1
    /// This will be the audio player that we use to play the alarm sound.
    private var _audioPlayer: AVAudioPlayer? {
        didSet {    // We set the Alarm Editor button text to reflect whether or not we play/continue, or pause a playing sound. It will be invisible, unless we are editing an alarm.
            DispatchQueue.main.async {
                self.editAlarmTestSoundButton.setTitle((nil == self._audioPlayer ? "LOCAL-TEST-SOUND" : "LOCAL-PAUSE-SOUND").localizedVariant, for: .normal)
            }
        }
    }
    /// This contains information about music items.
    var _songs: [String: [SongInfo]] = [:]
    /// This is an index of the keys (artists) for the songs Dictionary.
    var _artists: [String] = []

    /* ################################################################## */
    // MARK: - Instance IB Properties
    /* ################################################################## */
    /// This is the UIPickerView that is used to select the font.
    @IBOutlet weak var fontDisplayPickerView: UIPickerView!
    /// This is the UIPickerView that is used to select the color.
    @IBOutlet weak var colorDisplayPickerView: UIPickerView!
    /// This is the main view, holding the standard display items.
    @IBOutlet weak var mainNumberDisplayView: UIView!
    /// This is a normally hidden view that holds the color and font selection UIPickerViews
    @IBOutlet weak var mainPickerContainerView: UIView!
    /// This is the hidden slider for changing the brightness on the left side of the screen..
    @IBOutlet weak var leftBrightnessSlider: TheBestClockVerticalBrightnessSliderView!
    /// This is the hidden slider for changing the brightness on the right side of the screen..
    @IBOutlet weak var rightBrightnessSlider: TheBestClockVerticalBrightnessSliderView!
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
    /// This will be the container for the flashing view that appears when there's an alarm.
    @IBOutlet weak var alarmDisplayView: UIView!
    /// This is the view that will actually display the flashes.
    @IBOutlet weak var flasherView: UIView!
    /// This is the "invisible" button that we use to dismiss the alarm editor.
    @IBOutlet weak var dismissAlarmEditorButton: UIButton!
    /// This is a "partial mask" view for our alarm editor screen.
    @IBOutlet weak var editAlarmScreenMaskView: UIView!
    /// This is the little "more info" button that is displayed at the bottom of the setup screen.
    @IBOutlet weak var infoButton: UIButton!
    /// This switch will denote the "active" state of the alarm.
    @IBOutlet weak var alarmEditorActiveSwitch: UISwitch!
    /// This is the localized label for that switch, but we make it a button, so it can be used to trigger the switch.
    @IBOutlet weak var alarmEditorActiveButton: UIButton!
    /// This is the switch that selects whether or not to use a vibration (on supported devices).
    @IBOutlet weak var alarmEditorVibrateBeepSwitch: UISwitch!
    /// This is the localized label for that switch, but we make it a button, so it can be used to trigger the switch.
    @IBOutlet weak var alarmEditorVibrateButton: UIButton!
    /// This is the segmented switch that selects the type of sounds we'll use.
    @IBOutlet weak var alarmEditSoundModeSelector: UISegmentedControl!
    /// This is the picker view we use to select playback sounds for the alarm.
    @IBOutlet weak var editAlarmPickerView: UIPickerView!
    /// This is the button that is pressed to test the sounds.
    @IBOutlet weak var editAlarmTestSoundButton: UIButton!
    /// This is the "STOP" long press gesture recognizer.
    @IBOutlet var shutUpAlreadyGestureRecognizer: UILongPressGestureRecognizer!
    /// This is the "snooze" tap gesture recognizer.
    @IBOutlet var snoozeGestureRecogninzer: UITapGestureRecognizer!
    /// This is a view that we temorarily put up while fetching the music collection.
    @IBOutlet weak var musicLookupThrobberView: UIView!
    /// This is the throbber in that view.
    @IBOutlet weak var musicLookupThrobber: UIActivityIndicatorView!
    /// This is the secondary picker view for selecting songs in the Alarm Editor.
    @IBOutlet weak var songSelectionPickerView: UIPickerView!
    
    /* ################################################################## */
    // MARK: - Instance Properties
    /* ################################################################## */
    /// This is the currently selected main font. It's an index into our font selection Array.
    var selectedFontIndex: Int = 0
    /// This is an index into our color selection Array, denoting the color we have selected.
    var selectedColorIndex: Int = 0
    /// This indicates the brightness level of the screen.
    var selectedBrightness: CGFloat = 1.0

    /* ################################################################## */
    // MARK: - Instance Calculated Properties
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
     - returns the selected color.
     */
    var selectedColor: UIColor {
        return self._colorSelection[self.selectedColorIndex]
    }
    
    /* ################################################################## */
    /**
     - returns the selected font name.
     */
    var selectedFontName: String {
        return self._fontSelection[self.selectedFontIndex]
    }

    /* ################################################################## */
    // MARK: - Media Methods
    /* ################################################################## */
    /**
     This is called when we want to access the music library to make a list of artists and songs.
     */
    private func _loadMediaLibrary() {
        if .authorized == MPMediaLibrary.authorizationStatus() {    // Already authorized? Head on in!
            if let songItems: [MPMediaItemCollection] = MPMediaQuery.songs().collections {
                self._loadSongData(songItems)
            }
        } else {    // Can I see your ID, sir?
            MPMediaLibrary.requestAuthorization { status in
                switch status {
                case.authorized:
                    if let songItems: [MPMediaItemCollection] = MPMediaQuery.songs().collections {
                        self._loadSongData(songItems)
                    }
                    
                default:
                    TheBestClockAppDelegate.reportError(heading: "ERROR_HEADER_MEDIA", text: "ERROR_TEXT_MEDIA_PERMISSION_DENIED")
                }
            }
        }
    }
    
    /* ################################################################## */
    /**
     This reads all the user's music, and sorts it into a couple of bins for us to reference later.
     
     - parameter inSongs: The list of songs we read in, as media items.
     */
    private func _loadSongData(_ inSongs: [MPMediaItemCollection]) {
        var songList: [SongInfo] = []
        self._songs = [:]
        self._artists = []

        // We just read in every damn song we have, then we set up an "index" Dictionary that sorts by artist name, then each artist element has a list of songs.
        // We sort the artists and songs alphabetically. Primitive, but sufficient.
        for album in inSongs {
            let albumInfo = album.items
            
            // Each song is a media element, so we read the various parts that matter to us.
            for song in albumInfo {
                // Anything we don't know is filled with "Unknown XXX".
                var songInfo: SongInfo = SongInfo(songTitle: "LOCAL-UNKNOWN-SONG".localizedVariant, artistName: "LOCAL-UNKNOWN-ARTIST".localizedVariant, albumTitle: "LOCAL-UNKNOWN-ALBUM".localizedVariant, resourceURI: nil)
                
                if let songTitle = song.value( forProperty: MPMediaItemPropertyTitle ) as? String {
                    songInfo.songTitle = songTitle.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
                }
                
                if let artistName = song.value( forProperty: MPMediaItemPropertyArtist ) as? String {
                    songInfo.artistName = artistName.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines) // Trim the crap.
                }
                
                if let albumTitle = song.value( forProperty: MPMediaItemPropertyAlbumTitle ) as? String {
                    songInfo.albumTitle = albumTitle.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
                }
                
                if let resourceURI = song.assetURL {    // If we don't have one of these, then too bad. We won't be playing.
                    songInfo.resourceURI = resourceURI
                }
                
                if nil != songInfo.resourceURI, !songInfo.description.isEmpty {
                    songList.append(songInfo)
                }
            }
        }
        
        // We just create a big fat, honkin' Dictionary of songs; sorted by the artist name for each song.
        for song in songList {
            if nil == self._songs[song.artistName] {
                self._songs[song.artistName] = []
            }
            self._songs[song.artistName]?.append(song)
        }
        
        // We create the index, and sort the songs and keys.
        for artist in self._songs.keys {
            if var sortedSongs = self._songs[artist] {
                sortedSongs.sort(by: { a, b in
                    return a.songTitle < b.songTitle
                })
                self._songs[artist] = sortedSongs
            }
            self._artists.append(artist)    // This will be our artist key array.
        }
        
        self._artists.sort()
    }
    
    /* ################################################################## */
    /**
     This is called to play a sound, choosing from the various alarms. That alarm's indexed sound will be used.
     It is also used to continue a paused audio player (in which case, the sound is actually ignored).
     
     - parameter inAlarmIndex: This is the index of the alarm that we want to use to play the sound.
     */
    private func _playSound(_ inAlarmIndex: Int) {
        if nil == self._audioPlayer, .sounds == self._prefs.alarms[inAlarmIndex].selectedSoundMode, let soundUrl = URL(string: self._soundSelection[self._prefs.alarms[inAlarmIndex].selectedSoundIndex]) {
            self._playThisSound(soundUrl)
        }
    }
    
    /* ################################################################## */
    /**
     This plays any sound, using a given URL.
     
     - parameter inSoundURL: This is the URI to the sound resource.
     */
    private func _playThisSound(_ inSoundURL: URL) {
        do {
            if nil == self._audioPlayer {
                try self._audioPlayer = AVAudioPlayer(contentsOf: inSoundURL)
                self._audioPlayer?.numberOfLoops = -1   // Repeat indefinitely
            }
            self._audioPlayer?.play()
        } catch {
            TheBestClockAppDelegate.reportError(heading: "ERROR_HEADER_MEDIA", text: "ERROR_TEXT_MEDIA_CANNOT_CREATE_AVPLAYER")
        }
    }
    
    /* ################################################################## */
    /**
     If the audio player is going, this pauses it. Nothing happens if no audio player is going.
     */
    private func _pauseAudioPlayer() {
        if nil != self._audioPlayer {
            self._audioPlayer?.pause()
        }
    }
    
    /* ################################################################## */
    /**
     This terminates the audio player. Nothing happens if no audio player is going.
     */
    private func _stopAudioPlayer() {
        if nil != self._audioPlayer {
            self._audioPlayer?.stop()
            self._audioPlayer = nil
        }
    }

    /* ################################################################## */
    // MARK: - Instance Main Display Methods
    /* ################################################################## */
    /**
     This creates the display, as a gradient-filled font.
     */
    private func _createDisplayView(_ inContainerView: UIView, index inIndex: Int) -> UIView {
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
        let fontName = self._fontSelection[inIndex]
        let fontSize = 0 == self._fontSizeCache ? self.mainNumberDisplayView.bounds.size.height : self._fontSizeCache
        self._fontSizeCache = fontSize
        
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
            self._backgroundColor = (self.selectedBrightness == self._minimumBrightness) ? UIColor.black : UIColor(white: 0.25 * self.selectedBrightness, alpha: 1.0)
            if self.mainPickerContainerView.isHidden, -1 == self._currentlyEditingAlarmIndex { // We don't do this if we are in the appearance or alarm editor.
                TheBestClockAppDelegate.recordOriginalBrightness()
                UIScreen.main.brightness = self.selectedBrightness    // Also dim the screen.
            }
            
            // We create a gradient layer, with our color going from slightly darker, to full brightness.
            self.view.backgroundColor = self._backgroundColor
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
    private func _setAMPMLabel() {
        self.amPmLabel.backgroundColor = UIColor.clear
        var textColor: UIColor
        if 0 == self.selectedColorIndex {
            textColor = UIColor(white: self.selectedBrightness, alpha: 1.0)
        } else {
            let hue = self.selectedColor.hsba.h
            textColor = UIColor(hue: hue, saturation: 1.0, brightness: 1.3 * self.selectedBrightness, alpha: 1.0)
        }
        
        self.amPmLabel.font = UIFont(name: self.selectedFontName, size: self._amPmLabelFontSize)
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
            let hue = self.selectedColor.hsba.h
            textColor = UIColor(hue: hue, saturation: 1.0, brightness: 1.4 * self.selectedBrightness, alpha: 1.0)
        }
        
        self.dateDisplayLabel.font = UIFont(name: self.selectedFontName, size: self._dateLabelFontSize)
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
    private func _setUpAlarms() {
        // Take out the trash.
        for subview in self.alarmContainerView.subviews {
            subview.removeFromSuperview()
        }
        
        let alarms = self._prefs.alarms
        self._alarmButtons = []
        
        if !alarms.isEmpty {
            let percentage = CGFloat(1) / CGFloat(alarms.count)   // This will be used for our auto-layout stuff.
            var prevButton: TheBestClockAlarmView!
            var index = 0
            
            for alarm in alarms {
                let alarmButton = TheBestClockAlarmView(alarmRecord: alarm)
                self._addAlarmView(alarmButton, percentage: percentage, previousView: prevButton)
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
     This updates the alarm buttons to reflect the brightness, color and font.
     */
    private func _updateAlarms() {
        let alarms = self._alarmButtons
        
        for alarm in alarms {
            alarm.brightness = self.selectedBrightness
            alarm.fontColor = 0 == self.selectedColorIndex ? nil : self.selectedColor
            alarm.fontName = self.selectedFontName
            alarm.desiredFontSize = self._alarmsFontSize
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
    private func _addAlarmView(_ inSubView: TheBestClockAlarmView, percentage inPercentage: CGFloat, previousView inPreviousView: TheBestClockAlarmView!) {
        self.alarmContainerView.addSubview(inSubView)
        self._alarmButtons.append(inSubView)
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
    private func _checkAlarmStatus(soundOnly: Bool = false) {
        var index = 0
        var noAlarms = true // If we find an active alarm, this is made false.
        // If we have an active alarm, then we throw the switch, iGor.
        for alarm in self._prefs.alarms {
            if alarm.alarming {
                noAlarms = false
                if !soundOnly { // See if we want to be a flasher.
                    self._flashDisplay(self.selectedColor)
                }
                self._aooGah(index) // Play a sound and/or vibrate.
            } else if alarm.snoozing {  // If we have a snozing alarm, then it will "snore."
                self._zzzz(index)
            }
            
            index += 1
        }
        
        // If we are in hush time, then we shouldn't be talking.
        if noAlarms {
            self._stopAudioPlayer()
        }
    }
    
    /* ################################################################## */
    /**
     This plays whatever alarm is supposed to be alarming. This will vibrate, if we are set to do that.
     
     - parameter inIndex: This is the index of the alarm to be played.
     */
    private func _aooGah(_ inIndex: Int) {
        self.alarmDisplayView.isHidden = false
        if self._prefs.alarms[inIndex].isVibrateOn {
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        }
        self._playSound(inIndex)
    }
    
    /* ################################################################## */
    /**
     This flashes the display in a fading animation.
     
     - parameter inUIColor: This is the color to flash.
     */
    private func _flashDisplay(_ inUIColor: UIColor) {
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
    private func _zzzz(_ inIndex: Int) {
        self._alarmButtons[inIndex].snore()
    }

    /* ################################################################## */
    /**
     This starts our regular 1-second ticker.
     */
    private func _startTicker() {
        UIApplication.shared.isIdleTimerDisabled = true // This makes sure that we stay awake while this window is up.
        self._updateMainTime()
        self._checkAlarmStatus() // This just makes sure we get "instant on," if that's what we selected.
        if nil == self._ticker {
            self._ticker = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(type(of: self)._checkTicker(_:)), userInfo: nil, repeats: true)
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
    private func _updateMainTime() {
        _ = self._createDisplayView(self.mainNumberDisplayView, index: self.selectedFontIndex)
        self._setAMPMLabel()
        self._setDateDisplayLabel()
        self._updateAlarms()
    }

    /* ################################################################## */
    /**
     This is called from the timer.
     */
    @objc private func _checkTicker(_ inTimer: Timer) {
        DispatchQueue.main.async {
            self._updateMainTime()
            self._checkAlarmStatus()
        }
    }
    
    /* ################################################################## */
    // MARK: - Instance IBAction Methods
    /* ################################################################## */
    /**
     */
    @IBAction func hitTheSnooze(_ inGestureRecognizer: UITapGestureRecognizer) {
        for index in 0..<self._prefs.alarms.count where self._prefs.alarms[index].alarming {
            self._prefs.alarms[index].snoozing = true
        }
        self._stopAudioPlayer()
        self.alarmDisplayView.isHidden = true
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func shutUpAlready(_ inGestureRecognizer: UILongPressGestureRecognizer) {
        for index in 0..<self._prefs.alarms.count where self._prefs.alarms[index].alarming {
            self._prefs.alarms[index].isActive = false
            self._prefs.savePrefs()
            self._alarmButtons[index].alarmRecord.isActive = false
        }
        self._stopAudioPlayer()
        self.alarmDisplayView.isHidden = true
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func alarmActiveStateChanged(_ sender: TheBestClockAlarmView) {
        if -1 == self._currentlyEditingAlarmIndex {
            for index in 0..<self._alarmButtons.count where self._alarmButtons[index] == sender {
                if let alarmRecord = sender.alarmRecord {
                    self._prefs.alarms[index].isActive = alarmRecord.isActive
                    self._prefs.savePrefs()
                }
            }
            self._checkAlarmStatus() // This just makes sure we get "instant on," if that's what we selected.
        }
    }

    /* ################################################################## */
    /**
     */
    @IBAction func brightnessSliderChanged(_ sender: TheBestClockVerticalBrightnessSliderView) {
        self.selectedBrightness = max(self._minimumBrightness, min(sender.brightness, 1.0))
        let newBrightness = min(1.0, self.selectedBrightness)
        self._prefs?.brightnessLevel = newBrightness
        TheBestClockAppDelegate.recordOriginalBrightness()
        UIScreen.main.brightness = newBrightness    // Also dim the screen.
        self._updateMainTime()
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
     */
    @IBAction func openAppearanceEditor(_ sender: Any) {
        self.stopTicker()
        self.fontDisplayPickerView.delegate = self
        self.fontDisplayPickerView.dataSource = self
        self.colorDisplayPickerView.delegate = self
        self.colorDisplayPickerView.dataSource = self
        self.mainPickerContainerView.backgroundColor = self._backgroundColor
        self.fontDisplayPickerView.backgroundColor = self._backgroundColor
        self.colorDisplayPickerView.backgroundColor = self._backgroundColor
        self.fontDisplayPickerView.selectRow(self.selectedFontIndex, inComponent: 0, animated: false)
        self.colorDisplayPickerView.selectRow(self.selectedColorIndex, inComponent: 0, animated: false)
        TheBestClockAppDelegate.restoreOriginalBrightness()
        self.mainPickerContainerView.isHidden = false
    }
    
    /* ################################################################## */
    /**
     */
    private func _setInfoButtonColor() {
        var textColor: UIColor
        if 0 == self.selectedColorIndex {
            textColor = UIColor(white: self.selectedBrightness, alpha: 1.0)
        } else {
            let hue = self.selectedColor.hsba.h
            textColor = UIColor(hue: hue, saturation: 1.0, brightness: 1.4 * self.selectedBrightness, alpha: 1.0)
        }
        
        self.infoButton.tintColor = textColor
    }

    /* ################################################################## */
    /**
     */
    @IBAction func openInfo(_ sender: Any) {
        self.performSegue(withIdentifier: "open-info", sender: nil)
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
        self._startTicker()
    }

    /* ################################################################## */
    // MARK: - Alarm Editor Methods
    /* ################################################################## */
    /**
     This opens the editor screen for a selected alarm.
     */
    private func _openAlarmEditorScreen() {
        self.stopTicker()
        if 0 <= self._currentlyEditingAlarmIndex, self._prefs.alarms.count > self._currentlyEditingAlarmIndex {
            TheBestClockAppDelegate.restoreOriginalBrightness()
            let currentAlarm = self._prefs.alarms[self._currentlyEditingAlarmIndex]
            
            currentAlarm.isActive = true
            currentAlarm.snoozing = false
            self._alarmButtons[self._currentlyEditingAlarmIndex].alarmRecord.isActive = true
            self._alarmButtons[self._currentlyEditingAlarmIndex].alarmRecord.snoozing = false
            self.alarmEditorActiveSwitch.isOn = true
            self._showOnlyThisAlarm(self._currentlyEditingAlarmIndex)
            let time = currentAlarm.alarmTime
            let hours = time / 100
            let minutes = time - (hours * 100)
            
            var dateComponents = DateComponents()
            dateComponents.hour = hours
            dateComponents.minute = minutes
            
            let userCalendar = Calendar.current
            if let pickerDate = userCalendar.date(from: dateComponents) {
                self.editAlarmTimeDatePicker.setDate(pickerDate, animated: false)
            }
            let flashColor = (0 != self.selectedColorIndex ? self.selectedColor : UIColor.white)
            self.editAlarmScreenMaskView.backgroundColor = self.view.backgroundColor
            let flashImage = UIImage(color: flashColor.withAlphaComponent(0.5))
            self.dismissAlarmEditorButton.setBackgroundImage(flashImage, for: .focused)
            self.dismissAlarmEditorButton.setBackgroundImage(flashImage, for: .selected)
            self.dismissAlarmEditorButton.setBackgroundImage(flashImage, for: .highlighted)
            
            self.alarmEditorActiveSwitch.tintColor = self.selectedColor
            self.alarmEditorActiveSwitch.onTintColor = self.selectedColor
            self.alarmEditorActiveSwitch.thumbTintColor = self.selectedColor
            self.alarmEditorActiveButton.tintColor = self.selectedColor
            if let label = self.alarmEditorActiveButton.titleLabel {
                label.adjustsFontSizeToFitWidth = true
                label.baselineAdjustment = .alignCenters
                if let font = UIFont(name: self.selectedFontName, size: self._alarmEditorTopFontSize) {
                    label.font = font
                }
            }
            self.alarmEditorActiveSwitch.isOn = currentAlarm.isActive
            
            self.alarmEditorVibrateBeepSwitch.tintColor = self.selectedColor
            self.alarmEditorVibrateBeepSwitch.thumbTintColor = self.selectedColor
            self.alarmEditorVibrateBeepSwitch.onTintColor = self.selectedColor
            self.alarmEditorVibrateButton.tintColor = self.selectedColor

            if let label = self.alarmEditorVibrateButton.titleLabel {
                label.adjustsFontSizeToFitWidth = true
                label.baselineAdjustment = .alignCenters
                if let font = UIFont(name: self.selectedFontName, size: self._alarmEditorTopFontSize) {
                    label.font = font
                }
            }

            self.editAlarmTestSoundButton.tintColor = self.selectedColor
            if let label = self.editAlarmTestSoundButton.titleLabel {
                label.adjustsFontSizeToFitWidth = true
                label.baselineAdjustment = .alignCenters
                if let font = UIFont(name: self.selectedFontName, size: self._alarmEditorSoundButtonFontSize) {
                    label.font = font
                }
            }

            self.alarmEditorVibrateBeepSwitch.isOn = currentAlarm.isVibrateOn
            self.alarmEditSoundModeSelector.selectedSegmentIndex = currentAlarm.selectedSoundMode.rawValue
            self.alarmEditSoundModeSelector.tintColor = self.selectedColor
            
            if let font = UIFont(name: self.selectedFontName, size: 20) {
                self.alarmEditSoundModeSelector.setTitleTextAttributes([.font: font], for: .normal)
            }
            for index in 0..<self.alarmEditSoundModeSelector.numberOfSegments {
                self.alarmEditSoundModeSelector.setTitle(self.alarmEditSoundModeSelector.titleForSegment(at: index)?.localizedVariant, forSegmentAt: index)
            }
            self.editAlarmPickerView.reloadComponent(0)
            if 0 == self.alarmEditSoundModeSelector.selectedSegmentIndex {
                self.editAlarmPickerView.selectRow(currentAlarm.selectedSoundIndex, inComponent: 0, animated: false)
            } else if 1 == self.alarmEditSoundModeSelector.selectedSegmentIndex {
                self.editAlarmPickerView.selectRow(0, inComponent: 0, animated: false)
            }
            
            self._showHideItems()
            self.editAlarmScreenContainer.isHidden = false
            self.editAlarmTimeDatePicker.setValue(self.selectedColor, forKey: "textColor")
            // This nasty little hack, is because it is possible to get the alarm to display as inactive when it is, in fact, active.
            Timer.scheduledTimer(withTimeInterval: 0.125, repeats: false) { [unowned self] _ in
                DispatchQueue.main.async {
                    self.activeSwitchChanged(self.alarmEditorActiveSwitch)
                }
            }
        }
    }
    
    /* ################################################################## */
    /**
     */
    private func _showHideItems() {
        self.editAlarmTestSoundButton.isHidden = .sounds != self._prefs.alarms[self._currentlyEditingAlarmIndex].selectedSoundMode
        self.editAlarmPickerView.isHidden = .silence == self._prefs.alarms[self._currentlyEditingAlarmIndex].selectedSoundMode
        self.songSelectionPickerView.isHidden = .music != self._prefs.alarms[self._currentlyEditingAlarmIndex].selectedSoundMode
    }
    
    /* ################################################################## */
    /**
     */
    private func _showLookupThrobber() {
        self.musicLookupThrobber.color = self.selectedColor
        self.musicLookupThrobberView.backgroundColor = self._backgroundColor
        self.musicLookupThrobberView.isHidden = false
    }

    /* ################################################################## */
    /**
     */
    private func _hideLookupThrobber() {
        self.musicLookupThrobberView.isHidden = true
    }

    /* ################################################################## */
    /**
     */
    private func _showOnlyThisAlarm(_ inIndex: Int) {
        for alarm in self._alarmButtons where alarm.index != inIndex {
            alarm.isUserInteractionEnabled = false
            alarm.isHidden = true
        }
    }
    
    /* ################################################################## */
    /**
     */
    private func _refreshAlarm(_ inIndex: Int) {
        self._alarmButtons[inIndex].setNeedsDisplay()
    }

    /* ################################################################## */
    /**
     */
    private func _showAllAlarms() {
        for alarm in self._alarmButtons {
            alarm.isUserInteractionEnabled = true
            alarm.isHidden = false
        }
    }

    /* ################################################################## */
    /**
     */
    @IBAction func soundModeChanged(_ sender: UISegmentedControl) {
        self._prefs.alarms[self._currentlyEditingAlarmIndex].selectedSoundMode = TheBestClockAlarmSetting.AlarmPrefsMode(rawValue: self.alarmEditSoundModeSelector.selectedSegmentIndex) ?? .silence
        self._alarmButtons[self._currentlyEditingAlarmIndex].alarmRecord.selectedSoundMode = TheBestClockAlarmSetting.AlarmPrefsMode(rawValue: self.alarmEditSoundModeSelector.selectedSegmentIndex) ?? .silence
        self._showHideItems()
        
        self._stopAudioPlayer()
        if 1 == self.alarmEditSoundModeSelector.selectedSegmentIndex {
            self._showLookupThrobber()
            DispatchQueue.main.async {  // We do this, so we refresh the UI, and show the spinner. This can take a while.
                self._loadMediaLibrary()
                self.editAlarmPickerView.reloadComponent(0)
                self._hideLookupThrobber()
            }
        }
        self.editAlarmPickerView.reloadComponent(0)
        if 0 == self.alarmEditSoundModeSelector.selectedSegmentIndex {
            self.editAlarmPickerView.selectRow(self._prefs.alarms[self._currentlyEditingAlarmIndex].selectedSoundIndex, inComponent: 0, animated: false)
        }
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func activeSwitchChanged(_ inSwitch: UISwitch) {
        self._prefs.alarms[self._currentlyEditingAlarmIndex].isActive = inSwitch.isOn
        self._alarmButtons[self._currentlyEditingAlarmIndex].alarmRecord.isActive = inSwitch.isOn
        self._refreshAlarm(self._currentlyEditingAlarmIndex)
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func activeButtonHit(_ sender: Any) {
        self.alarmEditorActiveSwitch.setOn(!self.alarmEditorActiveSwitch.isOn, animated: true)
        self.alarmEditorActiveSwitch.sendActions(for: .valueChanged)
        self._refreshAlarm(self._currentlyEditingAlarmIndex)
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func vibrateSwitchChanged(_ inSwitch: UISwitch) {
        self._prefs.alarms[self._currentlyEditingAlarmIndex].isVibrateOn = inSwitch.isOn
        self._alarmButtons[self._currentlyEditingAlarmIndex].alarmRecord.isVibrateOn = inSwitch.isOn
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func vibrateButtonHit(_ sender: Any) {
        self.alarmEditorVibrateBeepSwitch.setOn(!self.alarmEditorVibrateBeepSwitch.isOn, animated: true)
        self.alarmEditorVibrateBeepSwitch.sendActions(for: .valueChanged)
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func testSoundButtonHit(_ sender: Any) {
        if "LOCAL-TEST-SOUND".localizedVariant == self.editAlarmTestSoundButton.title(for: .normal) {
            self.editAlarmTestSoundButton.setTitle("LOCAL-PAUSE-SOUND".localizedVariant, for: .normal)
            if let soundUrl = URL(string: self._soundSelection[self.editAlarmPickerView.selectedRow(inComponent: 0)]) {
                self._playThisSound(soundUrl)
            }
        } else {
            self.editAlarmTestSoundButton.setTitle("LOCAL-TEST-SOUND".localizedVariant, for: .normal)
            self._pauseAudioPlayer()
        }
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
            self._alarmButtons[self._currentlyEditingAlarmIndex].setNeedsDisplay()
        }
    }

    /* ################################################################## */
    /**
     This closes the alarm editor screen, making sure that everything is put back where it belongs.
     */
    @IBAction func closeAlarmEditorScreen(_ sender: Any! = nil) {
        self._stopAudioPlayer()
        self._prefs.savePrefs() // We commit the changes we made, here.
        self._currentlyEditingAlarmIndex = -1
        self.editAlarmScreenContainer.isHidden = true
        self._showAllAlarms()
        self._startTicker()
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
                if self._screenForThese.contains(fontName) {
                    self._fontSelection.append(fontName)
                }
            }
        }
        // So we have a predictable order.
        self._fontSelection.sort()
        
        // We add this to the beginning.
        self._fontSelection.insert(contentsOf: ["Let's Go Digital"], at: 0)
        self._fontSelection.append(contentsOf: ["AnglicanText", "Canterbury", "CelticHand"])
        
        // Pick up our beeper sounds.
        self._soundSelection = Bundle.main.paths(forResourcesOfType: "mp3", inDirectory: nil)

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
        self._updateMainTime()   // This will update the time. It will also set up our various labels and background colors.
        self._setInfoButtonColor()
        self.alarmEditorActiveButton.setTitle(self.alarmEditorActiveButton.title(for: .normal)?.localizedVariant, for: .normal)
        self.alarmEditorVibrateButton.setTitle(self.alarmEditorVibrateButton.title(for: .normal)?.localizedVariant, for: .normal)
        self.editAlarmTestSoundButton.setTitle("LOCAL-TEST-SOUND".localizedVariant, for: .normal)
        self.snoozeGestureRecogninzer.require(toFail: self.shutUpAlreadyGestureRecognizer)
        
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
        self._updateMainTime()
        if self.mainPickerContainerView.isHidden, -1 == self._currentlyEditingAlarmIndex { // We don't do this if we are in the appearance editor.
            UIScreen.main.brightness = self.selectedBrightness    // Dim the screen.
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
        self._fontSizeCache = 0
        self._startTicker()
        self._updateMainTime()
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
    // MARK: - Instance UIPickerView Delegate and Datasource Methods
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
        if self.colorDisplayPickerView == inPickerView {
            return self._colorSelection.count
        } else if self.fontDisplayPickerView == inPickerView {
            return self._fontSelection.count
        } else if self.editAlarmPickerView == inPickerView {
            if 0 == self.alarmEditSoundModeSelector.selectedSegmentIndex {
                return self._soundSelection.count
            } else if 1 == self.alarmEditSoundModeSelector.selectedSegmentIndex {
                return self._artists.count
            } else if self.songSelectionPickerView == inPickerView {

            }
        }
        return 0
    }

    /* ################################################################## */
    /**
     This will send the proper height for the picker row. The color picker is small squares.
     
     - parameter inPickerView: The UIPickerView being queried.
     */
    func pickerView(_ inPickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        if self.colorDisplayPickerView == inPickerView {
            return 80
        } else if self.fontDisplayPickerView == inPickerView {
            return inPickerView.bounds.size.height * 0.4
        } else if self.editAlarmPickerView == inPickerView || self.songSelectionPickerView == inPickerView {
            return 40
        }
        return 0
    }
    
    /* ################################################################## */
    /**
     This generates one row's content, depending on which picker is being specified.
     
     - parameter inPickerView: The UIPickerView being queried.
     */
    func pickerView(_ inPickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing inView: UIView?) -> UIView {
        let frame = CGRect(origin: CGPoint.zero, size: CGSize(width: inPickerView.bounds.size.width, height: self.pickerView(inPickerView, rowHeightForComponent: component)))
        var ret = inView ?? UIView(frame: frame)    // See if we can reuse an old view.
        if nil == inView {
            // Color picker is simple color squares.
            if self.colorDisplayPickerView == inPickerView {
                let insetView = UIView(frame: frame.insetBy(dx: inPickerView.bounds.size.width * 0.01, dy: inPickerView.bounds.size.width * 0.01))
                insetView.backgroundColor = self._colorSelection[row]
                ret.addSubview(insetView)
            } else if self.fontDisplayPickerView == inPickerView {    // We send generated times for the font selector.
                let frame = CGRect(x: 0, y: 0, width: inPickerView.bounds.size.width, height: self.pickerView(inPickerView, rowHeightForComponent: component))
                let reusingView = nil != inView ? inView!: UIView(frame: frame)
                self._fontSizeCache = self.pickerView(inPickerView, rowHeightForComponent: 0)
                ret = self._createDisplayView(reusingView, index: row)
            } else if self.editAlarmPickerView == inPickerView {
                let label = UILabel(frame: frame)
                label.font = UIFont.systemFont(ofSize: self._alarmEditorSoundPickerFontSize)
                label.adjustsFontSizeToFitWidth = true
                label.textAlignment = .center
                label.textColor = self.selectedColor
                label.backgroundColor = UIColor.clear
                var text = ""
                
                if 0 == self.alarmEditSoundModeSelector.selectedSegmentIndex {
                    let pathString = URL(fileURLWithPath: self._soundSelection[row]).lastPathComponent
                    text = pathString.localizedVariant
                } else if 1 == self.alarmEditSoundModeSelector.selectedSegmentIndex {
                    text = self._artists[row]
                }
                
                label.text = text
                
                ret.addSubview(label)
            } else if self.songSelectionPickerView == inPickerView {
                
            }
            ret.backgroundColor = UIColor.clear
        }
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
            self._prefs?.selectedColor = self.selectedColorIndex
            self._setInfoButtonColor()
            self.fontDisplayPickerView.reloadComponent(0)
        } else if self.fontDisplayPickerView == inPickerView {
            self.selectedFontIndex = row
            self._prefs?.selectedFont = self.selectedFontIndex
        } else if self.editAlarmPickerView == inPickerView {
            self._stopAudioPlayer()
            self.editAlarmTestSoundButton.setTitle("LOCAL-TEST-SOUND".localizedVariant, for: .normal)
            let currentAlarm = self._prefs.alarms[self._currentlyEditingAlarmIndex]
            if .sounds == currentAlarm.selectedSoundMode {
                currentAlarm.selectedSoundIndex = row
                self._alarmButtons[self._currentlyEditingAlarmIndex].alarmRecord.selectedSoundIndex = row
            }
        }
    }
    
    /* ################################################################## */
    // MARK: - Instance Alarm Editor Delegate Methods
    /* ################################################################## */
    /**
     */
    func openAlarmEditor(_ inAlarmIndex: Int) {
        if 0 <= inAlarmIndex, self._prefs.alarms.count > inAlarmIndex {
            if -1 == self._currentlyEditingAlarmIndex {
                self._currentlyEditingAlarmIndex = inAlarmIndex
                self._prefs.alarms[self._currentlyEditingAlarmIndex].isActive = true
                self._alarmButtons[self._currentlyEditingAlarmIndex].alarmRecord.isActive = true
                self._openAlarmEditorScreen()
            }
        }
    }
}
