/**
 © Copyright 2018, The Great Rift Valley Software Company. All rights reserved.
 
 This code is proprietary and confidential code,
 It is NOT to be reused or combined into any application,
 unless done so, specifically under written license from The Great Rift Valley Software Company.
 
 The Great Rift Valley Software Company: https://riftvalleysoftware.com
 */

import UIKit
import MediaPlayer

/* ################################################################################################################################## */
// MARK: Alarm Class
/* ################################################################################################################################## */
/**
 */
@objc(TheBestClockAlarmSetting)
class TheBestClockAlarmSetting: NSObject, NSCoding {
    /* ################################################################## */
    /** These are the keys we use for our alarms dictionary. */
    private enum AlarmPrefsKeys: String {
        /// The set time for this alarm
        case alarmTime
        /// Whether or not the alarm is currently active
        case isActive
        /// Is the alarm set to vibrate when going off?
        case isVibrateOn
        /// The sound mode (music, sound, silent)
        case selectedSoundMode
        /// If sound, the selected preset sound index
        case selectedSoundIndex
        /// If music, the selected resource URL for the song
        case selectedSongURL
    }
    
    /* ################################################################## */
    /** These are the keys we use to specify the alarm sound mode. */
    public enum AlarmPrefsMode: Int {
        /// Play from a selection of preset sounds
        case sounds
        /// Play a song from the music library
        case music
        /// Rely on flashing scree and, possibly, vibrate
        case silence
    }
    
    /* ################################################################## */
    // MARK: - Instance Internal Constant Properties
    /* ################################################################## */
    /// The number of minutes we snooze for.
    let snoozeTimeInMinutes: Int = 9
    /// The length of time an alarm will blare, in minutes.
    let alarmTimeInMinutes: Int = 15
    
    /* ################################################################## */
    // MARK: - Instance Stored Properties
    /* ################################################################## */
    /// SAVED IN STATE: The time (HHMM) for the alarm.
    var alarmTime: Int = 0
    /// SAVED IN STATE: True, for vibrate.
    var isVibrateOn: Bool = false
    /// SAVED IN STATE: The sound mode.
    var selectedSoundMode: AlarmPrefsMode = .sounds
    /// SAVED IN STATE: If the sound mode is sounds, the index of the stored sound.
    var selectedSoundIndex: Int = 0
    /// SAVED IN STATE: If the sound mode is music, the resource URL of the selected song.
    var selectedSongURL: String = ""
    /// SAVED IN STATE: True, if the alarm is active.
    var isActive: Bool = false {
        didSet {
            if !isActive || (isActive != oldValue) {  // If we are changing the active state, we kill snooze and the "bump" time.
                alarmResetTime = nil
                lastSnoozeTime = nil
            }
        }
    }
    
    /// EPHEMERAL: The time a "snooze" started.
    var lastSnoozeTime: Date!
    /// EPHEMERAL: The time that an alarm was deactivated, so it doesn't keep going off if we reactivate it.
    var deactivateTime: Date!
    /// EPHEMERAL: The time to be used as the start of the alarm range. This can be "bumped." If nil, then the set alarm time will be used to calculate the range.
    var alarmResetTime: Date!
    
