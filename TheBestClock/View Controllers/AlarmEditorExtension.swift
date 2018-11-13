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
// MARK: - Alarm Editor Extension -
/* ###################################################################################################################################### */
/**
 This extension breaks out the media handling and Alarm Editor into a separate file.
 */
extension MainScreenViewController {
    /* ################################################################## */
    // MARK: - Media Methods
    /* ################################################################## */
    /**
     This is called when we want to access the music library to make a list of artists and songs.
     
     - parameter displayWholeScreenThrobber: If true (default is false), then the "big" throbber screen will show while this is loading.
     - parameter forceReload: If true (default is false), then the entire music library will be reloaded, even if we already have it.
     */
    func loadMediaLibrary(displayWholeScreenThrobber inDisplayWholeScreenThrobber: Bool = false, forceReload inForceReload: Bool = false) {
        if self.artists.isEmpty || inForceReload { // If we are already loaded up, we don't need to do this (unless forced).
            if inDisplayWholeScreenThrobber {
                DispatchQueue.main.async {
                    self.showLargeLookupThrobber()
                }
            } else {
                DispatchQueue.main.async {
                    self.showLookupThrobber()
                }
            }
            if .authorized == MPMediaLibrary.authorizationStatus() {    // Already authorized? Head on in!
                self.loadUpOnMusic(displayWholeScreenThrobber: inDisplayWholeScreenThrobber, forceReload: inForceReload)
            } else {    // May I see your ID, sir?
                MPMediaLibrary.requestAuthorization { [unowned self] status in
                    switch status {
                    case.authorized:
                        self.loadUpOnMusic(displayWholeScreenThrobber: inDisplayWholeScreenThrobber, forceReload: inForceReload)
                        
                    default:
                        TheBestClockAppDelegate.reportError(heading: "ERROR_HEADER_MEDIA", text: "ERROR_TEXT_MEDIA_PERMISSION_DENIED")
                        self.dunLoadin()
                    }
                }
            }
        } else {
            self.dunLoadin()
        }
    }
    
    /* ################################################################## */
    /**
     This loads the music, assuming that we have been authorized.
     
     - parameter displayWholeScreenThrobber: If true (default is false), then the "big" throbber screen will show while this is loading.
     - parameter forceReload: If true (default is false), then the entire music library will be reloaded, even if we already have it.
     */
    func loadUpOnMusic(displayWholeScreenThrobber inDisplayWholeScreenThrobber: Bool = false, forceReload inForceReload: Bool = false) {
        if let songItems: [MPMediaItemCollection] = MPMediaQuery.songs().collections {
            DispatchQueue.main.async {
                self.loadSongData(songItems)
                self.dunLoadin()
            }
        }
    }
    
    /* ################################################################## */
    /**
     This is called after the music has been loaded. It sets up the Alarm Editor.
     */
    func dunLoadin() {
        DispatchQueue.main.async {
            self.editAlarmPickerView.reloadComponent(0)
            self.songSelectionPickerView.reloadComponent(0)
            self.selectSong()
            self.showHideItems()
            self.hideLargeLookupThrobber()
            self.hideLookupThrobber()
        }
    }
    
    /* ################################################################## */
    /**
     This reads all the user's music, and sorts it into a couple of bins for us to reference later.
     
     - parameter inSongs: The list of songs we read in, as media items.
     */
    func loadSongData(_ inSongs: [MPMediaItemCollection]) {
        var songList: [SongInfo] = []
        self.songs = [:]
        self.artists = []
        
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
                    songInfo.resourceURI = resourceURI.absoluteString
                }
                
