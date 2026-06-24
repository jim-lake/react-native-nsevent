import type { TurboModule } from 'react-native';
import { TurboModuleRegistry } from 'react-native';

export interface Spec extends TurboModule {
  registerEventCallback(callback: ((event: Object) => void) | null): void;
  startCapture(): void;
  stopCapture(): void;
  getMouseAndReset(): { dx: number; dy: number };
  isCaptureActive(): boolean;
}

export default TurboModuleRegistry.getEnforcing<Spec>('RNNSEvent');
