# 2026-04-04 macOS Menu Bar Icon Design

## Scope

- Platform: macOS only
- Surface: Menu Bar Extras in the system menu bar
- Source asset: `assets/icons/icon.icns` only

## Current Product Goal

- Kuclaw shows a native macOS status item in the system menu bar.
- The menu bar icon is derived from `icon.icns`.
- We do not maintain a second dedicated menu-bar SVG or PNG source.

## AppKit Requirements We Need To Respect

### 1. Use a template image

For a status item in the macOS menu bar, the image should behave like a template image so AppKit can tint it appropriately for light and dark menu bar appearances.

Implementation rule:

- Mark the final `NSImage` as a template image.
- The rendered glyph should be black + transparent before AppKit applies menu bar tinting.

### 2. Render for the menu bar slot, not for app-icon usage

`icon.icns` is an app icon source, not a ready-to-use menu bar glyph. It needs to be re-rendered for the menu bar slot.

Implementation rule:

- Keep `icon.icns` as the only source asset.
- Generate a menu bar–specific template image from that source at runtime.

### 3. Respect AppKit point size and screen backing scale

The menu bar slot is point-sized, but the actual raster shown on screen must match the current backing scale to remain crisp on Retina displays.

Implementation rule:

- Treat the menu bar slot as a `22pt x 22pt` logical canvas.
- Rasterize at `22pt * backingScaleFactor` pixels.
- Store the resulting `NSImage` with a logical size of `22pt x 22pt`.

### 4. Keep the glyph simple and legible at tiny size

The menu bar icon must survive tiny display sizes. Full-color detail, soft alpha edges, and app-icon styling reduce legibility.

Implementation rule:

- Convert the derived menu bar image to a monochrome template glyph.
- Prefer crisp alpha thresholds over soft, blurry masks.
- Preserve enough inner padding so the glyph does not feel cramped inside the status item slot.

## Chosen Implementation

### Runtime pipeline

1. Load `assets/icons/icon.icns` using native AppKit `NSImage`.
2. Rasterize the icon into a menu bar canvas sized for the current screen backing scale.
3. Convert the rasterized result into a black + transparent template glyph.
4. Wrap that raster in an `NSImage` whose logical size remains `22pt x 22pt`.
5. Set the result on `NSStatusItem.button.image`.

### Why this approach

- Keeps `icon.icns` as the only source of truth.
- Avoids Qt `.icns` parsing issues in the macOS status-item path.
- Produces a native AppKit template image suitable for menu bar tinting.
- Allows sharper rendering on Retina displays than a fixed 1x raster.

## Code Ownership

- Runtime rendering: `src/core/tray/MacStatusItemBackend.mm`
- Tray manager setup: `src/core/tray/TrayManager.cpp`
- Resource bundling: `apps/kuclaw-desktop/CMakeLists.txt`
- Verification: `tests/cpp/tst_tray_manager.cpp`

## Verification Expectations

### Automated checks

- `kuclaw_tray_manager_tests` should verify:
  - `icon.icns` exists
  - the native backend produces a renderable `NSImage`
  - the image is marked as a template image
  - the logical menu bar image size is `22pt x 22pt`
  - the generated glyph remains legible at menu bar scale

### Manual checks

- The menu bar extra is visible in the system menu bar.
- The icon is crisp enough to read at a glance.
- The status item remains visible on dark and light menu bars.
- Clicking the item still opens the expected Kuclaw menu/actions.

## Explicitly Removed / Outdated

The following older approach is no longer current and should not be reintroduced without a new decision:

- Using `assets/icons/menu-bar.svg` as a dedicated macOS menu bar source
- Depending on Qt icon loading/parsing for the macOS `.icns` status-item path
- Treating a fixed 1x raster as sufficient for Retina menu bar rendering
