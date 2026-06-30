import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';
import type {
  EventEmitter,
  Int32,
} from 'react-native/Libraries/Types/CodegenTypes';

// Event interfaces (for EventEmitters)
export interface KeyboardEvent {
  keyCode: Int32;
  pressed: boolean;
  shift: boolean;
  control: boolean;
  option: boolean;
  command: boolean;
  capsLock: boolean;
  function: boolean;
}

export interface MouseButtonEvent {
  button: Int32;
  pressed: boolean;
  x: number;
  y: number;
}

export interface ScrollEvent {
  deltaX: number;
  deltaY: number;
}

export interface MouseMoveEvent {
  deltaX: Int32;
  deltaY: Int32;
}

// Callback types (for direct registration)
export type KeyboardEventCallback = (
  keyCode: Int32,
  pressed: boolean,
  shift: boolean,
  control: boolean,
  option: boolean,
  command: boolean,
  capsLock: boolean,
  fn: boolean
) => void;
export type MouseButtonEventCallback = (
  button: Int32,
  pressed: boolean,
  x: number,
  y: number
) => void;
export type ScrollEventCallback = (deltaX: number, deltaY: number) => void;
export type MouseMoveEventCallback = (deltaX: Int32, deltaY: Int32) => void;

export interface Spec extends TurboModule {
  // Callbacks — enabled by setting the callback
  registerKeyboardEventCallback(callback: KeyboardEventCallback | null): void;
  registerMouseButtonEventCallback(
    callback: MouseButtonEventCallback | null
  ): void;
  registerScrollEventCallback(callback: ScrollEventCallback | null): void;
  registerMouseMoveEventCallback(callback: MouseMoveEventCallback | null): void;

  // Capture mode
  startCapture(): void;
  stopCapture(): void;
  isCaptureActive(): boolean;

  // EventEmitter toggles — enable/disable EventEmitter delivery
  toggleKeyboardEvents(enable: boolean): void;
  toggleMouseButtonEvents(enable: boolean): void;
  toggleScrollEvents(enable: boolean): void;
  toggleMouseMoveEvents(enable: boolean): void;

  // Mouse delta accumulate-reset polling interface
  _getMouseMoveDeltaAndReset(deltas: Object): void;

  // EventEmitters
  readonly onKeyboardEvent: EventEmitter<KeyboardEvent>;
  readonly onMouseButton: EventEmitter<MouseButtonEvent>;
  readonly onScrollEvent: EventEmitter<ScrollEvent>;
  readonly onMouseMoveEvent: EventEmitter<MouseMoveEvent>;
}

export const nativeModule = TurboModuleRegistry.getEnforcing<Spec>('RNNSEvent');
