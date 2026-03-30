#pragma once

#include <memory>

class QString;
class QLockFile;

class SingleInstanceGuard {
public:
    explicit SingleInstanceGuard(const QString& key);
    ~SingleInstanceGuard();

    bool isAnotherInstanceRunning();

private:
    std::unique_ptr<QLockFile> lockFile_;
};
