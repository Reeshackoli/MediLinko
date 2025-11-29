# Backend Integration Guide

## 🎯 Overview
Complete guide for integrating MediLinko Flutter app with Node.js/Express backend and MongoDB.

---

## 📋 Prerequisites

### Backend
- **Node.js** (v18+ recommended)
- **MongoDB Atlas** account with cluster created
- **npm** or **yarn** package manager

### Flutter
- **Flutter SDK** 3.35.3+
- **Android Studio** / **Xcode** / **VS Code**
- **Physical device** or **Emulator**

---

## 🚀 Backend Setup

### 1. Navigate to Backend Directory
```powershell
cd "d:\5 th sem notes\Mini Project\MediLinko_1\backend"
```

### 2. Install Dependencies
```powershell
npm install
```

### 3. Configure Environment Variables
The `.env` file is already configured with your MongoDB connection:

```env
MONGODB_URI=mongodb+srv://reeshackoli_db_user:OARwTTAxDCXPYqKA@cluster0.tkfu1ug.mongodb.net/medilinko?retryWrites=true&w=majority&appName=Cluster0
JWT_SECRET=your_super_secret_jwt_key_change_this_in_production_2024
JWT_EXPIRE=7d
PORT=3000
NODE_ENV=development
```

**⚠️ Important:** Change `JWT_SECRET` to a random secure string in production.

### 4. Start Backend Server

**Development Mode (with auto-reload):**
```powershell
npm run dev
```

**Production Mode:**
```powershell
npm start
```

**Expected Output:**
```
🚀 Server running on port 3000
📍 Environment: development
🌐 API available at http://localhost:3000/api
✅ MongoDB Connected: cluster0.tkfu1ug.mongodb.net
📊 Database: medilinko
```

### 5. Test Backend Health
Open browser or Postman:
```
GET http://localhost:3000/api/health
```

Response:
```json
{
  "success": true,
  "message": "MediLinko API is running",
  "timestamp": "2025-11-28T..."
}
```

---

## 📱 Flutter Setup

### 1. Install Flutter Dependencies
```powershell
cd "d:\5 th sem notes\Mini Project\MediLinko_1"
flutter pub get
```

### 2. Configure API Base URL

**File:** `lib/core/constants/api_config.dart`

#### For Different Platforms:

**iOS Simulator:**
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

**Android Emulator:**
```dart
static const String baseUrl = 'http://10.0.2.2:3000/api';
```

**Physical Device (same WiFi network):**
```dart
// Find your computer's IP address first:
// Windows: ipconfig (look for IPv4)
// Mac/Linux: ifconfig or ip addr

static const String baseUrl = 'http://192.168.x.x:3000/api';
// Replace 192.168.x.x with your actual IP
```

**Web:**
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

### 3. Run Flutter App
```powershell
# For Android
flutter run

# For iOS
flutter run -d ios

# For Web
flutter run -d chrome

# For specific device
flutter devices
flutter run -d <device-id>
```

---

## 🔄 How to Use API Services

### Example 1: Register New User

```dart
import 'package:medilinko/services/auth_service.dart';
import 'package:medilinko/models/user_role.dart';

// In your widget or provider
final response = await AuthService.register(
  fullName: 'John Doe',
  email: 'john@example.com',
  phone: '9876543210',
  password: 'password123',
  role: UserRole.user,
);

if (response.success) {
  print('Token: ${response.data!['token']}');
  print('User: ${response.data!['user']}');
  // Navigate to profile wizard
} else {
  print('Error: ${response.message}');
}
```

### Example 2: Login User

```dart
final response = await AuthService.login(
  email: 'john@example.com',
  password: 'password123',
);

if (response.success) {
  final user = UserModel.fromJson(response.data!['user']);
  // Navigate based on user.role
} else {
  print('Error: ${response.message}');
}
```

### Example 3: Update Profile Wizard Step

```dart
import 'package:medilinko/services/profile_service.dart';

// Update partial profile data
final stepData = {
  'ageOrDob': '25',
  'gender': 'Male',
  'city': 'Mumbai',
};

final response = await ProfileService.updateWizardStep(stepData);

if (response['success']) {
  print('Step saved successfully');
}
```

### Example 4: Complete Profile

