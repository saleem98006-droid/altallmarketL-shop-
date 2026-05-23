# iOS setup notes — tm_shop

This folder is prepared for iOS builds but requires CocoaPods steps on macOS to complete the setup.

Steps to finish on macOS:

1. Install CocoaPods (if not installed):

```bash
sudo gem install cocoapods
# or with Homebrew + Ruby setup if you prefer
```

2. From the project root, fetch Dart/Flutter packages:

```bash
cd "project/new1/tm_shop"
flutter pub get
```

3. Run CocoaPods in the `ios/` folder to create `Pods/` and `Podfile.lock` and update the workspace:

```bash
cd ios
pod repo update
pod install
```

4. Open the workspace in Xcode and verify signing & targets:

```bash
open Runner.xcworkspace
```

Notes:
- I did not create `Pods/` or `Podfile.lock` here because `pod install` must run on macOS with CocoaPods available.
- The `Podfile` is present and targets iOS 14.0.
