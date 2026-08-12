#!/usr/bin/env bash
# The check for milestone 4: the whole app, killed in the middle of a scan.
#
# That one kill exercises the entire design at once - the step derived from the files,
# temp file plus rename, the sweep, the C boundary and the streamed PDF. It is the only
# end-to-end check there is, so it builds the Rust library and the app itself rather
# than trusting whatever was built last.
#
# There is no way to tap a simulator from a script: `simctl` has no touch command, and
# AppleScript is not allowed near it without a human granting assistive access. So the
# app is driven by `-autofake 12`, which stands in for the taps and goes with the camera
# stand-in in milestone 5 ([`../FreePDF/FakeShoot.swift`](../FreePDF/FakeShoot.swift)).
#
# About three minutes cold, most of it the two builds.
set -u -o pipefail
cd "$(dirname "$0")/../.."

device="${DEVICE:-iPhone 17 Pro}"
bundle=com.julianhahn.freepdf
wanted="${PAGES:-12}"           # pages to shoot
kill_after="${KILL_AFTER:-3}"   # pages on disk before the app is killed
derived="${TMPDIR:-/tmp}/freepdf-check"

fail() { echo "FAIL: $*" >&2; exit 1; }

# Waits for something to become true instead of sleeping for a guess. Every wait in this
# file goes through here, so a slow machine costs time and never a false failure.
poll() {                        # poll <seconds> <command…>
    local deadline=$(( $(date +%s) + $1 )); shift
    until "$@"; do
        [ "$(date +%s)" -lt "$deadline" ] || return 1
        sleep 0.5
    done
}

pageFiles() { find "$scans" -path '*/page/*.jpg' 2>/dev/null | sort; }
pageCount() { pageFiles | grep -c . ; }
atLeast() { [ "$(pageCount)" -ge "$1" ]; }
scanned() { [ -f "$(find "$scans" -maxdepth 2 -name scan.pdf | head -1)" ] 2>/dev/null; }

# The library the app links, so a green check can never be about yesterday's Rust.
bash ffi/build-ios.sh >/dev/null || fail "the Rust library did not build"

udid=$(xcrun simctl list devices available \
       | sed -n "s/.*$device (\([0-9A-F-]\{36\}\)).*/\1/p" | head -1)
[ -n "$udid" ] || fail "no simulator called \"$device\""
xcrun simctl bootstatus "$udid" -b >/dev/null || fail "the simulator did not boot"

xcodebuild -project ios/FreePDF.xcodeproj -scheme FreePDF -sdk iphonesimulator \
           -destination "id=$udid" -derivedDataPath "$derived" -quiet build \
    || fail "the app did not build"

# A fresh install, because uninstalling takes the data container with it: the check
# starts from a phone that has never seen this app.
xcrun simctl uninstall "$udid" "$bundle" >/dev/null 2>&1
xcrun simctl install "$udid" "$derived/Build/Products/Debug-iphonesimulator/FreePDF.app" \
    || fail "the app did not install"
data=$(xcrun simctl get_app_container "$udid" "$bundle" data) \
    || fail "the app has no data container"
scans="$data/Documents/Scans"

# 1. Shoot twelve pages and start scanning them.
xcrun simctl launch "$udid" "$bundle" -autofake "$wanted" >/dev/null || fail "launch"
poll 180 atLeast "$kill_after" || fail "no page was scanned in three minutes"

# 2. Kill it in the middle, and remember exactly what was on disk at that moment.
finished=$(pageFiles)
sums=$(echo "$finished" | xargs shasum -a 256)
times=$(echo "$finished" | xargs stat -f '%m %N')
count=$(echo "$finished" | grep -c .)
[ "$count" -lt "$wanted" ] || fail "the scan was finished before the kill - lower kill_after"
echo "killed after $count of $wanted pages"

xcrun simctl terminate "$udid" "$bundle" || fail "the app would not stop"

# Debris of the kind a kill really leaves, planted while the app is dead. Nothing but
# the launch path calls `Scan.sweep()`, and until this milestone nothing called it at
# all, so this is the only thing watching that it is called.
folder=$(find "$scans" -maxdepth 1 -type d -name '2*' | head -1)
[ -n "$folder" ] || fail "no scan folder was made"
echo "half a page" > "$folder/page/0099.part"
echo "a cut-off PDF" > "$folder/scan.part"

# 3. Open it again. It has to find the half-scanned scan by itself and carry on.
xcrun simctl launch "$udid" "$bundle" -autofake "$wanted" >/dev/null || fail "relaunch"
poll 300 atLeast "$wanted" || fail "only $(pageCount) of $wanted pages after the relaunch"

# 4. What was finished before the kill has to be untouched - the same bytes, and the
#    same moment written, because a page that was scanned twice cost the user his time
#    even when the second attempt produced identical bytes.
echo "$sums" | shasum -a 256 -c --status - || fail "a finished page changed after the resume"
[ "$(echo "$finished" | xargs stat -f '%m %N')" = "$times" ] \
    || fail "a finished page was written again, so the work was done twice"

# 5. The PDF, built through the second C function.
poll 120 scanned || fail "no scan.pdf was written"
pdf=$(find "$scans" -maxdepth 2 -name scan.pdf | head -1)
[ "$(tail -c 5 "$pdf")" = "%%EOF" ] || fail "the PDF is cut off"

# 6. Nothing half-written survived any of it.
debris=$(find "$scans" -name '*.part' -o -name '*.nosync*')
[ -z "$debris" ] || fail "debris left behind: $debris"

xcrun simctl terminate "$udid" "$bundle" >/dev/null 2>&1
echo "$(pageCount) pages, $count of them written before the kill and untouched by it"
echo "scan ok"
