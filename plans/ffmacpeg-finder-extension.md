---
planStatus:
  planId: plan-ffmacpeg-finder-extension
  title: "FFmacPeg - macOS Finder Extension for FFmpeg Video Conversion"
  status: draft
  planType: system-design
  priority: high
  owner: mario
  stakeholders: []
  tags: [macos, swift, ffmpeg, finder-extension, video-conversion]
  created: "2026-03-03"
  updated: "2026-03-03T00:00:00.000Z"
  progress: 0
---

# FFmacPeg - macOS Finder Extension for FFmpeg Video Conversion

## Overview

A native macOS app that adds a right-click context menu option in Finder for converting video files between formats using ffmpeg. The converted file is saved to the same directory with the same name but updated extension.

**MVP scope:** Video conversions only. Audio and image support will be added in future iterations.

## User Flow

1. User right-clicks a video file in Finder
2. Context menu shows "Convert to..." submenu with valid target formats
3. User selects a target format
4. File is converted using ffmpeg with sensible default quality settings
5. Output saved alongside original (auto-renamed if conflict, e.g., `video (1).mp4`)
6. macOS notification on completion or failure

---

## Confirmed Architecture Decisions

### 1. Extension Type: Action Extension

- Apple's recommended approach for file operations ([docs](https://developer.apple.com/documentation/AppKit/add-functionality-to-finder-with-action-extensions))
- Works system-wide, no folder monitoring needed
- `NSExtensionActivationRule` predicates filter which file types activate it
- Reference: [Swift 6 Finder Action Extension](https://cmsj.net/2025/05/23/finder-action-swift6.html)

The extension will hand off conversion to the main app via URL scheme (the extension has limited lifetime/resources, ffmpeg conversions can take minutes).

### 2. UI Framework: SwiftUI

- Declarative, modern, easier to learn for first-time Swift developer
- More than sufficient for this app's minimal UI needs
- Apple's stated future direction
- References: [SwiftUI for Mac 2025](https://troz.net/post/2025/swiftui-mac-2025/)

### 3. FFmpeg Integration: Bundled Binary

- Zero user friction (no Homebrew dependency)
- Sandbox compatible (binary lives at `Contents/MacOS/ffmpeg`)
- Shell out via Swift's `Process` class
- Original FFmpegKit was [retired Jan 2025](https://tanersener.medium.com/saying-goodbye-to-ffmpegkit-33ae939767e1); the [kingslay/FFmpegKit fork](https://github.com/kingslay/FFmpegKit) is an alternative worth evaluating
- Static builds from [evermeet.cx](https://evermeet.cx/ffmpeg/) (x64) or compile for arm64
- All bundled binaries must be code-signed with `--options=runtime`
- Reference: [Embedding ffmpeg in macOS app](https://www.jwz.org/blog/2024/09/embedding-perl-and-ffmpeg-in-a-macos-app/)

### 4. Distribution: Direct (Developer ID + Notarization)

- Avoids App Store GPL/LGPL licensing concerns with ffmpeg
- Full control, no review delays
- Distribute as `.dmg` via GitHub Releases
- Requires Apple Developer Program ($99/year) - to be set up later
- Reference: [Notarizing macOS software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)

### 5. User Preferences (Confirmed)

| Setting | MVP Behavior | Future |
|---|---|---|
| **Quality** | Sensible defaults (CRF 20 video, copy audio when possible) | User-configurable presets |
| **File conflicts** | Auto-rename with suffix: `video (1).mp4` | Option to overwrite/ask |
| **Progress** | macOS notification on completion | Menu bar progress indicator |
| **Batch conversion** | Single file only | Multi-file selection support |
| **Format scope** | Video only | + Audio, Image |

---

## MVP Supported Video Conversions

| Source Extensions | Target Options |
|---|---|
| `.mov` | MP4, MKV, WebM, AVI, GIF |
| `.mp4` | MOV, MKV, WebM, AVI, GIF |
| `.avi` | MP4, MOV, MKV, WebM, GIF |
| `.mkv` | MP4, MOV, WebM, AVI, GIF |
| `.webm` | MP4, MOV, MKV, AVI, GIF |
| `.flv` | MP4, MOV, MKV, WebM, AVI |
| `.wmv` | MP4, MOV, MKV, WebM, AVI |
| `.mpg`, `.mpeg` | MP4, MOV, MKV, WebM, AVI |
| `.ts` | MP4, MOV, MKV, WebM, AVI |
| `.m4v` | MP4, MOV, MKV, WebM, AVI |

**Default ffmpeg settings:**
- Video codec: `libx264` (MP4/MOV/MKV/AVI), `libvpx-vp9` (WebM), `gif` (GIF)
- Audio codec: `aac` (MP4/MOV/M4V), `libvorbis` (WebM), copy when compatible
- Quality: CRF 20 (good balance of quality/size)
- Flags: `-movflags +faststart` for MP4 (enables streaming)

---

## App Architecture

```
FFmacPeg.app/
  Contents/
    MacOS/
      FFmacPeg              (main app binary)
      ffmpeg                (bundled, code-signed)
      ffprobe               (bundled, code-signed)
    PlugIns/
      ConvertAction.appex/  (Action Extension)
    Resources/
      ...
    Info.plist
```

### Components

**1. Main App (FFmacPeg)**
- SwiftUI app with minimal window (onboarding/how-to-use guide)
- Registers a custom URL scheme (`ffmacpeg://convert?file=...&format=...`)
- Runs ffmpeg conversion as a background `Process`
- Sends macOS notification (`UNUserNotificationCenter`) on completion/failure

**2. Action Extension (ConvertAction.appex)**
- Appears in Finder right-click menu as "Convert to..." with a submenu
- Activated only on video file UTIs via `NSExtensionActivationRule`
- Reads source file extension, presents valid target formats
- On selection, opens main app via URL scheme with file path + target format
- Lightweight - does NO conversion work itself

**3. Conversion Engine (shared Swift code)**
- `FFmpegRunner` class wrapping `Process` to execute bundled ffmpeg
- `FormatRegistry` mapping source extensions to valid targets + ffmpeg flags
- Auto-rename logic for file conflicts
- Error handling and notification dispatch

### Data Flow

```
Finder right-click → Action Extension activates
  → Extension reads file type
  → Shows target format submenu
  → User picks format
  → Extension opens URL: ffmacpeg://convert?file=/path/to/video.mov&format=mp4
  → Main app receives URL, extracts parameters
  → FFmpegRunner spawns: ffmpeg -i input.mov -c:v libx264 -crf 20 ... output.mp4
  → On completion → macOS notification: "video.mov converted to MP4"
  → On failure → macOS notification: "Conversion failed: [error]"
```

---

## Implementation Phases

### Phase 1: Project Scaffolding
- [ ] Install Xcode 16+ from Mac App Store
- [ ] Create new macOS SwiftUI App project "FFmacPeg"
- [ ] Add Action Extension target "ConvertAction"
- [ ] Configure app sandbox entitlements for both targets
- [ ] Configure hardened runtime
- [ ] Register custom URL scheme `ffmacpeg://` in Info.plist
- [ ] Set deployment target to macOS 15 (Sequoia)

### Phase 2: Bundle FFmpeg
- [ ] Obtain universal (arm64 + x86_64) static ffmpeg + ffprobe binaries
- [ ] Add "Copy Files" build phase to embed binaries in `Contents/MacOS/`
- [ ] Add build script phase to code-sign bundled binaries
- [ ] Write Swift helper to locate bundled binary: `Bundle.main.url(forAuxiliaryExecutable: "ffmpeg")`
- [ ] Verify execution from sandbox with a test conversion

### Phase 3: Conversion Engine
- [ ] Create `FormatRegistry.swift` - maps source extensions → target formats + ffmpeg args
- [ ] Create `FFmpegRunner.swift` - wraps `Process`, runs ffmpeg, captures output
- [ ] Implement auto-rename logic (`FileConflictResolver`)
- [ ] Implement macOS notifications via `UNUserNotificationCenter`
- [ ] Unit test the format registry and conflict resolver

### Phase 4: Action Extension
- [ ] Configure `NSExtensionActivationRule` SUBQUERY predicate for video UTIs
- [ ] Implement `ActionRequestHandler` to receive selected file
- [ ] Build SwiftUI format picker view (list of target formats)
- [ ] Wire up selection to open main app via URL scheme
- [ ] Test extension activation in Finder

### Phase 5: Main App Integration
- [ ] Handle incoming `ffmacpeg://` URLs in the SwiftUI app lifecycle (`onOpenURL`)
- [ ] Trigger conversion on URL receipt
- [ ] Build simple onboarding view ("How to enable the extension")
- [ ] Request notification permissions on first launch
- [ ] Handle edge cases (file not found, permission denied, ffmpeg errors)

### Phase 6: Polish & Distribution (requires Apple Developer Program)
- [ ] Code-sign app, extension, and ffmpeg binaries with Developer ID
- [ ] Notarize with `xcrun notarytool submit`
- [ ] Staple notarization ticket: `xcrun stapler staple FFmacPeg.app`
- [ ] Package as `.dmg` with `create-dmg` or Disk Utility
- [ ] Create GitHub release with download link
- [ ] Write README with install instructions

---

## Prerequisites

| Prerequisite | Status | Notes |
|---|---|---|
| Xcode 16+ | To install | Free from Mac App Store |
| Apple Developer Program | Later | $99/year, needed for Phase 6 only |
| macOS 15+ (Sequoia) | Current | Deployment target |
| ffmpeg static binary | To obtain | Universal arm64 + x86_64 |
| Swift 6 | Ships with Xcode 16 | |

**Note:** Phases 1-5 can be developed and tested locally without the Apple Developer Program. You only need it for code-signing and distribution (Phase 6).

---

## Future Enhancements (Post-MVP)

- Audio format conversions (MP3, AAC, WAV, FLAC, OGG, M4A)
- Image format conversions (JPG, PNG, WebP, TIFF)
- User-configurable quality presets
- Batch conversion (multiple files at once)
- Menu bar progress indicator
- Conversion history/log
- Drag-and-drop onto app icon to convert
- Preset profiles (e.g., "Web optimized", "Archive quality")

---

## Key References

- [Apple: Add Functionality to Finder with Action Extensions](https://developer.apple.com/documentation/AppKit/add-functionality-to-finder-with-action-extensions)
- [Swift 6 Finder Action Extension walkthrough](https://cmsj.net/2025/05/23/finder-action-swift6.html)
- [Finder Sync Extension Guide (Apple archive)](https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/Finder.html)
- [SwiftUI for Mac 2025](https://troz.net/post/2025/swiftui-mac-2025/)
- [kingslay/FFmpegKit (maintained fork)](https://github.com/kingslay/FFmpegKit)
- [FFmpegKit retirement announcement](https://tanersener.medium.com/saying-goodbye-to-ffmpegkit-33ae939767e1)
- [Embedding ffmpeg in macOS app](https://www.jwz.org/blog/2024/09/embedding-perl-and-ffmpeg-in-a-macos-app/)
- [Code signing & notarizing macOS software](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
- [macOS Sequoia Finder Extensions fix (15.2+)](https://apptyrant.com/2025/05/09/how-to-enable-finder-extensions-on-macos-sequoia-15-2-and-newer/)
- [evermeet.cx static ffmpeg builds](https://evermeet.cx/ffmpeg/)
