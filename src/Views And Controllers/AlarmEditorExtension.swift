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
        if artists.isEmpty || inForceReload { // If we are already loaded up, we don't need to do this (unless forced).
            isLoadin = false
            editAlarmTimeDatePicker.isEnabled = false
            alarmEditorActiveButton.isEnabled = false
            alarmEditorVibrateButton.isEnabled = false
            alarmEditorVibrateBeepSwitch.isEnabled = false
            alarmEditorActiveSwitch.isEnabled = false
            alarmEditSoundModeSelector.isEnabled = false
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
                loadUpOnMusic()
            } else {    // May I see your ID, sir?
                DispatchQueue.main.async {
                    MPMediaLibrary.requestAuthorization { [unowned self] status in
                        DispatchQueue.main.async {
                            switch status {
                            case.authorized:
                                self.loadUpOnMusic()
                                
                            default:
                                TheBestClockAppDelegate.reportError(heading: "ERROR_HEADER_MEDIA", text: "ERROR_TEXT_MEDIA_PERMISSION_DENIED")
                                self.dunLoadin()
                            }
                        }
                    }
                }
            }
        } else {
            DispatchQueue.main.async {
                self.dunLoadin()
            }
        }
    }
    
    /* ################################################################## */
    /**
     This loads the music, assuming that we have been authorized.
     */
    func loadUpOnMusic() {
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
        isLoadin = false
        editAlarmPickerView.reloadComponent(0)
        songSelectionPickerView.reloadComponent(0)
        selectSong()
        showHideItems()
        editAlarmTimeDatePicker.isEnabled = true
        alarmEditorActiveButton.isEnabled = true
        alarmEditorVibrateButton.isEnabled = true
        alarmEditorVibrateBeepSwitch.isEnabled = true
        alarmEditorActiveSwitch.isEnabled = true
        alarmEditSoundModeSelector.isEnabled = true
        hideLargeLookupThrobber()
        hideLookupThrobber()
    }
    
    /* ################################################################## */
    /**
     This reads all the user's music, and sorts it into a couple of bins for us to reference later.
     
     - parameter inSongs: The list of songs we read in, as media items.
     */
    func loadSongData(_ inSongs: [MPMediaItemCollection]) {
        var songList: [SongInfo] = []
        songs = [:]
        artists = []
        
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
            if nil == songs[song.artistName] {
                songs[song.artistName] = []
            }
            songs[song.artistName]?.append(song)
        }
        
        // We create the index, and sort the songs and keys.
        for artist in songs.keys {
            if var sortedSongs = songs[artist] {
                sortedSongs.sort(by: { a, b in
                    return a.songTitle < b.songTitle
                })
                songs[artist] = sortedSongs
            }
            artists.append(artist)    // This will be our artist key array.
        }
        
        artists.sort()
    }
    
    /* ################################################################## */
    /**
     This is called to play a sound, choosing from the various alarms. That alarm's indexed sound will be used.
     
     - parameter inAlarmIndex: This is the index of the alarm that we want to use to play the sound.
     */
    func playSound(_ inAlarmIndex: Int) {
        if nil == audioPlayer {
            var soundUrl: URL!
            
            // We do a check here, to make sure that, if we are in music mode, we have authorization, and a valid URI. If not, we switch to sound mode.
            // The idea is that it's really important that the alarm go off; even if it is not the one chosen by the user.
            // Also, we can't have an authorization request pop up here. Something needs to happen.
            // We will accept an authorization AND either a valid saved URI OR a valid default URI. Otherwise, we switch over to sound mode, temporarily.
            if .music == prefs.alarms[inAlarmIndex].selectedSoundMode
                && (
                    .authorized != MPMediaLibrary.authorizationStatus()
                    || (
                        nil == URL(string: prefs.alarms[inAlarmIndex].selectedSongURL.urlEncodedString ?? "") && nil == URL(string: findSongURL(artistIndex: 0, songIndex: 0).urlEncodedString ?? "")
                    )
                ) {
                // We use the sound URI, without forcing the alarm to change its saved mode.
                soundUrl = URL(string: soundSelection[prefs.alarms[inAlarmIndex].selectedSoundIndex].urlEncodedString ?? "")
                
                if nil == soundUrl {    // One last fallback. The first sound in the list.
                    soundUrl = URL(string: soundSelection[0].urlEncodedString ?? "")
                }
            }
            
            if nil == soundUrl {    // Assuming we didn't "fail over" to a sound.
                // Standard sound. We're kinda screwed, if the sound URI is bad.
                if .sounds == prefs.alarms[inAlarmIndex].selectedSoundMode, let soundUri = URL(string: soundSelection[prefs.alarms[inAlarmIndex].selectedSoundIndex].urlEncodedString ?? "") {
                    soundUrl = soundUri
                // Music, and valid saved song URI
                } else if .music == prefs.alarms[inAlarmIndex].selectedSoundMode, .authorized == MPMediaLibrary.authorizationStatus(), let songURI = URL(string: prefs.alarms[inAlarmIndex].selectedSongURL.urlEncodedString ?? "") {
                    soundUrl = songURI
                // Music, but the saved song URI is invalid, so we switch to the default one.
                }  else if .music == prefs.alarms[inAlarmIndex].selectedSoundMode, .authorized == MPMediaLibrary.authorizationStatus(), let defaultSongURI = URL(string: findSongURL(artistIndex: 0, songIndex: 0).urlEncodedString ?? "") {
                    soundUrl = defaultSongURI
                }
            }
            
            if nil != soundUrl {
                playThisSound(soundUrl)
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
            if nil == audioPlayer {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: []) // This line ensures that the sound will play, even with the ringer off.
                try audioPlayer = AVAudioPlayer(contentsOf: inSoundURL)
                audioPlayer?.numberOfLoops = -1   // Repeat indefinitely
            }
            audioPlayer?.play()
        } catch {
            TheBestClockAppDelegate.reportError(heading: "ERROR_HEADER_MEDIA", text: "ERROR_TEXT_MEDIA_CANNOT_CREATE_AVPLAYER")
        }
    }
    
    /* ################################################################## */
    /**
     If the audio player is going, this pauses it. Nothing happens if no audio player is going.
     */
    func pauseAudioPlayer() {
        audioPlayer?.pause()
        DispatchQueue.main.async {
            self.musicTestButton.isOn = true
        }
    }
    
    /* ################################################################## */
    /**
     This terminates the audio player. Nothing happens if no audio player is going.
     */
    func stopAudioPlayer() {
        audioPlayer?.stop()
        audioPlayer = nil
        DispatchQueue.main.async {
            self.musicTestButton.isOn = true
        }
    }
    
    /* ################################################################## */
    // MARK: - Alarm Editor Methods
    /* ################################################################## */
    /**
     This opens the editor screen for a selected alarm.
     */
    func openAlarmEditorScreen() {
        stopTicker()
        impactFeedbackGenerator?.impactOccurred()
        impactFeedbackGenerator?.prepare()
        if 0 <= currentlyEditingAlarmIndex, prefs.alarms.count > currentlyEditingAlarmIndex {
            if .music == prefs.alarms[currentlyEditingAlarmIndex].selectedSoundMode {   // We do this here, because it can take a little while for things to catch up, and we can get no throbber if we wait until just before we load the media.
                showLookupThrobber()
            }
            
            if alarmEditorMinimumHeight > UIScreen.main.bounds.size.height || alarmEditorMinimumHeight > UIScreen.main.bounds.size.width {
                TheBestClockAppDelegate.lockOrientation(.portrait, andRotateTo: .portrait)
            }
            
            let currentAlarm = prefs.alarms[currentlyEditingAlarmIndex]
            
            currentAlarm.isActive = true
            currentAlarm.snoozing = false
            alarmButtons[currentlyEditingAlarmIndex].alarmRecord = currentAlarm
            alarmButtons[currentlyEditingAlarmIndex].fullBright = true
            showOnlyThisAlarm(currentlyEditingAlarmIndex)
            let time = alarmButtons[currentlyEditingAlarmIndex].alarmRecord.alarmTime
            let hours = time / 100
            let minutes = time - (hours * 100)
            
            var dateComponents = DateComponents()
            dateComponents.hour = hours
            dateComponents.minute = minutes
            
            let userCalendar = Calendar.current
            if let pickerDate = userCalendar.date(from: dateComponents) {
                editAlarmTimeDatePicker.setDate(pickerDate, animated: false)
            }
            let flashColor = (0 != selectedColorIndex ? selectedColor : UIColor.white)
            editAlarmScreenMaskView.backgroundColor = view.backgroundColor
            let flashImage = UIImage(color: flashColor.withAlphaComponent(0.5))
            dismissAlarmEditorButton.setBackgroundImage(flashImage, for: .focused)
            dismissAlarmEditorButton.setBackgroundImage(flashImage, for: .selected)
            dismissAlarmEditorButton.setBackgroundImage(flashImage, for: .highlighted)

            alarmDeactivatedLabel.textColor = selectedColor
            musicLookupLabel.textColor = selectedColor
            noMusicAvailableLabel.textColor = selectedColor

            alarmEditorActiveSwitch.tintColor = selectedColor
            alarmEditorActiveSwitch.onTintColor = selectedColor
            alarmEditorActiveSwitch.thumbTintColor = selectedColor
            alarmEditorActiveSwitch.isOn = alarmButtons[currentlyEditingAlarmIndex].alarmRecord.isActive
            alarmEditorActiveButton.tintColor = selectedColor
            if let label = alarmEditorActiveButton.titleLabel {
                label.adjustsFontSizeToFitWidth = true
                label.baselineAdjustment = .alignCenters
            }

            alarmEditorVibrateBeepSwitch.tintColor = selectedColor
            alarmEditorVibrateBeepSwitch.thumbTintColor = selectedColor
            alarmEditorVibrateBeepSwitch.onTintColor = selectedColor
            alarmEditorVibrateButton.tintColor = selectedColor
            alarmEditorVibrateBeepSwitch.isOn = alarmButtons[currentlyEditingAlarmIndex].alarmRecord.isVibrateOn
            if let label = alarmEditorVibrateButton.titleLabel {
                label.adjustsFontSizeToFitWidth = true
                label.baselineAdjustment = .alignCenters
            }
            
            musicTestButton.tintColor = selectedColor
            musicTestButton.isOn = true
            editAlarmTestSoundButton.tintColor = selectedColor
            editAlarmTestSoundButton.isOn = true

            alarmEditSoundModeSelector.tintColor = selectedColor
            alarmEditSoundModeSelector.setEnabled(.denied != MPMediaLibrary.authorizationStatus(), forSegmentAt: 1)
            if !alarmEditSoundModeSelector.isEnabledForSegment(at: 1) && .music == alarmButtons[currentlyEditingAlarmIndex].alarmRecord.selectedSoundMode {
                alarmEditSoundModeSelector.selectedSegmentIndex = TheBestClockAlarmSetting.AlarmPrefsMode.silence.rawValue
            } else {
                alarmEditSoundModeSelector.selectedSegmentIndex = alarmButtons[currentlyEditingAlarmIndex].alarmRecord.selectedSoundMode.rawValue
            }
            
            if #available(iOS 13.0, *) {
                alarmEditSoundModeSelector.selectedSegmentTintColor = selectedColor
                alarmEditSoundModeSelector.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.black], for: .selected)
                alarmEditSoundModeSelector.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.lightGray], for: .disabled)
                alarmEditSoundModeSelector.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: selectedColor], for: .normal)
            }

            editAlarmPickerView.reloadComponent(0)
            if 0 == alarmEditSoundModeSelector.selectedSegmentIndex {
                editAlarmPickerView.selectRow(alarmButtons[currentlyEditingAlarmIndex].alarmRecord.selectedSoundIndex, inComponent: 0, animated: false)
            } else if 1 == alarmEditSoundModeSelector.selectedSegmentIndex {
                editAlarmPickerView.selectRow(0, inComponent: 0, animated: false)
            }
            
            showHideItems()
            editAlarmScreenContainer.isHidden = false
            editAlarmTimeDatePicker.setValue(selectedColor, forKey: "textColor")
            setupAlarmEditPickers()
            // This nasty little hack, is because it is possible to get the alarm to display as inactive when it is, in fact, active.
            Timer.scheduledTimer(withTimeInterval: 0.125, repeats: false) { [unowned self] _ in
                DispatchQueue.main.async {
                    self.activeSwitchChanged(self.alarmEditorActiveSwitch)
                }
            }
            
            UIScreen.main.brightness = 1.0  // Brighten the screen all the way for the editor.
       }
        
        if #available(iOS 13.0, *) {
            alarmEditSoundModeSelector.selectedSegmentTintColor = selectedColor
            alarmEditSoundModeSelector.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: selectedColor], for: .normal)
            if let color = view.backgroundColor {
                alarmEditSoundModeSelector.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: color], for: .selected)
            }
        }

        // Need to do this because of the whacky way we are presenting the editor screen. The underneath controls can "bleed through."
        mainNumberDisplayView.isAccessibilityElement = false
        dateDisplayLabel.isAccessibilityElement = false
        amPmLabel.isAccessibilityElement = false
        leftBrightnessSlider.isAccessibilityElement = false
        rightBrightnessSlider.isAccessibilityElement = false
    }
    
    /* ################################################################## */
    /**
     */
    func showHideItems() {
        editPickerContainerView.isHidden = .silence == prefs.alarms[currentlyEditingAlarmIndex].selectedSoundMode || (.music == prefs.alarms[currentlyEditingAlarmIndex].selectedSoundMode && (songs.isEmpty || artists.isEmpty))
        testSoundContainerView.isHidden = .sounds != prefs.alarms[currentlyEditingAlarmIndex].selectedSoundMode
        musicTestButtonView.isHidden = .music != prefs.alarms[currentlyEditingAlarmIndex].selectedSoundMode || songs.isEmpty || artists.isEmpty
        songSelectContainerView.isHidden = .music != prefs.alarms[currentlyEditingAlarmIndex].selectedSoundMode || songs.isEmpty || artists.isEmpty
        noMusicDisplayView.isHidden = .music != prefs.alarms[currentlyEditingAlarmIndex].selectedSoundMode || !(artists.isEmpty || songs.isEmpty)
        alarmDeactivatedLabel.isHidden = !prefs.alarms[currentlyEditingAlarmIndex].deferred
        alarmEditorVibrateButton.isHidden = "iPhone" != UIDevice.current.model   // Hide these on iPads, which don't do vibrate.
        alarmEditorVibrateBeepSwitch.isHidden = "iPhone" != UIDevice.current.model
        #if targetEnvironment(macCatalyst)  // Catalyst won't allow us to access the music library. Boo!
            self.alarmEditSoundModeSelector.setEnabled(false, forSegmentAt: 1)
            var segmentIndex = self.prefs.alarms[self.currentlyEditingAlarmIndex].selectedSoundMode.rawValue
            segmentIndex = segmentIndex == TheBestClockAlarmSetting.AlarmPrefsMode.music.rawValue ? TheBestClockAlarmSetting.AlarmPrefsMode.silence.rawValue : segmentIndex
            self.alarmEditSoundModeSelector.selectedSegmentIndex = segmentIndex
        #endif
    }
    
    /* ################################################################## */
    /**
     */
    func showLookupThrobber() {
        musicLookupThrobber.color = selectedColor
        musicLookupThrobberView.backgroundColor = backgroundColor
        musicLookupThrobberView.isHidden = false
    }
    
    /* ################################################################## */
    /**
     */
    func hideLookupThrobber() {
        musicLookupThrobberView.isHidden = true
    }
    
    /* ################################################################## */
    /**
     */
    func selectSong() {
        DispatchQueue.main.async {
            if -1 < self.currentlyEditingAlarmIndex, 1 == self.alarmEditSoundModeSelector.selectedSegmentIndex {
                var segmentIndex = self.prefs.alarms[self.currentlyEditingAlarmIndex].selectedSoundMode.rawValue
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
                        if  !self.alarmEditSoundModeSelector.isEnabledForSegment(at: 1),
                            .music == self.prefs.alarms[self.currentlyEditingAlarmIndex].selectedSoundMode {
                            segmentIndex = TheBestClockAlarmSetting.AlarmPrefsMode.silence.rawValue
                        }
                }
                self.alarmEditSoundModeSelector.selectedSegmentIndex = segmentIndex
            }
        }
    }
    
    /* ################################################################## */
    /**
     */
    func showOnlyThisAlarm(_ inIndex: Int) {
        for alarm in alarmButtons where alarm.index != inIndex {
            alarm.isUserInteractionEnabled = false
            alarm.isHidden = true
        }
    }
    
    /* ################################################################## */
    /**
     */
    func refreshAlarm(_ inIndex: Int) {
        alarmButtons[inIndex].setNeedsDisplay()
    }
    
    /* ################################################################## */
    /**
     */
    func showAllAlarms() {
        alarmButtons.forEach {
            $0.isUserInteractionEnabled = true
            $0.isHidden = false
        }
    }
    
    /* ################################################################## */
    /**
     */
    func findSongInfo(_ inURL: String = "") -> (artistIndex: Int, songIndex: Int) {
        for artistInfo in songs {
            var songIndex: Int = 0
            for song in artistInfo.value {
                if inURL == song.resourceURI {
                    if let artistIndex = artists.firstIndex(of: song.artistName) {
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
        
        if !artists.isEmpty, !songs.isEmpty {
            let artistName = artists[artistIndex]
            if let songInfo = songs[artistName], 0 <= songIndex, songIndex < songInfo.count {
                ret = songInfo[songIndex].resourceURI
            }
        }
        
        return ret
    }
    
    /* ################################################################## */
    /**
     */
    func setupAlarmEditPickers() {
        if 1 == alarmEditSoundModeSelector.selectedSegmentIndex {
            loadMediaLibrary()
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
        prefs.alarms[currentlyEditingAlarmIndex].selectedSoundMode = TheBestClockAlarmSetting.AlarmPrefsMode(rawValue: alarmEditSoundModeSelector.selectedSegmentIndex) ?? .silence
        alarmButtons[currentlyEditingAlarmIndex].alarmRecord.selectedSoundMode = TheBestClockAlarmSetting.AlarmPrefsMode(rawValue: alarmEditSoundModeSelector.selectedSegmentIndex) ?? .silence
        showHideItems()
        if .music == prefs.alarms[currentlyEditingAlarmIndex].selectedSoundMode {   // We do this here, because it can take a little while for things to catch up, and we can get no throbber if we wait until just before we load the media.
            showLookupThrobber()
        }
        stopAudioPlayer()
        setupAlarmEditPickers()
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func activeSwitchChanged(_ inSwitch: UISwitch) {
        let wasInactive = !prefs.alarms[currentlyEditingAlarmIndex].isActive
        prefs.alarms[currentlyEditingAlarmIndex].isActive = inSwitch.isOn
        alarmButtons[currentlyEditingAlarmIndex].alarmRecord.isActive = inSwitch.isOn
        if wasInactive && inSwitch.isOn {   // This allows us to reset the state by turning the alarm off and then on again. Just like The IT Crowd.
            // We toggle the deactivated state, so the user can set the alarm to go off later, in case it isn't set to do that.
            prefs.alarms[currentlyEditingAlarmIndex].deferred = !prefs.alarms[currentlyEditingAlarmIndex].deferred
            alarmButtons[currentlyEditingAlarmIndex].alarmRecord.deferred = prefs.alarms[currentlyEditingAlarmIndex].deferred  // We reset the deactivated state
        }
        showHideItems()
        refreshAlarm(currentlyEditingAlarmIndex)
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func activeButtonHit(_ sender: Any) {
        alarmEditorActiveSwitch.setOn(!alarmEditorActiveSwitch.isOn, animated: true)
        alarmEditorActiveSwitch.sendActions(for: .valueChanged)
        refreshAlarm(currentlyEditingAlarmIndex)
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func vibrateSwitchChanged(_ inSwitch: UISwitch) {
        prefs.alarms[currentlyEditingAlarmIndex].isVibrateOn = inSwitch.isOn
        alarmButtons[currentlyEditingAlarmIndex].alarmRecord.isVibrateOn = inSwitch.isOn
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func vibrateButtonHit(_ sender: Any) {
        alarmEditorVibrateBeepSwitch.setOn(!alarmEditorVibrateBeepSwitch.isOn, animated: true)
        alarmEditorVibrateBeepSwitch.sendActions(for: .valueChanged)
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func testSoundButtonHit(_ inSender: TheBestClockSpeakerButton) {
        if !inSender.isOn, (nil == audioPlayer || !(audioPlayer?.isPlaying ?? false)) {
            let soundIndex = editAlarmPickerView.selectedRow(inComponent: 0)
            if let soundURLString = soundSelection[soundIndex].urlEncodedString, let soundUrl = URL(string: soundURLString) {
                if alarmEditorVibrateBeepSwitch.isOn {
                    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
                }
                playThisSound(soundUrl)
            }
        } else if audioPlayer?.isPlaying ?? false {
            pauseAudioPlayer()
        } else {
            stopAudioPlayer()
        }
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func testSongButtonHit(_ inSender: TheBestClockSpeakerButton) {
        if !inSender.isOn, (nil == audioPlayer || !(audioPlayer?.isPlaying ?? false)) {
            var soundUrl: URL!
            
            if .music == prefs.alarms[currentlyEditingAlarmIndex].selectedSoundMode, .authorized == MPMediaLibrary.authorizationStatus(), let songURI = URL(string: prefs.alarms[currentlyEditingAlarmIndex].selectedSongURL) {
                soundUrl = songURI
            }
            
            if nil != soundUrl {
                if alarmEditorVibrateBeepSwitch.isOn {
                    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
                }
                playThisSound(soundUrl)
            }
        } else if audioPlayer?.isPlaying ?? false {
            pauseAudioPlayer()
        } else {
            stopAudioPlayer()
        }
    }
    
    /* ################################################################## */
    /**
     */
    @IBAction func alarmTimeDatePickerChanged(_ inDatePicker: UIDatePicker) {
        if 0 <= currentlyEditingAlarmIndex, prefs.alarms.count > currentlyEditingAlarmIndex {
            let date = inDatePicker.date
            
            let calendar = Calendar.current
            
            let hour = calendar.component(.hour, from: date)
            let minutes = calendar.component(.minute, from: date)
            
            let time = hour * 100 + minutes

            prefs.alarms[currentlyEditingAlarmIndex].alarmTime = time
            prefs.alarms[currentlyEditingAlarmIndex].clearState()
            alarmButtons[currentlyEditingAlarmIndex].alarmRecord = prefs.alarms[currentlyEditingAlarmIndex]
            
            alarmDeactivatedLabel.isHidden = true
            refreshAlarm(currentlyEditingAlarmIndex)
        }
    }
    
    /* ################################################################## */
    /**
     This closes the alarm editor screen, making sure that everything is put back where it belongs.
     */
    @IBAction func closeAlarmEditorScreen(_ sender: Any! = nil) {
        impactFeedbackGenerator?.impactOccurred()
        impactFeedbackGenerator?.prepare()
        TheBestClockAppDelegate.lockOrientation(.all)
        if 0 <= currentlyEditingAlarmIndex, alarmButtons.count > currentlyEditingAlarmIndex {
            alarmButtons[currentlyEditingAlarmIndex].fullBright = false
        }
        stopAudioPlayer()
        prefs.savePrefs() // We commit the changes we made, here.
        currentlyEditingAlarmIndex = -1
        editAlarmScreenContainer.isHidden = true
        showAllAlarms()
        snoozeCount = 0
        alarmSounded = false

        mainNumberDisplayView.isAccessibilityElement = true
        dateDisplayLabel.isAccessibilityElement = true
        amPmLabel.isAccessibilityElement = true
        leftBrightnessSlider.isAccessibilityElement = true
        rightBrightnessSlider.isAccessibilityElement = true

        startTicker()
    }
}
