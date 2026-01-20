# Backend URL Configuration Reference

## 🌐 Current Configuration

### Production Backend
```
URL: https://medilinko.onrender.com
API Base: https://medilinko.onrender.com/api
```

### Development Backend (Android Emulator)
```
URL: http://10.0.2.2:3000
API Base: http://10.0.2.2:3000/api
```

> **Note:** `10.0.2.2` is the special Android emulator address for localhost

## 🔧 How It Works

### Automatic URL Selection
The app automatically chooses the correct URL based on build mode:

| Build Mode | URL Used | When |
|------------|----------|------|
| **Release** | `https://medilinko.onrender.com/api` | Production APK/App Bundle |
| **Debug** | `http://10.0.2.2:3000/api` | `flutter run` in emulator |

### Code Implementation
Located in: `lib/core/constants/api_config.dart`

```dart
import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _productionUrl = 'https://medilinko.onrender.com/api';
  static const String _developmentUrl = 'http://10.0.2.2:3000/api';
  
  static String get baseUrl => kDebugMode ? _developmentUrl : _productionUrl;
}
```

## 📱 Usage in Code

All API services use `ApiConfig.baseUrl`:

```dart
// Example: Login API call
final response = await http.post(
  Uri.parse(ApiConfig.login),  // Automatically uses correct URL
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode(data),
);

// ApiConfig.login = '$baseUrl/auth/login'
// Production: https://medilinko.onrender.com/api/auth/login
// Debug: http://10.0.2.2:3000/api/auth/login
```

## 🔄 API Endpoints

All endpoints are automatically prefixed with the correct base URL:

### Auth Endpoints
- `ApiConfig.login` → `/auth/login`
- `ApiConfig.register` → `/auth/register`
- `ApiConfig.getMe` → `/auth/me`

### Profile Endpoints
- `ApiConfig.profile` → `/profile`
- `ApiConfig.wizardStep` → `/profile/wizard`

### User Endpoints
- `ApiConfig.doctors` → `/users/doctors`
- `ApiConfig.pharmacies` → `/users/pharmacies`

### Health Endpoint
- `ApiConfig.health` → `/health`

## 🚀 Testing Different Environments

### Test Production URL (in Debug Mode)
If you want to test production URL in debug mode:

1. Temporarily modify `api_config.dart`:
```dart
static String get baseUrl => _productionUrl; // Force production
```

2. Run the app:
```bash
flutter run
```

3. **Remember to revert** the change after testing

### Test Local Backend (Physical Device)
For physical devices, you need your computer's IP address:

1. Find your computer's IP (Windows):
```powershell
ipconfig
# Look for IPv4 Address (e.g., 192.168.1.100)
```

2. Temporarily modify `api_config.dart`:
```dart
static const String _developmentUrl = 'http://192.168.1.100:3000/api';
```

3. Ensure device and computer are on **same WiFi**

## 🔐 Emergency Service Configuration

Located in: `lib/services/emergency_web_service.dart`

```dart
static const String _baseUrl = kDebugMode 
    ? 'http://10.0.2.2:3000'  // Debug
    : 'https://medilinko.onrender.com';  // Production
```

## 📊 Environment Comparison

| Aspect | Development | Production |
|--------|-------------|------------|
| **Base URL** | `http://10.0.2.2:3000/api` | `https://medilinko.onrender.com/api` |
| **Build Mode** | Debug | Release |
| **kDebugMode** | `true` | `false` |
| **Network** | Local (emulator) | Internet (cloud) |
| **SSL** | ❌ HTTP | ✅ HTTPS |
| **Build Command** | `flutter run` | `flutter build apk --release` |

## 🛠️ Updating URLs

### Change Production URL
Edit `lib/core/constants/api_config.dart`:

```dart
static const String _productionUrl = 'https://your-new-url.com/api';
```

### Change Development URL
Edit `lib/core/constants/api_config.dart`:

```dart
static const String _developmentUrl = 'http://your-ip:port/api';
```

## ✅ Verification

### Check Current Configuration
1. Open `lib/core/constants/api_config.dart`
2. Verify production URL: `https://medilinko.onrender.com/api`
3. Verify development URL: `http://10.0.2.2:3000/api`

### Test Production Build
```bash
flutter build apk --release
# Install on device
# Should connect to https://medilinko.onrender.com/api
```

### Test Debug Build
```bash
flutter run
# Should connect to http://10.0.2.2:3000/api (emulator)
```

## 🔍 Troubleshooting

### "Connection refused" in Debug Mode
**Problem:** Local backend not running
**Solution:**
```bash
cd backend
npm start
# Backend should run on localhost:3000
```

### "Connection timeout" in Production
**Problem:** Production backend down or wrong URL
**Solution:**
1. Check if backend is deployed: https://medilinko.onrender.com/health
2. Verify URL in `api_config.dart`

### Physical Device Can't Connect in Debug
**Problem:** Using `10.0.2.2` (emulator-only address)
**Solution:** Use your computer's actual IP address (see "Test Local Backend" section)

## 📝 Summary

- ✅ **Production:** Automatic, uses deployed backend
- ✅ **Development:** Automatic, uses local backend
- ✅ **No user configuration** needed
- ✅ **No WiFi dependency** in production
- ✅ **Simple and maintainable**

---

**Last Updated:** January 20, 2026
**Configuration File:** `lib/core/constants/api_config.dart`
