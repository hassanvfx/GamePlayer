#!/usr/bin/env bash
set -euo pipefail
ma_destination="${IOS_DESTINATION:-platform=iOS Simulator,name=iPhone 16}"
xcodebuild -project GamePlayer.xcodeproj -scheme GamePlayer -destination "$ma_destination" CODE_SIGNING_ALLOWED=NO test
