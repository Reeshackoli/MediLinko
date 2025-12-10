# API Configuration Guide

## Overview
The API URL is now configurable using environment variables, making it easier for multiple developers to work on the same codebase without conflicts.

## Default Behavior
- **Web & iOS Simulator**: `http://localhost:3000/api`
- **Android Emulator**: `http://10.0.2.2:3000/api` (needs manual config)
- **Physical Devices**: Must use `--dart-define` flag

## Running on Different Devices

### 1. Web Browser (Chrome/Edge)
```bash
flutter run -d chrome
```
Default URL: `http://localhost:3000/api`

### 2. Android Emulator
```bash
flutter run
```
Default URL: `http://localhost:3000/api`

> **Note**: Android emulator should use `http://10.0.2.2:3000/api` to access localhost. You may need to override:
```bash
flutter run --dart-define=API_URL=http://10.0.2.2:3000/api
```

### 3. iOS Simulator
```bash
flutter run
```
Default URL: `http://localhost:3000/api`

### 4. Physical Device (Android/iOS)

**Step 1**: Find your computer's IP address
- **Windows**: `ipconfig` (look for IPv4 Address under Wi-Fi adapter)
- **Mac**: `ifconfig | grep "inet "` or System Preferences → Network
- **Linux**: `ip addr show` or `hostname -I`

**Step 2**: Ensure backend is accessible
- Backend must use `HOST='0.0.0.0'` in `server.js` (already configured)
- Both devices must be on the same Wi-Fi network

**Step 3**: Run with custom API URL
```bash
flutter run --dart-define=API_URL=http://YOUR_IP:3000/api
```

**Example**:
```bash
flutter run --dart-define=API_URL=http://192.168.1.100:3000/api
```

## Backend Configuration

Ensure your `backend/server.js` has:
```javascript
const HOST = '0.0.0.0'; // Listen on all network interfaces
```

This allows the backend to accept connections from other devices on the network.

## For Team Members

### Quick Start
1. Pull the latest code
2. Start backend: `cd backend && npm run dev`
3. Run Flutter app:
   - For web/emulator: `flutter run`
   - For physical device: `flutter run --dart-define=API_URL=http://YOUR_IP:3000/api`

### Important Notes
- **Never commit hardcoded IP addresses** to `api_config.dart`
- The default `localhost` configuration works for most development scenarios
- Only use `--dart-define` when testing on physical devices
- Make sure backend server is running before testing the app

## Troubleshooting

### "Connection refused" error
- ✅ Backend is running (`npm run dev` in backend folder)
- ✅ Using correct IP address for your device type
- ✅ Both devices on same Wi-Fi (for physical devices)
- ✅ Backend using `HOST='0.0.0.0'`

### "Route not found" error
- ✅ API URL includes `/api` at the end
- ✅ Example: `http://192.168.1.100:3000/api` (correct)
- ❌ Example: `http://192.168.1.100:3000` (incorrect)

### Changes not reflecting
- Stop the app completely
- Run `flutter clean`
- Run `flutter pub get`
- Restart with the `--dart-define` flag

## Production Deployment

For production, update the default URL in `api_config.dart`:
```dart
return 'https://your-production-api.com/api'; // Production URL
```

Or use environment variables in your CI/CD pipeline:
```bash
flutter build apk --dart-define=API_URL=https://your-production-api.com/api
```
