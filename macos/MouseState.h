#pragma once
#include <atomic>
#include <cstdint>

namespace facebook::react {

struct MouseState {
    std::atomic<int64_t> dx{0};
    std::atomic<int64_t> dy{0};
};

extern MouseState mouseState;

}  // namespace facebook::react
