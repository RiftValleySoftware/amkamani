![AmkaMani Icon](https://riftvalleysoftware.com/AmkaMani-Docs/icon.png)

ABOUT AMKAMANI
=
This is a very fundamental iOS-based (iPhone or iPad) alarm clock app.

It has been designed for usability, simplicity and reliability.

You can easily select a font and color scheme, a brightness level, and whether to wake up to:

1) Flashing Screen
2) Vibration (iPhones only, so far)
3) Built-In Sounds (Like classic alarm clock sounds)
4) Music (From your music library)

[This page covers its operation in great detail.](https://riftvalleysoftware.com/work/ios-apps/amkamani/)

This app is [publicly available on the Apple App Store](https://itunes.apple.com/us/app/amkamani/id1448933103). It is an [Apple iOS-only](https://www.apple.com/ios) app, written in [Swift](https://www.apple.com/swift/).

[This is the basic instruction page for AmkaMani](https://riftvalleysoftware.com/work/ios-apps/amkamani/)

[This page is the detailed documentation page for the AmkaMani Codebase](https://riftvalleysoftware.com/AmkaMani-Docs/)

[This is the Codebase for the AmkaMani App](https://github.com/RiftValleySoftware/amkamani)

This app requires iOS devices (iPhones, iPads and iPods), running iOS 10 or greater.

AmkaMani is a proprietary-code application, and the code is not licensed for reuse. The code is provided as open-source, for purposes of auditing and demonstration of [The Great Rift valley Software Company](https://riftvalleysoftware.com) coding style.

LICENSE
=
This app is **NOT** licensed for reuse. It is hoped that the open-source nature of the app will help folks to learn about what I can do, and give them some confidence in the app.

LOCALIZATION
=
Localization was commissioned from the folks at [Babble-on](https://www.ibabbleon.com).

PROJECT DESIGN AND DESCRIPTION
=

A Quick Note About the Weird App Structure
-
This app was designed on a fairly fundamental usability model: That the user can modify all the app settings directly from the main screen, and the development model followed that.

Sort of a "form follows function" experiment.

It was sort of an experiment. Almost the entire app is contained in the View Controller for the main screen. The editor screens are actually layers that are made visible upon user selection.

I probably wouldn't do it again that way, but the result has been a phenomenally usable app, written in a short period of time.

However, it's also a really big, fat, ugly set of source files. I could probably get the same behavior with separate View Controllers for at least the editors.

Also, you spend a heck of a lot of time in Interface Builder. IB is a dog. Not much fun to play with.

**EXPERIMENT RESULTS:** *Don't do that again. Put out your hand, palm up. **WHACK***
