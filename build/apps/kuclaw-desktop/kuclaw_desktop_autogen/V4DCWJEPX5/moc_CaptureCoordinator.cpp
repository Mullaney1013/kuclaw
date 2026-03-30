/****************************************************************************
** Meta object code from reading C++ file 'CaptureCoordinator.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.10.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../../../src/core/capture/CaptureCoordinator.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'CaptureCoordinator.h' doesn't include <QObject>."
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
struct qt_meta_tag_ZN18CaptureCoordinatorE_t {};
} // unnamed namespace

template <> constexpr inline auto CaptureCoordinator::qt_create_metaobjectdata<qt_meta_tag_ZN18CaptureCoordinatorE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "CaptureCoordinator",
        "captureActiveChanged",
        "",
        "captureCanceling",
        "captureCompleting",
        "captureCompleted",
        "SelectionResult",
        "result",
        "QImage",
        "image",
        "captureCanceled",
        "captureError",
        "message",
        "colorCopied",
        "colorValue",
        "swatchHex",
        "QPoint",
        "globalPoint"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'captureActiveChanged'
        QtMocHelpers::SignalData<void()>(1, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'captureCanceling'
        QtMocHelpers::SignalData<void()>(3, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'captureCompleting'
        QtMocHelpers::SignalData<void()>(4, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'captureCompleted'
        QtMocHelpers::SignalData<void(const SelectionResult &, const QImage &)>(5, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 6, 7 }, { 0x80000000 | 8, 9 },
        }}),
        // Signal 'captureCanceled'
        QtMocHelpers::SignalData<void()>(10, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'captureError'
        QtMocHelpers::SignalData<void(const QString &)>(11, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 12 },
        }}),
        // Signal 'colorCopied'
        QtMocHelpers::SignalData<void(const QString &, const QString &, const QPoint &)>(13, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 14 }, { QMetaType::QString, 15 }, { 0x80000000 | 16, 17 },
        }}),
    };
    QtMocHelpers::UintData qt_properties {
    };
    QtMocHelpers::UintData qt_enums {
    };
    return QtMocHelpers::metaObjectData<CaptureCoordinator, qt_meta_tag_ZN18CaptureCoordinatorE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject CaptureCoordinator::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN18CaptureCoordinatorE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN18CaptureCoordinatorE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN18CaptureCoordinatorE_t>.metaTypes,
    nullptr
} };

void CaptureCoordinator::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<CaptureCoordinator *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->captureActiveChanged(); break;
        case 1: _t->captureCanceling(); break;
        case 2: _t->captureCompleting(); break;
        case 3: _t->captureCompleted((*reinterpret_cast<std::add_pointer_t<SelectionResult>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QImage>>(_a[2]))); break;
        case 4: _t->captureCanceled(); break;
        case 5: _t->captureError((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 6: _t->colorCopied((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QString>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<QPoint>>(_a[3]))); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (CaptureCoordinator::*)()>(_a, &CaptureCoordinator::captureActiveChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (CaptureCoordinator::*)()>(_a, &CaptureCoordinator::captureCanceling, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (CaptureCoordinator::*)()>(_a, &CaptureCoordinator::captureCompleting, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (CaptureCoordinator::*)(const SelectionResult & , const QImage & )>(_a, &CaptureCoordinator::captureCompleted, 3))
            return;
        if (QtMocHelpers::indexOfMethod<void (CaptureCoordinator::*)()>(_a, &CaptureCoordinator::captureCanceled, 4))
            return;
        if (QtMocHelpers::indexOfMethod<void (CaptureCoordinator::*)(const QString & )>(_a, &CaptureCoordinator::captureError, 5))
            return;
        if (QtMocHelpers::indexOfMethod<void (CaptureCoordinator::*)(const QString & , const QString & , const QPoint & )>(_a, &CaptureCoordinator::colorCopied, 6))
            return;
    }
}

const QMetaObject *CaptureCoordinator::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *CaptureCoordinator::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN18CaptureCoordinatorE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int CaptureCoordinator::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 7)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 7;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 7)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 7;
    }
    return _id;
}

// SIGNAL 0
void CaptureCoordinator::captureActiveChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void CaptureCoordinator::captureCanceling()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void CaptureCoordinator::captureCompleting()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}

// SIGNAL 3
void CaptureCoordinator::captureCompleted(const SelectionResult & _t1, const QImage & _t2)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 3, nullptr, _t1, _t2);
}

// SIGNAL 4
void CaptureCoordinator::captureCanceled()
{
    QMetaObject::activate(this, &staticMetaObject, 4, nullptr);
}

// SIGNAL 5
void CaptureCoordinator::captureError(const QString & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 5, nullptr, _t1);
}

// SIGNAL 6
void CaptureCoordinator::colorCopied(const QString & _t1, const QString & _t2, const QPoint & _t3)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 6, nullptr, _t1, _t2, _t3);
}
QT_WARNING_POP
