#include "core/common/SingleInstanceGuard.h"

#include <QLockFile>
#include <QStandardPaths>

SingleInstanceGuard::SingleInstanceGuard(const QString& key)
    : lockFile_(std::make_unique<QLockFile>(
          QStandardPaths::writableLocation(QStandardPaths::TempLocation) + "/" + key)) {
    lockFile_->setStaleLockTime(0);
}

SingleInstanceGuard::~SingleInstanceGuard() {
    if (lockFile_ != nullptr && lockFile_->isLocked()) {
        lockFile_->unlock();
    }
}

bool SingleInstanceGuard::isAnotherInstanceRunning() {
    return !lockFile_->tryLock(0);
}
