#include "ui_bridge/viewmodels/ColorHistoryViewModel.h"

#include "core/clipboard/ClipboardManager.h"

#include <QDateTime>
#include <QVariantMap>

namespace {

constexpr int kMaxRecentColors = 20;

}

ColorHistoryViewModel::ColorHistoryViewModel(ClipboardManager* clipboardManager,
                                             QObject* parent)
    : QObject(parent),
      clipboardManager_(clipboardManager) {}

QVariantList ColorHistoryViewModel::recentColors() const {
    return recentColors_;
}

int ColorHistoryViewModel::recentColorCount() const {
    return recentColors_.size();
}

void ColorHistoryViewModel::recordCopiedColor(const QString& colorValue,
                                              const QString& swatchHex,
                                              const int x,
                                              const int y) {
    QVariantMap record;
    record.insert(QStringLiteral("copiedAt"),
                  QDateTime::currentDateTime().toString(QStringLiteral("yyyy-MM-dd HH:mm:ss")));
    record.insert(QStringLiteral("x"), x);
    record.insert(QStringLiteral("y"), y);
    record.insert(QStringLiteral("coordinatesLabel"),
                  QStringLiteral("X: %1  Y: %2").arg(x).arg(y));
    record.insert(QStringLiteral("colorValue"), colorValue);
    record.insert(QStringLiteral("swatchHex"), swatchHex);

    recentColors_.prepend(record);
    while (recentColors_.size() > kMaxRecentColors) {
        recentColors_.removeLast();
    }

    emit recentColorsChanged();
}

void ColorHistoryViewModel::copyColorValue(const QString& colorValue) {
    if (clipboardManager_ == nullptr) {
        return;
    }

    clipboardManager_->setText(colorValue);
}
