# FIX.md — Issues to Address Before Shipping

## Bugs

### 1. `NSCursor hide/unhide` not balanced on repeated calls
Calling `startCapture()` twice without `stopCapture()` will call `[NSCursor hide]` twice, requiring two `unhide` calls to restore. The destructor only calls `platformStopCapture()` once.

**Fix:** Guard `startCapture`/`stopCapture` with early returns if `captured_` is already in the desired state, or track hide count.

### ~~3. OtherMouseDown/Up not handled~~ FIXED
Added `NSEventMaskOtherMouseDown | NSEventMaskOtherMouseUp` to the mask and `NSEventTypeOtherMouseDown`/`NSEventTypeOtherMouseUp` to the switch.

## Cleanup

### 3. `react-native.config.js` references `ios` instead of `macos`
The platforms key is `ios` but this module only targets macOS. React Native macOS uses the `macos` platform key for autolinking.

**Fix:**
```js
platforms: {
  macos: {
    podspecPath: './react-native-nsevent.podspec',
  },
  android: null,
  ios: null,
},
```

### 4. No unit `test` script in package.json
`package.json` has `test:integration` but no `test` script. The README says `npm test` works.

**Fix:** Add a `"test"` script or document that only integration tests exist.

### 5. `static id monitor` is a file-scoped global
If the module is ever instantiated twice (unlikely but possible with hot reload), the second instance overwrites the first's monitor without removing it, leaking the first.

**Fix:** Make `monitor` an instance member of `RNNSEventModule`, or guard `platformInstallMonitor` to remove any prior monitor first.

## Testing Gaps

### 10. No unit tests for the TypeScript layer
No mocks or unit tests exist for `src/index.ts` or `NativeRNNSEvent.ts`. The only test is the Appium integration test.

**Suggested:** Add a simple unit test confirming the exports exist and the types are correct (using a mock TurboModule).

### 11. Integration test doesn't verify mouse capture
The test only checks keypress events. `startCapture`, `stopCapture`, `getMouseAndReset`, and scroll events are untested.

### 12. No test for `registerEventCallback(null)` (unregister)
Edge case: unregistering the callback while events are in-flight could hit the race in item #2.

## Summary

Priority order for shipping:
1. Autolinking fix (#3) — consumers won't be able to install without it
2. Cursor balance (#1) — cosmetic but annoying
3. Everything else — polish
