#include "RNNSEventModule.h"
#import "RNNSEventHelper.h"
#import <AppKit/AppKit.h>

namespace facebook::react {

RNNSEvent::RNNSEvent(std::shared_ptr<CallInvoker> jsInvoker)
    : NativeNSEventCxxSpec(std::move(jsInvoker)) {
  jsInvoker_ = NativeNSEventCxxSpec::jsInvoker_;
  dispatch_async(dispatch_get_main_queue(), ^{
    [RNNSEventHelper shared].module = this;
    [[RNNSEventHelper shared] start];
  });
}

RNNSEvent::~RNNSEvent() {
  auto *ptr = this;
  dispatch_async(dispatch_get_main_queue(), ^{
    if ([RNNSEventHelper shared].module == ptr) {
      [[RNNSEventHelper shared] stop];
      [RNNSEventHelper shared].module = nullptr;
      if ([RNNSEventHelper shared].captured) {
        [RNNSEventHelper shared].captured = false;
        CGAssociateMouseAndMouseCursorPosition(true);
        [NSCursor unhide];
      }
    }
  });
}

// MARK: - Callbacks

void RNNSEvent::registerKeyboardEventCallback(
    jsi::Runtime &rt, std::optional<jsi::Function> callback) {
  auto cb = callback.has_value()
                ? std::make_shared<jsi::Function>(std::move(*callback))
                : nullptr;
  dispatch_async(dispatch_get_main_queue(), ^{
    auto old = [[RNNSEventHelper shared] clearKeyboardCallback];
    if (old) {
      jsInvoker_->invokeAsync([old](jsi::Runtime &rt) mutable { old.reset(); });
    }
    if (cb) {
      [[RNNSEventHelper shared] setKeyboardCallback:std::move(cb)];
    }
  });
}

void RNNSEvent::registerMouseButtonEventCallback(
    jsi::Runtime &rt, std::optional<jsi::Function> callback) {
  auto cb = callback.has_value()
                ? std::make_shared<jsi::Function>(std::move(*callback))
                : nullptr;
  dispatch_async(dispatch_get_main_queue(), ^{
    auto old = [[RNNSEventHelper shared] clearMouseButtonCallback];
    if (old) {
      jsInvoker_->invokeAsync([old](jsi::Runtime &rt) mutable { old.reset(); });
    }
    if (cb) {
      [[RNNSEventHelper shared] setMouseButtonCallback:std::move(cb)];
    }
  });
}

void RNNSEvent::registerScrollEventCallback(
    jsi::Runtime &rt, std::optional<jsi::Function> callback) {
  auto cb = callback.has_value()
                ? std::make_shared<jsi::Function>(std::move(*callback))
                : nullptr;
  dispatch_async(dispatch_get_main_queue(), ^{
    auto old = [[RNNSEventHelper shared] clearScrollCallback];
    if (old) {
      jsInvoker_->invokeAsync([old](jsi::Runtime &rt) mutable { old.reset(); });
    }
    if (cb) {
      [[RNNSEventHelper shared] setScrollCallback:std::move(cb)];
    }
  });
}

void RNNSEvent::registerMouseMoveEventCallback(
    jsi::Runtime &rt, std::optional<jsi::Function> callback) {
  auto cb = callback.has_value()
                ? std::make_shared<jsi::Function>(std::move(*callback))
                : nullptr;
  dispatch_async(dispatch_get_main_queue(), ^{
    auto old = [[RNNSEventHelper shared] clearMouseMoveCallback];
    if (old) {
      jsInvoker_->invokeAsync([old](jsi::Runtime &rt) mutable { old.reset(); });
    }
    if (cb) {
      [[RNNSEventHelper shared] setMouseMoveCallback:std::move(cb)];
    }
  });
}

// MARK: - Capture mode

void RNNSEvent::startCapture(jsi::Runtime &rt) {
  dispatch_async(dispatch_get_main_queue(), ^{
    [RNNSEventHelper shared].captured = true;
    g_mouseDeltaX.store(0, std::memory_order_relaxed);
    g_mouseDeltaY.store(0, std::memory_order_relaxed);
    CGAssociateMouseAndMouseCursorPosition(false);
    [NSCursor hide];
  });
}

void RNNSEvent::stopCapture(jsi::Runtime &rt) {
  dispatch_async(dispatch_get_main_queue(), ^{
    [RNNSEventHelper shared].captured = false;
    g_mouseDeltaX.store(0, std::memory_order_relaxed);
    g_mouseDeltaY.store(0, std::memory_order_relaxed);
    CGAssociateMouseAndMouseCursorPosition(true);
    [NSCursor unhide];
  });
}

bool RNNSEvent::isCaptureActive(jsi::Runtime &rt) {
  return [RNNSEventHelper shared].captured;
}

// MARK: - EventEmitter toggles

void RNNSEvent::toggleKeyboardEvents(jsi::Runtime &rt, bool enable) {
  dispatch_async(dispatch_get_main_queue(), ^{
    [RNNSEventHelper shared].keyboardEventsEnabled = enable;
  });
}

void RNNSEvent::toggleMouseButtonEvents(jsi::Runtime &rt, bool enable) {
  dispatch_async(dispatch_get_main_queue(), ^{
    [RNNSEventHelper shared].mouseButtonEventsEnabled = enable;
  });
}

void RNNSEvent::toggleScrollEvents(jsi::Runtime &rt, bool enable) {
  dispatch_async(dispatch_get_main_queue(), ^{
    [RNNSEventHelper shared].scrollEventsEnabled = enable;
  });
}

void RNNSEvent::toggleMouseMoveEvents(jsi::Runtime &rt, bool enable) {
  dispatch_async(dispatch_get_main_queue(), ^{
    [RNNSEventHelper shared].mouseMoveEventsEnabled = enable;
  });
}

// MARK: - Mouse delta polling

void RNNSEvent::_getMouseMoveDeltaAndReset(jsi::Runtime &rt,
                                           jsi::Object deltas) {
  if (!deltas.isArrayBuffer(rt)) {
    throw jsi::JSError(
        rt, "_getMouseMoveDeltaAndReset: argument must be an ArrayBuffer");
  }
  auto buf = deltas.getArrayBuffer(rt);
  if (buf.size(rt) < 8) {
    throw jsi::JSError(
        rt, "_getMouseMoveDeltaAndReset: buffer must be at least 8 bytes");
  }
  int32_t *ptr = reinterpret_cast<int32_t *>(buf.data(rt));
  ::getMouseMoveDeltaAndReset(ptr);
}

} // namespace facebook::react
