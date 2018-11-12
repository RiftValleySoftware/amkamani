/**
 © Copyright 2018, The Great Rift Valley Software Company. All rights reserved.
 
 This code is proprietary and confidential code,
 It is NOT to be reused or combined into any application,
 unless done so, specifically under written license from The Great Rift Valley Software Company.
 
 The Great Rift Valley Software Company: https://riftvalleysoftware.com
 */

import UIKit

/* ###################################################################################################################################### */
// MARK: - Extensions -
/* ###################################################################################################################################### */
/**
 */
extension UIColor {
    /* ################################################################## */
    /**
     This just allows us to get an HSB color from a standard UIColor.
     From here: https://stackoverflow.com/a/30713456/879365
     
     - returns: A tuple, containing the HSBA color.
     */
    var hsba:(h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat) {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if self.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return (h: h, s: s, b: b, a: a)
        }
        return (h: 0, s: 0, b: 0, a: 0)
    }
    
    /* ################################################################## */
    /**
     - returns true, if the color is grayscale (or black or white).
     */
    var isGrayscale: Bool {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if !self.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return true
        }
        return h == 0 && s == 0
    }
    
    /* ################################################################## */
    /**
     - returns true, if the color is clear.
     */
    var isClear: Bool {
        var white: CGFloat = 0, h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if !self.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            return 0.0 == a
        } else if self.getWhite(&white, alpha: &a) {
            return 0.0 == a
        }

        return false
    }

    /* ################################################################## */
    /**
     - returns the white level of the color.
     */
    var whiteLevel: CGFloat {
        var white: CGFloat = 0, alpha: CGFloat = 0
        if self.getWhite(&white, alpha: &alpha) {
            return white
        }
        return 0
    }
}

/* ###################################################################################################################################### */
/**
 */
extension String {
    /* ################################################################## */
    /**
     - returns: the localized string (main bundle) for this string.
     */
    var localizedVariant: String {
        return NSLocalizedString(self, comment: "")
    }
    
    /* ################################################################## */
    /**
     This extension lets us uppercase only the first letter of the string (used for weekdays).
     From here: https://stackoverflow.com/a/28288340/879365
     
     - returns: The string, with only the first letter uppercased.
     */
    var firstUppercased: String {
        guard let first = first else { return "" }
        return String(first).uppercased() + dropFirst()
    }
}

/* ###################################################################################################################################### */
/**
 */
extension UIView {
    /* ################################################################## */
    /**
     */
    func addContainedView(_ inSubView: UIView) {
        self.addSubview(inSubView)
        
        inSubView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addConstraints([
            NSLayoutConstraint(item: inSubView,
                               attribute: .top,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .top,
                               multiplier: 1.0,
                               constant: 0),
            NSLayoutConstraint(item: inSubView,
                               attribute: .left,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .left,
                               multiplier: 1.0,
                               constant: 0),
            NSLayoutConstraint(item: inSubView,
                               attribute: .bottom,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .bottom,
                               multiplier: 1.0,
                               constant: 0),
            NSLayoutConstraint(item: inSubView,
                               attribute: .right,
                               relatedBy: .equal,
                               toItem: self,
                               attribute: .right,
                               multiplier: 1.0,
                               constant: 0)])
    }
    
    /* ################################################################## */
    /**
     - returns: the first responder view. Nil, if no view is a first responder.
     */
    var currentFirstResponder: UIResponder! {
        if self.isFirstResponder {
            return self
        }
        
        for view in self.subviews {
            if let responder = view.currentFirstResponder {
                return responder
            }
        }
        
        return nil
    }
}

/* ###################################################################################################################################### */
/**
 */
extension UIImage {
    /* ################################################################## */
    /**
     From here: https://stackoverflow.com/a/33675160/879365
     */
    public convenience init?(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }
}

