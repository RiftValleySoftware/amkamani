**Version 1.0.0.2015** *(TBD)*
- Tweaked the branding control in the info screen.
- The "deactivated" state can now be toggled by switching the activated state switch.
- Replaced the GCD timer with a standard high-level timer.

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
- Made it so there's no wait, once the alarm's minute is crossed (Happens right at the transition, now. Before, it could wait a few seconds).1
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
