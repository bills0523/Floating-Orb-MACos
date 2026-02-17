# Floating Orb macOS

Floating Orb is a native macOS utility built with **Swift + SwiftUI + AppKit**.  
It runs as a floating assistant orb (similar to Assistive Touch) that stays above other apps and opens into a tools panel.

## Core Experience

- Always-on-top floating orb (`NSPanel`, borderless/transparent)
- Double-click orb to expand/collapse tool window
- Draggable orb window
- Agent-style app (`LSUIElement`) so it does not appear in Dock
- Customizable tool order and enable/disable controls

## Tech Stack

- SwiftUI for UI
- AppKit (`NSPanel`, `NSWindow`, `NSHostingController`) for floating behavior
- AppleScript + shell commands for system-level actions
- `UserDefaults` / `@AppStorage` for persistence

## Current Functions

### System Controls

1. Desktop Icons Toggle  
Show/hide desktop icons by updating Finder defaults and restarting Finder.

2. Theme Toggle  
Switch macOS light/dark mode through AppleScript (`System Events`).

3. Finder Shortcut  
Open Finder at user home.

4. Terminal Shortcut  
Open Terminal quickly.

5. Volume Slider  
Single volume tool with slider and live percentage display (0–100%) in the tool window.

### Productivity Tools

1. Clipboard History  
Tracks last copied plain-text entries; click an item to copy it back.

2. QR Code Generator  
Generates high-contrast QR from typed text/URL.

3. Network Latency Checker  
Manual “Check Now” ping test with status color and ms result.

4. Date Utility  
Two modes:
- Difference: days left until selected future date
- Add: exact date after N days

5. Quick Timer  
Preset timers (5/15/25 min), countdown display, cancel, completion beep + local notification.

6. Sticky Note (Scratchpad)  
Persistent `TextEditor` using `@AppStorage("scratchpad_text")`, with Copy All and Clear.

7. Screen Ruler  
Semi-transparent draggable/resizable rectangle with live width/height in pixels, show/hide toggle, and size controls.

8. Decision Maker  
Coin Flip and Dice Roll with simple animation + sound feedback.

9. Image Converter (Drag & Drop)  
Drop image, convert to JPEG (quality 0.8), save to Downloads, show success message.

10. Clipboard Text Stats  
Reads clipboard text and shows:
- Character Count
- Word Count
- Sentence Count
- Estimated Read Time (200 wpm)

11. Floating Reference Image  
Drop image into tool, opens a separate floating reference window (borderless, draggable/resizable, right-click to close).

## Customization

Inside the orb panel, open **Customize Actions** to:

- Enable/disable each tool
- Reorder tool buttons
- Persist layout across launches

## Permissions and Technical Difficulty (Important)

macOS permissions for utility apps are strict and intentionally user-controlled.

1. Automation (`NSAppleEventsUsageDescription`)  
Required for AppleScript-driven operations (for example appearance toggling via `System Events`).  
Challenge: macOS may deny scripts silently until permission is granted in Privacy settings.

2. Notifications (`UNUserNotificationCenter`)  
Used by Quick Timer completion alerts.  
Challenge: user can block notifications; app must gracefully continue with sound fallback.

3. Why this is hard technically  
- Permissions are asynchronous and stateful (`notDetermined`, `denied`, `authorized`, etc.).
- Apps cannot forcibly grant themselves access.
- Some capabilities depend on OS internals and can change across macOS versions.
- Reliable UX requires fallback behavior, error messaging, and re-checking permission state.

## Project Structure

Main app source is under:

`floating orb/floating orb/`

Key files:

- `floating_orbApp.swift` - app entry + panel bootstrap
- `FloatingPanel.swift` - floating transparent panel configuration
- `FloatingPanelModifier.swift` - drag behavior for panel window
- `ContentView.swift` - orb UI, tool routing, customization page
- `ActionStore.swift` - action model, defaults, migration, persistence
- `SystemActionManager.swift` - system action execution layer

Tool modules:

- `ClipboardManager.swift`
- `ClipboardStatsView.swift`
- `QRCodeView.swift`
- `LatencyMonitor.swift`
- `DateUtilityView.swift`
- `QuickTimerView.swift`
- `StickyNoteView.swift`
- `ScreenRulerView.swift`
- `DecisionMakerView.swift`
- `ImageConverterView.swift`
- `FloatingReferenceImageView.swift`

## Run

1. Open `floating orb/floating orb.xcodeproj` in Xcode.
2. Select scheme `floating orb`.
3. Run on **My Mac**.
4. Grant requested permissions when prompted.

## Notes

- This app intentionally uses an agent-style floating window workflow rather than a standard docked app UI.
- Some system-facing features may behave differently across macOS versions due to platform restrictions.
