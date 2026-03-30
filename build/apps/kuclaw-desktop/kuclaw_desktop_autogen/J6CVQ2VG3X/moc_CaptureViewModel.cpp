/****************************************************************************
** Meta object code from reading C++ file 'CaptureViewModel.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.10.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../../../src/ui_bridge/viewmodels/CaptureViewModel.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'CaptureViewModel.h' doesn't include <QObject>."
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
struct qt_meta_tag_ZN16CaptureViewModelE_t {};
} // unnamed namespace

template <> constexpr inline auto CaptureViewModel::qt_create_metaobjectdata<qt_meta_tag_ZN16CaptureViewModelE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "CaptureViewModel",
        "overlayVisibleChanged",
        "",
        "desktopGeometryChanged",
        "desktopScreensChanged",
        "desktopSnapshotUrlChanged",
        "magnifierImageUrlChanged",
        "selectionRectChanged",
        "currentColorStringChanged",
        "toastRequested",
        "message",
        "beginCapture",
        "cancelCapture",
        "isWindowAutoSelectionEnabled",
        "setSelectionRect",
        "x",
        "y",
        "width",
        "height",
        "updateCursorPoint",
        "trackWindow",
        "moveSelectionBy",
        "dx",
        "dy",
        "moveSelectionTo",
        "resizeSelectionBy",
        "left",
        "top",
        "right",
        "bottom",
        "copy",
        "copyFullScreen",
        "save",
        "pin",
        "overlayVisible",
        "desktopGeometry",
        "QRect",
        "desktopScreens",
        "QVariantList",
        "desktopSnapshotUrl",
        "QUrl",
        "magnifierImageUrl",
        "selectionRect",
        "hasSelection",
        "currentColorString"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'overlayVisibleChanged'
        QtMocHelpers::SignalData<void()>(1, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'desktopGeometryChanged'
        QtMocHelpers::SignalData<void()>(3, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'desktopScreensChanged'
        QtMocHelpers::SignalData<void()>(4, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'desktopSnapshotUrlChanged'
        QtMocHelpers::SignalData<void()>(5, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'magnifierImageUrlChanged'
        QtMocHelpers::SignalData<void()>(6, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'selectionRectChanged'
        QtMocHelpers::SignalData<void()>(7, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'currentColorStringChanged'
        QtMocHelpers::SignalData<void()>(8, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'toastRequested'
        QtMocHelpers::SignalData<void(const QString &)>(9, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 10 },
        }}),
        // Method 'beginCapture'
        QtMocHelpers::MethodData<void()>(11, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'cancelCapture'
        QtMocHelpers::MethodData<void()>(12, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'isWindowAutoSelectionEnabled'
        QtMocHelpers::MethodData<bool() const>(13, 2, QMC::AccessPublic, QMetaType::Bool),
        // Method 'setSelectionRect'
        QtMocHelpers::MethodData<void(int, int, int, int)>(14, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 15 }, { QMetaType::Int, 16 }, { QMetaType::Int, 17 }, { QMetaType::Int, 18 },
        }}),
        // Method 'updateCursorPoint'
        QtMocHelpers::MethodData<void(int, int, bool)>(19, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 15 }, { QMetaType::Int, 16 }, { QMetaType::Bool, 20 },
        }}),
        // Method 'updateCursorPoint'
        QtMocHelpers::MethodData<void(int, int)>(19, 2, QMC::AccessPublic | QMC::MethodCloned, QMetaType::Void, {{
            { QMetaType::Int, 15 }, { QMetaType::Int, 16 },
        }}),
        // Method 'moveSelectionBy'
        QtMocHelpers::MethodData<void(int, int)>(21, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 22 }, { QMetaType::Int, 23 },
        }}),
        // Method 'moveSelectionTo'
        QtMocHelpers::MethodData<void(int, int)>(24, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 15 }, { QMetaType::Int, 16 },
        }}),
        // Method 'resizeSelectionBy'
        QtMocHelpers::MethodData<void(int, int, int, int)>(25, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 26 }, { QMetaType::Int, 27 }, { QMetaType::Int, 28 }, { QMetaType::Int, 29 },
        }}),
        // Method 'copy'
        QtMocHelpers::MethodData<void()>(30, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'copyFullScreen'
        QtMocHelpers::MethodData<void()>(31, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'save'
        QtMocHelpers::MethodData<void()>(32, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'pin'
        QtMocHelpers::MethodData<void()>(33, 2, QMC::AccessPublic, QMetaType::Void),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'overlayVisible'
        QtMocHelpers::PropertyData<bool>(34, QMetaType::Bool, QMC::DefaultPropertyFlags, 0),
        // property 'desktopGeometry'
        QtMocHelpers::PropertyData<QRect>(35, 0x80000000 | 36, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 1),
        // property 'desktopScreens'
        QtMocHelpers::PropertyData<QVariantList>(37, 0x80000000 | 38, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 2),
        // property 'desktopSnapshotUrl'
        QtMocHelpers::PropertyData<QUrl>(39, 0x80000000 | 40, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 3),
        // property 'magnifierImageUrl'
        QtMocHelpers::PropertyData<QUrl>(41, 0x80000000 | 40, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 4),
        // property 'selectionRect'
        QtMocHelpers::PropertyData<QRect>(42, 0x80000000 | 36, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 5),
        // property 'hasSelection'
        QtMocHelpers::PropertyData<bool>(43, QMetaType::Bool, QMC::DefaultPropertyFlags, 5),
        // property 'currentColorString'
        QtMocHelpers::PropertyData<QString>(44, QMetaType::QString, QMC::DefaultPropertyFlags, 6),
    };
    QtMocHelpers::UintData qt_enums {
    };
    return QtMocHelpers::metaObjectData<CaptureViewModel, qt_meta_tag_ZN16CaptureViewModelE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject CaptureViewModel::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN16CaptureViewModelE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN16CaptureViewModelE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN16CaptureViewModelE_t>.metaTypes,
    nullptr
} };

void CaptureViewModel::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<CaptureViewModel *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->overlayVisibleChanged(); break;
        case 1: _t->desktopGeometryChanged(); break;
        case 2: _t->desktopScreensChanged(); break;
        case 3: _t->desktopSnapshotUrlChanged(); break;
        case 4: _t->magnifierImageUrlChanged(); break;
        case 5: _t->selectionRectChanged(); break;
        case 6: _t->currentColorStringChanged(); break;
        case 7: _t->toastRequested((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 8: _t->beginCapture(); break;
        case 9: _t->cancelCapture(); break;
        case 10: { bool _r = _t->isWindowAutoSelectionEnabled();
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 11: _t->setSelectionRect((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[4]))); break;
        case 12: _t->updateCursorPoint((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[3]))); break;
        case 13: _t->updateCursorPoint((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 14: _t->moveSelectionBy((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 15: _t->moveSelectionTo((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 16: _t->resizeSelectionBy((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[4]))); break;
        case 17: _t->copy(); break;
        case 18: _t->copyFullScreen(); break;
        case 19: _t->save(); break;
        case 20: _t->pin(); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (CaptureViewModel::*)()>(_a, &CaptureViewModel::overlayVisibleChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (CaptureViewModel::*)()>(_a, &CaptureViewModel::desktopGeometryChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (CaptureViewModel::*)()>(_a, &CaptureViewModel::desktopScreensChanged, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (CaptureViewModel::*)()>(_a, &CaptureViewModel::desktopSnapshotUrlChanged, 3))
            return;
        if (QtMocHelpers::indexOfMethod<void (CaptureViewModel::*)()>(_a, &CaptureViewModel::magnifierImageUrlChanged, 4))
            return;
        if (QtMocHelpers::indexOfMethod<void (CaptureViewModel::*)()>(_a, &CaptureViewModel::selectionRectChanged, 5))
            return;
        if (QtMocHelpers::indexOfMethod<void (CaptureViewModel::*)()>(_a, &CaptureViewModel::currentColorStringChanged, 6))
            return;
        if (QtMocHelpers::indexOfMethod<void (CaptureViewModel::*)(const QString & )>(_a, &CaptureViewModel::toastRequested, 7))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<bool*>(_v) = _t->overlayVisible(); break;
        case 1: *reinterpret_cast<QRect*>(_v) = _t->desktopGeometry(); break;
        case 2: *reinterpret_cast<QVariantList*>(_v) = _t->desktopScreens(); break;
        case 3: *reinterpret_cast<QUrl*>(_v) = _t->desktopSnapshotUrl(); break;
        case 4: *reinterpret_cast<QUrl*>(_v) = _t->magnifierImageUrl(); break;
        case 5: *reinterpret_cast<QRect*>(_v) = _t->selectionRect(); break;
        case 6: *reinterpret_cast<bool*>(_v) = _t->hasSelection(); break;
        case 7: *reinterpret_cast<QString*>(_v) = _t->currentColorString(); break;
        default: break;
        }
    }
}

const QMetaObject *CaptureViewModel::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *CaptureViewModel::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN16CaptureViewModelE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int CaptureViewModel::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 21)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 21;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 21)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 21;
    }
    if (_c == QMetaObject::ReadProperty || _c == QMetaObject::WriteProperty
            || _c == QMetaObject::ResetProperty || _c == QMetaObject::BindableProperty
            || _c == QMetaObject::RegisterPropertyMetaType) {
        qt_static_metacall(this, _c, _id, _a);
        _id -= 8;
    }
    return _id;
}

// SIGNAL 0
void CaptureViewModel::overlayVisibleChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void CaptureViewModel::desktopGeometryChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void CaptureViewModel::desktopScreensChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 2, nullptr);
}

// SIGNAL 3
void CaptureViewModel::desktopSnapshotUrlChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 3, nullptr);
}

// SIGNAL 4
void CaptureViewModel::magnifierImageUrlChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 4, nullptr);
}

// SIGNAL 5
void CaptureViewModel::selectionRectChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 5, nullptr);
}

// SIGNAL 6
void CaptureViewModel::currentColorStringChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 6, nullptr);
}

// SIGNAL 7
void CaptureViewModel::toastRequested(const QString & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 7, nullptr, _t1);
}
QT_WARNING_POP
