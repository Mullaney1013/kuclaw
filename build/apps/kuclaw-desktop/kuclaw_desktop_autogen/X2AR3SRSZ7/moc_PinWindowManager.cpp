/****************************************************************************
** Meta object code from reading C++ file 'PinWindowManager.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.10.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../../../src/core/pin/PinWindowManager.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'PinWindowManager.h' doesn't include <QObject>."
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
struct qt_meta_tag_ZN16PinWindowManagerE_t {};
} // unnamed namespace

template <> constexpr inline auto PinWindowManager::qt_create_metaobjectdata<qt_meta_tag_ZN16PinWindowManagerE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "PinWindowManager",
        "pinCreated",
        "",
        "pinId",
        "pinClosed",
        "pinDestroyed",
        "pinsChanged",
        "createPinFromClipboard",
        "closePin",
        "destroyPin",
        "restoreLastClosedPin",
        "hideAllPins",
        "showAllPins",
        "setPinOpacity",
        "opacity",
        "setPinScale",
        "scale",
        "togglePassthrough"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'pinCreated'
        QtMocHelpers::SignalData<void(const QString &)>(1, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 3 },
        }}),
        // Signal 'pinClosed'
        QtMocHelpers::SignalData<void(const QString &)>(4, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 3 },
        }}),
        // Signal 'pinDestroyed'
        QtMocHelpers::SignalData<void(const QString &)>(5, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 3 },
        }}),
        // Signal 'pinsChanged'
        QtMocHelpers::SignalData<void()>(6, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'createPinFromClipboard'
        QtMocHelpers::MethodData<QString()>(7, 2, QMC::AccessPublic, QMetaType::QString),
        // Method 'closePin'
        QtMocHelpers::MethodData<void(const QString &)>(8, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 3 },
        }}),
        // Method 'destroyPin'
        QtMocHelpers::MethodData<void(const QString &)>(9, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 3 },
        }}),
        // Method 'restoreLastClosedPin'
        QtMocHelpers::MethodData<void()>(10, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'hideAllPins'
        QtMocHelpers::MethodData<void()>(11, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'showAllPins'
        QtMocHelpers::MethodData<void()>(12, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'setPinOpacity'
        QtMocHelpers::MethodData<void(const QString &, qreal)>(13, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 3 }, { QMetaType::QReal, 14 },
        }}),
        // Method 'setPinScale'
        QtMocHelpers::MethodData<void(const QString &, qreal)>(15, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 3 }, { QMetaType::QReal, 16 },
        }}),
        // Method 'togglePassthrough'
        QtMocHelpers::MethodData<void(const QString &)>(17, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 3 },
        }}),
    };
    QtMocHelpers::UintData qt_properties {
    };
    QtMocHelpers::UintData qt_enums {
    };
    return QtMocHelpers::metaObjectData<PinWindowManager, qt_meta_tag_ZN16PinWindowManagerE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject PinWindowManager::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN16PinWindowManagerE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN16PinWindowManagerE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN16PinWindowManagerE_t>.metaTypes,
    nullptr
} };

void PinWindowManager::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<PinWindowManager *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->pinCreated((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 1: _t->pinClosed((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 2: _t->pinDestroyed((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 3: _t->pinsChanged(); break;
        case 4: { QString _r = _t->createPinFromClipboard();
            if (_a[0]) *reinterpret_cast<QString*>(_a[0]) = std::move(_r); }  break;
        case 5: _t->closePin((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 6: _t->destroyPin((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 7: _t->restoreLastClosedPin(); break;
        case 8: _t->hideAllPins(); break;
        case 9: _t->showAllPins(); break;
        case 10: _t->setPinOpacity((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[2]))); break;
        case 11: _t->setPinScale((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<qreal>>(_a[2]))); break;
        case 12: _t->togglePassthrough((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (PinWindowManager::*)(const QString & )>(_a, &PinWindowManager::pinCreated, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (PinWindowManager::*)(const QString & )>(_a, &PinWindowManager::pinClosed, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (PinWindowManager::*)(const QString & )>(_a, &PinWindowManager::pinDestroyed, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (PinWindowManager::*)()>(_a, &PinWindowManager::pinsChanged, 3))
            return;
    }
}

const QMetaObject *PinWindowManager::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *PinWindowManager::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN16PinWindowManagerE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int PinWindowManager::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 13)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 13;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 13)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 13;
    }
    return _id;
}

// SIGNAL 0
void PinWindowManager::pinCreated(const QString & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 0, nullptr, _t1);
}

// SIGNAL 1
void PinWindowManager::pinClosed(const QString & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 1, nullptr, _t1);
}

// SIGNAL 2
void PinWindowManager::pinDestroyed(const QString & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 2, nullptr, _t1);
}

// SIGNAL 3
void PinWindowManager::pinsChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 3, nullptr);
}
QT_WARNING_POP
