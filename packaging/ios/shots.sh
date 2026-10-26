#!/bin/sh
# The App Store screenshots, as recipes. shots-appstore builds the app for the
# simulator, boots each simulator ship.toml names, installs the iPhone app or
# the watch app it embeds, and calls this with the simulator, the language and where the frames go;
# this file is the half that is Vier's: which screens, from the positions a
# Debug build sets up when launched with --demo.
#
#     ./packaging/ios/shots.sh --app <Vier.app> --device <udid> --lang en-us --outdir <dir>
#
# Author: David M. Anderson
# Built with AI assistance (Claude, Anthropic)
set -eu
app= device= lang= outdir=
while [ $# -gt 0 ]; do
    case "$1" in
        --app) app=$2; shift 2 ;;
        --device) device=$2; shift 2 ;;
        --lang) lang=$2; shift 2 ;;
        --outdir) outdir=$2; shift 2 ;;
        *) echo "shots.sh: unknown argument $1" >&2; exit 2 ;;
    esac
done
[ -n "$app" ] && [ -n "$device" ] && [ -n "$lang" ] && [ -n "$outdir" ] || { echo "shots.sh: --app, --device, --lang and --outdir are all required" >&2; exit 2; }
case "$lang" in
    en|en-us|en-US) languages='(en)'; locale=en_US ;;
    *) echo "shots.sh: no set is written for $lang" >&2; exit 2 ;;
esac
case "$(xcrun simctl list devices | grep -F "($device)" | head -1)" in
    *Watch*) plist=$(echo "$app"/Watch/*.app/Info.plist) ;;
    *) plist=$app/Info.plist ;;
esac
bundle=$(/usr/libexec/PlistBuddy -c 'Print CFBundleIdentifier' "$plist")
mkdir -p "$outdir"
settle=8
shot() {
    name=$1
    shift
    xcrun simctl launch --terminate-running-process "$device" "$bundle" \
        -AppleLanguages "$languages" -AppleLocale "$locale" "$@" >/dev/null
    sleep "$settle"
    xcrun simctl io "$device" screenshot --type=png "$outdir/$name.png" >/dev/null
    echo "$name"
}
shot 01-game --demo 3,3,2,4,4,4,2,1,5,3
shot 02-win --demo 3,4,4,5,5,6,5,6,6,0,6
shot 03-home
xcrun simctl terminate "$device" "$bundle" >/dev/null 2>&1 || true
