# 🚀 MediLinko - Backend Integration Complete!

## ✅ What's Been Added

### Backend (Node.js + Express + MongoDB)
```
backend/
├── config/
│   └── database.js          # MongoDB connection
├── controllers/
│   ├── authController.js     # Register, Login, GetMe
│   ├── profileController.js  # Profile updates, wizard steps
│   └── userController.js     # Get doctors/pharmacies
├── middleware/
│   └── auth.js              # JWT authentication & authorization
├── models/
│   └── User.js              # MongoDB User schema
├── routes/
│   ├── authRoutes.js        # /api/auth/*
│   ├── profileRoutes.js     # /api/profile/*
│   └── userRoutes.js        # /api/users/*
├── .env                     # Environment variables (MongoDB URI, JWT)
├── .gitignore              
├── package.json            
├── README.md               
└── server.js               # Main server file
```

### Flutter Services
```
lib/
├── core/constants/
│   └── api_config.dart      # API base URLs & endpoints
├── services/
│   ├── auth_service.dart     # Register, Login, GetMe APIs
│   ├── profile_service.dart  # Profile update APIs
│   ├── user_service.dart     # Get doctors/pharmacies APIs
│   └── token_service.dart    # JWT token storage
├── models/
│   └── user_model.dart       # Added fromJson() & toJson()
└── providers/
    ├── auth_provider_real_api.dart.example
    └── profile_wizard_provider_real_api.dart.example
```

### Documentation
- `BACKEND_INTEGRATION.md` - Complete integration guide
- `backend/README.md` - Backend API documentation

---

## 🎯 How It Works

### 1. Authentication Flow
```
User Registers → Backend creates user in MongoDB → Returns JWT token
                 ↓
           Token saved securely in Flutter
                 ↓
User Logs In → Backend validates credentials → Returns JWT + user data
                 ↓
           Token used for all protected requests
```

### 2. Profile Wizard Flow
```
User completes wizard step → Data sent to backend → Saved in MongoDB
                              ↓
                      Can be retrieved later
                              ↓
All steps completed → Profile marked as complete → User sees dashboard
```

### 3. Discovery Flow
```
User searches for doctors → Backend queries MongoDB → Returns filtered list
                              ↓
                    User views doctor profile
                              ↓
                    (Future: Book appointment)
```

---

## 🔧 Quick Start

### Start Backend Server
```powershell
cd "d:\5 th sem notes\Mini Project\MediLinko_1\backend"
npm run dev
```

Expected output:
```
🚀 Server running on port 3000
✅ MongoDB Connected: cluster0.tkfu1ug.mongodb.net
📊 Database: medilinko
```

### Configure Flutter Base URL

**Edit:** `lib/core/constants/api_config.dart`

**Android Emulator:**
```dart
static const String baseUrl = 'http://10.0.2.2:3000/api';
```

**iOS Simulator / Web:**
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

**Physical Device:**
```dart
static const String baseUrl = 'http://YOUR_IP:3000/api';
// Find IP: ipconfig (Windows) or ifconfig (Mac/Linux)
```

### Run Flutter App
```powershell
flutter run
```

---

## 📡 Available API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/me` - Get current user (Protected)

### Profile Management
- `GET /api/profile` - Get user profile (Protected)
- `PUT /api/profile` - Update complete profile (Protected)
- `PATCH /api/profile/wizard` - Update wizard step (Protected)

### Discovery
- `GET /api/users/doctors` - Get all doctors
- `GET /api/users/doctors/:id` - Get specific doctor
- `GET /api/users/pharmacies` - Get all pharmacies  
- `GET /api/users/pharmacies/:id` - Get specific pharmacy

### Health Check
- `GET /api/health` - Server status

---

## 🧪 Test with Postman

### 1. Register
```http
POST http://localhost:3000/api/auth/register
Content-Type: application/json

{
  "fullName": "Test User",
  "email": "test@example.com",
  "phone": "9876543210",
  "password": "test123",
  "role": "user"
}
```

### 2. Login
```http
POST http://localhost:3000/api/auth/login
Content-Type: application/json

{
  "email": "test@example.com",
  "password": "test123"
}
```

Copy the `token` from response.

### 3. Update Profile
```http
PUT http://localhost:3000/api/profile
Authorization: Bearer YOUR_TOKEN_HERE
Content-Type: application/json

{
  "ageOrDob": "25",
  "gender": "Male",
  "city": "Mumbai",
  "bloodGroup": "O+",
  "isProfileComplete": true
}
```

---

## 🔐 Security Features

