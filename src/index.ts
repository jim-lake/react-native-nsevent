import NativeRNNSEvent from './NativeRNNSEvent';

export type NSEventEvent =
  | {
      type: 'keyDown' | 'keyUp' | 'flagsChanged';
      keyCode: number;
      shift: boolean;
      control: boolean;
      option: boolean;
      command: boolean;
      capsLock: boolean;
      function: boolean;
    }
  | { type: 'mouseDown' | 'mouseUp'; button: number; x: number; y: number }
  | { type: 'scroll'; deltaX: number; deltaY: number };

export const registerEventCallback = NativeRNNSEvent.registerEventCallback as (
  callback: ((event: NSEventEvent) => void) | null
) => void;

export const { startCapture, stopCapture, getMouseAndReset, isCaptureActive } =
  NativeRNNSEvent;