```dart
final profileData = {
  'ageOrDob': '25',
  'gender': 'Male',
  'city': 'Mumbai',
  'bloodGroup': 'O+',
  'allergies': ['Peanuts'],
  'isProfileComplete': true,
};

final response = await ProfileService.updateProfile(profileData);
```

### Example 5: Get Doctors List

```dart
import 'package:medilinko/services/user_service.dart';

// Get all doctors
final response = await UserService.getDoctors();

// Filter by specialization and city
final filtered = await UserService.getDoctors(
  specialization: 'Cardiologist',
  city: 'Mumbai',
);

if (filtered['success']) {
  List doctors = filtered['data'];
  for (var doc in doctors) {
    print('Dr. ${doc['fullName']} - ${doc['specialization']}');
  }
}
```

---

## 🔐 Authentication Flow

### 1. User Registers
```
Flutter App → POST /api/auth/register
Backend → Creates user in MongoDB
Backend → Returns JWT token
Flutter → Saves token using TokenService
```

### 2. User Logs In
```
Flutter App → POST /api/auth/login
Backend → Verifies credentials
Backend → Returns JWT token + user data
Flutter → Saves token, updates state
```

### 3. Protected Requests
```
Flutter → Adds Authorization: Bearer <token> header
Backend → Validates JWT token
Backend → Returns user-specific data
```

### 4. User Logs Out
```
Flutter → Calls AuthService.logout()
TokenService → Deletes stored token
Flutter → Navigate to login screen
```

---

## 🧪 Testing with Postman/Thunder Client

### 1. Register User
```
POST http://localhost:3000/api/auth/register
Content-Type: application/json

{
  "fullName": "Test Doctor",
  "email": "doctor@test.com",
  "phone": "9876543210",
  "password": "test123",
  "role": "doctor"
}
```

### 2. Login
```
POST http://localhost:3000/api/auth/login
Content-Type: application/json

{
  "email": "doctor@test.com",
  "password": "test123"
}
```

Copy the `token` from response.

### 3. Update Profile (Protected)
```
PUT http://localhost:3000/api/profile
Authorization: Bearer <paste-your-token-here>
Content-Type: application/json

{
  "gender": "Male",
  "experience": "5",
  "specialization": "Cardiologist",
  "clinicName": "Heart Care Clinic",
  "city": "Mumbai",
  "consultationFee": "500",
  "isProfileComplete": true
}
```

### 4. Get Profile
```
GET http://localhost:3000/api/profile
Authorization: Bearer <your-token>
```

### 5. Get All Doctors
```
GET http://localhost:3000/api/users/doctors
```

### 6. Search Doctors
```
GET http://localhost:3000/api/users/doctors?specialization=Cardiologist&city=Mumbai
```

---

## 🗄️ Database Collections

MongoDB automatically creates collections:

### `users` Collection
Stores all users (patients, doctors, pharmacists) with role-specific fields.

**Sample Document:**
```json
{
  "_id": "674893e2f1a2b3c4d5e6f789",
  "fullName": "Dr. John Smith",
  "email": "john@example.com",
  "phone": "9876543210",
  "password": "$2a$10$hashed_password_here",
  "role": "doctor",
  "isProfileComplete": true,
  "gender": "Male",
  "experience": "10",
  "specialization": "Cardiologist",
  "clinicName": "Heart Care Clinic",
  "city": "Mumbai",
  "consultationFee": "1000",
  "licenseNumber": "MH-DOC-12345",
  "availableDays": ["Monday", "Wednesday", "Friday"],
  "timeSlots": ["09:00-12:00", "15:00-18:00"],
  "createdAt": "2025-11-28T10:30:00.000Z",
  "updatedAt": "2025-11-28T10:45:00.000Z"
}
```

---

## 🐛 Troubleshooting

### Backend Issues

**Problem:** MongoDB connection fails
```
❌ MongoDB connection error: ...
```

**Solution:**
- Verify MongoDB URI in `.env` file
- Check MongoDB Atlas cluster is running
- Ensure IP address is whitelisted in MongoDB Atlas
- Check internet connection

---

**Problem:** Port 3000 already in use
```
Error: listen EADDRINUSE: address already in use :::3000
```

