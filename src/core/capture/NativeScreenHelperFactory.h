#pragma once

#include <memory>

class INativeScreenHelper;

std::unique_ptr<INativeScreenHelper> createNativeScreenHelper();