                if nil != songInfo.resourceURI, !songInfo.description.isEmpty {
                    songList.append(songInfo)
                }
            }
        }
        
        // We just create a big fat, honkin' Dictionary of songs; sorted by the artist name for each song.
        for song in songList {
            if nil == self.songs[song.artistName] {
                self.songs[song.artistName] = []
            }
            self.songs[song.artistName]?.append(song)
        }
        
        // We create the index, and sort the songs and keys.
        for artist in self.songs.keys {
            if var sortedSongs = self.songs[artist] {
                sortedSongs.sort(by: { a, b in
                    return a.songTitle < b.songTitle
                })
                self.songs[artist] = sortedSongs
            }
            self.artists.append(artist)    // This will be our artist key array.
        }
        
        self.artists.sort()
    }
    
    /* ################################################################## */
    /**
     This is called to play a sound, choosing from the various alarms. That alarm's indexed sound will be used.
     It is also used to continue a paused audio player (in which case, the sound is actually ignored).
     
     - parameter inAlarmIndex: This is the index of the alarm that we want to use to play the sound.
     */
    func playSound(_ inAlarmIndex: Int) {
        if nil == self.audioPlayer {
            var soundUrl: URL!
            
            if .sounds == self.prefs.alarms[inAlarmIndex].selectedSoundMode, let soundUri = URL(string: self.soundSelection[self.prefs.alarms[inAlarmIndex].selectedSoundIndex]) {
                soundUrl = soundUri
            } else if .music == self.prefs.alarms[inAlarmIndex].selectedSoundMode, .authorized == MPMediaLibrary.authorizationStatus(), let songURI = URL(string: self.prefs.alarms[inAlarmIndex].selectedSongURL) {
                soundUrl = songURI
            }  else if .music == self.prefs.alarms[inAlarmIndex].selectedSoundMode, .authorized == MPMediaLibrary.authorizationStatus(), let defaultSongURI = URL(string: self.findSongURL(artistIndex: 0, songIndex: 0)) {
                soundUrl = defaultSongURI
            }
            
            if nil != soundUrl {
                self.playThisSound(soundUrl)
            }
        }
    }
    
    /* ################################################################## */
    /**
     This plays any sound, using a given URL.
     
     - parameter inSoundURL: This is the URI to the sound resource.
     */
    func playThisSound(_ inSoundURL: URL) {
        do {
            if nil == self.audioPlayer {
                try self.audioPlayer = AVAudioPlayer(contentsOf: inSoundURL)
                self.audioPlayer?.numberOfLoops = -1   // Repeat indefinitely
            }
            self.audioPlayer?.play()
        } catch {
            TheBestClockAppDelegate.reportError(heading: "ERROR_HEADER_MEDIA", text: "ERROR_TEXT_MEDIA_CANNOT_CREATE_AVPLAYER")
        }
    }
    
    /* ################################################################## */
    /**
     If the audio player is going, this pauses it. Nothing happens if no audio player is going.
     */
    func pauseAudioPlayer() {
        if nil != self.audioPlayer {
            self.audioPlayer?.pause()
        }
        self.editAlarmTestSoundButton.setTitle("LOCAL-TEST-SOUND".localizedVariant, for: .normal)
        self.musicTestButton.setTitle("LOCAL-TEST-SONG".localizedVariant, for: .normal)
    }
    
    /* ################################################################## */
    /**
     This terminates the audio player. Nothing happens if no audio player is going.
     */
    func stopAudioPlayer() {
        if nil != self.audioPlayer {
            self.audioPlayer?.stop()
            self.audioPlayer = nil
        }
        self.editAlarmTestSoundButton.setTitle("LOCAL-TEST-SOUND".localizedVariant, for: .normal)
        self.musicTestButton.setTitle("LOCAL-TEST-SONG".localizedVariant, for: .normal)
    }
    
    /* ################################################################## */
    // MARK: - Alarm Editor Methods
    /* ################################################################## */
    /**
     This opens the editor screen for a selected alarm.
     */
    func openAlarmEditorScreen() {
        self.stopTicker()
        if 0 <= self.currentlyEditingAlarmIndex, self.prefs.alarms.count > self.currentlyEditingAlarmIndex {
            if .music == self.prefs.alarms[self.currentlyEditingAlarmIndex].selectedSoundMode {   // We do this here, because it can take a little while for things to catch up, and we can get no throbber if we wait until just before we load the media.
                self.showLookupThrobber()
            }
            if self.alarmEditorMinimumHeight > UIScreen.main.bounds.size.height || self.alarmEditorMinimumHeight > UIScreen.main.bounds.size.width {
                TheBestClockAppDelegate.lockOrientation(.portrait, andRotateTo: .portrait)
            }
            TheBestClockAppDelegate.restoreOriginalBrightness()
            let currentAlarm = self.prefs.alarms[self.currentlyEditingAlarmIndex]
            
            currentAlarm.isActive = true
            currentAlarm.snoozing = false
            self.alarmButtons[self.currentlyEditingAlarmIndex].alarmRecord.isActive = true
            self.alarmButtons[self.currentlyEditingAlarmIndex].alarmRecord.snoozing = false
            self.alarmEditorActiveSwitch.isOn = true
            self.showOnlyThisAlarm(self.currentlyEditingAlarmIndex)
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
                if let font = UIFont(name: self.selectedFontName, size: self.alarmEditorTopFontSize) {
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
                if let font = UIFont(name: self.selectedFontName, size: self.alarmEditorTopFontSize) {
                    label.font = font
                }
            }
            
            self.musicTestButton.tintColor = self.selectedColor
            if let label = self.musicTestButton.titleLabel {
                label.adjustsFontSizeToFitWidth = true
                label.baselineAdjustment = .alignCenters
                if let font = UIFont(name: self.selectedFontName, size: self.alarmEditorSoundButtonFontSize) {
                    label.font = font
                }
            }
            
            self.editAlarmTestSoundButton.tintColor = self.selectedColor
            if let label = self.editAlarmTestSoundButton.titleLabel {
                label.adjustsFontSizeToFitWidth = true
                label.baselineAdjustment = .alignCenters
                if let font = UIFont(name: self.selectedFontName, size: self.alarmEditorSoundButtonFontSize) {
                    label.font = font
                }
            }
            
            self.alarmEditorVibrateBeepSwitch.isOn = currentAlarm.isVibrateOn
            self.alarmEditSoundModeSelector.setEnabled(.denied != MPMediaLibrary.authorizationStatus(), forSegmentAt: 1)
            if !self.alarmEditSoundModeSelector.isEnabledForSegment(at: 1) && .music == currentAlarm.selectedSoundMode {
                self.alarmEditSoundModeSelector.selectedSegmentIndex = TheBestClockAlarmSetting.AlarmPrefsMode.silence.rawValue
            } else {
                self.alarmEditSoundModeSelector.selectedSegmentIndex = currentAlarm.selectedSoundMode.rawValue
            }
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
            
            self.showHideItems()
            self.editAlarmScreenContainer.isHidden = false
            self.editAlarmTimeDatePicker.setValue(self.selectedColor, forKey: "textColor")
            self.setupAlarmEditPickers()
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
    func showHideItems() {
        self.testSoundContainerView.isHidden = .sounds != self.prefs.alarms[self.currentlyEditingAlarmIndex].selectedSoundMode
        self.musicTestButtonView.isHidden = .music != self.prefs.alarms[self.currentlyEditingAlarmIndex].selectedSoundMode || self.songs.isEmpty || self.artists.isEmpty
        self.editPickerContainerView.isHidden = .silence == self.prefs.alarms[self.currentlyEditingAlarmIndex].selectedSoundMode || (.music == self.prefs.alarms[self.currentlyEditingAlarmIndex].selectedSoundMode && (self.songs.isEmpty || self.artists.isEmpty))
        self.songSelectContainerView.isHidden = .music != self.prefs.alarms[self.currentlyEditingAlarmIndex].selectedSoundMode || self.songs.isEmpty || self.artists.isEmpty
    }
    
    /* ################################################################## */
    /**
     */
    func showLookupThrobber() {
        self.musicLookupThrobber.color = self.selectedColor
        self.musicLookupThrobberView.backgroundColor = self.backgroundColor
        self.musicLookupThrobberView.isHidden = false
    }
    
    /* ################################################################## */
    /**
     */
    func hideLookupThrobber() {
        self.musicLookupThrobberView.isHidden = true
    }
    
    /* ################################################################## */
    /**
     */
    func selectSong() {
        DispatchQueue.main.async {
            if 1 == self.alarmEditSoundModeSelector.selectedSegmentIndex {
                if .authorized == MPMediaLibrary.authorizationStatus() {
                    self.alarmEditSoundModeSelector.setEnabled(true, forSegmentAt: 1)
                    self.prefs.alarms[self.currentlyEditingAlarmIndex].selectedSoundMode = .music
                    let indexes = self.findSongInfo(self.prefs.alarms[self.currentlyEditingAlarmIndex].selectedSongURL)
                    self.editAlarmPickerView.selectRow(indexes.artistIndex, inComponent: 0, animated: true)
                    self.songSelectionPickerView.reloadComponent(0)
                    self.songSelectionPickerView.selectRow(indexes.songIndex, inComponent: 0, animated: true)
                    self.pickerView(self.songSelectionPickerView, didSelectRow: self.songSelectionPickerView.selectedRow(inComponent: 0), inComponent: 0)
                } else {
                    self.alarmEditSoundModeSelector.setEnabled(.denied != MPMediaLibrary.authorizationStatus(), forSegmentAt: 1)
                    if !self.alarmEditSoundModeSelector.isEnabledForSegment(at: 1) && .music == self.prefs.alarms[self.currentlyEditingAlarmIndex].selectedSoundMode {
                        self.alarmEditSoundModeSelector.selectedSegmentIndex = TheBestClockAlarmSetting.AlarmPrefsMode.silence.rawValue
                    } else {
                        self.alarmEditSoundModeSelector.selectedSegmentIndex = self.prefs.alarms[self.currentlyEditingAlarmIndex].selectedSoundMode.rawValue
                    }
                }
            }
        }
    }
    
    /* ################################################################## */
    /**
     */
    func showOnlyThisAlarm(_ inIndex: Int) {
        for alarm in self.alarmButtons where alarm.index != inIndex {
            alarm.isUserInteractionEnabled = false
            alarm.isHidden = true
        }
    }
    
    /* ################################################################## */
    /**
     */
    func refreshAlarm(_ inIndex: Int) {
        self.alarmButtons[inIndex].setNeedsDisplay()
    }
    
    /* ################################################################## */
    /**
     */
    func showAllAlarms() {
        for alarm in self.alarmButtons {
            alarm.isUserInteractionEnabled = true
            alarm.isHidden = false
        }
    }
    
    /* ################################################################## */
    /**
     */
    func findSongInfo(_ inURL: String = "") -> (artistIndex: Int, songIndex: Int) {
        for artistInfo in self.songs {
            var songIndex: Int = 0
            for song in artistInfo.value {
                if inURL == song.resourceURI {
                    if let artistIndex = self.artists.firstIndex(of: song.artistName) {
                        return (artistIndex: Int(artistIndex), songIndex: songIndex)
                    }
                }
                songIndex += 1
            }
        }
        
        return (artistIndex: 0, songIndex: 0)
    }
    
    /* ################################################################## */
    /**
     */
    func findSongURL(artistIndex: Int, songIndex: Int) -> String {
        var ret = ""
        
        if !self.artists.isEmpty, !self.songs.isEmpty {
            let artistName = self.artists[artistIndex]
            if let songInfo = self.songs[artistName], 0 <= songIndex, songIndex < songInfo.count {
                ret = songInfo[songIndex].resourceURI
            }
        }
        
        return ret
    }
    
    /* ################################################################## */
    /**
     */
    func setupAlarmEditPickers() {
        if 1 == self.alarmEditSoundModeSelector.selectedSegmentIndex {
            self.loadMediaLibrary()
        } else {
            DispatchQueue.main.async {
                if 0 == self.alarmEditSoundModeSelector.selectedSegmentIndex {
                    self.editAlarmPickerView.selectRow(self.prefs.alarms[self.currentlyEditingAlarmIndex].selectedSoundIndex, inComponent: 0, animated: false)
                }
                self.editAlarmPickerView.reloadComponent(0)
            }
        }
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func soundModeChanged(_ sender: UISegmentedControl) {
        self.prefs.alarms[self.currentlyEditingAlarmIndex].selectedSoundMode = TheBestClockAlarmSetting.AlarmPrefsMode(rawValue: self.alarmEditSoundModeSelector.selectedSegmentIndex) ?? .silence
        self.alarmButtons[self.currentlyEditingAlarmIndex].alarmRecord.selectedSoundMode = TheBestClockAlarmSetting.AlarmPrefsMode(rawValue: self.alarmEditSoundModeSelector.selectedSegmentIndex) ?? .silence
        self.showHideItems()
        if .music == self.prefs.alarms[self.currentlyEditingAlarmIndex].selectedSoundMode {   // We do this here, because it can take a little while for things to catch up, and we can get no throbber if we wait until just before we load the media.
            self.showLookupThrobber()
        }
        self.stopAudioPlayer()
        self.setupAlarmEditPickers()
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func activeSwitchChanged(_ inSwitch: UISwitch) {
        self.prefs.alarms[self.currentlyEditingAlarmIndex].isActive = inSwitch.isOn
        self.alarmButtons[self.currentlyEditingAlarmIndex].alarmRecord.isActive = inSwitch.isOn
        self.refreshAlarm(self.currentlyEditingAlarmIndex)
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func activeButtonHit(_ sender: Any) {
        self.alarmEditorActiveSwitch.setOn(!self.alarmEditorActiveSwitch.isOn, animated: true)
        self.alarmEditorActiveSwitch.sendActions(for: .valueChanged)
        self.refreshAlarm(self.currentlyEditingAlarmIndex)
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func vibrateSwitchChanged(_ inSwitch: UISwitch) {
        self.prefs.alarms[self.currentlyEditingAlarmIndex].isVibrateOn = inSwitch.isOn
        self.alarmButtons[self.currentlyEditingAlarmIndex].alarmRecord.isVibrateOn = inSwitch.isOn
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
            if let soundUrl = URL(string: self.soundSelection[self.editAlarmPickerView.selectedRow(inComponent: 0)]) {
                self.playThisSound(soundUrl)
            }
        } else {
            self.pauseAudioPlayer()
        }
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func testSongButtonHit(_ sender: Any) {
        if "LOCAL-TEST-SONG".localizedVariant == self.musicTestButton.title(for: .normal) {
            self.musicTestButton.setTitle("LOCAL-PAUSE-SONG".localizedVariant, for: .normal)
            var soundUrl: URL!
            
            if .music == self.prefs.alarms[self.currentlyEditingAlarmIndex].selectedSoundMode, .authorized == MPMediaLibrary.authorizationStatus(), let songURI = URL(string: self.prefs.alarms[self.currentlyEditingAlarmIndex].selectedSongURL) {
                soundUrl = songURI
            }
            
            if nil != soundUrl {
                self.playThisSound(soundUrl)
            }
        } else {
            self.pauseAudioPlayer()
        }
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func alarmTimeDatePickerChanged(_ inDatePicker: UIDatePicker) {
        if 0 <= self.currentlyEditingAlarmIndex, self.prefs.alarms.count > self.currentlyEditingAlarmIndex {
            let date = inDatePicker.date
            
            let calendar = Calendar.current
            
            let hour = calendar.component(.hour, from: date)
            let minutes = calendar.component(.minute, from: date)
            
            let time = hour * 100 + minutes
            self.alarmButtons[self.currentlyEditingAlarmIndex].alarmRecord.alarmTime = time
            self.prefs.alarms[self.currentlyEditingAlarmIndex] = self.alarmButtons[self.currentlyEditingAlarmIndex].alarmRecord
            self.alarmButtons[self.currentlyEditingAlarmIndex].setNeedsDisplay()
        }
    }
    
    /* ################################################################## */
    /**
     This closes the alarm editor screen, making sure that everything is put back where it belongs.
     */
    @IBAction func closeAlarmEditorScreen(_ sender: Any! = nil) {
        TheBestClockAppDelegate.lockOrientation(.all)
        self.stopAudioPlayer()
        self.prefs.savePrefs() // We commit the changes we made, here.
        self.currentlyEditingAlarmIndex = -1
        self.editAlarmScreenContainer.isHidden = true
        self.showAllAlarms()
        self.startTicker()
    }
}
