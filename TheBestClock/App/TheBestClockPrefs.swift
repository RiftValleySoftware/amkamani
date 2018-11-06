/**
 © Copyright 2018, The Great Rift Valley Software Company. All rights reserved.
 
 This code is proprietary and confidential code,
 It is NOT to be reused or combined into any application,
 unless done so, specifically under written license from The Great Rift Valley Software Company.
 
 The Great Rift Valley Software Company: https://riftvalleysoftware.com
 */

import UIKit

/* ################################################################################################################################## */
// MARK: - Prefs Class -
/* ###################################################################################################################################### */
/**
 */
class TheBestClockPrefs {
    /* ################################################################## */
    // MARK: Private Static Properties
    /* ################################################################## */
    /** This is the key for the prefs used by this app. */
    private static let _mainPrefsKey: String = "TheBestClockPrefs"
    
    /* ################################################################## */
    // MARK: Private Variable Properties
    /* ################################################################## */
    /** We load the user prefs into this Dictionary object. */
    private var _loadedPrefs: NSMutableDictionary! = nil
    
    private var _alarms: [TheBestClockAlarmSetting] = [TheBestClockAlarmSetting(),
                                                       TheBestClockAlarmSetting(),
                                                       TheBestClockAlarmSetting(),
                                                       TheBestClockAlarmSetting()
        ]
    
    /* ################################################################## */
    // MARK: Private Enums
    /* ################################################################## */
    /** These are the keys we use for our persistent prefs dictionary. */
    private enum PrefsKeys: String {
        case selectedColor, selectedFont, brightnessLevel, alarms
    }
    
    /* ################################################################## */
    /** These are the keys we use for our alarms dictionary. */
    private enum AlarmPrefsKeys: String {
        case alarmTimeInSeconds, playlistID, isActive
    }

    /* ################################################################## */
    // MARK: Private Instance Methods
    /* ################################################################## */
    /**
     This method simply saves the main preferences Dictionary into the standard user defaults.
     */
    private func _savePrefs() {
        UserDefaults.standard.set(self._loadedPrefs, forKey: type(of: self)._mainPrefsKey)
    }
    
    /* ################################################################## */
    /**
     This method loads the main prefs into our instance storage.
     
     NOTE: This will overwrite any unsaved changes to the current _loadedPrefs property.
     
     - returns: a Bool. True, if the load was successful.
     */
    private func _loadPrefs() -> Bool {
        if let temp = UserDefaults.standard.object(forKey: type(of: self)._mainPrefsKey) as? NSDictionary {
            self._loadedPrefs = NSMutableDictionary(dictionary: temp)
        } else {
            self._loadedPrefs = NSMutableDictionary()
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
    // MARK: Internal Owned Classes
    /* ################################################################## */
    /**
     */
    @objc(_TtCC12TheBestClock24MainScreenViewController24TheBestClockAlarmSetting)class TheBestClockAlarmSetting: NSObject, NSCoding {
        var alarmTimeInSeconds: Int = 0
        var playlistID: UUID = UUID()
        var isActive: Bool = false
        var snoozing: Bool = false
        
        /* ################################################################## */
        /**
         */
        func encode(with aCoder: NSCoder) {
            aCoder.encode(self.alarmTimeInSeconds, forKey: TheBestClockPrefs.AlarmPrefsKeys.alarmTimeInSeconds.rawValue)
            aCoder.encode(self.playlistID, forKey: TheBestClockPrefs.AlarmPrefsKeys.playlistID.rawValue)
            aCoder.encode(self.isActive, forKey: TheBestClockPrefs.AlarmPrefsKeys.isActive.rawValue)
        }
        
        /* ################################################################## */
        /**
         */
        override init() {
            super.init()
        }
        
        /* ################################################################## */
        /**
         */
        required init?(coder aDecoder: NSCoder) {
            super.init()
            
            if let isActive = aDecoder.decodeObject(forKey: TheBestClockPrefs.AlarmPrefsKeys.isActive.rawValue) as? Bool {
                self.isActive = isActive
            }
            
            if let playListID = aDecoder.decodeObject(forKey: TheBestClockPrefs.AlarmPrefsKeys.playlistID.rawValue) as? UUID {
                self.playlistID = playListID
            }

            if let alarmTimeInSeconds = aDecoder.decodeObject(forKey: TheBestClockPrefs.AlarmPrefsKeys.playlistID.rawValue) as? NSNumber {
                self.alarmTimeInSeconds = alarmTimeInSeconds.intValue
            } else {
                self.alarmTimeInSeconds = 0
            }
        }
    }

    /* ################################################################## */
    /**
     - returns: An Array of alarm settings objects.
     */
    var alarms: [TheBestClockAlarmSetting] {
        get {
            if self._loadPrefs() {
                if let alarms = self._loadedPrefs.object(forKey: type(of: self).PrefsKeys.alarms.rawValue) as? [TheBestClockAlarmSetting] {
                    self._alarms = alarms
                }
            }
            
            return self._alarms
        }
        
        set {
            self._alarms = newValue
            if self._loadPrefs() {
                self._loadedPrefs.setObject(self._alarms, forKey: type(of: self).PrefsKeys.alarms.rawValue as NSString)
                self._savePrefs()
            }
        }
    }
    
    /* ################################################################## */
    // MARK: Instance Calculated Properties
    /* ################################################################## */
    /**
     - returns: the selected color index, as an Int.
     */
    var selectedColor: Int {
        get {
            var ret: Int = 0
            if self._loadPrefs() {
                if let temp = self._loadedPrefs.object(forKey: type(of: self).PrefsKeys.selectedColor.rawValue) as? NSNumber {
                    ret = temp.intValue
                }
            }
            
            return ret
        }
        
        set {
            if self._loadPrefs() {
                let value = NSNumber(value: newValue)
                self._loadedPrefs.setObject(value, forKey: type(of: self).PrefsKeys.selectedColor.rawValue as NSString)
                self._savePrefs()
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
            if self._loadPrefs() {
                if let temp = self._loadedPrefs.object(forKey: type(of: self).PrefsKeys.selectedFont.rawValue) as? NSNumber {
                    ret = temp.intValue
                }
            }
            
            return ret
        }
        
        set {
            if self._loadPrefs() {
                let value = NSNumber(value: newValue)
                self._loadedPrefs.setObject(value, forKey: type(of: self).PrefsKeys.selectedFont.rawValue as NSString)
                self._savePrefs()
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
            if self._loadPrefs() {
                if let temp = self._loadedPrefs.object(forKey: type(of: self).PrefsKeys.brightnessLevel.rawValue) as? NSNumber {
                    ret = CGFloat(temp.floatValue)
                }
            }
            
            return ret
        }
        
        set {
            if self._loadPrefs() {
                let value = NSNumber(value: Float(newValue))
                self._loadedPrefs.setObject(value, forKey: type(of: self).PrefsKeys.brightnessLevel.rawValue as NSString)
                self._savePrefs()
            }
        }
    }
}
