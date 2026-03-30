/****************************************************************************
** Meta object code from reading C++ file 'CaptureSessionController.h'
**
** Created by: The Qt Meta Object Compiler version 69 (Qt 6.10.2)
**
** WARNING! All changes made in this file will be lost!
*****************************************************************************/

#include "../../../../../src/core/capture/CaptureSessionController.h"
#include <QtCore/qmetatype.h>

#include <QtCore/qtmochelpers.h>

#include <memory>


#include <QtCore/qxptype_traits.h>
#if !defined(Q_MOC_OUTPUT_REVISION)
#error "The header file 'CaptureSessionController.h' doesn't include <QObject>."
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
struct qt_meta_tag_ZN24CaptureSessionControllerE_t {};
} // unnamed namespace

template <> constexpr inline auto CaptureSessionController::qt_create_metaobjectdata<qt_meta_tag_ZN24CaptureSessionControllerE_t>()
{
    namespace QMC = QtMocConstants;
    QtMocHelpers::StringRefStorage qt_stringData {
        "CaptureSessionController",
        "stateChanged",
        "",
        "selectionRectChanged",
        "magnifierUpdated",
        "QImage",
        "image",
        "QColor",
        "color",
        "sessionCompleted",
        "resultImage",
        "beginSession",
        "setWindowAutoSelectionEnabled",
        "enabled",
        "isWindowAutoSelectionEnabled",
        "moveSelectionTo",
        "x",
        "y",
        "copyFullScreen",
        "cancelSession",
        "updateSelection",
        "QRect",
        "rect",
        "updateCursorPoint",
        "QPoint",
        "point",
        "trackWindow",
        "nudgeSelection",
        "dx",
        "dy",
        "resizeSelection",
        "left",
        "top",
        "right",
        "bottom",
        "enterAnnotating",
        "copyResultToClipboard",
        "saveResultToFile",
        "path",
        "pinResult",
        "selectionRect",
        "state",
        "CaptureState",
        "Idle",
        "Selecting",
        "Selected",
        "Annotating",
        "Exporting",
        "Cancelled"
    };

    QtMocHelpers::UintData qt_methods {
        // Signal 'stateChanged'
        QtMocHelpers::SignalData<void()>(1, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'selectionRectChanged'
        QtMocHelpers::SignalData<void()>(3, 2, QMC::AccessPublic, QMetaType::Void),
        // Signal 'magnifierUpdated'
        QtMocHelpers::SignalData<void(const QImage &, const QColor &)>(4, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 5, 6 }, { 0x80000000 | 7, 8 },
        }}),
        // Signal 'sessionCompleted'
        QtMocHelpers::SignalData<void(const QImage &)>(9, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 5, 10 },
        }}),
        // Method 'beginSession'
        QtMocHelpers::MethodData<void()>(11, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'setWindowAutoSelectionEnabled'
        QtMocHelpers::MethodData<void(bool)>(12, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Bool, 13 },
        }}),
        // Method 'isWindowAutoSelectionEnabled'
        QtMocHelpers::MethodData<bool() const>(14, 2, QMC::AccessPublic, QMetaType::Bool),
        // Method 'moveSelectionTo'
        QtMocHelpers::MethodData<void(int, int)>(15, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 16 }, { QMetaType::Int, 17 },
        }}),
        // Method 'copyFullScreen'
        QtMocHelpers::MethodData<void()>(18, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'cancelSession'
        QtMocHelpers::MethodData<void()>(19, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'updateSelection'
        QtMocHelpers::MethodData<void(const QRect &)>(20, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 21, 22 },
        }}),
        // Method 'updateCursorPoint'
        QtMocHelpers::MethodData<void(const QPoint &, bool)>(23, 2, QMC::AccessPublic, QMetaType::Void, {{
            { 0x80000000 | 24, 25 }, { QMetaType::Bool, 26 },
        }}),
        // Method 'updateCursorPoint'
        QtMocHelpers::MethodData<void(const QPoint &)>(23, 2, QMC::AccessPublic | QMC::MethodCloned, QMetaType::Void, {{
            { 0x80000000 | 24, 25 },
        }}),
        // Method 'nudgeSelection'
        QtMocHelpers::MethodData<void(int, int)>(27, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 28 }, { QMetaType::Int, 29 },
        }}),
        // Method 'resizeSelection'
        QtMocHelpers::MethodData<void(int, int, int, int)>(30, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::Int, 31 }, { QMetaType::Int, 32 }, { QMetaType::Int, 33 }, { QMetaType::Int, 34 },
        }}),
        // Method 'enterAnnotating'
        QtMocHelpers::MethodData<void()>(35, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'copyResultToClipboard'
        QtMocHelpers::MethodData<void()>(36, 2, QMC::AccessPublic, QMetaType::Void),
        // Method 'saveResultToFile'
        QtMocHelpers::MethodData<void(const QString &)>(37, 2, QMC::AccessPublic, QMetaType::Void, {{
            { QMetaType::QString, 38 },
        }}),
        // Method 'pinResult'
        QtMocHelpers::MethodData<void()>(39, 2, QMC::AccessPublic, QMetaType::Void),
    };
    QtMocHelpers::UintData qt_properties {
        // property 'selectionRect'
        QtMocHelpers::PropertyData<QRect>(40, 0x80000000 | 21, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 1),
        // property 'state'
        QtMocHelpers::PropertyData<enum CaptureState>(41, 0x80000000 | 42, QMC::DefaultPropertyFlags | QMC::EnumOrFlag, 0),
    };
    QtMocHelpers::UintData qt_enums {
        // enum 'CaptureState'
        QtMocHelpers::EnumData<enum CaptureState>(42, 42, QMC::EnumIsScoped).add({
            {   43, CaptureState::Idle },
            {   44, CaptureState::Selecting },
            {   45, CaptureState::Selected },
            {   46, CaptureState::Annotating },
            {   47, CaptureState::Exporting },
            {   48, CaptureState::Cancelled },
        }),
    };
    return QtMocHelpers::metaObjectData<CaptureSessionController, qt_meta_tag_ZN24CaptureSessionControllerE_t>(QMC::MetaObjectFlag{}, qt_stringData,
            qt_methods, qt_properties, qt_enums);
}
Q_CONSTINIT const QMetaObject CaptureSessionController::staticMetaObject = { {
    QMetaObject::SuperData::link<QObject::staticMetaObject>(),
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN24CaptureSessionControllerE_t>.stringdata,
    qt_staticMetaObjectStaticContent<qt_meta_tag_ZN24CaptureSessionControllerE_t>.data,
    qt_static_metacall,
    nullptr,
    qt_staticMetaObjectRelocatingContent<qt_meta_tag_ZN24CaptureSessionControllerE_t>.metaTypes,
    nullptr
} };

