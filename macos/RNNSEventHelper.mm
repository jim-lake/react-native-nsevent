#import "RNNSEventHelper.h"
#import "RNNSEventModule.h"
#import <AppKit/AppKit.h>

std::atomic<int32_t> g_mouseDeltaX{0};
std::atomic<int32_t> g_mouseDeltaY{0};
static std::atomic<int32_t> g_mouseCallbackDeltaX{0};
static std::atomic<int32_t> g_mouseCallbackDeltaY{0};

@implementation RNNSEventHelper {
  std::shared_ptr<facebook::jsi::Function> _keyboardCallback;
  std::shared_ptr<facebook::jsi::Function> _mouseButtonCallback;
  std::shared_ptr<facebook::jsi::Function> _scrollCallback;
  std::shared_ptr<facebook::jsi::Function> _mouseMoveCallback;
  id _monitor;
}

+ (instancetype)shared {
  static RNNSEventHelper *instance = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[RNNSEventHelper alloc] init];
  });
  return instance;
}

- (void)start {
  if (_monitor) {
    return;
  }

  NSEventMask mask = NSEventMaskKeyDown | NSEventMaskKeyUp |
                     NSEventMaskFlagsChanged | NSEventMaskLeftMouseDown |
                     NSEventMaskLeftMouseUp | NSEventMaskRightMouseDown |
                     NSEventMaskRightMouseUp | NSEventMaskOtherMouseDown |
                     NSEventMaskOtherMouseUp | NSEventMaskScrollWheel |
                     NSEventMaskMouseMoved | NSEventMaskLeftMouseDragged |
                     NSEventMaskRightMouseDragged |
                     NSEventMaskOtherMouseDragged;

  _monitor =
      [NSEvent addLocalMonitorForEventsMatchingMask:mask
                                            handler:^NSEvent *(NSEvent *event) {
                                              [self handleEvent:event];
                                              return event;
                                            }];
}

- (void)handleEvent:(NSEvent *)event {
  if (!self.module) {
    return;
  }

  NSWindow *window = event.window;
  if (!window || !window.isKeyWindow || !NSApp.isActive) {
    return;
  }

  NSEventType type = event.type;

  // Mouse move / drag events
  if (type == NSEventTypeMouseMoved || type == NSEventTypeLeftMouseDragged ||
      type == NSEventTypeRightMouseDragged ||
      type == NSEventTypeOtherMouseDragged) {
    [self handleMouseMove:event];
    return;
  }

  // Keyboard events
  if (type == NSEventTypeKeyDown || type == NSEventTypeKeyUp ||
      type == NSEventTypeFlagsChanged) {
    // Skip key repeats
    if (type == NSEventTypeKeyDown && event.isARepeat) {
      return;
    }
    [self handleKeyboard:event];
    return;
  }

  // Mouse button events
  if (type == NSEventTypeLeftMouseDown || type == NSEventTypeLeftMouseUp ||
      type == NSEventTypeRightMouseDown || type == NSEventTypeRightMouseUp ||
      type == NSEventTypeOtherMouseDown || type == NSEventTypeOtherMouseUp) {
    [self handleMouseButton:event];
    return;
  }

  // Scroll events
  if (type == NSEventTypeScrollWheel) {
    [self handleScroll:event];
    return;
  }
}

- (void)handleMouseMove:(NSEvent *)event {
  int32_t dx = (int32_t)event.deltaX;
  int32_t dy = (int32_t)event.deltaY;

  // Always accumulate for the polling interface
  g_mouseDeltaX.fetch_add(dx, std::memory_order_relaxed);
  g_mouseDeltaY.fetch_add(dy, std::memory_order_relaxed);

  // Callback interface — accumulate separately, coalesce on JS thread
  if (_mouseMoveCallback) {
    g_mouseCallbackDeltaX.fetch_add(dx, std::memory_order_relaxed);
    g_mouseCallbackDeltaY.fetch_add(dy, std::memory_order_relaxed);
    auto cb = _mouseMoveCallback;
    self.module->jsInvoker_->invokeAsync([cb](facebook::jsi::Runtime &rt) {
      int32_t cdx =
          g_mouseCallbackDeltaX.exchange(0, std::memory_order_relaxed);
      int32_t cdy =
          g_mouseCallbackDeltaY.exchange(0, std::memory_order_relaxed);
      if (cdx != 0 || cdy != 0) {
        cb->call(rt, cdx, cdy);
      }
    });
  }

  // EventEmitter interface
  if (self.mouseMoveEventsEnabled) {
    facebook::react::MouseMoveEventStruct evt{dx, dy};
    self.module->emitOnMouseMoveEvent(evt);
  }
}

