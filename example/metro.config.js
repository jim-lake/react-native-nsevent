const path = require('path');
const { getDefaultConfig, mergeConfig } = require('@react-native/metro-config');

const root = path.resolve(__dirname, '..');
const exclusionList = require(
  path.resolve(
    __dirname,
    'node_modules/metro-config/src/defaults/exclusionList'
  )
).default;

const config = {
  watchFolders: [root],
  resolver: {
    extraNodeModules: {
      'react-native-nsevent': root,
      react: path.resolve(__dirname, 'node_modules/react'),
      'react-native': path.resolve(__dirname, 'node_modules/react-native'),
      'react-native-macos': path.resolve(
        __dirname,
        'node_modules/react-native-macos'
      ),
    },
    blockList: exclusionList([
      new RegExp(
        root.replace(/[/\\]/g, '[/\\\\]') +
          '[/\\\\]node_modules[/\\\\]react[/\\\\].*'
      ),
      new RegExp(
        root.replace(/[/\\]/g, '[/\\\\]') +
          '[/\\\\]node_modules[/\\\\]react-native[/\\\\].*'
      ),
    ]),
  },
};

module.exports = mergeConfig(getDefaultConfig(__dirname), config);
