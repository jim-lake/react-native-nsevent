# react-native-nsevent

React Native macOS native module for window-scoped NSEvent input with relative mouse capture.

## Installation

```bash
npm install react-native-nsevent
cd macos && pod install
```

## API

```typescript
import {
  registerEventCallback,
  startCapture,
  stopCapture,
  getMouseAndReset,
  isCaptureActive,
} from 'react-native-nsevent';
```

### `registerEventCallback(callback | null)`
Register a callback for keyboard, mouse button, and scroll wheel events. Pass `null` to unregister.

### `startCapture()`
Enter relative mouse capture mode. Hides cursor and accumulates mouse deltas.

### `stopCapture()`
Exit capture mode. Restores cursor.

### `getMouseAndReset(): { dx, dy }`
Atomically read and reset accumulated mouse deltas. Call this per-frame from your game loop.

### `isCaptureActive(): boolean`
Returns whether capture mode is active.

## Example

```bash
cd example
npm install
cd macos && pod install && cd ..
npm run macos
```

## Testing

Unit tests:
```bash
npm test
```

Integration tests (requires Appium with mac2 driver):
```bash
appium driver install mac2
appium &
npm run test:integration
```