/* ################################################################################################################################## */
// MARK: Alarm Class
/* ################################################################################################################################## */
/**
 */
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
    
    private let _snoozeTimeInMinutes: Int = 9
    private let _alarmTimeInMinutes: Int = 15
    
    var alarmTime: Int = 0
    var isVibrateOn: Bool = false
    var selectedSoundMode: AlarmPrefsMode = .sounds
    var selectedSoundIndex: Int = 0
    var selectedSongURL: String = ""
    var isActive: Bool = false {
        didSet {
            if !self.isActive || (self.isActive != oldValue) {
                self.lastSnoozeTime = nil
            }
        }
    }

    var lastSnoozeTime: Date!

    /* ################################################################## */
    /**
     */
    func encode(with aCoder: NSCoder) {
        let alarmTime = NSNumber(value: self.alarmTime)
        aCoder.encode(alarmTime, forKey: AlarmPrefsKeys.alarmTime.rawValue)
        let isActive = NSNumber(value: self.isActive)
        aCoder.encode(isActive, forKey: AlarmPrefsKeys.isActive.rawValue)
        let isVibrateOn = NSNumber(value: self.isVibrateOn)
        aCoder.encode(isVibrateOn, forKey: AlarmPrefsKeys.isVibrateOn.rawValue)
        let selectedSoundIndex = NSNumber(value: self.selectedSoundIndex)
        aCoder.encode(selectedSoundIndex, forKey: AlarmPrefsKeys.selectedSoundIndex.rawValue)
        aCoder.encode(self.selectedSongURL as NSString, forKey: AlarmPrefsKeys.selectedSongURL.rawValue)
        let selectedSoundMode = NSNumber(value: self.selectedSoundMode.rawValue)
        aCoder.encode(selectedSoundMode, forKey: AlarmPrefsKeys.selectedSoundMode.rawValue)
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
    init (alarmRecord inAlarmToCopy: TheBestClockAlarmSetting) {
        super.init()
        self.selectedSoundMode = inAlarmToCopy.selectedSoundMode
        self.selectedSoundIndex = inAlarmToCopy.selectedSoundIndex
        self.selectedSongURL = inAlarmToCopy.selectedSongURL
        self.isVibrateOn = inAlarmToCopy.isVibrateOn
        self.isActive = inAlarmToCopy.isActive
        self.alarmTime = inAlarmToCopy.alarmTime
    }
    
    /* ################################################################## */
    /**
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
    
    /* ################################################################## */
    /**
     */
    override var description: String {
        return "[isActive: " + (self.isActive ? "true" : "false") + ", time: \(self.alarmTime), isVibrateOn: \(self.isVibrateOn), selectedSoundIndex: \(self.selectedSoundIndex), selectedSongURL: \(self.selectedSongURL), selectedSoundMode: \(self.selectedSoundMode)]"
    }
    
    /* ################################################################## */
    /**
     */
    var snoozing: Bool {
        get {
            return nil != self.lastSnoozeTime
        }
        
        set {
            if self.isActive, newValue {
                var now = Date()
                now.addTimeInterval(TimeInterval(self._snoozeTimeInMinutes * 60))
                self.lastSnoozeTime = now
            } else {
                if (!newValue || !self.isActive) && nil != self.lastSnoozeTime {
                    self.lastSnoozeTime = nil
                }
            }
        }
    }
    
    /* ################################################################## */
    /**
     */
    var alarming: Bool {
        let dateComponents = Calendar.current.dateComponents([.hour, .minute], from: Date())
        if self.isActive, let hour = dateComponents.hour, let minute = dateComponents.minute {
            if self.snoozing {
                let interval = self.lastSnoozeTime.timeIntervalSinceNow
                if 0 > interval {
                    return true
                }
            } else {
                var meTime = hour * 100 + minute
                if self._alarmTimeInMinutes > meTime {
                    meTime = 2400 + meTime - self._alarmTimeInMinutes
                }
                
                var alarmTimeHours = self.alarmTime / 100
                let alarmTimeMinutes = self.alarmTime - (alarmTimeHours * 100)
                var newAlarmTimeMinutes = alarmTimeMinutes + self._alarmTimeInMinutes
                
                while 60 < newAlarmTimeMinutes {
                    alarmTimeHours += 1
                    newAlarmTimeMinutes -= 60
                }
                
                while 2359 < alarmTimeHours {
                    alarmTimeHours -= 24
                }
                
                let timeRange = self.alarmTime..<(alarmTimeHours * 100 + newAlarmTimeMinutes)
                
                return timeRange.contains(meTime)
            }
        }
        
        return false
    }
}

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
    
    private var _alarms: [TheBestClockAlarmSetting] = []
    
    private var _numberOfAlarms = 3
    
    /* ################################################################## */
    // MARK: Private Enums
    /* ################################################################## */
    /** These are the keys we use for our persistent prefs dictionary. */
    private enum PrefsKeys: String {
        case selectedColor, selectedFont, brightnessLevel, playlistID, alarms
    }
    
    /* ################################################################## */
    // MARK: Private Instance Methods
    /* ################################################################## */
    /**
     This method loads the main prefs into our instance storage.
     
     NOTE: This will overwrite any unsaved changes to the current _loadedPrefs property.
     
     - returns: a Bool. True, if the load was successful.
     */
    private func _loadPrefs() -> Bool {
        if let temp = UserDefaults.standard.object(forKey: type(of: self)._mainPrefsKey) as? NSDictionary {
            self._loadedPrefs = NSMutableDictionary(dictionary: temp)
            for index in 0..<self._numberOfAlarms {
                if self._alarms.count == index {    // This makes sure that we account for any empty spots (shouldn't happen).
                    self._alarms.append(TheBestClockAlarmSetting())
                }
                if let unarchivedObject = self._loadedPrefs.object(forKey: (type(of: self).PrefsKeys.alarms.rawValue + String(index)) as NSString) as? Data {
                    if let alarm = NSKeyedUnarchiver.unarchiveObject(with: unarchivedObject) as? TheBestClockAlarmSetting {
                        let oldSnoozeTime = self._alarms[index].lastSnoozeTime  // This makes sure we preserve any snoozing in progress. This is the only one that is not saved in prefs.
                        self._alarms[index] = alarm
                        self._alarms[index].lastSnoozeTime = oldSnoozeTime
                    }
                }
            }
        } else {
            self._loadedPrefs = NSMutableDictionary()
        }
        
        for index in 0..<self._numberOfAlarms where self._alarms.count == index {
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
                self.savePrefs()
            }
        }
    }
    
    /* ################################################################## */
    /**
     - returns: the playlist ID, as a UUID.
     */
    var playlistID: UUID {
        get {
            var ret: UUID = UUID()
            if self._loadPrefs() {
                if let temp = self._loadedPrefs.object(forKey: type(of: self).PrefsKeys.playlistID.rawValue) as? UUID {
                    ret = temp
                }
            }
            
            return ret
        }
        
        set {
            if self._loadPrefs() {
                let value = newValue
                self._loadedPrefs.setObject(value, forKey: type(of: self).PrefsKeys.playlistID.rawValue as NSString)
                self.savePrefs()
            }
        }
    }
    
    /* ################################################################## */
    /**
     This method simply saves the main preferences Dictionary into the standard user defaults.
     */
    func savePrefs() {
        for index in 0..<self._alarms.count {
            let archivedObject = NSKeyedArchiver.archivedData(withRootObject: self._alarms[index])
            self._loadedPrefs.setObject(archivedObject, forKey: (type(of: self).PrefsKeys.alarms.rawValue + String(index)) as NSString)
        }
        UserDefaults.standard.set(self._loadedPrefs, forKey: type(of: self)._mainPrefsKey)
    }
}
