# Web Wallpapers

**Product:** Loopscape (macOS)  
**Renderer:** `WebRenderer` (`WKWebView` full-screen behind desktop icons)

---

## How to use

1. Open **Settings** → **Renderer Mode** → **Web**.
2. Enter a **Web Source URL** or tap **Choose File** for a local HTML file.
3. Tap **Apply** (or apply from Home after selection).

Web mode is **optional**. Default video wallpapers use local files only and do not need network access.

---

## What counts as a “web wallpaper”

The engine loads whatever page or file the URL points to inside a full-screen `WKWebView`. There is **no** Wallpaper Engine Workshop format and **no** curated gallery.

**Usually works:**

- Full-page animated HTML/CSS/JS (generative art, canvas demos)
- A local `.html` file you author (Choose File) with fullscreen animation
- Simple pages that autoplay canvas/video without login

**Usually poor results:**

- Normal websites (news, search, YouTube home) — not designed edge-to-edge
- Sites that block embedding, require login, or refuse autoplay
- Bare image CDN links with no HTML wrapper

---

## Accepted URL schemes (M1+)

| Scheme | Allowed | Notes |
|--------|---------|-------|
| `https://…` | Yes | Remote pages; requires App Sandbox **network.client** |
| `file://…` or local path | Yes | Via Choose File or path string; no network needed |
| `http://…` | **No** | Rejected at validation (prefer HTTPS; ATS defaults) |
| `javascript:…` | **No** | Rejected |

Validation: `WebWallpaperURLValidator`. Navigation uses `WKNavigationDelegate` to block disallowed schemes and report load failures (previously apply could succeed while the page failed to load).

---

## Why remote web failed under sandbox (fixed in M1)

App Sandbox was enabled **without** `com.apple.security.network.client`. Local `file://` HTML could work; remote `https://` could not. M1 adds **network.client** to App Store and Direct entitlements.

---

## Mac App Store / privacy

- This optional mode is why the App Store listing declares **Unrestricted Web Access** (age rating 16+) — see [`APP_STORE_SUBMISSION.md`](APP_STORE_SUBMISSION.md) section 3.
- Loading a remote URL is **user-initiated**; the developer does not collect URL history or page content.
- Third-party site privacy practices are outside our control — disclose in [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md).
- Nutrition labels: **Data Not Collected** by the developer.

---

## Troubleshooting

| Symptom | Likely cause |
|---------|----------------|
| Blank desktop after Apply | Page failed to load — check error banner; try local HTML |
| “Invalid URL” | Non-https/file scheme or empty string |
| Page loads but wrong layout | Site not designed as fullscreen wallpaper |
| Worked in unsigned build, not MAS | Pre-M1 missing network entitlement (fixed) |

**Smoke test (Release-AppStore):**

1. **Local:** Choose File → fullscreen animated `.html` → Apply.
2. **Remote:** Paste a known-good `https://` demo page → Apply.

---

## Code touchpoints

- `WebWallpaperURLValidator.swift` — scheme allowlist
- `WebRenderer.swift` — load + navigation delegate
- `AppViewModel.swift` — apply path validation
- `SettingsTabView.swift` — Web URL field + Choose File importer

See [`M1_COMPLIANCE_CHECKLIST.md`](M1_COMPLIANCE_CHECKLIST.md) for compliance sign-off.
