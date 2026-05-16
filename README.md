# Canvas Deadlines

A lightweight macOS menu bar app that shows your Canvas assignment, quiz, and
exam deadlines as a live countdown — sorted from soonest to latest. It reads
directly from your Canvas **calendar feed (iCal/.ics)**, so it needs **no
Canvas API token** and works across **multiple schools** at once.

> Built for [Instructure Canvas](https://www.instructure.com/canvas) calendar
> feeds (originally for UCLA Extension, where students cannot generate access
> tokens). Native Swift, zero external dependencies.

## Features

- 🗓️ **Menu bar countdown** — every upcoming assignment / quiz / exam, sorted
  by due date.
- 🚦 **Urgency color bar** — at-a-glance status: 🔴 overdue · 🟠 within 1 day ·
  🟡 within 3 days · 🟢 further out.
- ✅ **Mark submitted / skip** — hover any item to mark it done (permanently
  removed) or skip it; both are restorable from Settings.
- 🏫 **Multi-school** — add a calendar feed per school; deadlines merge
  automatically and never collide across schools.
- 🗂️ **All / By course** — flat chronological view, or a collapsible
  per-course accordion.
- 🔗 **One click to Canvas** — clicking an item opens its Canvas page in the
  browser.
- ⚙️ **Settings** — overdue grace window, per-school feed management, custom
  course-name overrides, and a diagnostics export for troubleshooting.
- 🔒 **Private by design** — the feed URL (which embeds your personal token)
  is stored in the macOS Keychain and never leaves your machine.
- 🚀 **Launch at login** — optional, via `SMAppService` (packaged `.app` only).

## Requirements

- macOS 13 (Ventura) or later
- [Xcode](https://developer.apple.com/xcode/) or the Swift toolchain (to build)

## Install

Clone and build the app bundle:

```bash
git clone https://github.com/EwanWu06/CanvasDeadlines.git
cd CanvasDeadlines
./build.sh
```

This produces **`dist/CanvasDeadlines.app`**.

- Double-click it — a calendar icon 📅 appears in the menu bar.
- To keep it around, drag the `.app` into your **Applications** folder.
- First launch may show *"cannot verify the developer"* (the build is
  ad-hoc signed). **Right-click → Open → Open** once to allow it.

## First-time setup

Click the menu bar icon and follow the onboarding:

1. Log in to Canvas (the app opens it for you).
2. Go to **Calendar** → **Calendar Feed** (bottom-right).
3. Copy the `.ics` link, paste it back into the app, then **Test & Save**.

## Daily use

- Click the menu bar icon to see what's due, soonest first.
- Hover an item for two actions:
  - **Submitted** — mark done and remove it permanently.
  - **Skip** — hide it (restorable later).
- Toggle **All / By course** at the top; by-course groups collapse — click a
  course to expand it.
- Click an item to open it on Canvas.

## Settings

Open from the menu bar → Settings:

- **Calendar feeds (multi-school)** — add, test, rename, or remove a feed per
  school; deadlines merge automatically.
- **Overdue grace days** — hide items more than _N_ days past due (default 3).
- **Skipped / Marked submitted** — restore anything you removed by mistake.
- **Course-name overrides** — when a course shows as "Course #id", set a
  readable name manually.
- **About → Diagnostics** — export a report if an item is missing or
  misclassified.

## Notes

- Data comes from your Canvas personal calendar feed (iCal). An access token
  is **not used or supported**.
- Because the calendar feed has no "submitted" status, completed items are
  cleared manually via **Submitted**.
- After updating the code, re-run `./build.sh` to rebuild the `.app`.

## Tech

| | |
|---|---|
| Language | Swift 5.9 |
| UI | SwiftUI (`MenuBarExtra`) |
| Build | Swift Package Manager |
| Min OS | macOS 13 |
| Dependencies | None — system frameworks only |

Source lives in `Sources/CanvasDeadlines/` (Models / Services / ViewModels /
Views). Design and spec docs are in `docs/`; development history is in
`dev-log/`; the contributor workflow is described in `CLAUDE.md`.

## License

No license is currently specified — all rights reserved by the author.
</content>
</invoke>
