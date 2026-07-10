#!/bin/bash
#
# upload.sh — archive, export, and upload PaperDaily to App Store Connect (TestFlight).
#
# This runs everything I (Claude) cannot: it uses YOUR Apple Developer account.
# You must first:
#   1. Enroll in the Apple Developer Program (https://developer.apple.com/programs/, $99/yr).
#   2. Create an App Store Connect API key (Users and Access → Integrations → App Store
#      Connect API → generate). Note the Key ID and Issuer ID, download AuthKey_XXXX.p8,
#      and place it at ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8
#   3. Register the bundle ID and create the app record in App Store Connect
#      (see ../RELEASE.md steps 2–3).
#   4. Put your 10-char Team ID into AppStore/ExportOptions.plist (replace YOUR_TEAM_ID).
#
# Then run:  TEAM_ID=ABCDE12345 API_KEY_ID=XXXX API_ISSUER_ID=yyyy-... ./upload.sh
#
set -euo pipefail
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

: "${TEAM_ID:?set your 10-char Apple Team ID}"
: "${API_KEY_ID:?set your App Store Connect API Key ID}"
: "${API_ISSUER_ID:?set your App Store Connect API Issuer ID}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"          # …/PaperDaily
PROJ="$ROOT/PaperDaily.xcodeproj"
SCHEME="PaperDaily"
ARCHIVE="/tmp/PaperDaily.xcarchive"
EXPORT_DIR="/tmp/PaperDaily-export"
KEY_PATH="$HOME/.appstoreconnect/private_keys/AuthKey_${API_KEY_ID}.p8"

echo "▸ Archiving (Release, signed with team $TEAM_ID)…"
rm -rf "$ARCHIVE"
xcodebuild -project "$PROJ" -scheme "$SCHEME" -configuration Release \
  -destination 'generic/platform=iOS' -archivePath "$ARCHIVE" \
  DEVELOPMENT_TEAM="$TEAM_ID" -allowProvisioningUpdates \
  -authenticationKeyIssuerID "$API_ISSUER_ID" \
  -authenticationKeyID "$API_KEY_ID" \
  -authenticationKeyPath "$KEY_PATH" \
  archive

echo "▸ Exporting .ipa…"
rm -rf "$EXPORT_DIR"
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$ROOT/AppStore/ExportOptions.plist" \
  -allowProvisioningUpdates \
  -authenticationKeyIssuerID "$API_ISSUER_ID" \
  -authenticationKeyID "$API_KEY_ID" \
  -authenticationKeyPath "$KEY_PATH"

echo "▸ Uploading to App Store Connect…"
xcrun altool --upload-app -f "$EXPORT_DIR/PaperDaily.ipa" -t ios \
  --apiKey "$API_KEY_ID" --apiIssuer "$API_ISSUER_ID"

echo "✓ Done. The build appears in App Store Connect → TestFlight in a few minutes."
echo "  From there: internal testing (no review) or submit for App Store review (RELEASE.md step 7)."
