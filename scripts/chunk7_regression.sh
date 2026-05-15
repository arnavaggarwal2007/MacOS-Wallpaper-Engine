#!/bin/zsh
set -euo pipefail

PROJECT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$PROJECT_DIR"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
ARTIFACT_DIR="$PROJECT_DIR/artifacts/regression-$TIMESTAMP"
mkdir -p "$ARTIFACT_DIR"

# DerivedData location inside TMPDIR for writable path
DERIVED=${TMPDIR:-/tmp}/DerivedData_regression_$TIMESTAMP
mkdir -p "$DERIVED"

LOGFILE="$ARTIFACT_DIR/runner.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "Regression run started: $TIMESTAMP"
echo "DerivedData: $DERIVED"

# Build variants to run
CONFIGS=("Debug" "Release")

for cfg in "${CONFIGS[@]}"; do
  echo "\n--- Building configuration: $cfg ---"
  if [ "${CODE_SIGNING_ALLOWED:-YES}" = "NO" ]; then
    echo "Running build with CODE_SIGNING_ALLOWED=NO"
    env CODE_SIGNING_ALLOWED=NO TMPDIR="$TMPDIR" xcodebuild clean build -project "Personal Wallpaper Engine.xcodeproj" -scheme "Personal Wallpaper Engine" -configuration "$cfg" -derivedDataPath "$DERIVED" | tee "$ARTIFACT_DIR/build-$cfg.log"
  else
    TMPDIR="$TMPDIR" xcodebuild clean build -project "Personal Wallpaper Engine.xcodeproj" -scheme "Personal Wallpaper Engine" -configuration "$cfg" -derivedDataPath "$DERIVED" | tee "$ARTIFACT_DIR/build-$cfg.log"
  fi
done

# Run the existing smoke script (it performs additional validations)
if [ -x ./scripts/chunk7_smoke.sh ]; then
  echo "\n--- Running chunk7_smoke.sh ---"
  chmod +x ./scripts/chunk7_smoke.sh
  ./scripts/chunk7_smoke.sh 2>&1 | tee "$ARTIFACT_DIR/chunk7_smoke.log" || echo "smoke script exited with non-zero status"
else
  echo "No chunk7_smoke.sh found or not executable"
fi

# Codesign check (skip if CI disables signing)
APP_PATH="$DERIVED/Build/Products/Debug/Personal Wallpaper Engine.app"
if [ -d "$APP_PATH" ]; then
  echo "\n--- App built at: $APP_PATH ---"
  if [ "${CODE_SIGNING_ALLOWED:-YES}" = "NO" ]; then
    echo "Skipping codesign validation due to CODE_SIGNING_ALLOWED=NO"
  else
    echo "Validating codesign..."
    codesign --verify --deep --strict --verbose=2 "$APP_PATH" || echo "codesign validation failed"
  fi
else
  echo "Warning: App not found at expected path: $APP_PATH"
fi

# Collect some metadata
echo "\n--- Collecting metadata ---"
file "$DERIVED/Build/Products/Debug/Personal Wallpaper Engine.app/Contents/MacOS/Personal Wallpaper Engine" 2>/dev/null || true
ls -la "$DERIVED" || true

# Bundle artifacts
ARTIFACT_TAR="$PROJECT_DIR/artifacts/regression-$TIMESTAMP.tar.gz"
mkdir -p "$PROJECT_DIR/artifacts"
( cd "$PROJECT_DIR/artifacts" && tar -czf "regression-$TIMESTAMP.tar.gz" "regression-$TIMESTAMP" )

echo "Regression artifacts: $ARTIFACT_TAR"

echo "Regression run completed"
