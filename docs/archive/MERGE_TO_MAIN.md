# Merge to `main` — file checklist

Use this when merging `ui/polish/pr4-motion` (or your UI branch) into `main`.

## Include (source + docs)

- `Personal Wallpaper Engine/**/*.swift` — app source (excluding deleted legacy views)
- `Personal Wallpaper Engine/Assets.xcassets/**` — app icons if intentionally updated
- `Personal Wallpaper Engine.xcodeproj/**` — project (exclude `xcuserdata/`)
- `scripts/**` — smoke/regression scripts
- `.github/workflows/**` — CI if present
- Root docs: `README.md`, `ui_revamp_roadmap.md`, `PHASE_*_VALIDATION.md`, `DOCUMENTATION_UPDATE_SUMMARY.md`, `developmental_roadmap.md` (if updated)

## Do not commit

| Pattern | Reason |
|---------|--------|
| `Logs/Build*.txt` | Local Xcode export |
| `Logs/console_logs.md` | Local debug paste |
| `artifacts/` | Regression tarballs |
| `.phase*.log`, `.derivedData*` | Local build caches |
| `build/`, `DerivedData/`, `*.app` | Build products |
| `xcuserdata/` | Per-user Xcode state |

See [.gitignore](.gitignore) for the full list.

## Before push

```bash
git status
# Untracked Logs/Build*.txt should NOT appear once .gitignore is applied

git check-ignore -v Logs/Build\ Personal\ Wallpaper\ Engine_2026-05-20T17-19-47.txt
# Should show matching ignore rule

bash scripts/chunk7_smoke.sh
bash scripts/chunk7_regression.sh
```

## Suggested commit grouping

1. **UI Phase 2–4** — Swift UI revamp (tabs, glass, background, scroll)
2. **Cleanup** — remove `ContentView`, `HomeTabView`, `TransparentTabSwitcher`
3. **Docs** — roadmap, validation matrices, README

Or a single squashed commit if you prefer one PR.
