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

exec xcodebuild \
  -destination 'generic/platform=macOS' \
  "${XCODEBUILD_CI_SETTINGS[@]}" \
  "$@"
