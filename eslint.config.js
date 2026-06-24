import js from '@eslint/js';
import tseslint from 'typescript-eslint';

export default [
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    rules: {
      'no-empty': ['error', { allowEmptyCatch: true }],
    },
  },
  {
    files: ['__tests__/**/*.ts'],
    languageOptions: {
      globals: { describe: 'readonly', it: 'readonly', beforeAll: 'readonly', afterAll: 'readonly', expect: 'readonly', setTimeout: 'readonly' },
    },
    rules: {
      '@typescript-eslint/no-explicit-any': 'off',
    },
  },
  {
    files: ['src/NativeRNNSEvent.ts'],
    rules: {
      '@typescript-eslint/no-wrapper-object-types': 'off',
    },
  },
  { ignores: ['node_modules/', 'lib/', 'example/'] },
];
