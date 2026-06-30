# react-native-nsevent

React Native macOS native module for window-scoped NSEvent input with relative mouse capture.

Three delivery interfaces for different use cases:

- **EventEmitters** — Deterministic delivery to React. Every event arrives as a structured object. Best for UI-driven responses where you need every event.
- **Callbacks** — Optimized delivery via direct JSI invocation. Lower overhead than EventEmitters, best for high-frequency input handling.
- **Delta Polling** — Accumulate-reset interface for render loops. Read accumulated mouse deltas once per frame without flooding the JS thread.

## Installation

```bash
npm install react-native-nsevent
cd macos && pod install
```

## API

```typescript
import NSEvent from 'react-native-nsevent';
```

### EventEmitters

Subscribe to events on mount, control delivery with toggles:

```typescript
// Subscribe (always — toggles control whether native fires them)
const sub = NSEvent.onKeyboardEvent((e) => { /* ... */ });
const sub2 = NSEvent.onMouseButton((e) => { /* ... */ });
const sub3 = NSEvent.onScrollEvent((e) => { /* ... */ });
const sub4 = NSEvent.onMouseMoveEvent((e) => { /* ... */ });

// Enable/disable delivery
NSEvent.toggleKeyboardEvents(true);
NSEvent.toggleMouseButtonEvents(true);
NSEvent.toggleScrollEvents(true);
NSEvent.toggleMouseMoveEvents(true);

// Cleanup
sub.remove();
```

### Callbacks

Register a callback for direct invocation (independent of EventEmitters):

```typescript
NSEvent.registerKeyboardEventCallback((keyCode, pressed, shift, control, option, command, capsLock, fn) => {});
NSEvent.registerMouseButtonEventCallback((button, pressed, x, y) => {});
NSEvent.registerScrollEventCallback((deltaX, deltaY) => {});
NSEvent.registerMouseMoveEventCallback((deltaX, deltaY) => {});

// Unregister
NSEvent.registerKeyboardEventCallback(null);
```

### Mouse Delta Polling

Always-on accumulate-reset interface for game loops:

```typescript
const deltas = new Int32Array(2);

// Per-frame in your game loop:
NSEvent.getMouseMoveDeltaAndReset(deltas);
const dx = deltas[0];
const dy = deltas[1];
```

### Capture Mode

Hide cursor and dissociate mouse for relative input:

```typescript
NSEvent.startCapture();
NSEvent.stopCapture();
NSEvent.isCaptureActive(); // boolean
```

## Example

```bash
cd example
npm install
cd macos && pod install && cd ..
npm run macos
```

## Development

```bash
npm run ts:check
npm run pretty
```
