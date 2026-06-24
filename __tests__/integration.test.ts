/**
 * Integration test: Use Appium mac2 to send keypresses and verify
 * the app registers them in the event log.
 *
 * Prerequisites:
 *   appium running on port 4723 with mac2 driver
 *   Release build of NSEventExample.app
 */

import { remote, Browser } from 'webdriverio';
import { execSync } from 'child_process';
import * as path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const APP_PATH = path.resolve(
  __dirname,
  '../example/macos/build/Build/Products/Release/NSEventExample.app'
);
const BUNDLE_ID = 'org.reactjs.native.NSEventExample';

describe('NSEvent Integration - Keypress', () => {
  let driver: Browser;

  beforeAll(async () => {
    // Kill any existing instance
    try {
      execSync('pkill -x NSEventExample', { stdio: 'ignore' });
    } catch {}
    await new Promise((r) => setTimeout(r, 1000));

    // Launch app
    execSync(`open "${APP_PATH}"`);
    await new Promise((r) => setTimeout(r, 3000));

    // Connect Appium
    driver = await remote({
      hostname: '127.0.0.1',
      port: 4723,
      capabilities: {
        platformName: 'mac',
        'appium:automationName': 'Mac2',
        'appium:bundleId': BUNDLE_ID,
        'appium:noReset': true,
      } as any,
    });
  }, 30000);

  afterAll(async () => {
    if (driver) await driver.deleteSession();
    try {
      execSync('pkill -x NSEventExample', { stdio: 'ignore' });
    } catch {}
  });

  it('should register keypresses in the event log', async () => {
    // Click Start Capture
    const btn = await driver.$('~toggle-capture-btn');
    await btn.click();
    await new Promise((r) => setTimeout(r, 500));

    // Send keypress to the app window
    await driver.keys(['a']);
    await new Promise((r) => setTimeout(r, 500));

    // Check the event log for the keypress
    const log = await driver.$('~event-log');
    const logEntries = await log.$$('*');

    // Get text from log entries
    let found = false;
    for (const entry of logEntries) {
      const text = await entry.getAttribute('value');
      if (text && text.includes('keyDown')) {
        found = true;
        break;
      }
    }

    expect(found).toBe(true);
  }, 15000);
});
