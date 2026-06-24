#include "RNNSEventModule.h"
#import <Foundation/Foundation.h>
#include <ReactCommon/CxxTurboModuleUtils.h>

@interface RNNSEventLoader : NSObject
@end

@implementation RNNSEventLoader

+ (void)load {
  facebook::react::registerCxxModuleToGlobalModuleMap(
      "RNNSEvent", [](std::shared_ptr<facebook::react::CallInvoker> jsInvoker) {
        return std::make_shared<facebook::react::RNNSEventModule>(
            std::move(jsInvoker));
      });
}

@end
