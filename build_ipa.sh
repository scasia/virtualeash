#!/bin/bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

OUTPUT_DIR="$PROJECT_DIR/build_output"
ARCHIVE_PATH="$OUTPUT_DIR/virtualeash.xcarchive"
PAYLOAD_DIR="$OUTPUT_DIR/Payload"
IPA_PATH="$OUTPUT_DIR/virtualeash.ipa"

echo "===> Cleaning output directory..."
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

echo "===> Building archive with xcodebuild..."
xcodebuild archive \
    -project virtualeash.xcodeproj \
    -scheme virtualeash \
    -configuration Release \
    -destination 'generic/platform=iOS' \
    -archivePath "$ARCHIVE_PATH" \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="" \
    AD_HOC_CODE_SIGNING_ALLOWED=YES

echo "===> Packaging unencrypted IPA..."
mkdir -p "$PAYLOAD_DIR"
cp -R "$ARCHIVE_PATH/Products/Applications/virtualeash.app" "$PAYLOAD_DIR/"

cd "$OUTPUT_DIR"
zip -qry "virtualeash.ipa" "Payload"

rm -rf "$PAYLOAD_DIR"

echo "===> Successfully created IPA:"
ls -lh "$IPA_PATH"
