#include <QtQml/qqmlprivate.h>
#include <QtCore/qdir.h>
#include <QtCore/qurl.h>
#include <QtCore/qhash.h>
#include <QtCore/qstring.h>

namespace QmlCacheGeneratedCode {
namespace _qt_qml_Kuclaw_app_Main_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}
namespace _qt_qml_Kuclaw_app_AppShell_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}
namespace _qt_qml_Kuclaw_capture_CaptureOverlay_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}
namespace _qt_qml_Kuclaw_capture_CaptureOverlayWindow_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}
namespace _qt_qml_Kuclaw_capture_CaptureToolbar_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}
namespace _qt_qml_Kuclaw_capture_Magnifier_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}
namespace _qt_qml_Kuclaw_pin_PinboardPanel_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}
namespace _qt_qml_Kuclaw_settings_RecentColorPanel_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}
namespace _qt_qml_Kuclaw_settings_SettingsPanel_qml { 
    extern const unsigned char qmlData[];
    extern const QQmlPrivate::AOTCompiledFunction aotBuiltFunctions[];
    const QQmlPrivate::CachedQmlUnit unit = {
        reinterpret_cast<const QV4::CompiledData::Unit*>(&qmlData), &aotBuiltFunctions[0], nullptr
    };
}

}
namespace {
struct Registry {
    Registry();
    ~Registry();
    QHash<QString, const QQmlPrivate::CachedQmlUnit*> resourcePathToCachedUnit;
    static const QQmlPrivate::CachedQmlUnit *lookupCachedUnit(const QUrl &url);
};

Q_GLOBAL_STATIC(Registry, unitRegistry)


Registry::Registry() {
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Kuclaw/app/Main.qml"), &QmlCacheGeneratedCode::_qt_qml_Kuclaw_app_Main_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Kuclaw/app/AppShell.qml"), &QmlCacheGeneratedCode::_qt_qml_Kuclaw_app_AppShell_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Kuclaw/capture/CaptureOverlay.qml"), &QmlCacheGeneratedCode::_qt_qml_Kuclaw_capture_CaptureOverlay_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Kuclaw/capture/CaptureOverlayWindow.qml"), &QmlCacheGeneratedCode::_qt_qml_Kuclaw_capture_CaptureOverlayWindow_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Kuclaw/capture/CaptureToolbar.qml"), &QmlCacheGeneratedCode::_qt_qml_Kuclaw_capture_CaptureToolbar_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Kuclaw/capture/Magnifier.qml"), &QmlCacheGeneratedCode::_qt_qml_Kuclaw_capture_Magnifier_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Kuclaw/pin/PinboardPanel.qml"), &QmlCacheGeneratedCode::_qt_qml_Kuclaw_pin_PinboardPanel_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Kuclaw/settings/RecentColorPanel.qml"), &QmlCacheGeneratedCode::_qt_qml_Kuclaw_settings_RecentColorPanel_qml::unit);
    resourcePathToCachedUnit.insert(QStringLiteral("/qt/qml/Kuclaw/settings/SettingsPanel.qml"), &QmlCacheGeneratedCode::_qt_qml_Kuclaw_settings_SettingsPanel_qml::unit);
    QQmlPrivate::RegisterQmlUnitCacheHook registration;
    registration.structVersion = 0;
    registration.lookupCachedQmlUnit = &lookupCachedUnit;
    QQmlPrivate::qmlregister(QQmlPrivate::QmlUnitCacheHookRegistration, &registration);
}

Registry::~Registry() {
    QQmlPrivate::qmlunregister(QQmlPrivate::QmlUnitCacheHookRegistration, quintptr(&lookupCachedUnit));
}

const QQmlPrivate::CachedQmlUnit *Registry::lookupCachedUnit(const QUrl &url) {
    if (url.scheme() != QLatin1String("qrc"))
        return nullptr;
    QString resourcePath = QDir::cleanPath(url.path());
    if (resourcePath.isEmpty())
        return nullptr;
    if (!resourcePath.startsWith(QLatin1Char('/')))
        resourcePath.prepend(QLatin1Char('/'));
    return unitRegistry()->resourcePathToCachedUnit.value(resourcePath, nullptr);
}
}
int QT_MANGLE_NAMESPACE(qInitResources_qmlcache_kuclaw_desktop)() {
    ::unitRegistry();
    return 1;
}
Q_CONSTRUCTOR_FUNCTION(QT_MANGLE_NAMESPACE(qInitResources_qmlcache_kuclaw_desktop))
int QT_MANGLE_NAMESPACE(qCleanupResources_qmlcache_kuclaw_desktop)() {
    return 1;
}
