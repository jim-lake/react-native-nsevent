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
    files: ['**/*.js'],
    languageOptions: {
      globals: { module: 'readonly', require: 'readonly' },
    },
  },
  {
    files: ['spec/NativeNSEvent.ts'],
    rules: {
      '@typescript-eslint/no-wrapper-object-types': 'off',
    },
  },
  { ignores: ['node_modules/', 'lib/', 'example/'] },
];
