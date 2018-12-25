AmkaMani
=
This is a very fundamental iOS-based (iPhone or iPad) alarm clock app.

It has been designed for usability, simplicity and reliability.

You can easily select a font and color scheme, a brightness level, and whether to wake up to:

1) Flashing screen
2) Vibration (iPhones only, so far)
3) Sounds (Like classic alarm clock sounds)
4) Music (From your music library)

A QUICK NOTE ON THE APP STRUCTURE
-
This app was designed on a fairly fundamental usability model: That the user can modify all the app settings directly from the main screen, and the development model followed that.

It was sort of an experiment. Almost the entire app is contained in the View Controller for the main screen. The editor screens are actually layers that are made visible upon user selection.

I probably wouldn't do it again that way, but the result has been a phenomenally usable app, written in a short period of time.

However, it's also a really big, fat, ugly set of source files. I could probably get the same behavior with separate View Controllers for at least the editors.
