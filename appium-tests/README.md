# Appium tests (Android)

These tests run the Flutter Android app on a running emulator through Appium. The current test, `login-validation.cjs`, opens **Log in or sign up**, presses **Continue** with empty fields, and checks that both validation messages appear.

## One-time setup for each teammate

1. Install Flutter, Node.js, a JDK, and the Android SDK. Create an Android emulator in Android Studio (or use another emulator that appears in `adb devices`).
2. From a Command Prompt, install Appium and its Android driver if they are not already installed:

   ```bat
   npm.cmd install -g appium
   appium.cmd driver install uiautomator2
   ```

3. Install this test folder's dependencies:

   ```bat
   cd appium-tests
   npm.cmd ci
   cd ..
   ```

## Run the existing test

Use separate terminals for the Appium server and the test. Run steps 1 and 3 in the same Command Prompt so Appium receives the Android SDK settings.

1. Start an Android emulator and confirm its device ID:

   ```bat
   set "ANDROID_HOME=%LOCALAPPDATA%\Android\Sdk"
   set "PATH=%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\emulator;%PATH%"
   adb devices
   ```

   If your SDK is elsewhere, change `ANDROID_HOME` to its actual path. The test currently expects `emulator-5554`. If `adb devices` shows a different ID, change `appium:udid` in `login-validation.cjs`.

2. From the repository root, build the APK used by the test:

   ```bat
   flutter build apk --release
   ```

   The test reads `build/app/outputs/flutter-apk/app-release.apk`. Build it locally after pulling new app changes; the generated APK is not part of the test source.

3. Start Appium in one terminal and leave it running:

   ```bat
   appium.cmd
   ```

4. In another terminal, run the test:

   ```bat
   cd appium-tests
   npm.cmd test
   ```

   A successful run prints `PASS: Empty login shows both validation errors`. An error ends the command with a nonzero exit code. The test sets `appium:fullReset` to `true`, so Appium removes and reinstalls the app for each run, clearing its local app data.

## Add another test

1. Open the app in Appium Inspector to find a control's **accessibility id**. For example, `~Log in or sign up` in WebdriverIO matches the button's `content-desc` value.
2. Create another `.cjs` file in this folder. Follow `login-validation.cjs` for the Appium connection, `waitForDisplayed`, assertions, and `deleteSession()` cleanup.
3. Add a command for the new file to `package.json` under `scripts`, so teammates can run it consistently. Keep test credentials out of the repository.

Appium Inspector helps you inspect and click controls, but `npm.cmd test` runs the automated test. The Inspector plugin is optional for running this script.

## Keep a local result history (optional)

From `appium-tests` in Command Prompt:

```bat
echo %date% %time% >> test-history.txt
npm.cmd test >> test-history.txt 2>&1
```

Open `test-history.txt` to read past output. It is ignored by Git, so each teammate keeps their own history. Run `npm.cmd test` without redirection when you want to watch the output live.
