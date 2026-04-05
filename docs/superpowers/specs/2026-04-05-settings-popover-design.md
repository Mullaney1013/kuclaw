# Settings Popover Design

## Goal

Add a first-phase `Settings Popover` to the main workspace shell.

When the user clicks the expanded sidebar `Settings` button at the bottom of the
left sidebar, Kuclaw should open a floating popover directly above that button.
The popover should visually match the approved reference: rounded white surface,
soft shadow, thin separators, top account summary, and a vertical list of menu
items.

This phase only establishes the popover shell and its initial menu structure.
It does not yet implement nested language expansion or route the popover's
`Settings` row into the full Settings page.

## Scope

### In scope

- Add a reusable `SettingsPopover.qml` component under `qml/app/`.
- Open the popover from the expanded sidebar bottom `Settings` row in
  `AppShell.qml`.
- Position the popover directly above the trigger button, aligned to the left
  content edge of the button.
- Keep the trigger button in an active/highlighted state while the popover is
  open.
- Render the following static sections:
  - account summary
  - `Settings`
  - `Language`
  - `Rate limits remaining`
  - `Log out`
- Use the provided icons:
  - `assets/icons/language.svg`
  - `assets/icons/rate-limits-remaining.svg`
  - `assets/icons/log-out.svg`
- Close behavior:
  - click outside closes
  - `Esc` closes

### Out of scope for this phase

- `Language` inline disclosure expansion
- current-language checkmark
- clicking popover `Settings` to enter the main Settings / Preferences screen
- collapsed sidebar `settingsIcon` opening the same popover
- submenu navigation for `Rate limits remaining`
- real logout flow

These remain future phases after the static popover structure is accepted.

## Current Context

The current workspace shell already has:

- an expanded sidebar bottom `Settings` trigger:
  - `settingsRow` in `qml/app/AppShell.qml`
- a collapsed rail `settingsIcon`
- an existing full-page `SettingsPanel` shown when `currentPage === "settings"`

The first-phase popover sits in front of the existing shell and does not replace
the full settings page yet.

## UX Behavior

### Trigger

- Trigger source: expanded sidebar bottom `Settings` row only.
- Click on the row opens the popover instead of directly switching
  `currentPage` to `"settings"`.

### Placement

- The popover opens directly above the trigger row.
- The popover should appear visually anchored to the same left column as the
  row content rather than centered on the whole app window.
- A small vertical gap is acceptable so the popover reads as detached and
  floating, but it should still feel visually tied to the trigger.

### Trigger active state

- While the popover is open, the trigger row should keep the same shallow
  highlighted background used for an active state.
- This highlight is tied to popover visibility, not page selection.

### Dismissal

- Clicking outside the popover closes it.
- Pressing `Esc` closes it.
- Clicking the trigger again closes it.

## Visual Structure

### Container

- white background
- rounded corners in the existing shell language, approximately `10-12px`
- soft macOS-like shadow
- subtle border only if needed for edge definition

### Top account section

- two vertically stacked text rows:
  - `sinobec1013@gmail.com`
  - `Personal account`
- muted secondary text styling for the account type
- compact, quiet visual tone

### Core actions section

- row 1: `Settings` with settings icon
- row 2: `Language` with `language.svg`
- row 3: `Rate limits remaining` with `rate-limits-remaining.svg`

For this phase these rows are static menu rows only. They should look
interactive, but their advanced behaviors are deferred.

### Bottom actions section

- row 1: `Log out` with `log-out.svg`

### Separators

- one faint separator below the account section
- one faint separator above the logout section

## Interaction Model for This Phase

### Row behavior

- Rows respond to hover with a subtle background change.
- Cursor is pointer/hand for actionable rows.
- No submenu or disclosure animation is implemented in this phase.

### Click behavior for this phase

- `Settings` row: no navigation yet.
- `Language` row: no expansion yet.
- `Rate limits remaining` row: no navigation yet.
- `Log out` row: no logout flow yet.

All rows in phase one are visual-only action rows:

- they support hover styling
- they show pointer cursor
- they do not trigger navigation, disclosure, logout, or dismissal

The only ways to close the phase-one popover are:

- clicking outside
- pressing `Esc`
- clicking the trigger button again

## Component Structure

### `qml/app/SettingsPopover.qml`

Responsibilities:

- render the floating surface
- render account info and menu rows
- expose row-click signals for future phases
- expose `open` / `close` state through `Popup`

Suggested public API:

- `property string email`
- `property string accountLabel`
- `signal settingsClicked()`
- `signal languageClicked()`
- `signal rateLimitsClicked()`
- `signal logOutClicked()`

The signals can exist now even if most are not yet consumed. This keeps the
component ready for phase two without forcing implementation in phase one.

### `qml/app/AppShell.qml`

Responsibilities in this phase:

- own the single popover instance
- anchor it relative to `settingsRow`
- toggle it on trigger click
- keep the trigger row visually highlighted while open
- close it when clicking outside or pressing `Esc`

## Implementation Notes

- Use `Popup` from `QtQuick.Controls` rather than a custom free-floating `Item`.
  This gives us built-in outside-click and escape handling, plus a cleaner path
  for future interaction states.
- Keep the popover inside `AppShell.qml`'s top-level visual tree so it can float
  above both the sidebar and content area.
- Avoid wiring this phase into `root.currentPage`. The popover should be a shell
  overlay, not a page selection.
- Preserve current shell styling language by sourcing spacing and radii from
  `WorkspaceShellStyles.js` where practical, while allowing a small set of new
  popover-specific constants if needed.

## Testing Strategy

Add focused QML tests that prove:

- clicking expanded `Settings` opens the popover
- clicking expanded `Settings` again closes it
- popover appears above the trigger row
- trigger row stays visually active while popover is open
- `Esc` closes the popover
- click outside closes the popover

Do not write phase-two tests yet for inline language expansion or settings-page
navigation.

## Risks

- The expanded sidebar `Settings` row currently uses `selectionEnabled: false`,
  so its active visual state is not page-driven. The popover-open highlight must
  be layered in explicitly without breaking existing hover behavior.
- Positioning can become brittle if hardcoded against the whole window. The
  implementation should anchor to `settingsRow` geometry, not general sidebar
  guesses.
- If future collapsed-rail support is added, the component should be reusable
  rather than cloned.

## Future Phases

### Phase 2

- clicking popover `Settings` opens the full `SettingsPanel`
- `Language` becomes an inline disclosure group
- current language shows a trailing checkmark

### Phase 3

- `Rate limits remaining` opens its dedicated destination
- `Log out` performs a real logout flow
- collapsed `settingsIcon` can reuse the same popover
