#!/usr/bin/env bash
# Shared xcodebuild wrapper for local smoke/regression and GitHub Actions.
# When CODE_SIGNING_ALLOWED=NO, disables automatic signing (CI has no Apple cert).

set -euo pipefail

XCODEBUILD_CI_SETTINGS=()
if [[ "${CODE_SIGNING_ALLOWED:-YES}" == "NO" ]]; then
  XCODEBUILD_CI_SETTINGS=(
    CODE_SIGNING_ALLOWED=NO
    CODE_SIGNING_REQUIRED=NO
    CODE_SIGN_IDENTITY=-
    DEVELOPMENT_TEAM=
  )
fi

# Universal builds use generic/platform=macOS; XCTest needs a concrete arch (set via env).
DEST="${XCODEBUILD_DESTINATION:-generic/platform=macOS}"

if ((${#XCODEBUILD_CI_SETTINGS[@]} > 0)); then
  exec xcodebuild \
    -destination "$DEST" \
    "${XCODEBUILD_CI_SETTINGS[@]}" \
    "$@"
else
  exec xcodebuild \
    -destination "$DEST" \
    "$@"
fi
