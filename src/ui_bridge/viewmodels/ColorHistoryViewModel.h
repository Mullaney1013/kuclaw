#pragma once

#include <QObject>
#include <QVariantList>

class ClipboardManager;

class ColorHistoryViewModel final : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList recentColors READ recentColors NOTIFY recentColorsChanged)
    Q_PROPERTY(int recentColorCount READ recentColorCount NOTIFY recentColorsChanged)

public:
    explicit ColorHistoryViewModel(ClipboardManager* clipboardManager,
                                   QObject* parent = nullptr);

    QVariantList recentColors() const;
    int recentColorCount() const;

    Q_INVOKABLE void recordCopiedColor(const QString& colorValue,
                                       const QString& swatchHex,
                                       int x,
                                       int y);
    Q_INVOKABLE void copyColorValue(const QString& colorValue);

signals:
    void recentColorsChanged();

private:
    ClipboardManager* clipboardManager_ = nullptr;
    QVariantList recentColors_;
};
