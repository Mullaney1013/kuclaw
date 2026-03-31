set(KUCLAW_DESKTOP_TARGET kuclaw_desktop)

set(KUCLAW_DESKTOP_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/main.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/app/ApplicationCoordinator.cpp
    ${CMAKE_SOURCE_DIR}/src/core/common/Logger.cpp
    ${CMAKE_SOURCE_DIR}/src/core/common/SingleInstanceGuard.cpp
    ${CMAKE_SOURCE_DIR}/src/core/settings/SettingsManager.cpp
    ${CMAKE_SOURCE_DIR}/src/core/hotkey/HotkeyManager.cpp
    ${CMAKE_SOURCE_DIR}/src/integration/platform/NoopHotkeyRegistrar.cpp
    ${CMAKE_SOURCE_DIR}/src/integration/platform/MacHotkeyRegistrar.cpp
    ${CMAKE_SOURCE_DIR}/src/core/tray/TrayManager.cpp
    ${CMAKE_SOURCE_DIR}/src/core/clipboard/ClipboardManager.cpp
    ${CMAKE_SOURCE_DIR}/src/core/annotation/AnnotationManager.cpp
    ${CMAKE_SOURCE_DIR}/src/core/capture/ScreenCaptureManager.cpp
    ${CMAKE_SOURCE_DIR}/src/core/capture/CaptureSessionController.cpp
    ${CMAKE_SOURCE_DIR}/src/core/capture/FreezeOverlayWidget.cpp
    ${CMAKE_SOURCE_DIR}/src/core/capture/CaptureCoordinator.cpp
    ${CMAKE_SOURCE_DIR}/src/core/capture/NativeScreenHelperFactory.cpp
    ${CMAKE_SOURCE_DIR}/src/core/pin/PinWindowManager.cpp
    ${CMAKE_SOURCE_DIR}/src/ui_bridge/viewmodels/CaptureViewModel.cpp
    ${CMAKE_SOURCE_DIR}/src/ui_bridge/viewmodels/ColorHistoryViewModel.cpp
    ${CMAKE_SOURCE_DIR}/src/ui_bridge/viewmodels/PinboardViewModel.cpp
    ${CMAKE_SOURCE_DIR}/src/ui_bridge/viewmodels/SettingsViewModel.cpp
    ${CMAKE_SOURCE_DIR}/src/ui_bridge/viewmodels/WindowChromeViewModel.cpp
    ${CMAKE_SOURCE_DIR}/src/integration/platform/WinHotkeyRegistrar.cpp
    ${CMAKE_SOURCE_DIR}/src/integration/platform/NativeScreenHelperWin.cpp
)

if(APPLE)
    list(APPEND KUCLAW_DESKTOP_SOURCES
        ${CMAKE_SOURCE_DIR}/assets/icons/AppIcon.icns
        ${CMAKE_SOURCE_DIR}/src/integration/platform/MacWindowChrome.mm
        ${CMAKE_SOURCE_DIR}/src/integration/platform/NativeScreenHelperMac.mm
    )
    set_source_files_properties(
        ${CMAKE_SOURCE_DIR}/assets/icons/AppIcon.icns
        PROPERTIES MACOSX_PACKAGE_LOCATION Resources
    )
    set_source_files_properties(
        ${CMAKE_SOURCE_DIR}/src/integration/platform/MacWindowChrome.mm
        ${CMAKE_SOURCE_DIR}/src/integration/platform/NativeScreenHelperMac.mm
        PROPERTIES COMPILE_OPTIONS "-fobjc-arc"
    )
endif()

