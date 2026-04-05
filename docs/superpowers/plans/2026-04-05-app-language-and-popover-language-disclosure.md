# App Language And Popover Language Disclosure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add app-wide runtime language switching for `English (United States)` and `中文（中国）`, persist the selected language, default first launch to the system language, and turn the `Settings Popover` `Language` row into an inline disclosure group that switches the entire app immediately.

**Architecture:** Introduce one app-level language owner above the QML shell that resolves the initial locale, installs and swaps `QTranslator`, and persists `app/language` through `SettingsManager`. Convert existing user-facing QML and C++ strings to Qt translation primitives, then wire `SettingsPopover.qml` to expose inline language-disclosure actions while `AppShell.qml` binds those actions to the shared language owner.

**Tech Stack:** Qt 6, Qt Quick / Qt Quick Controls, QTranslator, QLocale, QSettings via `SettingsManager`, QML tests with `qmltestrunner`, desktop build integration in CMake.

---

## File Map

- **Create:** `/Users/Y/Documents/kuclaw/src/core/i18n/AppLanguageManager.h`
  - App-level language owner API for current locale, first-launch resolution, and runtime translator switching.
- **Create:** `/Users/Y/Documents/kuclaw/src/core/i18n/AppLanguageManager.cpp`
  - Implements locale resolution, translator installation, persistence, and supported-language metadata.
- **Create:** `/Users/Y/Documents/kuclaw/src/ui_bridge/viewmodels/AppLanguageViewModel.h`
  - QML-facing adapter exposing current language, supported languages, and selection methods.
- **Create:** `/Users/Y/Documents/kuclaw/src/ui_bridge/viewmodels/AppLanguageViewModel.cpp`
  - Bridges the app-level language owner to QML signals and invokables.
- **Create:** `/Users/Y/Documents/kuclaw/tests/cpp/tst_app_language_manager.cpp`
  - C++ tests for locale resolution, persistence override, and translator swapping.
- **Create:** `/Users/Y/Documents/kuclaw/translations/kuclaw_en_US.ts`
  - English source translation catalog.
- **Create:** `/Users/Y/Documents/kuclaw/translations/kuclaw_zh_CN.ts`
  - Simplified Chinese translation catalog.
- **Modify:** `/Users/Y/Documents/kuclaw/src/core/settings/SettingsManager.h`
  - Add typed helpers for `app/language` retrieval and persistence.
- **Modify:** `/Users/Y/Documents/kuclaw/src/core/settings/SettingsManager.cpp`
  - Implement typed language getter/setter helpers.
- **Modify:** `/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/app/ApplicationCoordinator.h`
  - Own the app language manager and view model.
- **Modify:** `/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/app/ApplicationCoordinator.cpp`
  - Construct the language manager/view model and expose them.
- **Modify:** `/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/main.cpp`
  - Expose the language view model to QML and ensure translator bootstrap runs before the main shell loads.
- **Modify:** `/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt`
  - Compile the new i18n sources, register translation assets, and include any required Qt translation tooling.
- **Modify:** `/Users/Y/Documents/kuclaw/qml/app/SettingsPopover.qml`
  - Add inline disclosure state and language selection UI while keeping approved phase-one layout language.
- **Modify:** `/Users/Y/Documents/kuclaw/qml/app/AppShell.qml`
  - Wire popover language actions to the shared language view model and update hard-coded shell strings to `qsTr(...)`.
- **Modify:** `/Users/Y/Documents/kuclaw/qml/app/ExpandedSidebarSettingsPopover.qml`
  - Translate the visible `Settings` label through `qsTr(...)`.
- **Modify:** `/Users/Y/Documents/kuclaw/qml/app/WorkspaceSidebarItems.js`
  - Replace hard-coded sidebar titles with a translator-friendly generation path.
- **Modify:** `/Users/Y/Documents/kuclaw/qml/settings/SettingsPanel.qml`
  - Translate visible settings-page copy through `qsTr(...)`.
- **Modify:** `/Users/Y/Documents/kuclaw/qml/settings/RecentColorPanel.qml`
  - Translate current visible strings.
- **Modify:** `/Users/Y/Documents/kuclaw/qml/pin/PinboardPanel.qml`
  - Translate visible strings.
- **Modify:** `/Users/Y/Documents/kuclaw/qml/capture/CaptureOverlayWindow.qml`
  - Translate window title.
- **Modify:** `/Users/Y/Documents/kuclaw/qml/capture/CaptureOverlay.qml`
  - Translate visible instructional copy.
- **Modify:** `/Users/Y/Documents/kuclaw/qml/capture/CaptureToolbar.qml`
  - Translate visible action labels.
