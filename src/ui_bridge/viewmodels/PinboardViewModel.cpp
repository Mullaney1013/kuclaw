#include "ui_bridge/viewmodels/PinboardViewModel.h"

#include "core/pin/PinWindowManager.h"

PinboardViewModel::PinboardViewModel(PinWindowManager* pinWindowManager,
                                     QObject* parent)
    : QObject(parent),
      pinWindowManager_(pinWindowManager) {
    connect(pinWindowManager_, &PinWindowManager::pinsChanged,
            this, &PinboardViewModel::pinCountChanged);
    connect(pinWindowManager_, &PinWindowManager::pinCreated, this,
            [this](const QString& pinId) {
                lastCreatedPinId_ = pinId;
                emit lastCreatedPinIdChanged();
                emit pinCountChanged();
            });
}

int PinboardViewModel::pinCount() const {
    return pinWindowManager_->pinCount();
}

QString PinboardViewModel::lastCreatedPinId() const {
    return lastCreatedPinId_;
}

void PinboardViewModel::pinFromClipboard() {
    pinWindowManager_->createPinFromClipboard();
}

void PinboardViewModel::hideAllPins() {
    pinWindowManager_->hideAllPins();
}

void PinboardViewModel::restoreLastClosed() {
    pinWindowManager_->restoreLastClosedPin();
}
