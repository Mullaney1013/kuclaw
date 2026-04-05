# Settings Popover Phase Two Design

## Goal

Extend the approved `Settings Popover` so that clicking its `Settings` row
closes the popover and enters Kuclaw's existing global `Settings /
Preferences` page.

This phase also brings the collapsed sidebar `settingsIcon` onto the same
popover entry path so both sidebar variants open the same menu.

## Scope

### In scope

- Keep the existing phase-one `Settings Popover` layout and dismissal behavior.
- Allow both sidebar entry points to open the same popover pattern:
  - expanded sidebar bottom `Settings` row
  - collapsed rail `settingsIcon`
- Clicking the `Settings` row inside the popover should:
  - close the popover
  - switch the shell to the existing full `Settings / Preferences` page
- Once the main `Settings` page is open:
  - the expanded sidebar bottom `Settings` button remains highlighted as the
    current page
  - both the expanded and collapsed sidebar settings triggers can still reopen
    the popover

### Out of scope for this phase

- `Language` inline disclosure expansion
- current-language checkmark
- `Rate limits remaining` navigation
- `Log out` behavior
- changing the visual structure of the popover
- changing the layout or semantics of the existing `SettingsPanel`

## Current Context

The current shell already has:

- a phase-one static `Settings Popover` above the expanded sidebar bottom
  `Settings` trigger
- a collapsed rail `settingsIcon`
- an existing full-page `SettingsPanel` shown when `currentPage === "settings"`

Right now:

- the expanded sidebar bottom trigger opens the popover
- popover rows are visual-only
- the collapsed rail icon still goes directly through its existing page route

This phase keeps the popover visuals intact and only extends the interaction
model.

## UX Behavior

### Sidebar entry points

- Expanded sidebar:
  - clicking the bottom `Settings` trigger opens the popover
- Collapsed sidebar:
  - clicking the `settingsIcon` opens the same popover pattern

Both entry points should feel like two presentations of the same shell control,
not two different features.

### Popover behavior

- The popover keeps the same placement style:
  - opens directly above the trigger
  - left-aligned to the trigger's content column
- The trigger that opened the popover stays visually active while the popover is
  open.
- Dismissal remains unchanged:
  - click outside closes
  - `Esc` closes
  - clicking the same trigger again closes

### `Settings` row behavior

- Clicking the popover's `Settings` row should:
  1. close the popover
  2. enter the existing global `Settings / Preferences` page

This action should not open a second popover, a nested sheet, or a new window.

### Highlighting after navigation

- After entering the main `Settings` page:
  - the expanded sidebar bottom `Settings` trigger remains highlighted as the
    currently selected destination
- When the user later clicks either sidebar settings trigger again:
  - the popover should still open
  - this is allowed even if the current page is already `settings`

## Interaction Model

### Signal flow

The popover remains presentation-focused and emits semantic action signals.

- `SettingsPopover.qml` emits `settingsClicked()`
- `AppShell.qml` consumes that signal and owns the page switch
- Sidebar entry controls only request “open/close popover”; they do not own page
  routing

This keeps page navigation in the shell and avoids coupling the popover
component directly to full-page content.

### Shared entry semantics

Both sidebar entry points should converge on the same popover-opening behavior:

- same content
- same dismissal rules
- same `Settings` row action

They may use different geometry anchors, but they should not diverge in
business behavior.

## Component Responsibilities

### `qml/app/SettingsPopover.qml`

Keeps responsibility for:

- rendering the popover surface
- exposing semantic signals for row actions

New behavior in this phase:

- the `Settings` row is no longer visual-only
- it emits `settingsClicked()` when activated

Deferred rows remain non-operative for now:

- `Language`
- `Rate limits remaining`
- `Log out`

### `qml/app/AppShell.qml`

Owns:

- `currentPage`
- full settings page routing
- popover close-then-navigate behavior
- selection/highlight rules after page changes
- the collapsed rail `settingsIcon` integration

### Expanded / collapsed sidebar triggers

The sidebar triggers stay lightweight:

- they open/close the popover
- they reflect active state
- they do not directly own full-page settings navigation

## Testing Strategy

Add focused QML tests that prove:

- expanded sidebar `Settings` still opens the popover
- collapsed rail `settingsIcon` opens the popover
- clicking the popover `Settings` row closes the popover and switches to the
  settings page
- when already on the settings page, both triggers can still reopen the popover
- the expanded sidebar bottom `Settings` trigger remains highlighted while the
  settings page is active

Do not add phase-three tests yet for:

- `Language` disclosure
- `Rate limits remaining` routing
- `Log out`

## Risks

- The existing expanded sidebar popover trigger is already implemented through a
  dedicated helper component, while the collapsed rail icon still uses the
  page-key route. This phase must unify the behavior without regressing current
  page selection visuals.
- The expanded trigger highlight now needs to represent two states cleanly:
  - popover open
  - settings page selected
  These should not conflict or flicker during close-then-navigate transitions.
