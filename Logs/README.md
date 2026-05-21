# Logs (local only)

This folder is for **local debugging** — Xcode build exports and console captures.

These files are **gitignored** and should not be committed:

- `Build Personal Wallpaper Engine_*.txt` — Xcode build log exports
- `console_logs.md` — pasted runtime logs from debugging sessions

Use `scripts/chunk7_smoke.sh` and `scripts/chunk7_regression.sh` for automated CI-style checks instead of checking in build output.
