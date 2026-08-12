#!/usr/bin/env bash
# The check for milestone 3: the resume rules. Ten moments the process could die, each
# one built as real files and read back through the model the app itself uses.
#
# No Xcode, no simulator, no project file - `Scan.swift` is Foundation only, so swiftc
# alone compiles the whole state machine.
set -euo pipefail
cd "$(dirname "$0")/.."

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# No -O: a failing `precondition` prints its sentence only in an unoptimised build, and
# a check that aborts without saying what it saw is half a check.
#
# Swift 6 language mode, because that is what a new Xcode project defaults to: the model
# has to survive strict concurrency here, not on the day it is dropped into the app.
swiftc -swift-version 6 -o "$work/check" FreePDF/Scan.swift check/main.swift

"$work/check" "$work"
echo "resume ok"
