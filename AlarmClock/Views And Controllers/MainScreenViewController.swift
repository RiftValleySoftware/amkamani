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
 
 Yeah, it's a big ugly mess. Read the README to find out why the app is configured this way.
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
        /// The title of the song
        var songTitle: String
        /// The name of the song artist
        var artistName: String
        /// The title of the album on which the song is found
        var albumTitle: String
        /// The URL to the song resource in the library
        var resourceURI: String!
        /// This is a text description of the song
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
    // MARK: - Instance Constant Properties
    /* ################################################################## */
    /// This is a list of a subset of fonts likely to be on the device. We want to reduce the choices for the user.
    let screenForThese: [String] = ["AmericanTypewriter-Bold",
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
    /// This is the base font size for the ante meridian label near the top of the screen.
    let amPmLabelFontSize: CGFloat = 30
    /// This is the base font size for the date display along the top.
    let dateLabelFontSize: CGFloat = 50
    /// This is the base font size for the row of alarm buttons along the bottom of the screen.
    let alarmsFontSize: CGFloat = 40
    /// This is the base font size for the various textual items in the Alarm Editor.
    let alarmEditorTopFontSize: CGFloat = 30
    /// This is the font size for the alarm sound/music selection picker.
    let alarmEditorSoundPickerFontSize: CGFloat = 24
    /// This is the base font size for the sound test button.
    let alarmEditorSoundButtonFontSize: CGFloat = 30

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
    @IBOutlet weak var editAlarmTestSoundButton: TheBestClockSpeakerButton!
    /// This is the "STOP" long press gesture recognizer.
    @IBOutlet var shutUpAlreadyLongPressGestureRecognizer: UILongPressGestureRecognizer!
    /// This is the "STOP" double-tap gesture recognizer.
    @IBOutlet var shutUpAlreadyDoubleTapRecognizer: UITapGestureRecognizer!
    /// This is the "snooze" tap gesture recognizer.
    @IBOutlet var snoozeGestureRecogninzer: UITapGestureRecognizer!
    /// This is a view that we temorarily put up while fetching the music collection.
    @IBOutlet weak var musicLookupThrobberView: UIView!
    /// This is the throbber in that view.
    @IBOutlet weak var musicLookupThrobber: UIActivityIndicatorView!
    /// This is the secondary picker view for selecting songs in the Alarm Editor.
    @IBOutlet weak var songSelectionPickerView: UIPickerView!
    /// This is a special view that we use to mask the entire screen for initial music load.
    @IBOutlet weak var wholeScreenThrobberView: UIView!
    /// This is the throbber in that screen.
    @IBOutlet weak var wholeScreenThrobber: UIActivityIndicatorView!
    /// This is the view that holds the test song button.
    @IBOutlet weak var musicTestButtonView: UIView!
    /// This is the test song button.
    @IBOutlet weak var musicTestButton: TheBestClockSpeakerButton!
    /// This is a container view for the main edit alarm picker (Sounds and Artists).
    @IBOutlet weak var editPickerContainerView: UIView!
    /// Thi is a container for the secondary music picker (songs)
    @IBOutlet weak var songSelectContainerView: UIView!
    /// This is a container for the test sound button.
    @IBOutlet weak var testSoundContainerView: UIView!
    /// This view is displayed when there is no music available.
    @IBOutlet weak var noMusicDisplayView: UIView!
    /// This is the label that specifies that there is no music available.
    @IBOutlet weak var noMusicAvailableLabel: UILabel!
    /// This label tells the user that the alarm will not go off until next time.
    @IBOutlet weak var alarmDeactivatedLabel: UILabel!
    /// This is a transparent view that allows gesture recognizers to disable the alarm.
    @IBOutlet weak var alarmDisableScreenView: UIView!
    /// This is the label that is displayed while the music is being looked up.
    @IBOutlet weak var musicLookupLabel: UILabel!
    
    /* ################################################################## */
    // MARK: - Instance Properties
    /* ################################################################## */
    /// This is set to true if an alarm goes off. We then check it to see if we need to stop a playing audio loop when the alarm ends. Otherwise, we could keep playing forever.
    var alarmSounded: Bool = false
    /// These are the persistent prefs that store our settings.
    var prefs: TheBestClockPrefs!
    /// If the Alarm Editor is open, then this is the index of the alarm being edited. It is -1 if the Alarm Editor is not open.
    var currentlyEditingAlarmIndex: Int = -1
    /// This is the currently selected main font. It's an index into our font selection Array.
    var selectedFontIndex: Int = 0
    /// This is an index into our color selection Array, denoting the color we have selected.
    var selectedColorIndex: Int = 0
    /// This indicates the brightness level of the screen.
    var selectedBrightness: CGFloat = 1.0
    /// This is an Array of the button objects that we generated for the alarms along the bottom of the screen.
    var alarmButtons: [TheBestClockAlarmView] = []
    /// These are the names of the fonts that we have selected to be choices.
    var fontSelection: [String] = []
    /// These are all the UIColors that we have to choose from. They are dynamically generated.
    var colorSelection: [UIColor] = []
    /// These are URL Strings of the various sound files we have for the "sounds" setting.
    var soundSelection: [String] = []
    /// This is the basic background color for the whole kit and kaboodle. It gets darker as the brightness is reduced.
    var backgroundColor: UIColor = UIColor.gray
    /// This is the "heartbeat" of the clock. It's a 1-second repeating timer.
    var timer: RVS_BasicGCDTimer!
    /// This is used to cache the selected main font size. We sort of use it as a semaphore.
    var fontSizeCache: CGFloat = 0
    /// This contains information about music items.
    var songs: [String: [SongInfo]] = [:]
    /// This is an index of the keys (artists) for the songs Dictionary.
    var artists: [String] = []
    /// This is the narrowest that a screen can be to properly accommodate an Alarm Editor. Under this, and we need to force portrait mode.
    var alarmEditorMinimumHeight: CGFloat = 500
    /// This is a simple semaphore to indicate that we are in the process of loading music.
    var isLoadin: Bool = false
    /// This records the number of snoozes. We use this if we don't have "forever snooze" on.
    var snoozeCount: Int = 0
    /// This will provide haptic/audio feedback for opening and closing the editors, and for ending alarms.
    var impactFeedbackGenerator: UIImpactFeedbackGenerator?
    /// This will provide haptic/audio feedback for selection "ticks."
    var selectionFeedbackGenerator: UISelectionFeedbackGenerator?
    /// This will be the audio player that we use to play the alarm sound.
    var audioPlayer: AVAudioPlayer? {
        didSet {    // We set the Alarm Editor button to reflect whether or not we play/continue, or pause a playing sound. It will be invisible, unless we are editing an alarm.
            DispatchQueue.main.async {
                if 0 <= self.currentlyEditingAlarmIndex {   // Only counts if we have the editor open.
                    self.editAlarmTestSoundButton.isOn = (nil == self.audioPlayer)
                }
            }
        }
    }

    /* ################################################################## */
    // MARK: - Instance Override Calculated Properties
    /* ################################################################## */
    /**
     - returns true, indicating that X-phones should hide the Home Bar.
     */
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
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
        return self.colorSelection[self.selectedColorIndex]
    }
    
    /* ################################################################## */
    /**
     - returns the selected font name.
     */
    var selectedFontName: String {
        return self.fontSelection[self.selectedFontIndex]
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
            return self.colorSelection.count
        } else if self.fontDisplayPickerView == inPickerView {
            return self.fontSelection.count
        } else if self.editAlarmPickerView == inPickerView {
            if 0 == self.alarmEditSoundModeSelector.selectedSegmentIndex {
                return self.soundSelection.count
            } else if 1 == self.alarmEditSoundModeSelector.selectedSegmentIndex {
                return self.artists.count
            }
        } else if !self.artists.isEmpty, !self.songs.isEmpty, 1 == self.alarmEditSoundModeSelector.selectedSegmentIndex, self.songSelectionPickerView == inPickerView {
            let artistName = self.artists[self.editAlarmPickerView.selectedRow(inComponent: 0)]
            if let songList = self.songs[artistName] {
                return songList.count
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
                insetView.backgroundColor = self.colorSelection[row]
                ret.addSubview(insetView)
            } else if self.fontDisplayPickerView == inPickerView {    // We send generated times for the font selector.
                let frame = CGRect(x: 0, y: 0, width: inPickerView.bounds.size.width, height: self.pickerView(inPickerView, rowHeightForComponent: component))
                let reusingView = nil != inView ? inView!: UIView(frame: frame)
                self.fontSizeCache = self.pickerView(inPickerView, rowHeightForComponent: 0)
                ret = self.createDisplayView(reusingView, index: row)
            } else if self.editAlarmPickerView == inPickerView {
                let label = UILabel(frame: frame)
                label.font = UIFont.systemFont(ofSize: self.alarmEditorSoundPickerFontSize)
                label.adjustsFontSizeToFitWidth = true
                label.textAlignment = .center
                label.textColor = self.selectedColor
                label.backgroundColor = UIColor.clear
                var text = ""
                
                if 0 == self.alarmEditSoundModeSelector.selectedSegmentIndex {
                    let pathString = URL(fileURLWithPath: self.soundSelection[row]).lastPathComponent
                    text = pathString.localizedVariant
                } else if 1 == self.alarmEditSoundModeSelector.selectedSegmentIndex {
                    text = self.artists[row]
                }
                
                label.text = text
                
                ret.addSubview(label)
            } else if self.songSelectionPickerView == inPickerView {
                let artistName = self.artists[self.editAlarmPickerView.selectedRow(inComponent: 0)]
                if let songs = self.songs[artistName] {
                    let selectedRow = max(0, min(songs.count - 1, row))
                    let song = songs[selectedRow]
                    let label = UILabel(frame: frame)
                    label.font = UIFont.systemFont(ofSize: self.alarmEditorSoundPickerFontSize)
                    label.adjustsFontSizeToFitWidth = true
                    label.textAlignment = .center
                    label.textColor = self.selectedColor
                    label.backgroundColor = UIColor.clear
                    label.text = song.songTitle
                    ret.addSubview(label)
                }
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
            self.prefs?.selectedColor = self.selectedColorIndex
            self.setInfoButtonColor()
            self.fontDisplayPickerView.reloadComponent(0)
        } else if self.fontDisplayPickerView == inPickerView {
            self.selectedFontIndex = row
            self.prefs?.selectedFont = self.selectedFontIndex
        } else if self.editAlarmPickerView == inPickerView, 0 <= self.currentlyEditingAlarmIndex {
            self.stopAudioPlayer()
            self.editAlarmTestSoundButton.isOn = true
            let currentAlarm = self.prefs.alarms[self.currentlyEditingAlarmIndex]
            if .sounds == currentAlarm.selectedSoundMode {
                currentAlarm.selectedSoundIndex = row
                self.alarmButtons[self.currentlyEditingAlarmIndex].alarmRecord.selectedSoundIndex = row
            } else {
                self.songSelectionPickerView.reloadComponent(0)
                self.songSelectionPickerView.selectRow(0, inComponent: 0, animated: true)
                let songURL = self.findSongURL(artistIndex: self.editAlarmPickerView.selectedRow(inComponent: 0), songIndex: 0)
                if !songURL.isEmpty, 0 <= self.currentlyEditingAlarmIndex {
                    self.prefs.alarms[self.currentlyEditingAlarmIndex].selectedSongURL = songURL
                    self.alarmButtons[self.currentlyEditingAlarmIndex].alarmRecord.selectedSongURL = songURL
                }
            }
        } else if self.songSelectionPickerView == inPickerView {
            self.stopAudioPlayer()
            let songURL = self.findSongURL(artistIndex: self.editAlarmPickerView.selectedRow(inComponent: 0), songIndex: row)
            if !songURL.isEmpty, 0 <= self.currentlyEditingAlarmIndex {
                self.prefs.alarms[self.currentlyEditingAlarmIndex].selectedSongURL = songURL
                self.alarmButtons[self.currentlyEditingAlarmIndex].alarmRecord.selectedSongURL = songURL
            }
        }
    }
}
