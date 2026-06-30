#pragma once

#import <Foundation/Foundation.h>
#include <atomic>
#include <jsi/jsi.h>

namespace facebook::react {
class RNNSEvent;
}

// Global mouse delta accumulators for the polling interface (always active)
extern std::atomic<int32_t> g_mouseDeltaX;
extern std::atomic<int32_t> g_mouseDeltaY;
inline void getMouseMoveDeltaAndReset(int32_t deltas[2]) {
  deltas[0] = g_mouseDeltaX.exchange(0, std::memory_order_relaxed);
  deltas[1] = g_mouseDeltaY.exchange(0, std::memory_order_relaxed);
}

@interface RNNSEventHelper : NSObject

@property(nonatomic, assign) facebook::react::RNNSEvent *module;
@property(nonatomic, assign) bool keyboardEventsEnabled;
@property(nonatomic, assign) bool mouseButtonEventsEnabled;
@property(nonatomic, assign) bool scrollEventsEnabled;
@property(nonatomic, assign) bool mouseMoveEventsEnabled;
@property(nonatomic, assign) bool captured;

+ (instancetype)shared;
- (void)start;
- (void)stop;

- (void)setKeyboardCallback:(std::shared_ptr<facebook::jsi::Function>)callback;
- (std::shared_ptr<facebook::jsi::Function>)clearKeyboardCallback;

- (void)setMouseButtonCallback:
    (std::shared_ptr<facebook::jsi::Function>)callback;
- (std::shared_ptr<facebook::jsi::Function>)clearMouseButtonCallback;

- (void)setScrollCallback:(std::shared_ptr<facebook::jsi::Function>)callback;
- (std::shared_ptr<facebook::jsi::Function>)clearScrollCallback;

- (void)setMouseMoveCallback:(std::shared_ptr<facebook::jsi::Function>)callback;
- (std::shared_ptr<facebook::jsi::Function>)clearMouseMoveCallback;

@end