- **Modify:** `/Users/Y/Documents/kuclaw/qml/capture/Magnifier.qml`
  - Translate visible strings.
- **Modify:** `/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml`
  - Extend popover tests for language disclosure, checkmark state, and selection behavior.
- **Modify:** `/Users/Y/Documents/kuclaw/PRD.md`
  - Sync app-wide language behavior after verification passes.

## Constraints To Preserve

- Only support `en_US` and `zh_CN` in this phase.
- First launch follows the system language only when no explicit saved preference exists.
- Once the user chooses a language, saved preference wins on later launches.
- Keep the existing phase-two `Settings Popover` entry behavior unchanged.
- `Language` selection must keep the popover open and the disclosure expanded.
- Do not implement `Rate limits remaining` or `Log out` behavior in this phase.

## Task 1: Add Typed Language Persistence To SettingsManager

**Files:**
- Modify: `/Users/Y/Documents/kuclaw/src/core/settings/SettingsManager.h`
- Modify: `/Users/Y/Documents/kuclaw/src/core/settings/SettingsManager.cpp`
- Test: `/Users/Y/Documents/kuclaw/tests/cpp/tst_app_language_manager.cpp`

- [ ] **Step 1: Write the failing persistence test**

Create `/Users/Y/Documents/kuclaw/tests/cpp/tst_app_language_manager.cpp` with:

```cpp
#include <QtTest>

#include "core/settings/SettingsManager.h"

class AppLanguageManagerTest final : public QObject {
    Q_OBJECT

private slots:
    void settingsManagerPersistsExplicitLanguage() {
        SettingsManager settings;
        settings.clearForTesting();

        QCOMPARE(settings.appLanguage().isEmpty(), true);

        settings.setAppLanguage(QStringLiteral("zh_CN"));
        QCOMPARE(settings.appLanguage(), QStringLiteral("zh_CN"));

        settings.setAppLanguage(QStringLiteral("en_US"));
        QCOMPARE(settings.appLanguage(), QStringLiteral("en_US"));
    }
};

QTEST_MAIN(AppLanguageManagerTest)
#include "tst_app_language_manager.moc"
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
cmake --build /Users/Y/Documents/kuclaw/build --target kuclaw_desktop -j 4
```

Expected:
- build fails because `SettingsManager` does not provide `appLanguage`, `setAppLanguage`, or `clearForTesting`

- [ ] **Step 3: Add the minimal typed API**

Update `/Users/Y/Documents/kuclaw/src/core/settings/SettingsManager.h`:

```cpp
class SettingsManager final : public QObject {
    Q_OBJECT
public:
    explicit SettingsManager(QObject* parent = nullptr);

    QVariant value(const QString& key, const QVariant& defaultValue = {}) const;
    void setValue(const QString& key, const QVariant& value);

    QString appLanguage() const;
    void setAppLanguage(const QString& localeCode);
    void clearForTesting();

    QKeySequence captureHotkey() const;
    QKeySequence pinHotkey() const;
    bool keepCurrentWindowOnCapture() const;
    bool magnifierEnabled() const;
    QString defaultColorFormat() const;
    QString defaultSaveDirectory() const;
    int closedPinRestoreLimit() const;

private:
    QSettings settings_;
};
```

Update `/Users/Y/Documents/kuclaw/src/core/settings/SettingsManager.cpp`:

```cpp
namespace {
constexpr auto kAppLanguageKey = "app/language";
}

QString SettingsManager::appLanguage() const {
    return value(QString::fromLatin1(kAppLanguageKey)).toString();
}

void SettingsManager::setAppLanguage(const QString& localeCode) {
    setValue(QString::fromLatin1(kAppLanguageKey), localeCode);
}

void SettingsManager::clearForTesting() {
    settings_.clear();
    settings_.sync();
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run:

```bash
cmake --build /Users/Y/Documents/kuclaw/build --target kuclaw_desktop -j 4
```

Expected:
- build succeeds with the new `SettingsManager` API available

- [ ] **Step 5: Commit**

```bash
git add /Users/Y/Documents/kuclaw/src/core/settings/SettingsManager.h \
        /Users/Y/Documents/kuclaw/src/core/settings/SettingsManager.cpp \
        /Users/Y/Documents/kuclaw/tests/cpp/tst_app_language_manager.cpp
