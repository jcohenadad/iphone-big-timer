# Big Timer (iPhone, SwiftUI)

Huge full-screen countdown. Presets + wheel picker for setup. Rings (even in silent mode) when time is up,
and via notifications when the phone is locked or the app is in the background.

Requirements: Mac with Xcode 16+, iPhone on iOS 17+.

## Install on your iPhone without a cable
1. On the iPhone: Wi-Fi on, same network as the Mac, phone unlocked.
2. Double-click `BigTimer.xcodeproj`. Xcode > Settings > Accounts: add your Apple ID (free is fine).
3. Click the BigTimer project > target BigTimer > Signing & Capabilities > Team: pick your "Personal Team".
   If the bundle ID is rejected, change it to something unique (e.g. com.yourname.bigtimer).
4. Xcode > Window > Devices and Simulators. Your iPhone should appear under "Discovered" — click **Pair**
   and type the code shown on the iPhone.
5. On the iPhone: Settings > Privacy & Security > Developer Mode > On (the phone restarts).
6. In Xcode's top bar choose your iPhone as run destination and press Run (⌘R).
7. First launch only: Settings > General > VPN & Device Management > trust your developer app.
8. Allow notifications when the app asks (needed for ringing while locked).

Free Apple ID builds expire after 7 days: just press Run again from Xcode (the phone needs to be on the same Wi-Fi).

## Using it
- Tap a preset chip or tap the big digits to open the setup wheel.
- Start / Pause / Resume with the big button, or tap the digits.
- +1:00 adds a minute (snoozes when ringing). ↺ resets.
- When time is up: screen flashes red, alarm loops, overtime counts up. Tap Stop.
- Turn the phone sideways for even bigger digits.