    /* ################################################################## */
    // MARK: - Instance Calculated Properties
    /* ################################################################## */
    /**
     - returns: True, if the alarm is currently "snoozing."
     */
    var snoozing: Bool {
        get {
            return nil != lastSnoozeTime
        }
        
        set {
            if isActive, newValue {
                var now = Date()
                now.addTimeInterval(TimeInterval(snoozeTimeInMinutes * 60))
                // We do this to chop off any dangling seconds.
                let todayComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: now)
                let components = DateComponents(year: todayComponents.year, month: todayComponents.month, day: todayComponents.day, hour: todayComponents.hour, minute: todayComponents.minute)
                if components.isValidDate(in: Calendar.current) {
                    lastSnoozeTime = Calendar.current.date(from: components)
                }
                deactivateTime = nil
            } else {
                if (!newValue || !isActive) && nil != lastSnoozeTime {
                    deferred = !newValue && nil != lastSnoozeTime  // This is to make sure that we don't go off again as soon as we close the editor.
                    lastSnoozeTime = nil
                    alarmResetTime = nil
                }
            }
        }
    }
    
    /* ################################################################## */
    /**
     This handles "deferring" an alarm. That prevents it from going off immediately when turned back on.
     
     Basic rule: It should ALWAYS be deferred when activating from the front panel, or when starting/bringing forward the app. It can be reset from the Alarm Editor Screen.
     
     - returns: True, if the alarm has been "deferred," and should not go off again.
     */
    var deferred: Bool {
        get {
            if nil != deactivateTime { // See if we even have a deferral in place.
                let interval = Date().timeIntervalSince(deactivateTime)    // How long has it been since we deactivated?
                // If we are greater than 0, it means that we are past the deferral window, so we can nuke the deferral. Also, being more than the alarm time in minutes away nukes the deferral.
                let absInterval = Int(Swift.abs(interval / 60))
                if 0 < interval || absInterval > alarmTimeInMinutes {
                    deactivateTime = nil
                    return false
                }
                
                return true
            }
            
            return false
        }
        
        set {
            if newValue {
                // What we do here, is add the alarm time to our current set time (not the current time). We have that many minutes of time before the deferral makes no sense.
                if let endDeactivateTime = Calendar.current.date(byAdding: .minute, value: alarmTimeInMinutes, to: currentAlarmTime) {
                    let interval = endDeactivateTime.timeIntervalSince(Date())      // How long until the next activation?
                    deactivateTime = (0 < interval) ? endDeactivateTime : nil  // We don't deactivate if we are too far in the past.
                }
            } else {
                deactivateTime = nil
            }
        }
    }
    /* ################################################################## */
    /**
     - returns: The alarm set, for today, with the possibility of being deferred.
     */
    var currentAlarmTime: Date! {
        _ = deferred           // We do this to clear away any deferral.
        if nil != alarmResetTime { // In case they keep banging on snooze.
            return alarmResetTime
        }
        
        return todaysAlarmTime
    }
    
    /* ################################################################## */
    /**
     - returns: The alarm set, for today.
     */
    var todaysAlarmTime: Date! {
        let alarmTimeHours = alarmTime / 100
        let alarmTimeMinutes = alarmTime - (alarmTimeHours * 100)
        
        let todayComponents = Calendar.current.dateComponents([.day, .month, .year], from: Date())
        let components = DateComponents(year: todayComponents.year, month: todayComponents.month, day: todayComponents.day, hour: alarmTimeHours, minute: alarmTimeMinutes)
        if components.isValidDate(in: Calendar.current) {
            return Calendar.current.date(from: components)
        }
        
        return nil
    }
    
    /* ################################################################## */
    /**
     This just resets the three main "ephemeral" states.
     */
    func clearState() {
        lastSnoozeTime = nil
        alarmResetTime = nil
        deferred = false
    }
    
    /* ################################################################## */
    /**
     - parameter withResetAdded: An optional Bool (default is false), that, if true, will include a cascading reset time.
     - returns: 1 if the alarm will be going off now. 0, if the alarm will not go off soon, or -1 if the alarm will go off within the alarm time window from now.
     */
    func alarmEngaged(withResetAdded: Bool = false) -> Int {
        if let alarmDate = withResetAdded ? currentAlarmTime : todaysAlarmTime {
            let todayComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
            // We do this, so we look at only the integer minutes, and not seconds.
            let components = DateComponents(year: todayComponents.year, month: todayComponents.month, day: todayComponents.day, hour: todayComponents.hour, minute: todayComponents.minute)
            if let todayNow = Calendar.current.date(from: components) {
                let backwards = todayNow.addingTimeInterval(TimeInterval(alarmTimeInMinutes * -60))
                let backwardsRange = backwards...todayNow
                if backwardsRange.contains(alarmDate) {
                    return 1
                }
                
                let forwards = todayNow.addingTimeInterval(TimeInterval(alarmTimeInMinutes * 60))
                let forwardsRange = todayNow...forwards // todayNow is actually not considered, as it was already eaten by backwards.
                
                if forwardsRange.contains(alarmDate) {
                    return -1
                }
            }
        }
        
        return 0
    }
    
    /* ################################################################## */
    /**
     - returns: True, if the alarm should be blaring right now.
     */
    var isAlarming: Bool {
        if let alarmTimeToday = currentAlarmTime {
            if isActive {
                if !deferred {  // See if we are in a "deactivated" state.
                    if snoozing {  // Are we asleep?
                        let interval = lastSnoozeTime.timeIntervalSinceNow
                        if 0 > interval {   // If not, wake up.
                            // We do this little dance to trim off the seconds.
                            let todayComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
                            let components = DateComponents(year: todayComponents.year, month: todayComponents.month, day: todayComponents.day, hour: todayComponents.hour, minute: todayComponents.minute)
                            if components.isValidDate(in: Calendar.current) {
                                alarmResetTime = Calendar.current.date(from: components)   // This is a new time for the alarm, starting at the end of snooze.
                            }
                            lastSnoozeTime = nil
                            return true
                        }
                        
                        return false
                    } else {
                        if let endAlarmTime = Calendar.current.date(byAdding: .minute, value: alarmTimeInMinutes, to: alarmTimeToday) {
                            let alarmRange = alarmTimeToday..<endAlarmTime
                            // We strip out the seconds.
                            let todayComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
                            let components = DateComponents(year: todayComponents.year, month: todayComponents.month, day: todayComponents.day, hour: todayComponents.hour, minute: todayComponents.minute)
                            if let date = Calendar.current.date(from: components), alarmRange.contains(date) {
                                return true
                            }
                        }
                    }
                }
            }
        }
        
        alarmResetTime = nil
        return false
    }
    
    /* ################################################################## */
    /**
     This is the standard NSCoding saver.
     
     - parameter with: The NSCoder object that will receive the "serialized" state.
     */
    func encode(with aCoder: NSCoder) {
        assert(0 <= alarmTime && 2400 > alarmTime)
        let alarmTime = NSNumber(value: self.alarmTime)
        aCoder.encode(alarmTime, forKey: AlarmPrefsKeys.alarmTime.rawValue)
        let isActive = NSNumber(value: self.isActive)
        aCoder.encode(isActive, forKey: AlarmPrefsKeys.isActive.rawValue)
        let isVibrateOn = NSNumber(value: self.isVibrateOn)
        aCoder.encode(isVibrateOn, forKey: AlarmPrefsKeys.isVibrateOn.rawValue)
        assert(0 <= selectedSoundIndex)
        let selectedSoundIndex = NSNumber(value: self.selectedSoundIndex)
        aCoder.encode(selectedSoundIndex, forKey: AlarmPrefsKeys.selectedSoundIndex.rawValue)
        aCoder.encode(selectedSongURL as NSString, forKey: AlarmPrefsKeys.selectedSongURL.rawValue)
        let selectedSoundMode = NSNumber(value: self.selectedSoundMode.rawValue)
        aCoder.encode(selectedSoundMode, forKey: AlarmPrefsKeys.selectedSoundMode.rawValue)
    }
    
    /* ################################################################## */
    /**
     Standard empty init.
     */
    override init() {
        super.init()
    }
    
    /* ################################################################## */
    /**
     NSCoding initializer.
     
     - parameter coder: The coder that we will get our state from.
     */
    required init?(coder aDecoder: NSCoder) {
        super.init()
        
        if let selectedSoundMode = aDecoder.decodeObject(forKey: AlarmPrefsKeys.selectedSoundMode.rawValue) as? NSNumber {
            self.selectedSoundMode = AlarmPrefsMode(rawValue: selectedSoundMode.intValue) ?? .silence
        }
        
        if let selectedSongURL = aDecoder.decodeObject(forKey: AlarmPrefsKeys.selectedSongURL.rawValue) as? NSString {
            self.selectedSongURL = selectedSongURL as String
        }
        
        if let selectedSoundIndex = aDecoder.decodeObject(forKey: AlarmPrefsKeys.selectedSoundIndex.rawValue) as? NSNumber {
            self.selectedSoundIndex = selectedSoundIndex.intValue
        }
        
        if let isVibrateOn = aDecoder.decodeObject(forKey: AlarmPrefsKeys.isVibrateOn.rawValue) as? NSNumber {
            self.isVibrateOn = isVibrateOn.boolValue
        }
        
        if let isActive = aDecoder.decodeObject(forKey: AlarmPrefsKeys.isActive.rawValue) as? NSNumber {
            self.isActive = isActive.boolValue
        }
        
        if let alarmTime = aDecoder.decodeObject(forKey: AlarmPrefsKeys.alarmTime.rawValue) as? NSNumber {
            self.alarmTime = alarmTime.intValue
        } else {
            alarmTime = 0
        }
    }
}

