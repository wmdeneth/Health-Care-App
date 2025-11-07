# Modern Compass Flutter App

A simple modern compass built with Flutter using `flutter_compass` and `permission_handler`.

Setup

1. Ensure you have Flutter installed and set up.
2. From the project root run:

```bash
flutter pub get
flutter run
```

Platform notes

- Android: add the following permission to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

- iOS: add location usage description to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Used to access compass heading</string>
```

That's it. The app displays the current heading and a modern-looking compass face. If you want, I can add animations, marker pins, or integrate GPS-based features.

Notes & missing platform folders

If this repository doesn't contain `android/` or `ios/` folders (for example, if you started with a Dart-only project), generate platform folders with Flutter before building:

```powershell
# from project root
flutter create .
flutter pub get
flutter run
```

When testing on emulators, magnetometer data may be unavailable. For accurate compass readings test on a physical device.

If you'd like, I can prepare ready-to-apply Android and iOS manifest patches — tell me whether you want me to modify them automatically (I will only do so if those platform folders exist in the repo).