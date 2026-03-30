# macOS Native Traffic Lights Integration Design

Date: 2026-03-30
Project: Kuclaw desktop shell
Scope: Replace self-drawn macOS traffic lights in the Qt/QML workspace shell with native NSWindow controls while preserving the approved Figma shell layout.

## Goal

Use the real macOS window controls for close, minimize, and zoom instead of maintaining a custom QML imitation. The workspace shell should keep the approved visual structure:

- the left toolbar/sidebar region uses the sidebar gray shell color
- the main content region remains a white canvas
- the title area visually blends into both regions
- the native traffic lights remain visible and usable in the top-left corner

This work is intentionally limited to macOS window chrome integration. It does not redesign the Windows shell or re-open the earlier workspace-content experiments.

## User-facing outcome

On macOS, Kuclaw will behave like a native desktop app:

- the standard red, yellow, and green window controls come from the system
- hover, inactive, Option-key zoom, disabled states, and dirty-state behavior are owned by macOS rather than reimplemented in QML
- the custom shell still appears edge-to-edge and modern, with content visually extending into the title-bar zone
- the sidebar toggle remains visible in the global toolbar, positioned to the right of the native traffic lights

## Non-goals

This design does not include:

- custom drawing of the six traffic-light states in production code
- a Windows equivalent native chrome redesign
- adding extra toolbar actions beyond the existing sidebar toggle and navigation controls
- changing the approved sidebar state machine beyond what is needed to leave space for native controls

## Current problem

The current shell uses a custom title bar in QML. This creates two issues:

1. The traffic lights are not genuinely native.
2. The shell must manually simulate behavior that macOS already provides.

That approach conflicts with the approved design direction. In Figma, the traffic lights are a layout reference; in the running app, they should come from the system.

## Recommended approach

Use a hybrid implementation:

- QML continues to render the shell layout and page content.
- Objective-C++ configures the underlying `NSWindow`.
- The native macOS buttons remain present and are visually integrated into the QML shell.

This is the most stable approach because it lets macOS keep ownership of control states and behaviors while Qt/QML remains responsible for the app chrome and layout.

## Architecture

### QML responsibilities

`AppShell.qml` should:

- reserve a left-side safe area for the native traffic lights
- place the sidebar toggle immediately to the right of that safe area
- treat the remaining top strip as part of the shell layout
- avoid rendering fake traffic-light circles on macOS

The rest of the approved shell remains in QML:

- collapsed / hover rail / expanded sidebar states
- left gray shell region
- right white content region
- placeholder content or future content pages

### Native macOS responsibilities

A macOS-specific window chrome adapter should:

- obtain the native `NSWindow` that backs the Qt window
- hide the title text
- make the title bar appear transparent
- allow content to extend into the title-bar area
- preserve the native traffic lights
- reposition them if needed so they align with the approved shell spacing

This adapter should live in the platform integration layer, not in shared business logic.

## Proposed implementation shape

### New platform adapter

Add a macOS-only helper, for example:

- `src/integration/platform/MacWindowChrome.h`
- `src/integration/platform/MacWindowChrome.mm`

Its public role is small:

- accept a `QWindow*`
- configure native title-bar behavior
- expose or apply layout metrics needed by QML, such as traffic-light inset and title-bar safe-area width

### QML integration boundary

`AppShell.qml` should not directly call Cocoa APIs. Instead, QML receives a small set of already-decided metrics or booleans, for example:

- `usesNativeMacTrafficLights`
- `macTrafficLightsInsetLeft`
- `macTrafficLightsSafeWidth`
- `macTitleBarHeight`

These can be provided via an existing coordinator/view-model bridge or a dedicated lightweight window-chrome bridge.

### Existing title bar controls

On macOS:

- remove or hide the self-drawn traffic lights
- keep the sidebar toggle
- keep back/forward controls if they remain part of the shell
- ensure the drag region excludes the native traffic-light zone and the remaining interactive controls

On non-macOS platforms:

- retain the current custom title-bar strategy until a platform-specific redesign is needed

## Layout rules

### Title-bar safe area

Reserve a safe area in the top-left of the shell for the native traffic lights. Initial layout guidance:

- safe-area height: approximately 30 to 36 px
- safe-area width: enough for the three native controls plus native spacing and a small right buffer

The exact width should come from measurement or a stable constant after validating against the native layout.

### Sidebar top region

The sidebar background may visually extend to the top edge, but its content must not collide with the traffic lights. The first navigational content row should begin below the safe area.

### Sidebar toggle placement

The sidebar toggle stays in the global toolbar and must appear immediately to the right of the native traffic lights safe area. It should remain visible even when the sidebar is collapsed.

## State behavior

The system, not QML, owns the traffic-light states:

- active/focused
- hover
- inactive/unfocused
- disabled fullscreen
- Option-modified zoom
- dirty-state indicator

QML only ensures enough room and correct visual integration around them. The Figma `macOS Traffic Lights Spec` remains a design artifact and implementation reference, not a production asset source.

## Error handling and fallbacks

If native chrome configuration fails for any reason:

- the app should fall back to the current custom title-bar behavior rather than becoming unusable
- the fallback should be limited to macOS startup/runtime failure cases
- failures should be logged clearly in development builds

This keeps the app launchable while we stabilize native integration.

## Testing strategy

### Manual verification on macOS

Verify:

- the app window opens with real native traffic lights
- the title text is hidden
- content visually extends into the title-bar area
- the sidebar toggle remains visible and clickable
- hover and inactive states match native macOS behavior
- the traffic lights do not overlap sidebar content
- moving between focused and unfocused windows changes the controls naturally

### Regression checks

Keep existing QML tests for shell state and title-bar interactions. Add focused checks where practical for:

- safe-area spacing logic
- macOS-only visibility toggles for custom versus native controls

## Risks

### Native pointer access

The exact Qt-to-`NSWindow` access path depends on the current Qt 6 setup and available native interfaces. This is manageable, but should be validated before large-scale QML changes.

### Layout drift

If the safe-area width is guessed instead of measured against native control placement, the sidebar toggle may drift too close to the traffic lights. This should be solved by using a stable metric path rather than trial-and-error constants wherever possible.

### Drag-region conflicts

If the title-bar drag region is not carefully bounded, clicks near the native controls or sidebar toggle may accidentally drag the window. This must be explicitly guarded.

## Implementation order

1. Add the macOS window chrome adapter and prove it can access/configure the native `NSWindow`.
2. Enable transparent/full-size content title-bar behavior while preserving the native traffic lights.
3. Feed title-bar safe-area metrics into QML.
4. Update `AppShell.qml` to reserve space and hide the fake traffic lights on macOS.
5. Reposition the sidebar toggle and confirm shell spacing matches the approved Figma design.
6. Manually validate focus/hover/native control behavior on macOS.

## Decision

Kuclaw should use native macOS traffic lights in the running app, while continuing to use Figma traffic-light states only as design and implementation reference material.
