#!/usr/bin/env zsh
set -euo pipefail
setopt pipefail 2>/dev/null || set -o pipefail

PROJECT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$PROJECT_DIR"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
XCODEBUILD="$SCRIPT_DIR/xcodebuild_ci.sh"
chmod +x "$XCODEBUILD" 2>/dev/null || true

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
echo "CODE_SIGNING_ALLOWED=${CODE_SIGNING_ALLOWED:-YES}"

# Build variants to run
CONFIGS=("Debug" "Release")

FIRST_CFG=1
for cfg in "${CONFIGS[@]}"; do
  echo "\n--- Building configuration: $cfg ---"
  if [ "${CODE_SIGNING_ALLOWED:-YES}" = "NO" ]; then
    echo "Running build with unsigned CI settings (CODE_SIGN_IDENTITY=-)"
  fi
  BUILD_ARGS=(build)
  if [ "$FIRST_CFG" -eq 1 ]; then
    BUILD_ARGS=(clean build)
    FIRST_CFG=0
  fi
  if ! TMPDIR="${TMPDIR:-/tmp}" "$XCODEBUILD" "${BUILD_ARGS[@]}" \
    -project "Personal Wallpaper Engine.xcodeproj" \
    -scheme "Personal Wallpaper Engine" \
    -configuration "$cfg" \
    -derivedDataPath "$DERIVED" \
    2>&1 | tee "$ARTIFACT_DIR/build-$cfg.log"
  then
    echo "ERROR: $cfg build failed (see $ARTIFACT_DIR/build-$cfg.log)" >&2
    exit 1
  fi
done

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
  echo "ERROR: App not found at expected path: $APP_PATH" >&2
  echo "See $ARTIFACT_DIR/build-Debug.log for xcodebuild output." >&2
  exit 1
fi

# Lightweight smoke validations (no second full rebuild)
if [ -x ./scripts/chunk7_smoke.sh ]; then
  echo "\n--- Bundle checks (smoke) ---"
  export CODE_SIGNING_ALLOWED="${CODE_SIGNING_ALLOWED:-YES}"
  export SMOKE_SKIP_BUILD=1
  export SMOKE_APP_PATH="$APP_PATH"
  if ! ./scripts/chunk7_smoke.sh 2>&1 | tee "$ARTIFACT_DIR/chunk7_smoke.log"; then
    echo "ERROR: smoke checks failed — regression aborted"
    exit 1
  fi
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
