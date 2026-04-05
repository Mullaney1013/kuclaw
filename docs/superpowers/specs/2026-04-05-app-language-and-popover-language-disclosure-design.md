# App Language And Popover Language Disclosure Design

## Goal

Add an app-wide language system for Kuclaw and extend the existing
`Settings Popover` so its `Language` row becomes an inline disclosure group that
can immediately switch the entire app between:

- `English (United States)`
- `中文（中国）`

This is a full app i18n phase, not just a popover interaction tweak.

## Scope

### In scope

- Add a real app-wide language preference with persistence.
- On first launch, default to the system language when it matches one of the
  supported languages.
- Support exactly these two locales:
  - `en_US`
  - `zh_CN`
- Make existing user-visible app copy translatable through the Qt translation
  system.
- Load and switch translators at runtime without requiring app restart.
- Extend `Settings Popover` so `Language` becomes an inline disclosure section.
- Show a trailing checkmark for the active language.
- Keep the popover open after language selection and keep the disclosure group
  expanded so the user can confirm the newly selected option.
- Refresh already-visible pages, including the existing Settings page, after a
  language change.

### Out of scope

- Additional languages beyond English and Simplified Chinese.
- Right-to-left language support.
- Advanced locale-specific formatting for time, currency, or region data.
- `Rate limits remaining` navigation.
- `Log out` behavior.
- New settings-page IA or layout changes unrelated to language switching.

## Current Context

The repository currently has:

- an approved phase-one and phase-two `Settings Popover`
- an existing full-page `SettingsPanel`
- `SettingsManager`, already used for persisted app settings
- many hard-coded QML strings, and no app-wide translator bootstrap yet

This phase introduces the missing translation infrastructure and wires the
popover disclosure interaction into it.

## Supported Languages

### Locale identifiers

- `English (United States)` → `en_US`
- `中文（中国）` → `zh_CN`

These locale codes are the only persisted values accepted in this phase.

### First-launch default

- On first launch, Kuclaw inspects the system locale.
- If the system locale resolves to Simplified Chinese for mainland China, the
  initial app language is `zh_CN`.
- Otherwise, the initial app language is `en_US`.

### After user choice

- Once the user manually selects a language, Kuclaw persists that explicit
  preference.
- Future launches use the saved value instead of re-following the system.

## Runtime Language Architecture

### Persistence

Use the existing `SettingsManager` to persist the app language under a dedicated
key:

- `app/language`

The persisted value is always one of:

- `en_US`
- `zh_CN`

### Translator ownership

Introduce a dedicated language owner at app level that is responsible for:

- resolving the initial locale
- loading the matching translation resources
- installing and replacing `QTranslator`
- exposing current language state to QML
- updating the persisted preference after user selection

This owner should sit above page-level UI so all loaded views share one source
of truth.

### Translation format

Use Qt’s native translation system:

- QML strings use `qsTr(...)`
- C++ user-facing strings use `tr(...)`
- translation source files live under a dedicated `translations/` directory

Expected translation assets:

- `translations/kuclaw_en_US.ts`
- `translations/kuclaw_zh_CN.ts`

Generated `.qm` files should be bundled into the app so runtime switching works
without external files.

## Language Switching Behavior

### Immediate application

Selecting a language in the popover should:

1. update the app-level language state
2. replace the installed translator immediately
3. persist the selected locale
4. refresh visible UI text without restart

This includes:

- the popover itself
- the current page, if already open
- the Settings page, if visible
- existing sidebar labels and other loaded shell text

### No-op reselection

If the user clicks the language that is already active:

- Kuclaw should not rewrite the preference redundantly
- no extra translator swap is needed
- the popover stays open and expanded as-is

## Settings Popover Disclosure Behavior

### Closed state

The `Language` row appears in the existing popover as a normal action row with:

- the language icon on the left
- the localized `Language` label
- a right-facing chevron on the far right

### Open state

When the user clicks `Language`:

- the row expands inline
- the right chevron rotates downward
- the popover height grows smoothly
- rows below (`Rate limits remaining`, `Log out`) are pushed down naturally

The expanded sub-list contains exactly:

- `中文（中国）`
- `English (United States)`

Each sub-row:

- is indented to show hierarchy
- is individually clickable
- shows a trailing checkmark on the currently active language

### Repeat interaction

- Clicking `Language` while collapsed expands it.
- Clicking `Language` while expanded collapses it.

### After selecting a language

After clicking one of the language options:

- the app switches language immediately
- the popover remains open
- the `Language` group remains expanded
- the trailing checkmark moves to the newly selected language

This gives immediate visual confirmation of the new state.

## Animation Guidance

The popover should stay visually close to native macOS menu behavior:

- short animation duration, approximately `140–180ms`
- easing such as `OutCubic`
- no exaggerated bounce or spring

Animated elements:

- language chevron rotation
- popover height change
- push-down of lower menu rows

## Component Responsibilities

### `SettingsPopover.qml`

Responsibilities:

- render the static popover container and menu rows
- own the `Language` disclosure visual state
- emit semantic actions for:
  - `settingsClicked()`
  - `languageToggled()`
  - `languageSelected(localeCode)`
  - existing deferred row signals

The component remains presentation-first; it should not directly install
translators or own persistence.

### App-level language owner

Responsibilities:

- determine current locale
- expose current locale to QML
- apply translator changes
- persist language changes

### `AppShell.qml`

Responsibilities:

- wire the popover’s language actions to the app-level language owner
- keep existing phase-two popover entry behavior unchanged
- reflect updated strings after translator changes

### `SettingsManager`

Responsibilities:

- persist and retrieve `app/language`

## Translation Coverage Expectations

This phase should cover existing user-visible app copy, not just the popover.

At minimum that includes:

- shell and sidebar labels
- `SettingsPopover`
- `SettingsPanel`
- capture overlays and toolbars
- pinboard panel
- recent color panel
- other currently surfaced hard-coded UI strings already present in QML

This phase does not need to translate developer-only logs or internal object
names.

## Testing Strategy

Add focused tests that prove:

- first-launch language falls back to system language for supported locales
- saved `app/language` overrides the system locale on later launches
- changing language updates the active locale immediately
- the `Language` row expands and collapses inline
- the active language row shows the checkmark
- selecting a new language keeps the popover open and expanded
- visible Settings content updates after language change

Keep the existing phase-two popover tests and extend them rather than replacing
them.

## Risks

- This is the first full translation pass in the repo, so missed hard-coded
  strings are likely if extraction is done piecemeal.
- Runtime translator swapping can look broken if some QML strings are still
  literal text instead of `qsTr(...)`.
- If translator ownership is buried too low in the UI tree, page refreshes will
  become inconsistent.
- The disclosure animation must not disturb the already-approved popover
  placement and dismissal behavior.

## Recommended Delivery Shape

Treat this as a dedicated app-i18n subproject with the popover disclosure built
on top of it:

1. add language state + translator bootstrap
2. wire persistence and first-launch locale resolution
3. translate current UI copy
4. add `Language` inline disclosure in the popover
5. connect disclosure selection to real language switching

This order reduces the risk of building a language picker before the app can
actually change languages.