git commit -m "feat: add persisted app language setting"
```

## Task 2: Add App-Level Language Owner And First-Launch Resolution

**Files:**
- Create: `/Users/Y/Documents/kuclaw/src/core/i18n/AppLanguageManager.h`
- Create: `/Users/Y/Documents/kuclaw/src/core/i18n/AppLanguageManager.cpp`
- Modify: `/Users/Y/Documents/kuclaw/tests/cpp/tst_app_language_manager.cpp`

- [ ] **Step 1: Write the failing language-resolution tests**

Extend `/Users/Y/Documents/kuclaw/tests/cpp/tst_app_language_manager.cpp` with:

```cpp
#include "core/i18n/AppLanguageManager.h"

private slots:
    void resolvesFirstLaunchFromSupportedSystemLocale() {
        SettingsManager settings;
        settings.clearForTesting();
        AppLanguageManager languageManager(&settings);

        QCOMPARE(languageManager.resolveInitialLocale(QLocale(QStringLiteral("zh_CN"))),
                 QStringLiteral("zh_CN"));
        QCOMPARE(languageManager.resolveInitialLocale(QLocale(QStringLiteral("en_US"))),
                 QStringLiteral("en_US"));
    }

    void fallsBackToEnglishForUnsupportedSystemLocale() {
        SettingsManager settings;
        settings.clearForTesting();
        AppLanguageManager languageManager(&settings);

        QCOMPARE(languageManager.resolveInitialLocale(QLocale(QStringLiteral("ja_JP"))),
                 QStringLiteral("en_US"));
    }

    void persistedLanguageOverridesSystemLocale() {
        SettingsManager settings;
        settings.clearForTesting();
        settings.setAppLanguage(QStringLiteral("zh_CN"));
        AppLanguageManager languageManager(&settings);

        QCOMPARE(languageManager.effectiveLocale(QLocale(QStringLiteral("en_US"))),
                 QStringLiteral("zh_CN"));
    }
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
cmake --build /Users/Y/Documents/kuclaw/build --target kuclaw_desktop -j 4
```

Expected:
- build fails because `AppLanguageManager` does not exist

- [ ] **Step 3: Implement the minimal language manager**

Create `/Users/Y/Documents/kuclaw/src/core/i18n/AppLanguageManager.h`:

```cpp
#pragma once

#include <QObject>
#include <QLocale>
#include <QStringList>

class QTranslator;
class SettingsManager;
class QGuiApplication;

class AppLanguageManager final : public QObject {
    Q_OBJECT
public:
    explicit AppLanguageManager(SettingsManager* settingsManager,
                                QGuiApplication* app = nullptr,
                                QObject* parent = nullptr);

    QString currentLocale() const;
    QStringList supportedLocales() const;
    QString resolveInitialLocale(const QLocale& systemLocale) const;
    QString effectiveLocale(const QLocale& systemLocale) const;
    bool setCurrentLocale(const QString& localeCode);
    bool initialize();

signals:
    void currentLocaleChanged();

private:
    bool isSupportedLocale(const QString& localeCode) const;
    SettingsManager* settingsManager_ = nullptr;
    QGuiApplication* app_ = nullptr;
    QTranslator* translator_ = nullptr;
    QString currentLocale_;
};
```

Create `/Users/Y/Documents/kuclaw/src/core/i18n/AppLanguageManager.cpp`:

```cpp
#include "core/i18n/AppLanguageManager.h"

#include <QGuiApplication>
#include <QTranslator>

#include "core/settings/SettingsManager.h"

namespace {
const QString kEnglishLocale = QStringLiteral("en_US");
const QString kChineseLocale = QStringLiteral("zh_CN");
}

AppLanguageManager::AppLanguageManager(SettingsManager* settingsManager,
                                       QGuiApplication* app,
                                       QObject* parent)
    : QObject(parent),
      settingsManager_(settingsManager),
      app_(app),
      translator_(new QTranslator(this)) {}

QString AppLanguageManager::currentLocale() const {
    return currentLocale_;
}

QStringList AppLanguageManager::supportedLocales() const {
    return {kEnglishLocale, kChineseLocale};
}

QString AppLanguageManager::resolveInitialLocale(const QLocale& systemLocale) const {
    return systemLocale.name() == kChineseLocale ? kChineseLocale : kEnglishLocale;
}

QString AppLanguageManager::effectiveLocale(const QLocale& systemLocale) const {
    const QString saved = settingsManager_ ? settingsManager_->appLanguage() : QString();
    if (isSupportedLocale(saved)) {
        return saved;
    }

    return resolveInitialLocale(systemLocale);
}

bool AppLanguageManager::isSupportedLocale(const QString& localeCode) const {
    return localeCode == kEnglishLocale || localeCode == kChineseLocale;
}

