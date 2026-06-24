/** @type {import('jest').Config} */
export default {
  preset: 'ts-jest/presets/default-esm',
  testMatch: ['**/__tests__/integration.test.ts'],
  testTimeout: 60000,
  extensionsToTreatAsEsm: ['.ts'],
  transform: {
    '^.+\\.ts$': ['ts-jest', { useESM: true }],
  },
};