void CaptureSessionController::qt_static_metacall(QObject *_o, QMetaObject::Call _c, int _id, void **_a)
{
    auto *_t = static_cast<CaptureSessionController *>(_o);
    if (_c == QMetaObject::InvokeMetaMethod) {
        switch (_id) {
        case 0: _t->stateChanged(); break;
        case 1: _t->selectionRectChanged(); break;
        case 2: _t->magnifierUpdated((*reinterpret_cast<std::add_pointer_t<QImage>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<QColor>>(_a[2]))); break;
        case 3: _t->sessionCompleted((*reinterpret_cast<std::add_pointer_t<QImage>>(_a[1]))); break;
        case 4: _t->beginSession(); break;
        case 5: _t->setWindowAutoSelectionEnabled((*reinterpret_cast<std::add_pointer_t<bool>>(_a[1]))); break;
        case 6: { bool _r = _t->isWindowAutoSelectionEnabled();
            if (_a[0]) *reinterpret_cast<bool*>(_a[0]) = std::move(_r); }  break;
        case 7: _t->moveSelectionTo((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 8: _t->copyFullScreen(); break;
        case 9: _t->cancelSession(); break;
        case 10: _t->updateSelection((*reinterpret_cast<std::add_pointer_t<QRect>>(_a[1]))); break;
        case 11: _t->updateCursorPoint((*reinterpret_cast<std::add_pointer_t<QPoint>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<bool>>(_a[2]))); break;
        case 12: _t->updateCursorPoint((*reinterpret_cast<std::add_pointer_t<QPoint>>(_a[1]))); break;
        case 13: _t->nudgeSelection((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2]))); break;
        case 14: _t->resizeSelection((*reinterpret_cast<std::add_pointer_t<int>>(_a[1])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[2])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[3])),(*reinterpret_cast<std::add_pointer_t<int>>(_a[4]))); break;
        case 15: _t->enterAnnotating(); break;
        case 16: _t->copyResultToClipboard(); break;
        case 17: _t->saveResultToFile((*reinterpret_cast<std::add_pointer_t<QString>>(_a[1]))); break;
        case 18: _t->pinResult(); break;
        default: ;
        }
    }
    if (_c == QMetaObject::IndexOfMethod) {
        if (QtMocHelpers::indexOfMethod<void (CaptureSessionController::*)()>(_a, &CaptureSessionController::stateChanged, 0))
            return;
        if (QtMocHelpers::indexOfMethod<void (CaptureSessionController::*)()>(_a, &CaptureSessionController::selectionRectChanged, 1))
            return;
        if (QtMocHelpers::indexOfMethod<void (CaptureSessionController::*)(const QImage & , const QColor & )>(_a, &CaptureSessionController::magnifierUpdated, 2))
            return;
        if (QtMocHelpers::indexOfMethod<void (CaptureSessionController::*)(const QImage & )>(_a, &CaptureSessionController::sessionCompleted, 3))
            return;
    }
    if (_c == QMetaObject::ReadProperty) {
        void *_v = _a[0];
        switch (_id) {
        case 0: *reinterpret_cast<QRect*>(_v) = _t->selectionRect(); break;
        case 1: *reinterpret_cast<enum CaptureState*>(_v) = _t->state(); break;
        default: break;
        }
    }
}

