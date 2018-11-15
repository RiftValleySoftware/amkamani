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
     This class is a wrapper for the low-level GCD event repeater.
     
     This was cribbed from here: https://medium.com/@danielgalasko/a-background-repeating-timer-in-swift-412cecfd2ef9
     */
    class RepeatingTimer {
        /// This holds our current run state.
        private var state: _State = ._suspended
        
        /// This is the time between fires, in seconds.
        let timeInterval: TimeInterval
        /// This is the callback event handler we registered.
        var eventHandler: (() -> Void)?
        
        /* ############################################################## */
        /**
         This calculated property will create a new timer that repeats.
         
         It uses the current queue.
         */
        private lazy var timer: DispatchSourceTimer = {
            let t = DispatchSource.makeTimerSource()    // We make a generic, default timer source. No frou-frou.
            t.schedule(deadline: .now() + self.timeInterval, repeating: self.timeInterval)  // We tell it to repeat at our interval.
            t.setEventHandler(handler: { [unowned self] in  // This is the callback.
                self.eventHandler?()    // This just calls the event handler we registered.
            })
            return t
        }()
        
        /// This is used to hold state flags for internal use.
        private enum _State {
            /// The timer is currently paused.
            case _suspended
            /// The timer has been resumed, and is firing.
            case _resumed
        }
        
        /* ############################################################## */
        /**
         Default constructor
         
         - parameter timeInterval: The time (in seconds) between fires.
         */
        init(timeInterval inTimeInterval: TimeInterval) {
            self.timeInterval = inTimeInterval
        }

        /* ############################################################## */
        /**
         If the timer is not currently running, we resume. If running, nothing happens.
         */
        func resume() {
            if self.state == ._resumed {
                return
            }
            self.state = ._resumed
            self.timer.resume()
        }
        
        /* ############################################################## */
        /**
         If the timer is currently running, we suspend. If not running, nothing happens.
         */
        func suspend() {
            if self.state == ._suspended {
                return
            }
            self.state = ._suspended
            self.timer.suspend()
        }

        /* ############################################################## */
        /**
         We have to carefully dismantle this, as we can end up with crashes if we don't clean up properly.
         */
        deinit {
            self.timer.setEventHandler {}
            self.timer.cancel()
            self.resume()   // You need to call resume after canceling. I guess it lets the queue clean up.
            self.eventHandler = nil
        }
    }
    
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
        var resourceURI: String!
        
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
    /// This is our minimum brightness threshold. We don't let the text and stuff quite make it to 0.
    let minimumBrightness: CGFloat = 0.15
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
    /// This is the base font size for the deactivated label.
    let alarmDeactivatedLabelFontSize: CGFloat = 15

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
    /// This is a special view that we use to mask the entire screen for initial music load.
    @IBOutlet weak var wholeScreenThrobberView: UIView!
    /// This is the throbber in that screen.
    @IBOutlet weak var wholeScreenThrobber: UIActivityIndicatorView!
    /// This is the view that holds the test song button.
    @IBOutlet weak var musicTestButtonView: UIView!
    /// This is the test song button.
    @IBOutlet weak var musicTestButton: UIButton!
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
    
    /* ################################################################## */
    // MARK: - Instance Properties
    /* ################################################################## */
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
    var ticker: RepeatingTimer!
    /// This is used to cache the selected main font size. We sort of use it as a semaphore.
    var fontSizeCache: CGFloat = 0
    /// This contains information about music items.
    var songs: [String: [SongInfo]] = [:]
    /// This is an index of the keys (artists) for the songs Dictionary.
    var artists: [String] = []
    /// This is the narrowest that a screen can be to properly accommodate an Alarm Editor. Under this, and we need to force portrait mode.
    var alarmEditorMinimumHeight: CGFloat = 550
    /// Thi is a simple semaphore to indicate that we are in the process of loading music.
    var isLoadin: Bool = false
    /// This will be the audio player that we use to play the alarm sound.
    var audioPlayer: AVAudioPlayer? {
        didSet {    // We set the Alarm Editor button text to reflect whether or not we play/continue, or pause a playing sound. It will be invisible, unless we are editing an alarm.
            DispatchQueue.main.async {
                self.editAlarmTestSoundButton.setTitle((nil == self.audioPlayer ? "LOCAL-TEST-SOUND" : "LOCAL-PAUSE-SOUND").localizedVariant, for: .normal)
            }
        }
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
}
