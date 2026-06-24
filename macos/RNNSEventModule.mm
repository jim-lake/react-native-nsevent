#include "RNNSEventModule.h"
#import <AppKit/AppKit.h>

namespace facebook::react {

static id monitor = nil;

// --- Platform functions ---

void platformStartCapture() {
  dispatch_async(dispatch_get_main_queue(), ^{
    CGAssociateMouseAndMouseCursorPosition(false);
    [NSCursor hide];
  });
}

void platformStopCapture() {
  dispatch_async(dispatch_get_main_queue(), ^{
    CGAssociateMouseAndMouseCursorPosition(true);
    [NSCursor unhide];
  });
}

void platformInstallMonitor(
    std::function<void(const char *type, int keyCode,
                       unsigned long modifierFlags, int buttonNumber,
                       double locationX, double locationY, double scrollDeltaX,
                       double scrollDeltaY)>
        eventCb,
    std::function<void(double dx, double dy)> mouseCb,
    std::function<bool()> isCapturedCb) {
  platformRemoveMonitor();

  NSEventMask mask = NSEventMaskKeyDown | NSEventMaskKeyUp |
                     NSEventMaskFlagsChanged | NSEventMaskLeftMouseDown |
                     NSEventMaskLeftMouseUp | NSEventMaskRightMouseDown |
                     NSEventMaskRightMouseUp | NSEventMaskOtherMouseDown |
                     NSEventMaskOtherMouseUp | NSEventMaskScrollWheel |
                     NSEventMaskMouseMoved | NSEventMaskLeftMouseDragged |
                     NSEventMaskRightMouseDragged |
                     NSEventMaskOtherMouseDragged;

  auto handler = ^NSEvent *(NSEvent *event) {
    NSWindow *window = event.window;
    if (!window || !window.isKeyWindow || !NSApp.isActive) {
      return event;
    }

    NSEventType type = event.type;

    if (isCapturedCb() &&
        (type == NSEventTypeMouseMoved || type == NSEventTypeLeftMouseDragged ||
         type == NSEventTypeRightMouseDragged ||
         type == NSEventTypeOtherMouseDragged)) {
      mouseCb(event.deltaX, event.deltaY);
      return event;
    }

    // Skip key repeats
    if (type == NSEventTypeKeyDown && event.isARepeat) {
      return event;
    }

    const char *typeStr = nullptr;
    int keyCode = -1;
    unsigned long modifierFlags = 0;
    int buttonNumber = -1;
    double locationX = 0, locationY = 0;
    double scrollDeltaX = 0, scrollDeltaY = 0;

    switch (type) {
    case NSEventTypeKeyDown:
      typeStr = "keyDown";
      keyCode = event.keyCode;
      modifierFlags = event.modifierFlags;
      break;
    case NSEventTypeKeyUp:
      typeStr = "keyUp";
      keyCode = event.keyCode;
      modifierFlags = event.modifierFlags;
      break;
    case NSEventTypeFlagsChanged:
      typeStr = "flagsChanged";
      keyCode = event.keyCode;
      modifierFlags = event.modifierFlags;
      break;
    case NSEventTypeLeftMouseDown:
    case NSEventTypeRightMouseDown:
    case NSEventTypeOtherMouseDown:
      typeStr = "mouseDown";
      buttonNumber = (int)event.buttonNumber;
      locationX = event.locationInWindow.x;
      locationY = event.locationInWindow.y;
      break;
    case NSEventTypeLeftMouseUp:
    case NSEventTypeRightMouseUp:
    case NSEventTypeOtherMouseUp:
      typeStr = "mouseUp";
      buttonNumber = (int)event.buttonNumber;
      locationX = event.locationInWindow.x;
      locationY = event.locationInWindow.y;
      break;
    case NSEventTypeScrollWheel:
      typeStr = "scroll";
      scrollDeltaX = event.scrollingDeltaX;
      scrollDeltaY = event.scrollingDeltaY;
      break;
    default:
      break;
    }

    if (typeStr) {
      eventCb(typeStr, keyCode, modifierFlags, buttonNumber, locationX,
              locationY, scrollDeltaX, scrollDeltaY);
    }

    return event;
  };

  monitor = [NSEvent addLocalMonitorForEventsMatchingMask:mask handler:handler];
}

void platformRemoveMonitor() {
  if (monitor) {
    [NSEvent removeMonitor:monitor];
    monitor = nil;
  }
}

// --- RNNSEventModule implementation ---

RNNSEventModule::RNNSEventModule(std::shared_ptr<CallInvoker> jsInvoker)
    : NativeRNNSEventCxxSpecJSI(std::move(jsInvoker)) {
  platformInstallMonitor(
      [this](const char *type, int keyCode, unsigned long modifierFlags,
             int buttonNumber, double locationX, double locationY,
             double scrollDeltaX, double scrollDeltaY) {
        if (!callback_ || !runtime_) {
          return;
        }
        jsInvoker_->invokeAsync([this, typeStr = std::string(type), keyCode,
                                 modifierFlags, buttonNumber, locationX,
                                 locationY, scrollDeltaX, scrollDeltaY]() {
          if (!callback_ || !runtime_) {
            return;
          }
          auto &rt = *runtime_;
          jsi::Object obj(rt);
          obj.setProperty(rt, "type",
                          jsi::String::createFromAscii(rt, typeStr));

          if (typeStr == "keyDown" || typeStr == "keyUp" ||
              typeStr == "flagsChanged") {
            obj.setProperty(rt, "keyCode", (double)keyCode);
            obj.setProperty(rt, "shift",
                            (bool)(modifierFlags & NSEventModifierFlagShift));
            obj.setProperty(rt, "control",
                            (bool)(modifierFlags & NSEventModifierFlagControl));
            obj.setProperty(rt, "option",
                            (bool)(modifierFlags & NSEventModifierFlagOption));
            obj.setProperty(rt, "command",
                            (bool)(modifierFlags & NSEventModifierFlagCommand));
            obj.setProperty(
                rt, "capsLock",
                (bool)(modifierFlags & NSEventModifierFlagCapsLock));
            obj.setProperty(
                rt, "function",
                (bool)(modifierFlags & NSEventModifierFlagFunction));
          } else if (typeStr == "mouseDown" || typeStr == "mouseUp") {
            obj.setProperty(rt, "button", (double)buttonNumber);
            obj.setProperty(rt, "x", locationX);
            obj.setProperty(rt, "y", locationY);
          } else if (typeStr == "scroll") {
            obj.setProperty(rt, "deltaX", scrollDeltaX);
            obj.setProperty(rt, "deltaY", scrollDeltaY);
          }

          callback_->call(rt, obj);
        });
      },
      [](double dx, double dy) {
        mouseState.dx.fetch_add(static_cast<int64_t>(dx),
                                std::memory_order_relaxed);
        mouseState.dy.fetch_add(static_cast<int64_t>(dy),
                                std::memory_order_relaxed);
      },
      [this]() { return captured_; });
}

RNNSEventModule::~RNNSEventModule() {
  platformRemoveMonitor();
  if (captured_) {
    platformStopCapture();
  }
}

void RNNSEventModule::registerEventCallback(
    jsi::Runtime &rt, std::optional<jsi::Function> callback) {
  runtime_ = &rt;
  if (!callback.has_value()) {
    callback_ = nullptr;
  } else {
    callback_ = std::make_shared<jsi::Function>(std::move(callback.value()));
  }
}

void RNNSEventModule::startCapture(jsi::Runtime &rt) {
  captured_ = true;
  mouseState.dx.store(0, std::memory_order_relaxed);
  mouseState.dy.store(0, std::memory_order_relaxed);
  platformStartCapture();
}

void RNNSEventModule::stopCapture(jsi::Runtime &rt) {
  captured_ = false;
  mouseState.dx.store(0, std::memory_order_relaxed);
  mouseState.dy.store(0, std::memory_order_relaxed);
  platformStopCapture();
}

jsi::Object RNNSEventModule::getMouseAndReset(jsi::Runtime &rt) {
  jsi::Object result(rt);
  result.setProperty(
      rt, "dx", (double)mouseState.dx.exchange(0, std::memory_order_acq_rel));
  result.setProperty(
      rt, "dy", (double)mouseState.dy.exchange(0, std::memory_order_acq_rel));
  return result;
}

bool RNNSEventModule::isCaptureActive(jsi::Runtime &rt) { return captured_; }

} // namespace facebook::react