/* ################################################################################################################################## */
// MARK: - Prefs Class -
/* ###################################################################################################################################### */
/**
 */
@objc(TheBestClockPrefs)
class TheBestClockPrefs: NSObject {
    /* ################################################################## */
    // MARK: Class Methods
    /* ################################################################## */
    /**
     */
    class func registerDefaults() {
        var loadedPrefs: [String: Any] = [:]
        NSKeyedArchiver.setClassName("TheBestClockAlarmSetting", for: TheBestClockAlarmSetting.self)
        loadedPrefs[PrefsKeys.snoozeCount.rawValue] = 0
        loadedPrefs[PrefsKeys.selectedColor.rawValue] = 0
        loadedPrefs[PrefsKeys.selectedFont.rawValue] = 0
        loadedPrefs[PrefsKeys.brightnessLevel.rawValue] = 1.0
        for index in 0..<TheBestClockPrefs._numberOfAlarms {
            if  let archivedObject = try? NSKeyedArchiver.archivedData(withRootObject: TheBestClockAlarmSetting(), requiringSecureCoding: false) {
                loadedPrefs[TheBestClockPrefs.PrefsKeys.alarms.rawValue + String(index)] = archivedObject
            }
        }
        UserDefaults.standard.register(defaults: loadedPrefs)
    }
    
