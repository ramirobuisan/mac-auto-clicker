#!/bin/bash
set -e

# Base directories
APP_NAME="MacAutoClicker"
BUNDLE_DIR="${APP_NAME}.app"
CONTENTS_DIR="${BUNDLE_DIR}/Contents"
MAC_OS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "🧹 Cleaning up old builds..."
rm -rf "${BUNDLE_DIR}"
rm -f "${APP_NAME}"

echo "🔨 Compiling main.swift..."
SDK_PATH=$(xcrun --show-sdk-path --sdk macosx)
swiftc -O -parse-as-library -o "${APP_NAME}" main.swift -sdk "${SDK_PATH}" -target arm64-apple-macosx13.0

echo "📦 Bundling app..."
mkdir -p "${MAC_OS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Copy binary and plist
mv "${APP_NAME}" "${MAC_OS_DIR}/${APP_NAME}"
cp Info.plist "${CONTENTS_DIR}/Info.plist"

echo "✅ App bundled successfully: ${BUNDLE_DIR}"
