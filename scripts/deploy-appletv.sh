#!/bin/sh
# Builds a Release version, installs it on a paired Apple TV and starts it – without attaching a debugger.
# Usage (from repo root): scripts/deploy-appletv.sh [device name or UDID]   (default: "AppleTV")
set -eu

DEVICE="${1:-AppleTV}"
DERIVED=build/device

xcodebuild build -project TVDash.xcodeproj -scheme TVDash -configuration Release \
  -destination "generic/platform=tvOS" -derivedDataPath "$DERIVED" -allowProvisioningUpdates -quiet
xcrun devicectl device install app --device "$DEVICE" "$DERIVED/Build/Products/Release-appletvos/TVDash.app"
xcrun devicectl device process launch --device "$DEVICE" --terminate-existing com.hbakesson.tvdash
