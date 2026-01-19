# 🏥 MediLinko - Healthcare Management Application

A comprehensive role-based healthcare application built with Flutter and Node.js, featuring medicine reminders, appointment booking, and pharmacy services.

## 📖 Documentation Quick Links

| Document | Purpose | When to Use |
|----------|---------|-------------|
| [🚀 QUICK_START.md](QUICK_START.md) | Get running in 15 minutes | First-time setup, want speed |
| [🔔 FCM_SETUP_GUIDE.md](FCM_SETUP_GUIDE.md) | Complete Firebase setup | Setting up notifications |
| [✅ SETUP_CHECKLIST.md](SETUP_CHECKLIST.md) | Interactive setup tracking | Track your progress |
| [🗺️ SETUP_FLOWCHART.md](SETUP_FLOWCHART.md) | Visual setup guide | Visual learner |
| [❓ FAQ.md](FAQ.md) | Common questions & answers | Troubleshooting, general help |
| [📦 REPO_SETUP_SUMMARY.md](REPO_SETUP_SUMMARY.md) | What's in this repo | Understanding structure |
| [🔗 EMERGENCY_INTEGRATION.md](EMERGENCY_INTEGRATION.md) | EmergencyMed QR integration | Setting up emergency QR system |
| [🤝 CONTRIBUTING.md](CONTRIBUTING.md) | Development guidelines | Contributing code |

> **New Developer?** Start with [QUICK_START.md](QUICK_START.md) or [SETUP_FLOWCHART.md](SETUP_FLOWCHART.md)  
> **Having Issues?** Check [FAQ.md](FAQ.md) first!

## 📱 Features

### For Users
- 💊 Medicine reminder system with dose tracking
- 📅 Book appointments with doctors
- 🔍 Find nearby pharmacies
- 🚨 Emergency QR code with web interface
- 📋 Health profile management
- ⭐ Rate and review doctors/pharmacies
- 🔔 Push notifications for reminders

### For Doctors
- 📆 Manage appointment schedules
- 👥 View patient appointments
- 📊 Profile and clinic management
- ⭐ View ratings and reviews
- 🔔 Appointment notifications