bool AppLanguageManager::initialize() {
    return setCurrentLocale(effectiveLocale(QLocale::system()));
}

bool AppLanguageManager::setCurrentLocale(const QString& localeCode) {
    if (!isSupportedLocale(localeCode)) {
        return false;
    }

    currentLocale_ = localeCode;
    if (settingsManager_) {
        settingsManager_->setAppLanguage(localeCode);
    }
    emit currentLocaleChanged();
    return true;
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run:

```bash
cmake --build /Users/Y/Documents/kuclaw/build --target kuclaw_desktop -j 4
```

Expected:
- build succeeds with the resolution tests green

- [ ] **Step 5: Commit**

```bash
git add /Users/Y/Documents/kuclaw/src/core/i18n/AppLanguageManager.h \
        /Users/Y/Documents/kuclaw/src/core/i18n/AppLanguageManager.cpp \
        /Users/Y/Documents/kuclaw/tests/cpp/tst_app_language_manager.cpp
git commit -m "feat: add app language manager"
```

## Task 3: Expose App Language To QML And Bootstrap Before Shell Load

**Files:**
- Create: `/Users/Y/Documents/kuclaw/src/ui_bridge/viewmodels/AppLanguageViewModel.h`
- Create: `/Users/Y/Documents/kuclaw/src/ui_bridge/viewmodels/AppLanguageViewModel.cpp`
- Modify: `/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/app/ApplicationCoordinator.h`
- Modify: `/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/app/ApplicationCoordinator.cpp`
- Modify: `/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/main.cpp`
- Modify: `/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt`
- Test: `/Users/Y/Documents/kuclaw/tests/cpp/tst_app_language_manager.cpp`

- [ ] **Step 1: Write the failing QML-bridge test**

Extend `/Users/Y/Documents/kuclaw/tests/cpp/tst_app_language_manager.cpp` with:

```cpp
#include "ui_bridge/viewmodels/AppLanguageViewModel.h"

private slots:
    void viewModelReflectsCurrentLocaleAndCanSwitch() {
        SettingsManager settings;
        settings.clearForTesting();
        AppLanguageManager languageManager(&settings);
        AppLanguageViewModel viewModel(&languageManager);

        QVERIFY(languageManager.setCurrentLocale(QStringLiteral("en_US")));
        QCOMPARE(viewModel.currentLocale(), QStringLiteral("en_US"));

        viewModel.selectLocale(QStringLiteral("zh_CN"));
        QCOMPARE(viewModel.currentLocale(), QStringLiteral("zh_CN"));
        QCOMPARE(settings.appLanguage(), QStringLiteral("zh_CN"));
    }
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
cmake --build /Users/Y/Documents/kuclaw/build --target kuclaw_desktop -j 4
```

Expected:
- build fails because `AppLanguageViewModel` does not exist

- [ ] **Step 3: Implement the minimal bridge and wire it into app bootstrap**

Create `/Users/Y/Documents/kuclaw/src/ui_bridge/viewmodels/AppLanguageViewModel.h`:

```cpp
#pragma once

#include <QObject>
#include <QStringList>

class AppLanguageManager;

class AppLanguageViewModel final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString currentLocale READ currentLocale NOTIFY currentLocaleChanged)
    Q_PROPERTY(QStringList supportedLocales READ supportedLocales CONSTANT)
public:
    explicit AppLanguageViewModel(AppLanguageManager* languageManager,
                                  QObject* parent = nullptr);

    QString currentLocale() const;
    QStringList supportedLocales() const;

    Q_INVOKABLE void selectLocale(const QString& localeCode);

signals:
    void currentLocaleChanged();

private:
    AppLanguageManager* languageManager_ = nullptr;
};
```

Create `/Users/Y/Documents/kuclaw/src/ui_bridge/viewmodels/AppLanguageViewModel.cpp`:

```cpp
#include "ui_bridge/viewmodels/AppLanguageViewModel.h"

#include "core/i18n/AppLanguageManager.h"

AppLanguageViewModel::AppLanguageViewModel(AppLanguageManager* languageManager,
                                           QObject* parent)
    : QObject(parent),
      languageManager_(languageManager) {
    connect(languageManager_, &AppLanguageManager::currentLocaleChanged,
            this, &AppLanguageViewModel::currentLocaleChanged);
}

QString AppLanguageViewModel::currentLocale() const {
    return languageManager_ ? languageManager_->currentLocale() : QString();
}

QStringList AppLanguageViewModel::supportedLocales() const {
    return languageManager_ ? languageManager_->supportedLocales() : QStringList();
}

void AppLanguageViewModel::selectLocale(const QString& localeCode) {
    if (languageManager_) {
        languageManager_->setCurrentLocale(localeCode);
    }
}
```

Update `/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/app/ApplicationCoordinator.h` by adding:

```cpp
#include "core/i18n/AppLanguageManager.h"
#include "ui_bridge/viewmodels/AppLanguageViewModel.h"
...
    AppLanguageViewModel* appLanguageViewModel();
...
    AppLanguageManager appLanguageManager_;
    AppLanguageViewModel appLanguageViewModel_;
```

Update `/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/app/ApplicationCoordinator.cpp` constructor init list:

```cpp
      appLanguageManager_(&settingsManager_, qobject_cast<QGuiApplication*>(QCoreApplication::instance()), this),
      appLanguageViewModel_(&appLanguageManager_, this),
```

Add method:

```cpp
AppLanguageViewModel* ApplicationCoordinator::appLanguageViewModel() {
    return &appLanguageViewModel_;
}
```

Update `/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/main.cpp` before loading QML:

```cpp
    coordinator.appLanguageViewModel();
    coordinator.appLanguageManager().initialize();
    engine.rootContext()->setContextProperty("appLanguageViewModel", coordinator.appLanguageViewModel());
```

If `appLanguageManager()` accessor does not exist yet, add it to the coordinator interface in the same task.

Update `/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt` to compile the new i18n and view model files.

- [ ] **Step 4: Run the test to verify it passes**

Run:

```bash
cmake --build /Users/Y/Documents/kuclaw/build --target kuclaw_desktop -j 4
```

Expected:
- build succeeds with the view-model bridge wired into the app

- [ ] **Step 5: Commit**

```bash
git add /Users/Y/Documents/kuclaw/src/ui_bridge/viewmodels/AppLanguageViewModel.h \
        /Users/Y/Documents/kuclaw/src/ui_bridge/viewmodels/AppLanguageViewModel.cpp \
        /Users/Y/Documents/kuclaw/apps/kuclaw-desktop/app/ApplicationCoordinator.h \
        /Users/Y/Documents/kuclaw/apps/kuclaw-desktop/app/ApplicationCoordinator.cpp \
        /Users/Y/Documents/kuclaw/apps/kuclaw-desktop/main.cpp \
        /Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt \
        /Users/Y/Documents/kuclaw/tests/cpp/tst_app_language_manager.cpp
git commit -m "feat: expose app language to qml"
```

## Task 4: Add Translation Assets And Runtime Translator Loading

**Files:**
- Modify: `/Users/Y/Documents/kuclaw/src/core/i18n/AppLanguageManager.cpp`
- Create: `/Users/Y/Documents/kuclaw/translations/kuclaw_en_US.ts`
- Create: `/Users/Y/Documents/kuclaw/translations/kuclaw_zh_CN.ts`
- Modify: `/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt`
- Test: `/Users/Y/Documents/kuclaw/tests/cpp/tst_app_language_manager.cpp`

- [ ] **Step 1: Write the failing translator-load test**

Extend `/Users/Y/Documents/kuclaw/tests/cpp/tst_app_language_manager.cpp` with:

```cpp
private slots:
    void initializePersistsAndReportsLoadedLocale() {
        SettingsManager settings;
        settings.clearForTesting();
        AppLanguageManager languageManager(&settings);

        QVERIFY(languageManager.initialize());
        QVERIFY(languageManager.currentLocale() == QStringLiteral("en_US")
             || languageManager.currentLocale() == QStringLiteral("zh_CN"));
    }
```

- [ ] **Step 2: Run the test to verify it fails or is incomplete**

Run:

```bash
cmake --build /Users/Y/Documents/kuclaw/build --target kuclaw_desktop -j 4
```

Expected:
- translator load path is missing or test is incomplete because no translation assets are bundled yet

- [ ] **Step 3: Add translation assets and real translator installation**

Create `/Users/Y/Documents/kuclaw/translations/kuclaw_en_US.ts`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<TS version="2.1" language="en_US">
<context>
    <name>AppShell</name>
    <message>
        <source>Kuclaw</source>
        <translation>Kuclaw</translation>
    </message>
</context>
</TS>
```

Create `/Users/Y/Documents/kuclaw/translations/kuclaw_zh_CN.ts` with the same source entry translated to Chinese where appropriate.

Update `/Users/Y/Documents/kuclaw/src/core/i18n/AppLanguageManager.cpp`:

```cpp
bool AppLanguageManager::setCurrentLocale(const QString& localeCode) {
    if (!isSupportedLocale(localeCode) || app_ == nullptr) {
        return false;
    }

    app_->removeTranslator(translator_);
    translator_->load(QStringLiteral(":/translations/kuclaw_%1.qm").arg(localeCode));
    app_->installTranslator(translator_);

    if (currentLocale_ == localeCode) {
        return true;
    }

    currentLocale_ = localeCode;
    if (settingsManager_) {
        settingsManager_->setAppLanguage(localeCode);
    }
    emit currentLocaleChanged();
    return true;
}
```

Update `/Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt` to add the translation files to the build and bundle compiled `.qm` assets into the app resources.

- [ ] **Step 4: Run the test to verify it passes**

Run:

```bash
cmake --build /Users/Y/Documents/kuclaw/build --target kuclaw_desktop -j 4
```

Expected:
- build succeeds and translation assets are included

- [ ] **Step 5: Commit**

```bash
git add /Users/Y/Documents/kuclaw/src/core/i18n/AppLanguageManager.cpp \
        /Users/Y/Documents/kuclaw/translations/kuclaw_en_US.ts \
        /Users/Y/Documents/kuclaw/translations/kuclaw_zh_CN.ts \
        /Users/Y/Documents/kuclaw/apps/kuclaw-desktop/CMakeLists.txt \
        /Users/Y/Documents/kuclaw/tests/cpp/tst_app_language_manager.cpp
git commit -m "feat: load runtime translation assets"
```

## Task 5: Translate Existing App Copy Into Qt Translation Strings

**Files:**
- Modify: `/Users/Y/Documents/kuclaw/qml/app/AppShell.qml`
- Modify: `/Users/Y/Documents/kuclaw/qml/app/ExpandedSidebarSettingsPopover.qml`
- Modify: `/Users/Y/Documents/kuclaw/qml/app/WorkspaceSidebarItems.js`
- Modify: `/Users/Y/Documents/kuclaw/qml/settings/SettingsPanel.qml`
- Modify: `/Users/Y/Documents/kuclaw/qml/settings/RecentColorPanel.qml`
- Modify: `/Users/Y/Documents/kuclaw/qml/pin/PinboardPanel.qml`
- Modify: `/Users/Y/Documents/kuclaw/qml/capture/CaptureOverlayWindow.qml`
- Modify: `/Users/Y/Documents/kuclaw/qml/capture/CaptureOverlay.qml`
- Modify: `/Users/Y/Documents/kuclaw/qml/capture/CaptureToolbar.qml`
- Modify: `/Users/Y/Documents/kuclaw/qml/capture/Magnifier.qml`
- Modify: `/Users/Y/Documents/kuclaw/translations/kuclaw_en_US.ts`
- Modify: `/Users/Y/Documents/kuclaw/translations/kuclaw_zh_CN.ts`
- Test: `/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml`

- [ ] **Step 1: Write the failing translated-shell test**

Add to `/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml`:

```qml
    function test_popover_labels_refresh_when_language_changes() {
        const subject = createWindowSubject()
        verify(subject !== null)

        subject.open()
        tryCompare(subject, "opened", true)

        const languageLabel = findByObjectName(subject, "languageLabel")
        compare(languageLabel.text, "Language")

        subject.currentLocale = "zh_CN"
        tryCompare(languageLabel, "text", "语言")
    }
```

Expected current failure:
- `SettingsPopover` has no `currentLocale`-driven translated labels yet

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml -platform offscreen
```

Expected:
- FAIL because the labels remain hard-coded

- [ ] **Step 3: Convert visible strings to translation primitives**

Examples of minimal code changes:

In `/Users/Y/Documents/kuclaw/qml/app/ExpandedSidebarSettingsPopover.qml`:

```qml
                text: qsTr("Settings")
```

In `/Users/Y/Documents/kuclaw/qml/app/SettingsPopover.qml` row model:

```qml
                label: qsTr("Settings")
...
                label: qsTr("Language")
...
                label: qsTr("Rate limits remaining")
...
            label: qsTr("Log out")
```

In `/Users/Y/Documents/kuclaw/qml/app/AppShell.qml`:

```qml
    title: qsTr("Kuclaw")
```

Apply the same pattern to the current visible strings already identified in `SettingsPanel`, `RecentColorPanel`, `PinboardPanel`, `CaptureOverlay`, `CaptureToolbar`, `CaptureOverlayWindow`, `Magnifier`, and shell/sidebar labels.

Populate the Chinese translations in `/Users/Y/Documents/kuclaw/translations/kuclaw_zh_CN.ts` for the translated strings added in this task.

- [ ] **Step 4: Run the test to verify it passes**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml -platform offscreen
cmake --build /Users/Y/Documents/kuclaw/build --target kuclaw_desktop -j 4
```

Expected:
- translated popover labels update correctly
- app still builds cleanly

- [ ] **Step 5: Commit**

```bash
git add /Users/Y/Documents/kuclaw/qml/app/AppShell.qml \
        /Users/Y/Documents/kuclaw/qml/app/ExpandedSidebarSettingsPopover.qml \
        /Users/Y/Documents/kuclaw/qml/app/WorkspaceSidebarItems.js \
        /Users/Y/Documents/kuclaw/qml/settings/SettingsPanel.qml \
        /Users/Y/Documents/kuclaw/qml/settings/RecentColorPanel.qml \
        /Users/Y/Documents/kuclaw/qml/pin/PinboardPanel.qml \
        /Users/Y/Documents/kuclaw/qml/capture/CaptureOverlayWindow.qml \
        /Users/Y/Documents/kuclaw/qml/capture/CaptureOverlay.qml \
        /Users/Y/Documents/kuclaw/qml/capture/CaptureToolbar.qml \
        /Users/Y/Documents/kuclaw/qml/capture/Magnifier.qml \
        /Users/Y/Documents/kuclaw/translations/kuclaw_en_US.ts \
        /Users/Y/Documents/kuclaw/translations/kuclaw_zh_CN.ts \
        /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml
git commit -m "feat: translate current app copy"
```

## Task 6: Add Language Inline Disclosure UI To SettingsPopover

**Files:**
- Modify: `/Users/Y/Documents/kuclaw/qml/app/SettingsPopover.qml`
- Modify: `/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml`

- [ ] **Step 1: Write the failing disclosure tests**

Extend `/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml` with:

```qml
    function test_language_row_expands_inline_and_shows_checkmark() {
        const subject = createWindowSubject()
        subject.currentLocale = "en_US"

        subject.open()
        tryCompare(subject, "opened", true)

        const languageHitArea = findByObjectName(subject, "languageHitArea")
        mouseClick(languageHitArea, 24, 24, Qt.LeftButton)

        const englishOption = findByObjectName(subject, "languageOption_en_US")
        const chineseOption = findByObjectName(subject, "languageOption_zh_CN")
        const englishCheckmark = findByObjectName(subject, "languageCheckmark_en_US")

        verify(englishOption !== null)
        verify(chineseOption !== null)
        verify(englishCheckmark !== null)
        compare(englishCheckmark.visible, true)
    }

    function test_selecting_language_keeps_popover_open_and_expanded() {
        const subject = createWindowSubject()
        let selectedLocale = ""
        subject.languageSelected.connect(function(localeCode) { selectedLocale = localeCode })

        subject.open()
        tryCompare(subject, "opened", true)

        mouseClick(findByObjectName(subject, "languageHitArea"), 24, 24, Qt.LeftButton)
        mouseClick(findByObjectName(subject, "languageOption_zh_CN"), 24, 24, Qt.LeftButton)

        compare(selectedLocale, "zh_CN")
        verify(subject.opened)
        compare(subject.languageExpanded, true)
    }
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml -platform offscreen
```

Expected:
- FAIL because the disclosure UI does not exist yet

- [ ] **Step 3: Implement the inline disclosure UI**

Update `/Users/Y/Documents/kuclaw/qml/app/SettingsPopover.qml` with public API:

```qml
    property bool languageExpanded: false
    property string currentLocale: "en_US"
    signal languageToggled()
    signal languageSelected(string localeCode)
```

Implement the `Language` row click behavior:

```qml
            if (row.semanticId === "settings") {
                root.settingsClicked()
            } else if (row.semanticId === "language") {
                root.languageExpanded = !root.languageExpanded
                root.languageToggled()
            }
```

Add the nested language options block directly below the language row:

```qml
        Column {
            id: languageOptions
            objectName: "languageOptions"
            visible: root.languageExpanded
            spacing: 4

            Repeater {
                model: [
                    { localeCode: "zh_CN", label: "中文（中国）" },
                    { localeCode: "en_US", label: "English (United States)" }
                ]

                delegate: Item {
                    objectName: "languageOption_" + modelData.localeCode
                    width: parent.width
                    height: 40

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.languageSelected(modelData.localeCode)
                    }

                    Label {
                        text: modelData.label
                    }

                    Label {
                        objectName: "languageCheckmark_" + modelData.localeCode
                        visible: root.currentLocale === modelData.localeCode
                        text: "✓"
                    }
                }
            }
        }
