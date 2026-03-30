#pragma once

#include <QString>

class Logger {
public:
    static void info(const QString& category, const QString& message);
    static void warn(const QString& category, const QString& message);
    static void error(const QString& category, const QString& message);
};