**Solution:**
```powershell
# Find process using port 3000
netstat -ano | findstr :3000

# Kill the process
taskkill /PID <process-id> /F

# Or change PORT in .env file
PORT=3001
```

---

### Flutter Issues

**Problem:** Connection refused error in Flutter
```
Connection error: Connection refused
```

**Solutions:**
1. **Android Emulator:** Change base URL to `http://10.0.2.2:3000/api`
2. **Physical Device:** Use computer's local IP (e.g., `http://192.168.1.100:3000/api`)
3. **iOS Simulator:** Should work with `http://localhost:3000/api`
4. Ensure backend server is running

---

**Problem:** CORS errors in Flutter Web
```
Access to XMLHttpRequest blocked by CORS policy
```

**Solution:** Backend already has CORS enabled. If issue persists, run Flutter web with:
```powershell
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

---

**Problem:** Certificate verification error
```
HandshakeException: Handshake error
```

**Solution:** For development only:
```dart
// In lib/services/auth_service.dart (top of file)
import 'dart:io';

// Then in main.dart
void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(ProviderScope(child: MyApp()));
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
```

⚠️ **Only use this in development! Remove for production.**

---

## 📊 API Response Format

### Success Response
```json
{
  "success": true,
  "message": "Operation successful",
  "data": { ... }
}
```

### Error Response
```json
{
  "success": false,
  "message": "Error description"
}
```

---

## 🔒 Security Best Practices

### For Production:

1. **Change JWT Secret:**
   - Generate a strong random string
   - Update in `.env` file
   - Never commit to Git

2. **Use HTTPS:**
   - Deploy backend with SSL certificate
   - Update Flutter base URL to `https://`

3. **Whitelist IPs:**
   - MongoDB Atlas: Add only server IPs
   - Remove `0.0.0.0/0` (allow all)

4. **Environment Variables:**
   - Never commit `.env` to Git
   - Use different secrets for dev/prod

5. **Rate Limiting:**
   - Add rate limiting middleware
   - Prevent brute force attacks

6. **Input Validation:**
   - Already implemented with express-validator
   - Add custom validators as needed

---

## 🚀 Deployment

### Backend Deployment (Render/Railway/Heroku)

1. Create account on hosting platform
2. Connect GitHub repository
3. Set environment variables
4. Deploy backend
5. Get deployment URL (e.g., `https://medilinko-api.onrender.com`)

### Update Flutter Base URL
```dart
// lib/core/constants/api_config.dart
static const String baseUrl = 'https://medilinko-api.onrender.com/api';
```

### Flutter Deployment
- **Android:** `flutter build apk --release`
- **iOS:** `flutter build ios --release`
- **Web:** `flutter build web` → Deploy to Firebase Hosting/Vercel

---

## 📞 Next Steps

1. **Test Registration Flow:**
   - Start backend server
   - Run Flutter app
   - Register as User/Doctor/Pharmacist
   - Complete profile wizard
   - Verify data in MongoDB Atlas

2. **Test Login Flow:**
   - Login with created account
   - Verify dashboard loads
   - Check profile data

3. **Test Discovery:**
   - Create multiple doctor profiles
   - Search from user dashboard
   - Verify filters work

4. **Add Features:**
   - Appointment booking system
   - Prescription management
   - Chat functionality
   - Payment integration
   - Push notifications

---

## 📚 Additional Resources

- **MongoDB Docs:** https://www.mongodb.com/docs/
- **Express.js Guide:** https://expressjs.com/
- **Flutter HTTP Package:** https://pub.dev/packages/http
- **JWT.io:** https://jwt.io/ (for debugging tokens)
- **Postman:** https://www.postman.com/

---

## ✅ Quick Checklist

- [ ] MongoDB Atlas cluster running
- [ ] Backend dependencies installed (`npm install`)
- [ ] `.env` file configured
- [ ] Backend server running (`npm run dev`)
- [ ] Health endpoint responding
- [ ] Flutter dependencies installed (`flutter pub get`)
- [ ] API base URL configured correctly
- [ ] Test registration successful
- [ ] Test login successful
- [ ] Profile update working
- [ ] Data visible in MongoDB Atlas

---

**🎉 You're all set! Happy coding!**