set(KUCLAW_QML_FILES
    ${CMAKE_SOURCE_DIR}/qml/app/Main.qml
    ${CMAKE_SOURCE_DIR}/qml/app/AppShell.qml
    ${CMAKE_SOURCE_DIR}/qml/app/AutomationSectionStyles.js
    ${CMAKE_SOURCE_DIR}/qml/app/TitleBarLayout.js
    ${CMAKE_SOURCE_DIR}/qml/app/WorkspaceSidebarItems.js
    ${CMAKE_SOURCE_DIR}/qml/app/WorkspaceShellState.js
    ${CMAKE_SOURCE_DIR}/qml/app/WorkspaceShellStyles.js
    ${CMAKE_SOURCE_DIR}/qml/app/TitleBarControls.qml
    ${CMAKE_SOURCE_DIR}/qml/app/ShellNavigation.js
    ${CMAKE_SOURCE_DIR}/qml/app/WorkspaceSelection.js
    ${CMAKE_SOURCE_DIR}/qml/capture/CaptureOverlay.qml
    ${CMAKE_SOURCE_DIR}/qml/capture/CaptureOverlayWindow.qml
    ${CMAKE_SOURCE_DIR}/qml/capture/CaptureToolbar.qml
    ${CMAKE_SOURCE_DIR}/qml/capture/Magnifier.qml
    ${CMAKE_SOURCE_DIR}/qml/pin/PinboardPanel.qml
    ${CMAKE_SOURCE_DIR}/qml/settings/RecentColorPanel.qml
    ${CMAKE_SOURCE_DIR}/qml/settings/SettingsPanel.qml
)

set(KUCLAW_RESOURCE_FILES
    ${CMAKE_SOURCE_DIR}/assets/icons/locus.svg
    ${CMAKE_SOURCE_DIR}/assets/icons/home.svg
    ${CMAKE_SOURCE_DIR}/assets/icons/my-projects.svg
    ${CMAKE_SOURCE_DIR}/assets/icons/team.svg
    ${CMAKE_SOURCE_DIR}/assets/icons/settings.svg
    ${CMAKE_SOURCE_DIR}/assets/icons/sidebar-toggle.svg
)

set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/qml/app/Main.qml
    PROPERTIES QT_RESOURCE_ALIAS app/Main.qml
)
set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/qml/app/AppShell.qml
    PROPERTIES QT_RESOURCE_ALIAS app/AppShell.qml
)
set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/qml/app/AutomationSectionStyles.js
    PROPERTIES QT_RESOURCE_ALIAS app/AutomationSectionStyles.js
)
set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/qml/app/TitleBarLayout.js
    PROPERTIES QT_RESOURCE_ALIAS app/TitleBarLayout.js
)
set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/qml/app/WorkspaceSidebarItems.js
    PROPERTIES QT_RESOURCE_ALIAS app/WorkspaceSidebarItems.js
)
set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/qml/app/WorkspaceShellState.js
    PROPERTIES QT_RESOURCE_ALIAS app/WorkspaceShellState.js
)
set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/qml/app/WorkspaceShellStyles.js
    PROPERTIES QT_RESOURCE_ALIAS app/WorkspaceShellStyles.js
)
set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/qml/app/TitleBarControls.qml
    PROPERTIES QT_RESOURCE_ALIAS app/TitleBarControls.qml
)
set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/qml/app/ShellNavigation.js
    PROPERTIES QT_RESOURCE_ALIAS app/ShellNavigation.js
)
set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/qml/app/WorkspaceSelection.js
    PROPERTIES QT_RESOURCE_ALIAS app/WorkspaceSelection.js
)
set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/assets/icons/locus.svg
    PROPERTIES QT_RESOURCE_ALIAS assets/icons/locus.svg
)
set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/assets/icons/home.svg
    PROPERTIES QT_RESOURCE_ALIAS assets/icons/home.svg
)
set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/assets/icons/my-projects.svg
    PROPERTIES QT_RESOURCE_ALIAS assets/icons/my-projects.svg
)
set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/assets/icons/team.svg
    PROPERTIES QT_RESOURCE_ALIAS assets/icons/team.svg
)
set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/assets/icons/settings.svg
    PROPERTIES QT_RESOURCE_ALIAS assets/icons/settings.svg
)
set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/assets/icons/sidebar-toggle.svg
    PROPERTIES QT_RESOURCE_ALIAS assets/icons/sidebar-toggle.svg
)
set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/qml/capture/CaptureOverlay.qml
    PROPERTIES QT_RESOURCE_ALIAS capture/CaptureOverlay.qml
)
set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/qml/capture/CaptureOverlayWindow.qml
    PROPERTIES QT_RESOURCE_ALIAS capture/CaptureOverlayWindow.qml
)
set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/qml/capture/CaptureToolbar.qml
    PROPERTIES QT_RESOURCE_ALIAS capture/CaptureToolbar.qml
)
set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/qml/capture/Magnifier.qml
    PROPERTIES QT_RESOURCE_ALIAS capture/Magnifier.qml
)
set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/qml/pin/PinboardPanel.qml
    PROPERTIES QT_RESOURCE_ALIAS pin/PinboardPanel.qml
)
set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/qml/settings/RecentColorPanel.qml
    PROPERTIES QT_RESOURCE_ALIAS settings/RecentColorPanel.qml
)
set_source_files_properties(
    ${CMAKE_SOURCE_DIR}/qml/settings/SettingsPanel.qml
    PROPERTIES QT_RESOURCE_ALIAS settings/SettingsPanel.qml
)

