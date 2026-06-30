import { nativeModule } from '../spec/NativeNSEvent';
import type { Spec } from '../spec/NativeNSEvent';
export type * from '../spec/NativeNSEvent';

export interface PublicSpec extends Omit<Spec, '_getMouseMoveDeltaAndReset'> {
  getMouseMoveDeltaAndReset(deltas: Int32Array): void;
}

const exportedModule = nativeModule as unknown as PublicSpec;

exportedModule.getMouseMoveDeltaAndReset = (deltas: Int32Array) => {
  nativeModule._getMouseMoveDeltaAndReset(deltas.buffer);
};

export default exportedModule;
