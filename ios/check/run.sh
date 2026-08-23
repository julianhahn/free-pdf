#!/usr/bin/env bash
# The check that needs no Xcode: eighteen sections, each built as real files and read
# back through the model the app itself uses. Twelve are moments - ten where the process
# is killed, two the user reaches on his own - and the rest are the sentences the list
# rows say and the values a page keeps.
#
# No Xcode, no simulator, no project file - `Scan.swift` and `Engine.swift` are
# Foundation only, so swiftc alone compiles the whole state machine and the values a
# page keeps. The four C calls live in `EngineCalls.swift` and are not needed here.
set -euo pipefail
cd "$(dirname "$0")/.."

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# No -O: a failing `precondition` prints its sentence only in an unoptimised build, and
# a check that aborts without saying what it saw is half a check.
#
# Swift 6 language mode, because that is what a new Xcode project defaults to: the model
# has to survive strict concurrency here, not on the day it is dropped into the app.
swiftc -swift-version 6 -o "$work/check" FreePDF/Scan.swift FreePDF/Engine.swift check/main.swift

"$work/check" "$work"
echo "resume ok"