```

Use a `Behavior on height` / `Behavior on rotation` for the approved short animation.

- [ ] **Step 4: Run the test to verify it passes**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml -platform offscreen
```

Expected:
- disclosure tests pass

- [ ] **Step 5: Commit**

```bash
git add /Users/Y/Documents/kuclaw/qml/app/SettingsPopover.qml \
        /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml
git commit -m "feat: add popover language disclosure"
```

## Task 7: Connect Language Selection To Real Runtime Switching

**Files:**
- Modify: `/Users/Y/Documents/kuclaw/qml/app/AppShell.qml`
- Modify: `/Users/Y/Documents/kuclaw/qml/app/SettingsPopover.qml`
- Modify: `/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml`
- Modify: `/Users/Y/Documents/kuclaw/src/ui_bridge/viewmodels/AppLanguageViewModel.cpp`

- [ ] **Step 1: Write the failing phase-three shell test**

Add to `/Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml`:

```qml
    function test_selecting_new_language_switches_app_and_keeps_popover_open() {
        const harness = createPhaseTwoShellHarness()
        verify(harness !== null)
        verify(harness.controller !== null)

        mouseClick(harness.expandedSettings.settingsTrigger, 24, 24, Qt.LeftButton)
        tryCompare(harness.controller, "popoverOpen", true)

        const languageHitArea = findByObjectName(harness.controller.settingsPopover, "languageHitArea")
        mouseClick(languageHitArea, 24, 24, Qt.LeftButton)

        const chineseOption = findByObjectName(harness.controller.settingsPopover, "languageOption_zh_CN")
        mouseClick(chineseOption, 24, 24, Qt.LeftButton)

        verify(harness.controller.popoverOpen)
        compare(harness.controller.settingsPopover.languageExpanded, true)
        compare(harness.languageViewModel.currentLocale, "zh_CN")
    }
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml -platform offscreen
```