- (void)handleKeyboard:(NSEvent *)event {
  int keyCode = (int)event.keyCode;
  bool pressed = (event.type != NSEventTypeKeyUp);
  unsigned long flags = event.modifierFlags;
  bool shift = (flags & NSEventModifierFlagShift) != 0;
  bool control = (flags & NSEventModifierFlagControl) != 0;
  bool option = (flags & NSEventModifierFlagOption) != 0;
  bool command = (flags & NSEventModifierFlagCommand) != 0;
  bool capsLock = (flags & NSEventModifierFlagCapsLock) != 0;
  bool fn = (flags & NSEventModifierFlagFunction) != 0;

  // Callback interface
  if (_keyboardCallback) {
    auto cb = _keyboardCallback;
    self.module->jsInvoker_->invokeAsync([cb, keyCode, pressed, shift, control,
                                          option, command, capsLock,
                                          fn](facebook::jsi::Runtime &rt) {
      cb->call(rt, keyCode, pressed, shift, control, option, command, capsLock,
               fn);
    });
  }

  // EventEmitter interface
  if (self.keyboardEventsEnabled) {
    facebook::react::KeyboardEventStruct evt{
        keyCode, pressed, shift, control, option, command, capsLock, fn};
    self.module->emitOnKeyboardEvent(evt);
  }
}

- (void)handleMouseButton:(NSEvent *)event {
  int32_t button = (int32_t)event.buttonNumber;
  bool pressed = (event.type == NSEventTypeLeftMouseDown ||
                  event.type == NSEventTypeRightMouseDown ||
                  event.type == NSEventTypeOtherMouseDown);
  double x = event.locationInWindow.x;
  double y = event.locationInWindow.y;

  // Callback interface
  if (_mouseButtonCallback) {
    auto cb = _mouseButtonCallback;
    self.module->jsInvoker_->invokeAsync(
        [cb, button, pressed, x, y](facebook::jsi::Runtime &rt) {
          cb->call(rt, button, pressed, x, y);
        });
  }

  // EventEmitter interface
  if (self.mouseButtonEventsEnabled) {
    facebook::react::MouseButtonEventStruct evt{button, pressed, x, y};
    self.module->emitOnMouseButton(evt);
  }
}

- (void)handleScroll:(NSEvent *)event {
  double deltaX = event.scrollingDeltaX;
  double deltaY = event.scrollingDeltaY;

  // Callback interface
  if (_scrollCallback) {
    auto cb = _scrollCallback;
    self.module->jsInvoker_->invokeAsync(
        [cb, deltaX, deltaY](facebook::jsi::Runtime &rt) {
          cb->call(rt, deltaX, deltaY);
        });
  }

  // EventEmitter interface
  if (self.scrollEventsEnabled) {
    facebook::react::ScrollEventStruct evt{deltaX, deltaY};
    self.module->emitOnScrollEvent(evt);
  }
}

- (void)stop {
  if (_monitor) {
    [NSEvent removeMonitor:_monitor];
    _monitor = nil;
  }
}

// MARK: - Keyboard callback

- (void)setKeyboardCallback:(std::shared_ptr<facebook::jsi::Function>)callback {
  _keyboardCallback = std::move(callback);
}

- (std::shared_ptr<facebook::jsi::Function>)clearKeyboardCallback {
  return std::move(_keyboardCallback);
}

// MARK: - Mouse button callback

- (void)setMouseButtonCallback:
    (std::shared_ptr<facebook::jsi::Function>)callback {
  _mouseButtonCallback = std::move(callback);
}

- (std::shared_ptr<facebook::jsi::Function>)clearMouseButtonCallback {
  return std::move(_mouseButtonCallback);
}

// MARK: - Scroll callback

- (void)setScrollCallback:(std::shared_ptr<facebook::jsi::Function>)callback {
  _scrollCallback = std::move(callback);
}

- (std::shared_ptr<facebook::jsi::Function>)clearScrollCallback {
  return std::move(_scrollCallback);
}

// MARK: - Mouse move callback

- (void)setMouseMoveCallback:
    (std::shared_ptr<facebook::jsi::Function>)callback {
  _mouseMoveCallback = std::move(callback);
}

- (std::shared_ptr<facebook::jsi::Function>)clearMouseMoveCallback {
  return std::move(_mouseMoveCallback);
}

@end