    /* ################################################################## */
    // MARK: Private Static Properties
    /* ################################################################## */
    /** This is the key for the prefs used by this app. */
    private static let _mainPrefsKey: String = "AmkaMani_Settings"
    /// The fixed number of alarms
    private static let _numberOfAlarms = 3
    
    /* ################################################################## */
    // MARK: Private Variable Properties
    /* ################################################################## */
    /** We load the user prefs into this Dictionary object. */
    private var _loadedPrefs: NSMutableDictionary! = nil
    /// The alarms that we have loaded
    private var _alarms: [TheBestClockAlarmSetting] = []
    
    /* ################################################################## */
    // MARK: Private Enums
    /* ################################################################## */
    /** These are the keys we use for our persistent prefs dictionary. */
    private enum PrefsKeys: String {
        /// This is how many times you can "snooze" before the app gives up
        case snoozeCount
        /// This is the color selected for the fonts
        case selectedColor
        /// This is the font we are using to display the clock
        case selectedFont
        /// This is the fixed brightness level for the display
        case brightnessLevel
        /// These are the alarms
        case alarms
    }
    
    /* ################################################################## */
    // MARK: Private Instance Methods
    /* ################################################################## */
    /**
     This method loads the main prefs into our instance storage.
     
     NOTE: This will overwrite any unsaved changes to the current _loadedPrefs property.
     
     - returns: a Bool. True, if the load was successful.
     */
    func loadPrefs() -> Bool {
        if let temp = UserDefaults.standard.object(forKey: type(of: self)._mainPrefsKey) as? NSDictionary {
            let defaults = UserDefaults.standard
            _loadedPrefs = NSMutableDictionary(dictionary: temp)
            if let snoozeCount = defaults.value(forKey: type(of: self).PrefsKeys.snoozeCount.rawValue) as? NSNumber {
                _loadedPrefs.setObject(snoozeCount, forKey: type(of: self).PrefsKeys.snoozeCount.rawValue as NSString)
            }
            NSKeyedUnarchiver.setClass(TheBestClockAlarmSetting.self, forClassName: "TheBestClockAlarmSetting")
            // We cycle through the number of alarms that we are supposed to have. We either load saved settings, or we create new empty settings for each alarm.
            for index in 0..<type(of: self)._numberOfAlarms {
                if _alarms.count == index {    // This makes sure that we account for any empty spots (shouldn't happen).
                    _alarms.append(TheBestClockAlarmSetting())
                }
                if let unarchivedObject = _loadedPrefs.object(forKey: (type(of: self).PrefsKeys.alarms.rawValue + String(index)) as NSString) as? Data {
                    if let alarm = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(unarchivedObject) as? TheBestClockAlarmSetting {
                        let oldResetTime = _alarms[index].alarmResetTime  // This makes sure we preserve any reset in progress. This is not saved in prefs.
                        let oldSnoozeTime = _alarms[index].lastSnoozeTime  // This makes sure we preserve any snoozing in progress. This is not saved in prefs.
                        let oldDeactivateTime = _alarms[index].deactivateTime  // This makes sure we preserve any deactivated alarms in progress. This is not saved in prefs.
                        _alarms[index] = alarm
                        _alarms[index].alarmResetTime = oldResetTime
                        _alarms[index].lastSnoozeTime = oldSnoozeTime
                        _alarms[index].deactivateTime = oldDeactivateTime
                    }
                }
            }
        } else {
            _loadedPrefs = NSMutableDictionary()
        }
        
        for index in 0..<type(of: self)._numberOfAlarms where _alarms.count == index {
            _alarms.append(TheBestClockAlarmSetting())
        }
        #if DEBUG
            print("Loaded Prefs: \(String(describing: _loadedPrefs))")
        #endif
        
        // If we are in restricted media mode, then we don't allow any of our timers to be in Music mode.
        for alarm in _alarms where .music == alarm.selectedSoundMode {  // Only ones that are set to Music get changed.
            #if targetEnvironment(macCatalyst)  // Catalyst won't allow us to access the music library. Boo!
                alarm.selectedSoundMode = .silence
            #else
                alarm.selectedSoundMode = (.denied == MPMediaLibrary.authorizationStatus() || .restricted == MPMediaLibrary.authorizationStatus()) ? .silence : alarm.selectedSoundMode
            #endif
        }

        return nil != _loadedPrefs
    }
    
