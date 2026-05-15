#!/usr/bin/env bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_NAME="Personal Wallpaper Engine"
XCODEPROJ="$PROJECT_DIR/$PROJECT_NAME.xcodeproj"
SCHEME="$PROJECT_NAME"
DERIVED="$TMPDIR/DerivedData_$$"
BUILD_DIR="$DERIVED/Build/Products/Debug"
APP_PATH="$BUILD_DIR/$PROJECT_NAME.app"

echo "DerivedData: $DERIVED"
rm -rf "$DERIVED"
mkdir -p "$DERIVED"

echo "Building project..."
xcodebuild clean build -project "$XCODEPROJ" -scheme "$SCHEME" -configuration Debug -derivedDataPath "$DERIVED"

if [ -d "$APP_PATH" ]; then
  echo "Build succeeded; app bundle found at: $APP_PATH"
else
  echo "ERROR: App bundle not found at expected path: $APP_PATH" >&2
  exit 2
fi

# Basic validation: check executable exists and is a Mach-O binary
EXECUTABLE="$APP_PATH/Contents/MacOS/$PROJECT_NAME"
if [ -f "$EXECUTABLE" ]; then
  echo "Executable present: $EXECUTABLE"
  file "$EXECUTABLE"
else
  echo "ERROR: Executable missing inside app bundle" >&2
  exit 3
fi

# Try a light validation: run codesign --verify (non-fatal if unsigned)
if command -v codesign >/dev/null 2>&1; then
  echo "Validating codesign for bundle (may fail on CI without identity)..."
  set +e
  codesign --verify --deep --strict --verbose=2 "$APP_PATH" || echo "codesign validation failed or not applicable in this environment"
  set -e
fi

# Optionally attempt to launch the app in the background (non-blocking)
if command -v open >/dev/null 2>&1; then
  echo "Attempting to open app (will not block)..."
  open "$APP_PATH" || echo "open failed or prevented by environment"
fi

echo "Smoke check completed successfully."
exit 0
