/****************************************************************************
** Meta object code from reading C++ file 'ApplicationCoordinator.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.10.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../../../apps/kuclaw-desktop/app/ApplicationCoordinator.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'ApplicationCoordinator.h' doesn't include <QObject>."
#elif Q_MOC_OUTPUT_REVISION != 69
#error "This file was generated using the moc from 6.10.2. It"
#error "cannot be used with the include files from this version of Qt."
#error "(The moc has changed too much.)"
#endif

#ifndef Q_CONSTINIT
#define Q_CONSTINIT
#endif

QT_WARNING_PUSH
QT_WARNING_DISABLE_DEPRECATED
QT_WARNING_DISABLE_GCC("-Wuseless-cast")
namespace {
struct qt_meta_tag_ZN22ApplicationCoordinatorE_t {};
} // unnamed namespace

template <> constexpr inline auto ApplicationCoordinator::qt_create_metaobjectdata<qt_meta_tag_ZN22ApplicationCoordinatorE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "ApplicationCoordinator",
        "captureStarted",
        "",
        "captureFinished",
        "captureInProgressChanged",
        "reopenRequested",
        "fatalErrorOccurred",
        "message",
        "beginCapture",
        "pinFromClipboard",
        "hideAllPins",
        "restoreLastClosedPin",
        "shutdown",
        "captureInProgress",
        "captureBackend"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'captureStarted'
        QtMocHelpers::SignalData<void()>(1, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'captureFinished'
        QtMocHelpers::SignalData<void()>(3, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'captureInProgressChanged'
        QtMocHelpers::SignalData<void()>(4, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'reopenRequested'
        QtMocHelpers::SignalData<void()>(5, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'fatalErrorOccurred'
        QtMocHelpers::SignalData<void(const QString &)>(6, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 7 },
        }}),
        // Slot 'beginCapture'
        QtMocHelpers::SlotData<void()>(8, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'pinFromClipboard'
        QtMocHelpers::SlotData<void()>(9, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'hideAllPins'
        QtMocHelpers::SlotData<void()>(10, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'restoreLastClosedPin'
        QtMocHelpers::SlotData<void()>(11, 2, QMC::AccessPublic, QMetaType::Void),
        // Slot 'shutdown'
        QtMocHelpers::SlotData<void()>(12, 2, QMC::AccessPublic, QMetaType::Void),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'captureInProgress'
        QtMocHelpers::PropertyData<bool>(13, QMetaType::Bool, QMC::DefaultPropertyFlags, 2),
        // property 'captureBackend'
        QtMocHelpers::PropertyData<QString>(14, QMetaType::QString, QMC::DefaultPropertyFlags | QMC::Constant),
    };
    QtMocHelpers::UintData qt_enums {
    };
    return QtMocHelpers::metaObjectData<ApplicationCoordinator, qt_meta_tag_ZN22ApplicationCoordinatorE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject ApplicationCoordinator::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN22ApplicationCoordinatorE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN22ApplicationCoordinatorE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN22ApplicationCoordinatorE_t>.metaTypes,
    nullptr
} };

void ApplicationCoordinator::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<ApplicationCoordinator *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->captureStarted(); break;
        case 1: _t->captureFinished(); break;
        case 2: _t->captureInProgressChanged(); break;
        case 3: _t->reopenRequested(); break;
        case 4: _t->fatalErrorOccurred((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 5: _t->beginCapture(); break;
        case 6: _t->pinFromClipboard(); break;
        case 7: _t->hideAllPins(); break;
        case 8: _t->restoreLastClosedPin(); break;
        case 9: _t->shutdown(); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (ApplicationCoordinator::*)()>(_a, &ApplicationCoordinator::captureStarted, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (ApplicationCoordinator::*)()>(_a, &ApplicationCoordinator::captureFinished, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (ApplicationCoordinator::*)()>(_a, &ApplicationCoordinator::captureInProgressChanged, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (ApplicationCoordinator::*)()>(_a, &ApplicationCoordinator::reopenRequested, 3))
            return;
        if (QtMocHelpers::indexOfMethod<void (ApplicationCoordinator::*)(const QString & )>(_a, &ApplicationCoordinator::fatalErrorOccurred, 4))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<bool*>(_v) = _t->captureInProgress(); break;
        case 1: *reinterpret_cast<QString*>(_v) = _t->captureBackend(); break;
        default: break;
        }
    }
}

const QMetaObject *ApplicationCoordinator::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *ApplicationCoordinator::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN22ApplicationCoordinatorE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int ApplicationCoordinator::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 10)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 10;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 10)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 10;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 2;
    }
    return _id;
}

// SIGNAL 0
void ApplicationCoordinator::captureStarted()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void ApplicationCoordinator::captureFinished()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void ApplicationCoordinator::captureInProgressChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}

// SIGNAL 3
void ApplicationCoordinator::reopenRequested()
{
    QMetaObject::activate(this, &staticMetaObject, 3, nullptr);
}

// SIGNAL 4
void ApplicationCoordinator::fatalErrorOccurred(const QString & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 4, nullptr, _t1);
}
QT_WARNING_POP