    /* ################################################################## */
    // MARK: Class Static Properties
    /* ################################################################## */
    /**
     This is our minimum brightness threshold. We don't let the text and stuff quite make it to 0.
     */
    static let minimumBrightness: CGFloat = 0.1
    
    /* ################################################################## */
    // MARK: Class Static Calculated Properties
    /* ################################################################## */
    /**
     This tells us whether or not the device is set for military time.
     */
    static var using12hClockFormat: Bool {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        let dateString = formatter.string(from: Date())
        let amRange = dateString.range(of: formatter.amSymbol)
        let pmRange = dateString.range(of: formatter.pmSymbol)
        
        return !(pmRange == nil && amRange == nil)
    }
    
    /* ################################################################## */
    /**
     This tells us whether or not the device is set for kilometers.
     */
    static var usingKilometeres: Bool {
        let locale = NSLocale.current
        return locale.usesMetricSystem
    }
    
    /* ################################################################## */
    /**
     Returns the 0-based index of the first weekday for the current calendar (0 = Sunday, 6 = Saturday).
     */
    static var indexOfWeekStart: Int {
        return Calendar.current.firstWeekday - 1
    }
    
    /* ################################################################## */
    // MARK: Instance Static Methods
    /* ################################################################## */
    /**
     Gets a localized version of the weekday name from an index.
     
     Cribbed from Here: http://stackoverflow.com/questions/7330420/how-do-i-get-the-name-of-a-day-of-the-week-in-the-users-locale#answer-34289913
     
     - parameter weekdayNumber::1-based index (1 - 7), with 1 being Sunday, and 7 being Saturday.
     - parameter short::if true, then the shortened version of the name is returned (default is false).

     - returns: The localized, full-length weekday name (or shortened, if short is true).
     */
    class func weekdayNameFromWeekdayNumber(_ weekdayNumber: Int, short: Bool = false) -> String {
        let calendar = Calendar.current
        let weekdaySymbols = short ? calendar.shortWeekdaySymbols : calendar.weekdaySymbols
        let weekdayIndex = weekdayNumber - 1
        var index = weekdayIndex
        if 6 < index {
            index -= 7
        }
        return weekdaySymbols[index].firstUppercased
    }