qt_add_executable(${KUCLAW_DESKTOP_TARGET}
    ${KUCLAW_DESKTOP_SOURCES}
)

set_target_properties(${KUCLAW_DESKTOP_TARGET} PROPERTIES
    CXX_STANDARD 20
    CXX_STANDARD_REQUIRED ON
)

if(APPLE)
    set_target_properties(${KUCLAW_DESKTOP_TARGET} PROPERTIES
        OBJCXX_STANDARD 20
        OBJCXX_STANDARD_REQUIRED ON
        MACOSX_BUNDLE_ICON_FILE AppIcon.icns
    )
    target_compile_options(${KUCLAW_DESKTOP_TARGET}
        PRIVATE
            $<$<COMPILE_LANGUAGE:OBJCXX>:-std=c++20>
    )
endif()

qt_add_qml_module(${KUCLAW_DESKTOP_TARGET}
    URI Kuclaw
    VERSION 1.0
    QML_FILES
        ${KUCLAW_QML_FILES}
    RESOURCES
        ${KUCLAW_RESOURCE_FILES}
)

target_include_directories(${KUCLAW_DESKTOP_TARGET}
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/src
)

target_link_libraries(${KUCLAW_DESKTOP_TARGET}
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Qml
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Widgets
)

if(APPLE)
    target_link_libraries(${KUCLAW_DESKTOP_TARGET}
        PRIVATE
            "-framework Carbon"
            "-framework ApplicationServices"
            "-framework AppKit"
            "-framework CoreGraphics"
            "-framework CoreMedia"
            "-framework CoreVideo"
            "-framework AVFoundation"
            "-framework ScreenCaptureKit"
    )
endif()

set_target_properties(${KUCLAW_DESKTOP_TARGET} PROPERTIES
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
    OUTPUT_NAME Kuclaw
)

install(TARGETS ${KUCLAW_DESKTOP_TARGET}
    BUNDLE DESTINATION .
    RUNTIME DESTINATION bin
)

qt_add_executable(kuclaw_window_chrome_tests
    ${CMAKE_SOURCE_DIR}/tests/cpp/tst_window_chrome_viewmodel.cpp
    ${CMAKE_SOURCE_DIR}/src/ui_bridge/viewmodels/WindowChromeViewModel.cpp
)

target_include_directories(kuclaw_window_chrome_tests
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_SOURCE_DIR}/src
)

target_link_libraries(kuclaw_window_chrome_tests
    PRIVATE
        Qt6::Core
        Qt6::Gui
        Qt6::Test
)

if(APPLE)
    target_sources(kuclaw_window_chrome_tests
        PRIVATE
            ${CMAKE_SOURCE_DIR}/src/integration/platform/MacWindowChrome.mm
    )

    set_source_files_properties(
        ${CMAKE_SOURCE_DIR}/src/integration/platform/MacWindowChrome.mm
        PROPERTIES COMPILE_OPTIONS "-fobjc-arc"
    )

    target_link_libraries(kuclaw_window_chrome_tests
        PRIVATE
            "-framework AppKit"
    )
endif()

add_test(NAME kuclaw_window_chrome_tests COMMAND kuclaw_window_chrome_tests)
