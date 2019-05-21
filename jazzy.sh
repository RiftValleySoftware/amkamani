#!/bin/sh
CWD="$(pwd)"
MY_SCRIPT_PATH=`dirname "${BASH_SOURCE[0]}"`
cd "${MY_SCRIPT_PATH}"
rm -drf docs
jazzy   --github_url https://github.com/RiftValleySoftware/amkamani \
        --readme ./README.md \
        --theme fullwidth \
        --author The\ Great\ Rift\ Valley\ Software\ Company \
        --author_url https://riftvalleysoftware.com \
        --module AmkaMani \
        --min-acl private \
        --exclude=./*/*/TheGreatRiftValleyDrawing.swift,./*/TheBestClockSpeakerButton.swift \
        --copyright [©2019\ The\ Great\ Rift\ Valley\ Software\ Company]\(https://riftvalleysoftware.com\) \
        -x CODE_SIGNING_ALLOWED=NO
cp icon.png docs/icon.png
cp .nojekyll docs/.nojekyll
cp img/*.* docs/img/
cd "${CWD}"
