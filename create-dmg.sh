#!/bin/bash
set -e

APP_NAME="Peek"
PROJECT="Peek.xcodeproj"
SCHEME="Peek"
BUILD_DIR="build"
DMG_NAME="${APP_NAME}.dmg"
DMG_TEMP="${BUILD_DIR}/${APP_NAME}-temp.dmg"
DMG_STAGING="${BUILD_DIR}/dmg-staging"

echo "==> Cleaning build directory..."
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

echo "==> Building ${APP_NAME} (Release)..."
xcodebuild -project "${PROJECT}" \
    -scheme "${SCHEME}" \
    -configuration Release \
    SYMROOT="$(pwd)/${BUILD_DIR}" \
    build

APP_PATH="${BUILD_DIR}/Release/${APP_NAME}.app"

if [ ! -d "${APP_PATH}" ]; then
    echo "ERROR: App not found at ${APP_PATH}"
    exit 1
fi

echo "==> App built: ${APP_PATH}"
xattr -cr "${APP_PATH}" 2>/dev/null || true

echo "==> Creating DMG..."
rm -rf "${DMG_STAGING}"
mkdir -p "${DMG_STAGING}"

cp -R "${APP_PATH}" "${DMG_STAGING}/"
ln -s /Applications "${DMG_STAGING}/Applications"

# Create DMG
hdiutil create -srcfolder "${DMG_STAGING}" \
    -volname "${APP_NAME}" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "${BUILD_DIR}/${DMG_NAME}"

rm -rf "${DMG_STAGING}"

echo ""
echo "==> DMG created successfully!"
ls -lh "${BUILD_DIR}/${DMG_NAME}"
