#pragma once
#include "MouseState.h"
#include <RNNSEventSpecJSI.h>
#include <functional>
#include <memory>

namespace facebook::react {

void platformStartCapture();
void platformStopCapture();
void platformInstallMonitor(
    std::function<void(const char *type, int keyCode,
                       unsigned long modifierFlags, int buttonNumber,
                       double locationX, double locationY, double scrollDeltaX,
                       double scrollDeltaY)>
        eventCb,
    std::function<void(double dx, double dy)> mouseCb,
    std::function<bool()> isCapturedCb);
void platformRemoveMonitor();

class RNNSEventModule : public NativeRNNSEventCxxSpecJSI {
public:
  RNNSEventModule(std::shared_ptr<CallInvoker> jsInvoker);
  ~RNNSEventModule() override;

  void registerEventCallback(jsi::Runtime &rt,
                             std::optional<jsi::Function> callback) override;
  void startCapture(jsi::Runtime &rt) override;
  void stopCapture(jsi::Runtime &rt) override;
  jsi::Object getMouseAndReset(jsi::Runtime &rt) override;
  bool isCaptureActive(jsi::Runtime &rt) override;

private:
  std::shared_ptr<jsi::Function> callback_;
  jsi::Runtime *runtime_ = nullptr;
  bool captured_ = false;
};

} // namespace facebook::react
