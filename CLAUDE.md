# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

4champ is an iOS app (fork of https://github.com/sitomani/4champ) for playing Amiga tracker music modules. It streams modules from the AMP (Amiga Music Preservation) database at 4champ.net and also supports local module collection management.

## Building and Running

This is an **Xcode project** — there are no command-line build or test commands. Build and run via Xcode:
- Open `4champ.xcodeproj` in Xcode
- Build target: `4champ` (main app) or `SamplePlayer` (minimal test app in `SamplePlayer/`)
- The `SamplePlayer` app is useful for testing replay changes in isolation without the full app

There is no automated test suite currently in the repository.

## Architecture

### Clean Swift (VIP) Pattern
All main scenes follow the **Clean Swift** (View-Interactor-Presenter) pattern. Each scene folder under `4champ/Scenes/` contains:
- `*ViewController.swift` — UI, delegates to interactor
- `*Interactor.swift` — Business logic, observes `modulePlayer` and `moduleStorage`
- `*Presenter.swift` — Formats data for display
- `*Router.swift` — Navigation
- `*Models.swift` — Request/Response/ViewModel structs for the VIP cycle

### Global Singletons (AppDelegate.swift)
Five app-wide singletons are declared at the top level in `AppDelegate.swift` and used throughout:
```swift
let modulePlayer = ModulePlayer()
let moduleStorage = ModuleStorage()
let log = AMPLogger()
let settings = SettingsInteractor()
let shareUtil = ShareUtility()
```

### Replay Layer (Objective-C)
The audio replay subsystem is written in **Objective-C** and exposed to Swift via the bridging header (`4champ-bridging-header.h`). The key protocols are in `Replay.h`:
- `ReplayControl` — load/play/stop/pause/resume/settings
- `ReplayInformation` — position, channel volumes, pattern data
- `ReplayerStream` — raw PCM frame reading
- `ReplayStreamDelegate` — callbacks for audio buffer updates and end-of-stream

`Replay.m` is the central coordinator that manages three replayer backends:
- `MPTReplayer` (OpenMPT) — handles most tracker formats (MOD, XM, IT, S3M, etc.)
- `HVLReplayer` — HivelyTracker AHX/HVL formats
- `UADEReplayer` — UADE for esoteric Amiga formats

`Replay` uses iOS `AudioToolbox` (`AudioUnit` / `RemoteIO`) for real-time audio rendering.

### Data Model
- `MMD` struct (`Data/Structs.swift`) — the central module metadata type used everywhere
- `ModuleStorage` (`Scenes/Local/ModuleStorage.swift`) — CoreData persistence using `AmpCDModel.xcdatamodeld`, with `ModuleInfo` and `Playlist` entities
- `ModuleService` enum distinguishes AMP-sourced vs. locally-imported modules

### Networking
Native iOS networking only (no third-party dependencies). `NetworkClient` sends typed `APIRequest` objects against `Endpoint` cases defined in `Networking/Endpoints.swift`. Module downloads decompress gzip content using platform zlib via `ModuleFetcher`.

### Visualizer
The Visualizer scene (`Scenes/Visualizer/`) has three rendering layers:
- **Channel volume bars** — SpriteKit (`AmpVizScene.swift`)
- **Amplitude waveform** — Apple Metal vertex shader (`VertexShaderView.swift` + `amplitudegraph.metal`)
- **Pattern visualiser** — `CATextLayer`/`CAScrollLayer` grid (`PatternVisualiser.swift`)

### Localisation
Strings use a custom `l13n()` extension on `String` (`l13n/String+extension.swift`). All string keys are looked up via `NSLocalizedString`; untranslated strings fall back to English (`en.lproj`). Supported locales: `en`, `fi`, `da`, `de`, `es`, `nb`, `pt-BR`, `ru`, `sv`.

### Scenes Overview
| Scene | Purpose |
|---|---|
| Radio | Stream modules from AMP radio channels or custom search-based channels |
| Search | Search modules/composers/groups/texts on AMP API |
| Local | Browse and manage locally saved modules |
| Playlists | User-created playlists (SwiftUI views mixed with UIKit) |
| Visualizer | Full-screen playback view with waveform, pattern, and channel bar visualisations |
| Settings | Stereo separation, interpolation filter, Amiga resampler toggle |
| About | App info |

## Key Conventions

- **Logging**: Use the global `log` singleton (`log.debug(...)`, `log.info(...)`, `log.error(...)`). Debug logs are stripped in release builds.
- **Localisation**: All user-visible strings must use `.l13n()` and have a key in `en.lproj/Localizable.strings`.
- **Appearance**: All colors and fonts come from `Utils/Appearance.swift` static properties.
- **Module format support**: Supported file extensions are declared per-replayer via `+supportedFormats` class methods and aggregated in `Replay.m`. Adding a new format requires updating the replayer's list and potentially `Info.plist` document types.
- **Mixed language**: Swift interops with the Objective-C replay layer through the bridging header. Swift cannot directly call C++ so C++ replayer internals are wrapped in Objective-C (`.m` / `.mm` files).
