#!/bin/sh
CWD="$(pwd)"
MY_SCRIPT_PATH=`dirname "${BASH_SOURCE[0]}"`
cd "${MY_SCRIPT_PATH}"
jazzy --github_url https://github.com/LittleGreenViper/the-best-clock.git --readme ./README.md --min-acl private
cd "${CWD}"
