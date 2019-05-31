![AmkaMani Icon](https://open-source-docs.riftvalleysoftware.com/docs/AmkaMani/icon.png)

ABOUT AMKAMANI
=
This is a very fundamental iOS-based (iPhone or iPad) alarm clock app.

It has been designed for usability, simplicity and reliability.

You can easily select a font and color scheme, a brightness level, and whether to wake up to:

- Flashing Screen
- Vibration (iPhones only, so far)
- Built-In Sounds (Like classic alarm clock sounds)
- Music (From your music library)

This app is [publicly available on the Apple App Store](https://itunes.apple.com/us/app/amkamani/id1448933103). It is an [Apple iOS-only](https://www.apple.com/ios) app, written in [Swift](https://www.apple.com/swift/).

[This is the basic instruction page for AmkaMani](https://riftvalleysoftware.com/work/ios-apps/amkamani/)

[This page is the detailed documentation page for the AmkaMani Codebase](https://open-source-docs.riftvalleysoftware.com/docs/AmkaMani/index.html)

[This is the Codebase for the AmkaMani App](https://github.com/RiftValleySoftware/amkamani)

This app requires iOS devices (iPhones, iPads and iPods), running iOS 10 or greater.

AmkaMani is a proprietary-code application, and the code is not licensed for reuse. The code is provided as open-source, for purposes of auditing and demonstration of [The Great Rift valley Software Company](https://riftvalleysoftware.com) coding style.

LICENSE
=
This app is **NOT** licensed for reuse. It is hoped that the open-source nature of the app will help folks to learn about what I can do, and give them some confidence in the app.

LOCALIZATION
=
Localization was commissioned from the folks at [Babble-on](https://www.ibabbleon.com).

There are few places that text is shown. The bulk of the localization is actually in the extensive VoiceOver Mode support.

PROJECT DESIGN AND DESCRIPTION
=

A Quick Note About the Weird App Structure
-
This app was designed on a fairly fundamental usability model: That the user can modify all the app settings directly from the main screen, and the development model followed that.

Sort of a "form follows function" experiment. Almost the entire app is contained in the View Controller for the main screen. The editor screens are actually layers that are made visible upon user selection.

I probably wouldn't do it again that way, but the result has been a phenomenally usable app, written in a short period of time (The entire app took about a week to write, but the "polishing the fenders" stage took over a month).

However, it's also a really big, fat, ugly set of source files. I could probably get the same behavior with separate View Controllers for at least the editors.

Also, you spend a heck of a lot of time in Interface Builder (Storyboard Editor). IB is a dog. Not much fun to play with.

**EXPERIMENT RESULTS:** *Result Successful. Methodology Not Recommended.*

Screen Layout
-
The way the app is laid out, is that screens appear over each other. There's really only four screens in the app:
![AmkaMani Icon](https://open-source-docs.riftvalleysoftware.com/docs/AmkaMani/img/Layout.png)

The main screen shows the running clock.

If  you long-press in the main screen, another screen appears over it, containing two pickers that allow you to choose a font and a color for the display. As noted, this screen is not presented by a separate [UIViewController](https://developer.apple.com/documentation/uikit/uiviewcontroller). Instead, what happens is that a previously hidden [UIView](https://developer.apple.com/documentation/uikit/uiview) is exposed, covering the main view. This new view will contain the pickers necessary to select the color and the font.

When you select a color, that color will be used everywhere in the app. The font will be used in many places (not all).

You can also bring in an About/Info screen modally. This one is handled by a separate ViewController. Tapping in it will cause the view to dismiss.

If you long-press in an alarm in the main screen, a new view will be exposed (again, not using a ViewController). It will also force iPhones to portrait, as it requires that much vertical space. This is the Alarm Editor.

Along either side of the Main Diplay, are hidden sliders that will allow you to change the brightness. Touching them will expose them as "upside-down teardrop" shapes, with a luminance gradient.

Apple does not allow app developers to access the ambient light sensor, so we cannot automatically adjust the brightness to match ambient conditions. It must be done manually.

The brightness change will actually dim the backlight; not just the colors, and we are careful to replace the brightness level when switching out or off. This allows AmkaMani to be extremely power-efficient, and it can be used without requiring the device to be connected to a charger.

AmkaMani needs to be up front. It will not work as a background app.
