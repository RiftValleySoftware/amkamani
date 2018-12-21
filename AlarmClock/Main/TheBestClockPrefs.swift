/**
 © Copyright 2018, The Great Rift Valley Software Company. All rights reserved.
 
 This code is proprietary and confidential code,
 It is NOT to be reused or combined into any application,
 unless done so, specifically under written license from The Great Rift Valley Software Company.
 
 The Great Rift Valley Software Company: https://riftvalleysoftware.com
 */

import UIKit

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
        case alarmTime, isActive, isVibrateOn, selectedSoundMode, selectedSoundIndex, selectedSongURL
    }
    
    /* ################################################################## */
    /** These are the keys we use to specify the alarm sound mode. */
    public enum AlarmPrefsMode: Int {
        case sounds, music, silence
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
            if !self.isActive || (self.isActive != oldValue) {  // If we are changing the active state, we kill snooze and the "bump" time.
                self.alarmResetTime = nil
                self.lastSnoozeTime = nil
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
            return nil != self.lastSnoozeTime
        }
        
        set {
            if self.isActive, newValue {
                var now = Date()
                now.addTimeInterval(TimeInterval(self.snoozeTimeInMinutes * 60))
                // We do this to chop off any dangling seconds.
                let todayComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: now)
                let components = DateComponents(year: todayComponents.year, month: todayComponents.month, day: todayComponents.day, hour: todayComponents.hour, minute: todayComponents.minute)
                if components.isValidDate(in: Calendar.current) {
                    self.lastSnoozeTime = Calendar.current.date(from: components)
                }
                self.deactivateTime = nil
            } else {
                if (!newValue || !self.isActive) && nil != self.lastSnoozeTime {
                    self.deactivated = !newValue && nil != self.lastSnoozeTime
                    self.lastSnoozeTime = nil
                    self.alarmResetTime = nil
                }
            }
        }
    }
    
    /* ################################################################## */
    /**
     - returns: True, if the alarm has been "deactivated," and should not go off again.
     */
    var deactivated: Bool {
        get {
            if nil != self.deactivateTime {
                let interval = Date().timeIntervalSince(self.deactivateTime)
                if interval > 0 {
                    self.deactivateTime = nil
                }
            }
            return nil != self.deactivateTime
        }
        
        set {
            if self.isActive, newValue {
                if let endDeactivateTime = Calendar.current.date(byAdding: .minute, value: self.alarmTimeInMinutes, to: self.currentAlarmTime) {
                    self.deactivateTime = endDeactivateTime
                }
            } else {
                if !newValue && nil != self.deactivateTime {
                    self.deactivateTime = nil
                }
            }
        }
    }
    /* ################################################################## */
    /**
     - returns: The alarm set, for today, with the possibility of being deferred.
     */
    var currentAlarmTime: Date! {
        if nil != self.alarmResetTime { // In case they keep banging on snooze.
            return self.alarmResetTime
        }
        
        return self.todaysAlarmTime
    }
    
    /* ################################################################## */
    /**
     - returns: The alarm set, for today.
     */
    var todaysAlarmTime: Date! {
        let alarmTimeHours = self.alarmTime / 100
        let alarmTimeMinutes = self.alarmTime - (alarmTimeHours * 100)
        
        let todayComponents = Calendar.current.dateComponents([.day, .month, .year], from: Date())
        let components = DateComponents(year: todayComponents.year, month: todayComponents.month, day: todayComponents.day, hour: alarmTimeHours, minute: alarmTimeMinutes)
        if components.isValidDate(in: Calendar.current) {
            return Calendar.current.date(from: components)
        }
        
        return nil
    }
    
    /* ################################################################## */
    /**
     This just resets the two main "ephemeral" states.
     */
    func clearState() {
        self.lastSnoozeTime = nil
        self.alarmResetTime = nil
    }
    
    /* ################################################################## */
    /**
     - parameter withResetAdded: An optional Bool (default is false), that, if true, will include a cascading reset time.
     - returns: 1 if the alarm will be going off now. 0, if the alarm will not go off soon, or -1 if the alarm will go off within the alarm time window from now.
     */
    func alarmEngaged(withResetAdded: Bool = false) -> Int {
        if let alarmDate = withResetAdded ? self.currentAlarmTime : self.todaysAlarmTime {
            let todayComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
            // We do this, so we look at only the integer minutes, and not seconds.
            let components = DateComponents(year: todayComponents.year, month: todayComponents.month, day: todayComponents.day, hour: todayComponents.hour, minute: todayComponents.minute)
            if let todayNow = Calendar.current.date(from: components) {
                let backwards = todayNow.addingTimeInterval(TimeInterval(self.alarmTimeInMinutes * -60))
                let backwardsRange = backwards...todayNow
                if backwardsRange.contains(alarmDate) {
                    return 1
                }
                
                let forwards = todayNow.addingTimeInterval(TimeInterval(self.alarmTimeInMinutes * 60))
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
        if let alarmTimeToday = self.currentAlarmTime {
            if self.isActive {
                #if DEBUG
                print("Alarm Date Today: \(alarmTimeToday)")
                #endif
                if !self.deactivated {  // See if we are in a "deactivated" state.
                    if self.snoozing {  // Are we asleep?
                        let interval = self.lastSnoozeTime.timeIntervalSinceNow
                        if 0 > interval {   // If not, wake up.
                            // We do this little dance to trim off the seconds.
                            let todayComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
                            let components = DateComponents(year: todayComponents.year, month: todayComponents.month, day: todayComponents.day, hour: todayComponents.hour, minute: todayComponents.minute)
                            if components.isValidDate(in: Calendar.current) {
                                self.alarmResetTime = Calendar.current.date(from: components)   // This is a new time for the alarm, starting at the end of snooze.
                            }
                            self.lastSnoozeTime = nil
                            return true
                        }
                        
                        return false
                    } else {
                        if let endAlarmTime = Calendar.current.date(byAdding: .minute, value: self.alarmTimeInMinutes, to: alarmTimeToday) {
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
        
        self.alarmResetTime = nil
        return false
    }
    
    /* ################################################################## */
    /**
     This is the standard NSCoding saver.
     
     - parameter with: The NSCoder object that will receive the "serialized" state.
     */
    func encode(with aCoder: NSCoder) {
        assert(0 <= self.alarmTime && 2400 > self.alarmTime)
        let alarmTime = NSNumber(value: self.alarmTime)
        aCoder.encode(alarmTime, forKey: AlarmPrefsKeys.alarmTime.rawValue)
        let isActive = NSNumber(value: self.isActive)
        aCoder.encode(isActive, forKey: AlarmPrefsKeys.isActive.rawValue)
        let isVibrateOn = NSNumber(value: self.isVibrateOn)
        aCoder.encode(isVibrateOn, forKey: AlarmPrefsKeys.isVibrateOn.rawValue)
        assert(0 <= self.selectedSoundIndex)
        let selectedSoundIndex = NSNumber(value: self.selectedSoundIndex)
        aCoder.encode(selectedSoundIndex, forKey: AlarmPrefsKeys.selectedSoundIndex.rawValue)
        aCoder.encode(self.selectedSongURL as NSString, forKey: AlarmPrefsKeys.selectedSongURL.rawValue)
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
            self.alarmTime = 0
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
        loadedPrefs[self.PrefsKeys.noSnoozeLimit.rawValue] = 1
        loadedPrefs[self.PrefsKeys.snoozeCount.rawValue] = 4
        loadedPrefs[self.PrefsKeys.selectedColor.rawValue] = 0
        loadedPrefs[self.PrefsKeys.selectedFont.rawValue] = 0
        loadedPrefs[self.PrefsKeys.brightnessLevel.rawValue] = 1.0
        for index in 0..<TheBestClockPrefs._numberOfAlarms {
            let archivedObject = NSKeyedArchiver.archivedData(withRootObject: TheBestClockAlarmSetting())
            loadedPrefs[TheBestClockPrefs.PrefsKeys.alarms.rawValue + String(index)] = archivedObject
        }
        UserDefaults.standard.register(defaults: loadedPrefs)
    }
    
    /* ################################################################## */
    // MARK: Private Static Properties
    /* ################################################################## */
    /** This is the key for the prefs used by this app. */
    private static let _mainPrefsKey: String = "AmkaMani_SavedSettings"
    private static let _numberOfAlarms = 3
    
    /* ################################################################## */
    // MARK: Private Variable Properties
    /* ################################################################## */
    /** We load the user prefs into this Dictionary object. */
    private var _loadedPrefs: NSMutableDictionary! = nil
    private var _alarms: [TheBestClockAlarmSetting] = []
    
    /* ################################################################## */
    // MARK: Private Enums
    /* ################################################################## */
    /** These are the keys we use for our persistent prefs dictionary. */
    private enum PrefsKeys: String {
        case snoozeCount, noSnoozeLimit, selectedColor, selectedFont, brightnessLevel, alarms
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
            self._loadedPrefs = NSMutableDictionary(dictionary: temp)
            if let noSnoozeLimit = defaults.value(forKey: type(of: self).PrefsKeys.noSnoozeLimit.rawValue) as? NSNumber {
                self._loadedPrefs.setObject(noSnoozeLimit, forKey: type(of: self).PrefsKeys.noSnoozeLimit.rawValue as NSString)
            }
            if let snoozeCount = defaults.value(forKey: type(of: self).PrefsKeys.snoozeCount.rawValue) as? NSNumber {
                self._loadedPrefs.setObject(snoozeCount, forKey: type(of: self).PrefsKeys.snoozeCount.rawValue as NSString)
            }
            NSKeyedUnarchiver.setClass(TheBestClockAlarmSetting.self, forClassName: "TheBestClockAlarmSetting")
            // We cycle through the number of alarms that we are supposed to have. We either load saved settings, or we create new empty settings for each alarm.
            for index in 0..<type(of: self)._numberOfAlarms {
                if self._alarms.count == index {    // This makes sure that we account for any empty spots (shouldn't happen).
                    self._alarms.append(TheBestClockAlarmSetting())
                }
                if let unarchivedObject = self._loadedPrefs.object(forKey: (type(of: self).PrefsKeys.alarms.rawValue + String(index)) as NSString) as? Data {
                    if let alarm = NSKeyedUnarchiver.unarchiveObject(with: unarchivedObject) as? TheBestClockAlarmSetting {
                        let oldResetTime = self._alarms[index].alarmResetTime  // This makes sure we preserve any reset in progress. This is not saved in prefs.
                        let oldSnoozeTime = self._alarms[index].lastSnoozeTime  // This makes sure we preserve any snoozing in progress. This is not saved in prefs.
                        let oldDeactivateTime = self._alarms[index].deactivateTime  // This makes sure we preserve any deactivated alarms in progress. This is not saved in prefs.
                        self._alarms[index] = alarm
                        self._alarms[index].alarmResetTime = oldResetTime
                        self._alarms[index].lastSnoozeTime = oldSnoozeTime
                        self._alarms[index].deactivateTime = oldDeactivateTime
                    }
                }
            }
        } else {
            self._loadedPrefs = NSMutableDictionary()
        }
        
        for index in 0..<type(of: self)._numberOfAlarms where self._alarms.count == index {
            self._alarms.append(TheBestClockAlarmSetting())
        }
        
        return nil != self._loadedPrefs
    }
    
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
            return self._alarms
        }
        
        set {
            self._alarms = newValue
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
            if !self.noSnoozeLimit, self.loadPrefs() {
                if let temp = self._loadedPrefs.object(forKey: type(of: self).PrefsKeys.snoozeCount.rawValue) as? NSNumber {
                    ret = temp.intValue
                }
            }
            
            return ret
        }
        
        set {
            if self.loadPrefs() {
                let value = NSNumber(value: newValue)
                self._loadedPrefs.setObject(value, forKey: type(of: self).PrefsKeys.snoozeCount.rawValue as NSString)
                self.savePrefs()
            }
        }
    }
    
    /* ################################################################## */
    /**
     - returns: true, if we are in "Forever Snooze" mode (no limit).
     */
    var noSnoozeLimit: Bool {
        get {
            var ret: Bool = false
            if self.loadPrefs() {
                if let temp = self._loadedPrefs.object(forKey: type(of: self).PrefsKeys.noSnoozeLimit.rawValue) as? NSNumber {
                    ret = temp.boolValue
                }
            }
            
            return ret
        }
        
        set {
            if self.loadPrefs() {
                let value = NSNumber(value: newValue)
                self._loadedPrefs.setObject(value, forKey: type(of: self).PrefsKeys.noSnoozeLimit.rawValue as NSString)
                self.savePrefs()
            }
        }
    }
    
    /* ################################################################## */
    /**
     - returns: the selected color index, as an Int.
     */
    var selectedColor: Int {
        get {
            var ret: Int = 0
            if self.loadPrefs() {
                if let temp = self._loadedPrefs.object(forKey: type(of: self).PrefsKeys.selectedColor.rawValue) as? NSNumber {
                    ret = temp.intValue
                }
            }
            
            return ret
        }
        
        set {
            if self.loadPrefs() {
                let value = NSNumber(value: newValue)
                self._loadedPrefs.setObject(value, forKey: type(of: self).PrefsKeys.selectedColor.rawValue as NSString)
                self.savePrefs()
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
            if self.loadPrefs() {
                if let temp = self._loadedPrefs.object(forKey: type(of: self).PrefsKeys.selectedFont.rawValue) as? NSNumber {
                    ret = temp.intValue
                }
            }
            
            return ret
        }
        
        set {
            if self.loadPrefs() {
                let value = NSNumber(value: newValue)
                self._loadedPrefs.setObject(value, forKey: type(of: self).PrefsKeys.selectedFont.rawValue as NSString)
                self.savePrefs()
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
            if self.loadPrefs() {
                if let temp = self._loadedPrefs.object(forKey: type(of: self).PrefsKeys.brightnessLevel.rawValue) as? NSNumber {
                    ret = CGFloat(temp.floatValue)
                }
            }
            
            return ret
        }
        
        set {
            if self.loadPrefs() {
                let value = NSNumber(value: Float(newValue))
                self._loadedPrefs.setObject(value, forKey: type(of: self).PrefsKeys.brightnessLevel.rawValue as NSString)
                self.savePrefs()
            }
        }
    }
    
    /* ################################################################## */
    /**
     This method simply saves the main preferences Dictionary into the standard user defaults.
     */
    func savePrefs() {
        NSKeyedArchiver.setClassName("TheBestClockAlarmSetting", for: TheBestClockAlarmSetting.self)
        for index in 0..<self._alarms.count {
            let archivedObject = NSKeyedArchiver.archivedData(withRootObject: self._alarms[index])
            self._loadedPrefs.setObject(archivedObject, forKey: (type(of: self).PrefsKeys.alarms.rawValue + String(index)) as NSString)
        }
        UserDefaults.standard.set(self._loadedPrefs, forKey: type(of: self)._mainPrefsKey)
    }
}