    /* ################################################################## */
    /**
     - returns: An Array of alarm settings objects.
     */
    var alarms: [TheBestClockAlarmSetting] {
        get {
            return _alarms
        }
        
        set {
            _alarms = newValue
        }
    }
    
    /* ################################################################## */
    // MARK: Instance Calculated Properties
    /* ################################################################## */
    /**
     - returns: the number of snoozes to allow. Ignored, if noSnoozeLimit is true.
     */
    var snoozeCount: Int {
        get {
            var ret: Int = 0
            if let temp = _loadedPrefs.object(forKey: type(of: self).PrefsKeys.snoozeCount.rawValue) as? NSNumber {
                ret = temp.intValue
            }
            
            return ret
        }
        
        set {
            if loadPrefs() {
                let value = NSNumber(value: newValue)
                _loadedPrefs.setObject(value, forKey: type(of: self).PrefsKeys.snoozeCount.rawValue as NSString)
                savePrefs()
            }
        }
    }
    
    /* ################################################################## */
    /**
     - returns: true, if we are in "Forever Snooze" mode (no limit). READ ONLY
     */
    var noSnoozeLimit: Bool {
        return 0 == snoozeCount
    }
    
    /* ################################################################## */
    /**
     - returns: the selected color index, as an Int.
     */
    var selectedColor: Int {
        get {
            var ret: Int = 0
            if loadPrefs() {
                if let temp = _loadedPrefs.object(forKey: type(of: self).PrefsKeys.selectedColor.rawValue) as? NSNumber {
                    ret = temp.intValue
                }
            }
            
            return ret
        }
        
        set {
            if loadPrefs() {
                let value = NSNumber(value: newValue)
                _loadedPrefs.setObject(value, forKey: type(of: self).PrefsKeys.selectedColor.rawValue as NSString)
                savePrefs()
            }
        }
    }
    
    /* ################################################################## */
    /**
     - returns: the selected font index, as an Int.
     */
    var selectedFont: Int {
        get {
            var ret: Int = 0
            if loadPrefs() {
                if let temp = _loadedPrefs.object(forKey: type(of: self).PrefsKeys.selectedFont.rawValue) as? NSNumber {
                    ret = temp.intValue
                }
            }
            
            return ret
        }
        
        set {
            if loadPrefs() {
                let value = NSNumber(value: newValue)
                _loadedPrefs.setObject(value, forKey: type(of: self).PrefsKeys.selectedFont.rawValue as NSString)
                savePrefs()
            }
        }
    }
    
    /* ################################################################## */
    /**
     - returns: the brightness level, as a CGFloat.
     */
    var brightnessLevel: CGFloat {
        get {
            var ret: CGFloat = 1.0
            if loadPrefs() {
                if let temp = _loadedPrefs.object(forKey: type(of: self).PrefsKeys.brightnessLevel.rawValue) as? NSNumber {
                    ret = CGFloat(temp.floatValue)
                }
            }
            
            return ret
        }
        
        set {
            if loadPrefs() {
                let value = NSNumber(value: Float(Swift.min(1.0, Swift.max(type(of: self).minimumBrightness, newValue))))   // Make sure we don't go below minimum.
                #if DEBUG
                if let temp = _loadedPrefs.object(forKey: type(of: self).PrefsKeys.brightnessLevel.rawValue) as? NSNumber {
                    print("Changing stored brightness from \(temp) to \(value)")
                }
                #endif
                _loadedPrefs.setObject(value, forKey: type(of: self).PrefsKeys.brightnessLevel.rawValue as NSString)
                savePrefs()
            }
        }
    }
    
    /* ################################################################## */
    /**
     This method simply saves the main preferences Dictionary into the standard user defaults.
     */
    func savePrefs() {
        NSKeyedArchiver.setClassName("TheBestClockAlarmSetting", for: TheBestClockAlarmSetting.self)
        for index in 0..<_alarms.count {
            if  let archivedObject = try? NSKeyedArchiver.archivedData(withRootObject: _alarms[index], requiringSecureCoding: false) {
                _loadedPrefs.setObject(archivedObject, forKey: (type(of: self).PrefsKeys.alarms.rawValue + String(index)) as NSString)
            }
        }
        UserDefaults.standard.set(_loadedPrefs, forKey: type(of: self)._mainPrefsKey)
    }
}
