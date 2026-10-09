const { remote } = require('webdriverio');
const path = require('node:path');

async function main() {
  const driver = await remote({
    hostname: '127.0.0.1',
    port: 4723,
    logLevel: 'error',
    capabilities: {
      platformName: 'Android',
      'appium:automationName': 'UiAutomator2',
      'appium:udid': 'emulator-5554',
      'appium:app': path.resolve(__dirname, '..', 'build', 'app',
        'outputs', 'flutter-apk', 'app-release.apk'),
      'appium:fullReset': true,
    },
  });

  try {
    const login = await driver.$('~Log in or sign up');
    await login.waitForDisplayed({ timeout: 30000 });
    await login.click();

    const continueButton = await driver.$('~Continue');
    await continueButton.waitForDisplayed({ timeout: 10000 });
    await continueButton.click();

    await driver.waitUntil(async () => {
      const screen = await driver.getPageSource();
      return screen.includes('Enter a valid email address.') &&
        screen.includes('Enter your password.');
    }, { timeout: 10000, timeoutMsg: 'Login validation errors did not appear' });

    console.log('PASS: Empty login shows both validation errors');
  } finally {
    await driver.deleteSession();
  }
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});