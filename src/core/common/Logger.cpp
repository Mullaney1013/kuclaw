#include "core/common/Logger.h"

#include <QDebug>

void Logger::info(const QString& category, const QString& message) {
    qInfo().noquote() << QString("[%1] %2").arg(category, message);
}

void Logger::warn(const QString& category, const QString& message) {
    qWarning().noquote() << QString("[%1] %2").arg(category, message);
}

void Logger::error(const QString& category, const QString& message) {
    qCritical().noquote() << QString("[%1] %2").arg(category, message);
}