- ✅ **Password Hashing** - bcryptjs with salt rounds
- ✅ **JWT Authentication** - Secure token-based auth
- ✅ **Protected Routes** - Middleware authorization
- ✅ **CORS Enabled** - Cross-origin requests allowed
- ✅ **Helmet Security** - Security headers added
- ✅ **Input Validation** - express-validator
- ✅ **Secure Token Storage** - flutter_secure_storage

---

## 📊 MongoDB Database

**Database Name:** `medilinko`  
**Collection:** `users`

**Sample User Document:**
```json
{
  "_id": "674893e2f1a2b3c4d5e6f789",
  "fullName": "Dr. John Smith",
  "email": "john@example.com",
  "phone": "9876543210",
  "password": "$2a$10$hashed...",
  "role": "doctor",
  "isProfileComplete": true,
  "experience": "10",
  "specialization": "Cardiologist",
  "clinicName": "Heart Care Clinic",
  "city": "Mumbai",
  "consultationFee": "1000",
  "createdAt": "2025-11-28T...",
  "updatedAt": "2025-11-28T..."
}
```

---

## 🚨 Common Issues & Solutions

### Backend Won't Start
- Check MongoDB URI in `.env`
- Ensure port 3000 is free
- Run `npm install` again

### Flutter Connection Error
- Android Emulator: Use `http://10.0.2.2:3000/api`
- Physical Device: Use your computer's IP
- Ensure backend is running
- Check firewall settings

### Token Errors
- Token expired (default: 7 days)
- Login again to get new token
- Check Authorization header format: `Bearer <token>`

---

## 🎯 Integration Steps

### Option 1: Quick Test (Keep Mock Data)
Current app works with mock data. Backend is ready but not connected to Flutter UI yet.

### Option 2: Full Integration (Replace Mock with Real API)

1. **Update Auth Provider:**
   ```bash
   # Backup current provider
   cp lib/providers/auth_provider.dart lib/providers/auth_provider_backup.dart
   
   # Replace with real API version
   cp lib/providers/auth_provider_real_api.dart.example lib/providers/auth_provider.dart
   ```

2. **Update Profile Wizard Provider:**
   ```bash
   cp lib/providers/profile_wizard_provider_real_api.dart.example lib/providers/profile_wizard_provider.dart
   ```

3. **Update API Config:**
   Edit `lib/core/constants/api_config.dart` with correct base URL for your device.

4. **Test Registration Flow:**
   - Start backend server
   - Run Flutter app
   - Register new user
   - Check MongoDB Atlas for new user document

---

## 📝 Next Development Steps

1. **Appointments System**
   - Create Appointment model
   - Add booking endpoints
   - UI for booking/viewing appointments

2. **Prescription Management**
   - Upload/view prescriptions
   - OCR for prescription text
   - Doctor-patient prescription sharing

3. **Real-time Chat**
   - WebSocket integration
   - Patient-doctor messaging
   - File sharing in chat

4. **Payment Integration**
   - Razorpay/Stripe
   - Consultation fees
   - Medicine orders

5. **Push Notifications**
   - Firebase Cloud Messaging
   - Appointment reminders
   - New message notifications

6. **Admin Panel**
   - User management
   - Analytics dashboard
   - Verification system

---

## 📚 Tech Stack Summary

### Backend
- **Runtime:** Node.js 18+
- **Framework:** Express.js
- **Database:** MongoDB Atlas
- **ODM:** Mongoose
- **Authentication:** JWT + bcryptjs
- **Security:** Helmet, CORS
- **Logging:** Morgan
- **Dev Tools:** Nodemon

### Flutter
- **Framework:** Flutter 3.35.3
- **State Management:** Riverpod 2.6.1
- **Navigation:** GoRouter 14.8.1
- **HTTP:** http 1.1.0
- **Storage:** flutter_secure_storage 9.0.0
- **UI:** Material 3

---

## ✅ Verification Checklist

- [x] MongoDB cluster created and accessible
- [x] Backend server starts without errors
- [x] Health endpoint returns success
- [x] User registration works via Postman
- [x] User login returns JWT token
- [x] Protected routes require authentication
- [x] Profile update saves to MongoDB
- [x] Flutter services created
- [x] Token storage implemented
- [x] User model has fromJson/toJson
- [x] Documentation complete

---

## 🎉 You're Ready!

Your MediLinko app now has:
- ✅ Complete backend API with MongoDB
- ✅ JWT-based authentication
- ✅ Profile management system
- ✅ Doctor/Pharmacy discovery
- ✅ Flutter services for API integration
- ✅ Comprehensive documentation

**Read `BACKEND_INTEGRATION.md` for detailed setup instructions!**

---

**Need Help?**
- Check `backend/README.md` for API documentation
- See `BACKEND_INTEGRATION.md` for integration guide
- Review example providers in `lib/providers/*_real_api.dart.example`
