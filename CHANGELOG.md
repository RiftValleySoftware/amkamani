**Version 1.0.0.2026** *(TBD)*
- Reduced the number of haptic "ticks" when adjusting brightness.

**Version 1.0.0.2025** *(January 11, 2019)*
- The app now auto-hides the Home Bar on X-phones and latest-gen iPads.
- reduced the minimum brightness (new phones have much brighter screens).
- Added haptics for various events.

**Version 1.0.0.2024** *(January 10, 2019)*
- Fixed an issue caused by my previous messing around, where turning an alarm off and on in the main display would cause that alarm to not go off.
- The alarm display now shows reversed if the alarm is deferred.

**Version 1.0.0.2023** *(January 9, 2019)*
- Fixed an issue, where the deferral wasn't being set correctly after re-activating after a snooze. It should always be deferred when reactivating from the main display.
- Fixed an issue, where letting a sound play out for the entire alarm period would keep it going forever.

**Version 1.0.0.2022** *(January 9, 2019)*
- Fixed a bug, where sometimes, testing a song would not work in the alarm editor.
- Switched over to a new Bundle ID and organization.

**Version 1.0.0.2021** *(January 7, 2019)*
- Added a bit of code to ensure that the touch sensor is "woken up" when the alarm sounds. After extended periods of time, the system can "sleep" the touch sensor, so it requires two taps.

**Version 1.0.0.2020** *(January 2, 2019)*
- Fixed a bug, where the ioriginal screen brightness wasn't being properly restored if an editor had been opened.

**Version 1.0.0.2019** *(January 2, 2019)*
- Added the localizable InfoPlist.strings file.
- Completely changed the way that the "snooze limit" is handled in the System Prefs section. I was quite unsatisfied with the previous version.
- The prefs have been completely reset, so you'll need to respecify the settings.
- Removed the double-tap gestures.
- Added a bit of a "fail-safe" check when playing a sound, where we make sure the authorization and saved song URI are valid for Music Mode. If not, we switch to Sound Mode when the alarm is played.
- The screen brightness now goes to full when editing the color and font (not just the alarm).

**Version 1.0.0.2017** *(December 26, 2018)*
- More accessibility work.
- Changed the source of the display name in the info screen.
- Changed the prefs key, so we will get new prefs.
- Changed the brightness sliders, so they have a larger hit test area.
- The brightness sliders now extend further up.
- Added a placeholder for German localization.
- Made it so that the alarm display at the bottom of the Alarm Editor is set to full brightness when editing (it was dimmed, before, if the app was dimmed).
- Tweaks to make sure that we never go below minimum brightness.

**Version 1.0.0.2016** *(December 18, 2018)*
- Fixed a minor cosmetic bug, where switching out of the app would not always restore the correct original brightness level.
- Added testing and QC stuff.
- Fixed a bug, where a couple of accessibility strings in the Appearance Editor were not being properly set.
- Added accessibility strings to the alarm set segmented switch.
- Tweaked the accessibility strings.
- Renamed the app to "AmkaMani".

**Version 1.0.0.2015** *(December 2, 2018)*
- Tweaked the branding control in the info screen.
- The "deactivated" state can now be toggled by switching the activated state switch.
- Replaced the GCD timer with a standard high-level timer.
- I **FINALLY** figured out what was causing the alarm crash, and fixed it. It was the music library load.
- Narrowed the requirement for forced portrait a bit. Probably won't make any difference.
- The active/vibrate switch buttons now use a normal font.
- Added placeholders for French and Spanish localization.
- Switched the font of the "No Music Available" label to use the system italic.
- Localized the sounds.
- Now force-copy the localization files to the settings bundle.
- Deleted the tests, as we won't use them for this project.
- Fixed a bug, where the "everlasting snooze" wasn't working properly.
- Added some comments to the localization files to assist localization.
- Added a tolerance to the ticker to help reduce energy usage.

**Version 1.0.0.2014** *(December 1, 2018)*
- When deactivating a snoozing alarm, the alarm would not go into a "next time" mode. It does so now.
- If the vibrate switch is on when the sound/song test button is hit, the phone will give one vibrate.
- Made a bit more room between the test button and the text that displays a note about "next time."
- Made the "snoring" a bit more efficient and responsive.
- Made it so that the "deactivations" and snoozing are turned off if the app goes into the background (but not if the app is behind a pulldown).
- Made the gradient a bit more extreme, and made the active alarms stand out a bit more.
- The settings bundle now uses the main localizable file (makes localization easier).
- The event timer now has some leeway, which helps reduce the energy footprint of the app.
- Did some work to make sure that static data members are set in a synchronous thread.
- The display now gets bright when the alarm goes off. This makes the flash more prominent.

**Version 1.0.0.2012** *(November 25, 2018)*
- New App Icon
- The app could crash when the alarm sounded. This has been fixed.
- The disable alarm touch was unreliable. It should now be more reliable.

**Version 1.0.0.2011** *(November 18, 2018)*
- Replaced a few strings in the Alarm Editor with icons for localization.
- Added the ability to specify a "snooze threshold" in the Settings panel for the app.
- Modified the alarm and snooze flasher animations to be a bit more correct, and to possibly reduce interference with taps.

**Version 1.0.0.2009** *(November 16, 2018)*
- Audio now plays when silent mode on.

**Version 1.0.0.2008** *(November 16, 2018)*
- Added the non-exempt encryption flag.
- Added accessibility strings.

**Version 1.0.0.2007** *(November 16, 2018)*
- Made it so there's no wait, once the alarm's minute is crossed (Happens right at the transition, now. Before, it could wait a few seconds).
- There was a bug, where the app would not restore its ticker after being backgrounded. That has been fixed.

**Version 1.0.0.2006** *(November 15, 2018)*
- Changed the method used to run the "heartbeat" of the app.
- Fixed a bug in the URLs that prevented sounds from playing.
- Added text to indicate that an alarm is deactivated "until next time."
- Completely redid the time calculation engine.
- Implemented "Forever Snooze."
- The vibrate switch and button are now hidden for iPads.
- Disable the various pickers and switches in the Alarm Editor while the music lookup is happening.

**Version 1.0.0.2002** *(November 14, 2018)*
- Fixed the way prefs are saved, so future releases shouldn't crash on startup.
- Added an indicator if there is no music.
- Made the darkener sliders more prominent when going dark.

**Version 1.0.0.2000** *(November 13, 2018)*
- First Beta Release

**Version 1.0.0.1000** *(November 12, 2018)*
- First Alpha Release