const QMetaObject *CaptureSessionController::metaObject() const
{
    return QObject::d_ptr->metaObject ? QObject::d_ptr->dynamicMetaObject() : &staticMetaObject;
}

void *CaptureSessionController::qt_metacast(const char *_clname)
{
    if (!_clname) return nullptr;
    if (!strcmp(_clname, qt_staticMetaObjectStaticContent<qt_meta_tag_ZN24CaptureSessionControllerE_t>.strings))
        return static_cast<void*>(this);
    return QObject::qt_metacast(_clname);
}

int CaptureSessionController::qt_metacall(QMetaObject::Call _c, int _id, void **_a)
{
    _id = QObject::qt_metacall(_c, _id, _a);
    if (_id < 0)
        return _id;
    if (_c == QMetaObject::InvokeMetaMethod) {
        if (_id < 19)
            qt_static_metacall(this, _c, _id, _a);
        _id -= 19;
    }
    if (_c == QMetaObject::RegisterMethodArgumentMetaType) {
        if (_id < 19)
            *reinterpret_cast<QMetaType *>(_a[0]) = QMetaType();
        _id -= 19;
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
void CaptureSessionController::stateChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 0, nullptr);
}

// SIGNAL 1
void CaptureSessionController::selectionRectChanged()
{
    QMetaObject::activate(this, &staticMetaObject, 1, nullptr);
}

// SIGNAL 2
void CaptureSessionController::magnifierUpdated(const QImage & _t1, const QColor & _t2)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 2, nullptr, _t1, _t2);
}

// SIGNAL 3
void CaptureSessionController::sessionCompleted(const QImage & _t1)
{
    QMetaObject::activate<void>(this, &staticMetaObject, 3, nullptr, _t1);
}
QT_WARNING_POP