Expected:
- FAIL because AppShell does not yet route language selections anywhere

- [ ] **Step 3: Wire AppShell to the app language view model**

Update `/Users/Y/Documents/kuclaw/qml/app/AppShell.qml` so the settings popover controller / popover instance receives and updates the current locale:

```qml
    SidebarSettingsPopoverController {
        id: settingsPopoverController
        email: "sinobec1013@gmail.com"
        accountLabel: qsTr("Personal account")
        expandedTriggerItem: settingsRow.settingsTrigger
        railTriggerItem: settingsIcon
        onSettingsRequested: root.openSettingsPageFromPopover()
        onLanguageRequested: function(localeCode) {
            appLanguageViewModel.selectLocale(localeCode)
        }
    }
```

If the controller does not yet proxy language actions, add the minimal pass-through there and bind `SettingsPopover.currentLocale` to `appLanguageViewModel.currentLocale`.

- [ ] **Step 4: Run the test to verify it passes**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml -platform offscreen
cmake --build /Users/Y/Documents/kuclaw/build --target kuclaw_desktop -j 4
```

Expected:
- language-selection shell test passes
- desktop build still succeeds

- [ ] **Step 5: Commit**

```bash
git add /Users/Y/Documents/kuclaw/qml/app/AppShell.qml \
        /Users/Y/Documents/kuclaw/qml/app/SettingsPopover.qml \
        /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml \
        /Users/Y/Documents/kuclaw/src/ui_bridge/viewmodels/AppLanguageViewModel.cpp
git commit -m "feat: wire runtime language switching"
```

## Task 8: Sync PRD After Fresh Verification

**Files:**
- Modify: `/Users/Y/Documents/kuclaw/PRD.md`

- [ ] **Step 1: Run fresh verification for the completed scope**

Run:

```bash
qmltestrunner -input /Users/Y/Documents/kuclaw/tests/qml/tst_settings_popover.qml -platform offscreen
cmake --build /Users/Y/Documents/kuclaw/build --target kuclaw_desktop -j 4
```

Expected:
- popover tests pass
- desktop build succeeds

- [ ] **Step 2: Update `PRD.md`**

Add stable behavior describing:

```md
- App language supports `English (United States)` and `中文（中国）`.
- On first launch, app language follows the system language when supported.
- After manual selection, the chosen language persists across launches.
- In `Settings Popover`, the `Language` row expands inline and shows the active language with a checkmark.
- Selecting a language updates the app immediately without closing the popover.
```

Also note deferred items if still not implemented:

```md
- `Rate limits remaining` action remains deferred.
- `Log out` action remains deferred.
```

- [ ] **Step 3: Commit**

```bash
git add /Users/Y/Documents/kuclaw/PRD.md
git commit -m "docs: sync app language behavior in PRD"
```
