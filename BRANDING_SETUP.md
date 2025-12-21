# Medilinko App Branding Setup

## Overview
This guide will help you set up the custom Medilinko logo as the app icon and splash screen.

## Prerequisites
1. A logo image file (PNG format recommended)
2. Image dimensions: At least 1024x1024 pixels for best results

## Setup Instructions

### Step 1: Add Logo Image
1. Create the `assets/images` folder in your project root (if it doesn't exist):
   ```
   mkdir -p assets/images
   ```

2. Place your Medilinko logo file in `assets/images/logo.png`

### Step 2: Update pubspec.yaml
The `pubspec.yaml` has already been updated with the necessary configurations:
- `flutter_launcher_icons` for app icon generation
- `flutter_native_splash` for splash screen

### Step 3: Install Dependencies
Run the following command to install the required packages:
```bash
flutter pub get
```

### Step 4: Generate App Icons
Run this command to generate app icons for both Android and iOS:
```bash
flutter pub run flutter_launcher_icons
```

This will create app launcher icons in:
- `android/app/src/main/res/mipmap-*/` (Android)
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/` (iOS)

### Step 5: Generate Splash Screen
Run this command to generate the native splash screen:
```bash
flutter pub run flutter_native_splash:create
```

This will create splash screen resources in:
- `android/app/src/main/res/drawable*/` (Android)
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/` (iOS)

### Step 6: Clean and Rebuild
After generating icons and splash screen:
```bash
flutter clean
flutter pub get
flutter run
```

## Configuration Details

### App Icon Configuration (in pubspec.yaml)
```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/logo.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/images/logo.png"
```

### Splash Screen Configuration (in pubspec.yaml)
```yaml
flutter_native_splash:
  color: "#FFFFFF"
  image: assets/images/logo.png
  android: true
  ios: true
```

## Customization Options

### Change Background Color
To change the splash screen background color, modify the `color` value:
```yaml
color: "#4C9AFF"  # Use your brand color
```

### Add Dark Mode Support
```yaml
flutter_native_splash:
  color: "#FFFFFF"
  color_dark: "#000000"
  image: assets/images/logo.png
  image_dark: assets/images/logo_dark.png
```

### Android Adaptive Icons
For Android 8.0+, you can customize the adaptive icon:
```yaml
adaptive_icon_background: "#FFFFFF"
adaptive_icon_foreground: "assets/images/logo_foreground.png"
```

## Troubleshooting

### Issue: Icons not showing after generation
- Solution: Run `flutter clean` and rebuild the app
- For Android: Uninstall the app completely before reinstalling

### Issue: Splash screen shows white flash
- Solution: Make sure you've run `flutter pub run flutter_native_splash:create`
- Restart your device/emulator

### Issue: iOS icons not updating
- Solution: Clean Xcode build folder:
  - Open Xcode
  - Product → Clean Build Folder
  - Rebuild in Xcode or run `flutter run`

## Verification

### Check App Icon
1. Install the app on a device/emulator
2. Check the home screen - you should see your logo as the app icon

### Check Splash Screen
1. Launch the app
2. The splash screen should display immediately with your logo
3. No white screen or default Flutter logo should appear

## Additional Resources
- [flutter_launcher_icons Documentation](https://pub.dev/packages/flutter_launcher_icons)
- [flutter_native_splash Documentation](https://pub.dev/packages/flutter_native_splash)

## Notes
- Always use high-resolution images (1024x1024 or higher)
- PNG format with transparency works best
- Test on both Android and iOS devices
- The splash screen will automatically adapt to different screen sizes
