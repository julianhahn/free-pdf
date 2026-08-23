#!/usr/bin/env bash
# The check that needs no Xcode: one grep over the view code, then eighteen sections
# built as real files and read
# back through the model the app itself uses. Twelve are moments - ten where the process
# is killed, two the user reaches on his own - and the rest are the sentences the list
# rows say and the values a page keeps.
#
# No Xcode, no simulator, no project file - `Scan.swift` and `Engine.swift` are
# Foundation only, so swiftc alone compiles the whole state machine and the values a
# page keeps. The four C calls live in `EngineCalls.swift` and are not needed here.
set -euo pipefail
cd "$(dirname "$0")/.."

# A style that builds its own control around `configuration.$something` draws correctly
# and is dead: the tap reaches a copy of the binding and nothing is ever written. That
# shipped once, in `8a40b68`, and killed every switch in the app while `cargo test`,
# `bridge_check`, this check and `scan_check.sh` all still said ok - because none of them
# taps anything ([`../AGENTS.md`](../AGENTS.md#tapping-a-control-in-the-simulator-without-hunting-for-it)).
#
# This is a grep and it knows it. It watches the one shape that caused the bug, not the
# whole class - a control can still be dead in ten other ways, and only a finger in the
# simulator finds those. It costs nothing and it closes the door that was actually walked
# through.
# The second grep drops comment lines: `SettingStyle.swift` names the wrong shape on
# purpose, so the next reader meets the trap before the code does.
# `|| true` because both greps exit 1 when they find nothing, which is the good case,
# and `set -e` with `pipefail` would take that for a failure.
copied="$(grep -rn --include='*.swift' -E '(Toggle|Button|Slider)\(.*configuration\.\$' FreePDF/ \
          | grep -vE ':[[:space:]]*//' || true)"
if [ -n "$copied" ]; then
    echo "$copied" >&2
    echo "The lines above build a control around a copy of configuration's binding." >&2
    echo "A tap will reach the copy and write nothing. Use Toggle(configuration) instead." >&2
    exit 1
fi

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