### For Pharmacists
- 💊 Manage medicine inventory
- 📦 Stock management
- 📍 Location-based services
- ⭐ Manage reviews
- 🔔 Order notifications

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK** (3.35.3 or higher)
- **Node.js** (v14 or higher) and npm
- **MongoDB** (Local or Atlas)
- **Firebase Account** (for push notifications)
- **Android Studio** / **Xcode** (for mobile development)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/medilinko.git
   cd medilinko
   ```

2. **Setup Firebase (IMPORTANT for notifications)**
   
   📖 **Follow the detailed setup guide**: [FCM_SETUP_GUIDE.md](FCM_SETUP_GUIDE.md)
   
   Quick steps:
   - Create Firebase project
   - Add Android/iOS apps
   - Download configuration files
   - Setup backend service account
   - Run `flutterfire configure`

3. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

4. **Setup Backend**
   ```bash
   cd backend
   npm install
   ```

5. **Configure Backend Environment**
   
   Create `backend/.env` file:
   ```env
   MONGODB_URI=mongodb://localhost:27017/medilinko
   JWT_SECRET=your-secret-key-change-in-production
   PORT=3000
   NODE_ENV=development
   ```

6. **Place Firebase Service Account Key**
   
   Download from Firebase Console and place at:
   ```
   backend/config/firebase-service-account.json
   ```

7. **Start Backend Server**
   ```bash
   cd backend
   npm start
   ```

8. **Run Flutter App**
   ```bash
   flutter run
   ```

## 📁 Project Structure

```
MediLinko/
├── lib/                          # Flutter application
│   ├── core/                     # Core utilities
│   │   ├── constants/            # App constants
│   │   ├── router/               # Navigation
│   │   └── theme/                # App theme
│   ├── models/                   # Data models
│   ├── providers/                # Riverpod providers
│   ├── screens/                  # UI screens
│   │   ├── auth/                 # Authentication screens
│   │   ├── dashboards/           # Role-based dashboards
│   │   └── profile_wizard/       # Profile setup wizards
│   ├── services/                 # API and background services
│   └── widgets/                  # Reusable widgets
├── backend/                      # Node.js backend
│   ├── config/                   # Configuration files
│   ├── controllers/              # Route controllers
│   ├── models/                   # MongoDB models
│   ├── routes/                   # API routes
│   ├── services/                 # Business logic
│   └── middleware/               # Auth middleware
├── android/                      # Android native code
├── ios/                          # iOS native code
└── assets/                       # Images and resources
```

## 🔑 Key Technologies

### Frontend (Flutter)
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **UI Framework**: Material 3
- **Local Storage**: Flutter Secure Storage
- **Notifications**: Firebase Cloud Messaging
- **Background Services**: Flutter Background Service
- **Location**: Geolocator
- **File Handling**: File Picker

### Backend (Node.js)
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose
- **Authentication**: JWT
- **Push Notifications**: Firebase Admin SDK
- **API Documentation**: REST API

## 🔐 Authentication

The app uses JWT-based authentication with role-based access control:

- Users register with role selection (User/Doctor/Pharmacist)
- JWT tokens stored securely using Flutter Secure Storage
- Protected API routes using auth middleware
- Role-based UI and functionality

## 🔔 Push Notifications Setup

**IMPORTANT**: For push notifications to work, each developer must set up their own Firebase project.

📖 **Complete setup guide**: [FCM_SETUP_GUIDE.md](FCM_SETUP_GUIDE.md)

### Quick Setup:
1. Create Firebase project
2. Add Android/iOS apps
3. Download `google-services.json` → place in `android/app/`
4. Download Firebase service account key → place in `backend/config/`
5. Run `flutterfire configure`
6. Configure backend `.env`

## 📱 Running on Different Platforms

### Android
```bash
flutter run -d android
```

### iOS
```bash
flutter run -d ios
```

### Web
```bash
flutter run -d chrome
```

## 🧪 Testing

### Run Flutter Tests
```bash
flutter test
```

### Run Backend Tests
```bash
cd backend
npm test
```

### Check Code Quality
```bash
flutter analyze
```

## 🏗️ Building for Production

### Android APK
```bash
flutter build apk --release
```

### Android App Bundle
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🌍 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `GET /api/auth/profile` - Get user profile

### Appointments
- `GET /api/appointments` - Get user appointments
- `POST /api/appointments` - Create appointment
- `PATCH /api/appointments/:id` - Update appointment
- `DELETE /api/appointments/:id` - Cancel appointment

### Medicine Reminders
- `GET /api/medicine-reminders` - Get user medicines
- `POST /api/medicine-reminders` - Add medicine
- `PATCH /api/medicine-reminders/:id` - Update medicine
- `DELETE /api/medicine-reminders/:id` - Remove medicine

### Notifications
- `GET /api/notifications` - Get user notifications
- `POST /api/notifications/mark-read` - Mark as read
- `POST /api/fcm/token` - Save FCM token

See full API documentation in backend README.

## 🔒 Security Considerations

### Files to NEVER Commit (Already in .gitignore)
- `google-services.json`
- `backend/config/firebase-service-account.json`
- `.env` files
- Private keys

### Security Best Practices
- Rotate JWT secrets in production
- Use environment variables for sensitive data
- Enable Firebase App Check
- Use HTTPS in production
- Implement rate limiting
- Validate all user inputs
- Use parameterized queries

## 🐛 Troubleshooting

### Common Issues

**1. Firebase initialization error**
- Ensure `firebase_options.dart` exists
- Run `flutterfire configure`
- Check Firebase project configuration

**2. Notifications not working**
- Follow [FCM_SETUP_GUIDE.md](FCM_SETUP_GUIDE.md)
- Check FCM token is saved
- Verify backend has service account key
- Enable FCM API in Firebase Console

**3. Backend connection error**
- Check backend server is running
- Verify MongoDB connection
- Check API URLs in Flutter app
- Review CORS settings

**4. Build errors**
```bash
flutter clean
flutter pub get
cd android && ./gradlew clean
cd .. && flutter run
```

## 📚 Documentation

- [FCM Setup Guide](FCM_SETUP_GUIDE.md) - Firebase Cloud Messaging setup
- [Emergency Integration Guide](EMERGENCY_INTEGRATION.md) - EmergencyMed QR code integration
- [Medicine Tracker Enhancement](MEDICINE_TRACKER_ENHANCEMENT.md) - Feature details
- [Copilot Instructions](.github/copilot-instructions.md) - Development guidelines

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## 📄 License

This project is licensed under the MIT License.

## 👥 Team

- **Developer**: Sushil SC
- **Project**: Mini Project (5th Semester)

## 📞 Support

For issues and questions:
- Open an issue on GitHub
- Check [FCM_SETUP_GUIDE.md](FCM_SETUP_GUIDE.md) for notification setup
- Review troubleshooting section

## 🗺️ Roadmap

- [ ] Add telemedicine video consultations
- [ ] Implement payment gateway integration
- [ ] Add AI-powered symptom checker
- [ ] Implement medicine delivery tracking
- [ ] Add multi-language support
- [ ] Implement dark mode
- [ ] Add data analytics dashboard
- [ ] Implement prescription OCR scanning

## ⚙️ Environment Setup Summary

### For New Developers

1. **Clone the repo**
2. **Read [FCM_SETUP_GUIDE.md](FCM_SETUP_GUIDE.md)** - MUST DO for notifications
3. **Setup Firebase project** (your own or get access to shared)
4. **Configure backend `.env`**
5. **Install dependencies** (`flutter pub get`, `npm install`)
6. **Run the app!**

---

**Built with ❤️ using Flutter and Node.js**
