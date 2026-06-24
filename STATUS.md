# STATUS.md — react-native-nsevent

## What's Done

### Native Module (`macos/RNNSEvent.mm`, `macos/RNNSEvent.h`)
- Obj-C++ implementation using `NSEvent addLocalMonitorForEventsMatchingMask:`
- `std::atomic<int64_t>` mouse delta accumulator
- **JSI direct function invocation** for event callback — stores a `shared_ptr<jsi::Function>` and invokes it on each event (no RCTResponseSenderBlock, no events)
- JSI binding installed via `RCTJavaScriptDidLoadNotification`
- Exports: `clearEventCallback`, `startCapture`, `stopCapture`, `getMouseAndReset` (sync), `isCaptureActive` (sync)
- Global JSI function `RNNSEvent_registerCallback` installed at runtime for registering the callback
- Window-scoped, no CGEventTap, no permissions required
- Podspec depends on `React-Core`, `React-cxxreact`, `React-jsi`

### JS API (`src/index.ts`)
- TypeScript API: `registerEventCallback` calls the global JSI function directly
- `clearEventCallback` uses NativeModules bridge method
- Exports: `registerEventCallback`, `startCapture`, `stopCapture`, `getMouseAndReset`, `isCaptureActive`

### Example App (`example/`)
- Scaffolded with `@react-native-community/cli init` (RN 0.81.2) + `react-native-macos-init` (0.81.7)
- `App.tsx` has: Start/Stop Capture button, Copy Log button, scrollable event log
- Accessibility labels set: `toggle-capture-btn`, `copy-log-btn`, `event-log`, `log-entry`
- Metro configured to resolve `react-native-nsevent` from parent dir
- **Release build compiles and links successfully with JSI changes**

### Appium Integration — PARTIALLY WORKING
- Appium 3.5.2 + mac2 driver 4.0.1 installed
- **Accessibility tree IS fully exposed** — STATUS.md previously claimed this was impossible, that was WRONG
- Session creation works with `appium:app` (path to .app) or `appium:bundleId` (when WDA already warm)
- Elements found: `toggle-capture-btn`, `copy-log-btn`, `event-log` all visible in XCUITest tree
- Button click works, keypress sending works via W3C actions

### Crash Bug (CURRENT BLOCKER)
- **Old crash (fixed):** `RCTResponseSenderBlock` called multiple times — SIGABRT in `convertJSIFunctionToCallback`. Fixed by switching to JSI direct function storage.
- **New crash:** App crashes on launch when JS calls native methods. Crash in `ObjCTurboModule::performVoidMethodInvocation` — likely the JS bundle embedded in the release build is STALE (still references old `registerEventCallback` bridge method that no longer exists). Need to rebuild with `xcodebuild` which re-bundles JS.

### Unit Tests (`__tests__/nsevent.test.ts`)
- 6 tests, all passing (mock-based)

### Integration Tests (`__tests__/integration.test.ts`)
- Rewritten to use Appium mac2 driver with webdriverio
- Flow: launch app → click Start Capture → send keypress → verify event log
- **Blocked on the crash bug above**

## Appium Lessons Learned

1. **React Native macOS + Fabric DOES expose accessibility tree to XCUITest/Appium mac2** — previous STATUS.md was wrong
2. `appium:app` (path) — WDA launches the app. Creates session in ~3s once WDA is warm. BUT scopes to whatever app is frontmost — must ensure our app is frontmost.
3. `appium:bundleId` — works when app is already running AND frontmost, but hangs if WDA needs to "Open" the app by bundle ID (blocks on XCUIApplication launch).
4. WDA (`WebDriverAgentRunner`) builds from source on first session (~3s after first build). Runs on port 10100. Must kill between test runs or use `appium:systemPort`.
5. Need `osascript -e 'tell application "NSEventExample" to activate'` to ensure app is frontmost before session creation.
6. Port cleanup required: `pkill -9 -f WebDriverAgentRunner; pkill -9 -f xcodebuild` between sessions.

## Next Steps

1. **Rebuild the release app** — `xcodebuild` in example/macos will re-bundle JS with the new `src/index.ts` that uses the global JSI function
2. **Verify no crash** — launch the rebuilt app, confirm JSI binding installs and `registerEventCallback` works
3. **Run integration test** — the test is written and ready, just needs the crash fixed
4. **Test script** — needs to: kill old processes, start appium, activate app, create session with correct caps, run jest

## Key Config
- `package.json` — `"type": "module"`, ESM throughout
- `jest.integration.config.js` — `ts-jest/presets/default-esm`, 60s timeout
- Appium caps that work: `{platformName: "mac", appium:automationName: "Mac2", appium:app: "/path/to/NSEventExample.app"}`
- App bundle ID: `org.reactjs.native.NSEventExample`
