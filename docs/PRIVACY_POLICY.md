# Privacy Policy — Deskloop

**Last updated:** 2026-08-20  
**Product:** Deskloop (macOS)  
**Applies to:** Mac App Store and any future direct-download builds unless a superseding policy is published

This document is the canonical source for the policy published at
<https://arnavaggarwal2007.github.io/MacOS-Wallpaper-Engine/privacy/> and used as the
App Store Connect **Privacy Policy URL**. When editing this file, update
[`privacy/index.html`](privacy/index.html) in the same change — that is the page
GitHub Pages actually serves.

---

## Summary

Deskloop is a **local-first** wallpaper application. It does **not** require an account and does **not** include analytics or advertising SDKs in the current product design. It does **not** use generative AI features.

---

## Generative AI

This app does **not** include chatbots, image generation, or other generative AI features. Wallpaper content comes from **your** local video files, optional local HTML files, or **URLs you choose** for web wallpapers.

---

## Information we do not collect

We do not collect:

- Names, email addresses, or account credentials (no accounts)
- Location data
- Advertising identifiers
- Usage analytics or telemetry sold to third parties (no third-party analytics SDKs)
- Generative-AI prompts or outputs (no AI features in the app)
- Your wallpaper media files (videos, images, or web content remain on your Mac)

---

## Information stored on your device

The app stores preferences and state **locally** on your Mac, for example:

- Selected wallpaper paths and **security-scoped bookmarks** so access can be restored after relaunch
- Collections, desktop setups, library folder roots, and related settings (typically via UserDefaults / local JSON)
- Optional thumbnail caches for library browsing
- Power and performance preference settings

This data stays on your device unless you choose to back up your Mac with your own tools (Time Machine, etc.).

---

## Network use

- **Default desktop video wallpapers** use local files only and do not require network access for playback.
- **Optional web wallpapers:** If you enter or select a remote URL, the app may load that URL over the network at your request. Only `https://` addresses and local HTML files are accepted. Content and privacy practices of those third-party sites are outside our control, and we do not record which URLs you load.
- **Mac App Store builds:** Updates are delivered by Apple through the Mac App Store. The app does not use a third-party auto-updater.
- **Future direct-download builds:** May check for updates (for example via Sparkle). When that ships, this policy will be updated to describe update checks.

---

## Screen Saver and lock-screen helpers (future)

When Screen Saver or lock-screen export features ship, they will use local media and system settings you control. Shared preferences between the main app and a Screen Saver extension may use an **App Group** container on your Mac — still local, not uploaded to us.

---

## Children’s privacy

The app is not directed at children under 13. We do not knowingly collect personal information from children.

---

## Third-party services

- **Apple:** App Store distribution, optional crash reporting you enable in system settings, and payment processing if optional In-App Purchases (for example a tip) are offered.
- We do not sell personal information.

---

## Your choices

- Remove library folders, clear caches, and delete the app to remove local preferences (standard macOS app data locations).
- Revoke file access via macOS System Settings → Privacy & Security where applicable.
- Uninstall the Screen Saver module (when shipped) via System Settings → Screen Saver.

---

## Changes

We may update this policy. The “Last updated” date will change; material changes for App Store builds will be reflected in App Store Connect privacy labels when required.

---

## Contact

For privacy questions: **arnevaggarrwal@gmail.com**  
Support: <https://github.com/arnavaggarwal2007/MacOS-Wallpaper-Engine/issues>

---

## Developer

**Arnav Aggarwal**
