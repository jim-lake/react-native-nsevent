#pragma once

#include "RNNSEventSpecJSI.h"

namespace facebook::react {

// Type aliases for codegen structs
using KeyboardEventStruct =
    NativeNSEventKeyboardEvent<int, bool, bool, bool, bool, bool, bool, bool>;
using MouseButtonEventStruct =
    NativeNSEventMouseButtonEvent<int, bool, double, double>;
using ScrollEventStruct = NativeNSEventScrollEvent<double, double>;
using MouseMoveEventStruct = NativeNSEventMouseMoveEvent<int, int>;

// Bridging for KeyboardEvent
template <> struct Bridging<KeyboardEventStruct> {
  static KeyboardEventStruct
  fromJs(jsi::Runtime &rt, const jsi::Object &value,
         const std::shared_ptr<CallInvoker> &jsInvoker) {
    return NativeNSEventKeyboardEventBridging<KeyboardEventStruct>::fromJs(
        rt, value, jsInvoker);
  }
  static jsi::Object toJs(jsi::Runtime &rt, const KeyboardEventStruct &value,
                          const std::shared_ptr<CallInvoker> &jsInvoker) {
    return NativeNSEventKeyboardEventBridging<KeyboardEventStruct>::toJs(
        rt, value, jsInvoker);
  }
};

// Bridging for MouseButtonEvent
template <> struct Bridging<MouseButtonEventStruct> {
  static MouseButtonEventStruct
  fromJs(jsi::Runtime &rt, const jsi::Object &value,
         const std::shared_ptr<CallInvoker> &jsInvoker) {
    return NativeNSEventMouseButtonEventBridging<
        MouseButtonEventStruct>::fromJs(rt, value, jsInvoker);
  }
  static jsi::Object toJs(jsi::Runtime &rt, const MouseButtonEventStruct &value,
                          const std::shared_ptr<CallInvoker> &jsInvoker) {
    return NativeNSEventMouseButtonEventBridging<MouseButtonEventStruct>::toJs(
        rt, value, jsInvoker);
  }
};

// Bridging for ScrollEvent
template <> struct Bridging<ScrollEventStruct> {
  static ScrollEventStruct
  fromJs(jsi::Runtime &rt, const jsi::Object &value,
         const std::shared_ptr<CallInvoker> &jsInvoker) {
    return NativeNSEventScrollEventBridging<ScrollEventStruct>::fromJs(
        rt, value, jsInvoker);
  }
  static jsi::Object toJs(jsi::Runtime &rt, const ScrollEventStruct &value,
                          const std::shared_ptr<CallInvoker> &jsInvoker) {
    return NativeNSEventScrollEventBridging<ScrollEventStruct>::toJs(rt, value,
                                                                     jsInvoker);
  }
};

// Bridging for MouseMoveEvent
template <> struct Bridging<MouseMoveEventStruct> {
  static MouseMoveEventStruct
  fromJs(jsi::Runtime &rt, const jsi::Object &value,
         const std::shared_ptr<CallInvoker> &jsInvoker) {
    return NativeNSEventMouseMoveEventBridging<MouseMoveEventStruct>::fromJs(
        rt, value, jsInvoker);
  }
  static jsi::Object toJs(jsi::Runtime &rt, const MouseMoveEventStruct &value,
                          const std::shared_ptr<CallInvoker> &jsInvoker) {
    return NativeNSEventMouseMoveEventBridging<MouseMoveEventStruct>::toJs(
        rt, value, jsInvoker);
  }
};

class RNNSEvent : public NativeNSEventCxxSpec<RNNSEvent> {
public:
  RNNSEvent(std::shared_ptr<CallInvoker> jsInvoker);
  ~RNNSEvent();

  // Promote emit methods to public so the helper can call them
  using NativeNSEventCxxSpec<RNNSEvent>::emitOnKeyboardEvent;
  using NativeNSEventCxxSpec<RNNSEvent>::emitOnMouseButton;
  using NativeNSEventCxxSpec<RNNSEvent>::emitOnScrollEvent;
  using NativeNSEventCxxSpec<RNNSEvent>::emitOnMouseMoveEvent;

  // Spec methods
  void registerKeyboardEventCallback(jsi::Runtime &rt,
                                     std::optional<jsi::Function> callback);
  void registerMouseButtonEventCallback(jsi::Runtime &rt,
                                        std::optional<jsi::Function> callback);
  void registerScrollEventCallback(jsi::Runtime &rt,
                                   std::optional<jsi::Function> callback);
  void registerMouseMoveEventCallback(jsi::Runtime &rt,
                                      std::optional<jsi::Function> callback);
  void startCapture(jsi::Runtime &rt);
  void stopCapture(jsi::Runtime &rt);
  bool isCaptureActive(jsi::Runtime &rt);
  void toggleKeyboardEvents(jsi::Runtime &rt, bool enable);
  void toggleMouseButtonEvents(jsi::Runtime &rt, bool enable);
  void toggleScrollEvents(jsi::Runtime &rt, bool enable);
  void toggleMouseMoveEvents(jsi::Runtime &rt, bool enable);
  void _getMouseMoveDeltaAndReset(jsi::Runtime &rt, jsi::Object deltas);

  std::shared_ptr<CallInvoker> jsInvoker_;
};

} // namespace facebook::react
