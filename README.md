# MediLinko - Smart Healthcare Companion

A comprehensive Flutter healthcare application with role-based access for Users, Doctors, and Pharmacists. Features include appointment booking, medicine tracking, fall detection emergency system, and more.

## ✨ Key Features

### 🚨 Fall Detection Emergency System
- **Real-time accelerometer monitoring** - Detects sudden falls
- **60-second countdown alert** - User can cancel if false alarm
- **Auto-emergency mode** - Shows medical ID card with:
  - Patient name & blood type
  - Allergies & medical conditions
  - Emergency contacts
  - QR code for quick medical info access
- **Screen wakelock** - Keeps screen on during emergencies
- **High-priority notifications** - Alerts emergency contacts

### 👥 Multi-Role Support
- **Users**: Manage health records, book appointments, track medications, fall detection
- **Doctors**: Clinic management, patient appointments, location-based discovery
- **Pharmacists**: Inventory management, medicine delivery, nearby pharmacy finder

### 🔐 Authentication & Profiles
- Beautiful onboarding with role selection
- Secure JWT-based authentication
- Multi-step profile wizards customized per role
- Profile completion tracking

### 🗺️ Location-Based Services
- Find nearby doctors with specialization filters
- Locate pharmacies within delivery radius
- Interactive maps with real-time locations

### 💊 Medicine Management
- Personal medicine tracker with calendar view
- Dose reminders and tracking
- Pharmacist inventory management
- Low stock alerts

### 📅 Appointment System
- Book doctor appointments
- View appointment history
- Doctor schedule management
- Real-time availability updates

## 🎨 Design

- **UI Style**: Clean, minimal, medical-themed Material 3 design
- **Primary Color**: Medical Blue (#4C9AFF)
- **Secondary Color**: Light Teal (#5FD4C4)
- **Components**: Rounded cards, smooth animations, intuitive navigation

## 🛠️ Tech Stack

### Frontend (Flutter)
- **Framework**: Flutter SDK 3.35.3
- **State Management**: Riverpod 2.6.1
- **Navigation**: GoRouter 14.8.1
- **UI**: Material 3 design
- **Sensors**: sensors_plus (fall detection)
- **Notifications**: flutter_local_notifications
- **Maps**: Google Maps integration
- **File Handling**: file_picker

### Backend (Node.js)
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose
- **Authentication**: JWT (jsonwebtoken)
- **Security**: bcrypt, helmet, cors
- **Dev Tools**: nodemon

## 📁 Project Structure

```
MediLinko/
├── lib/
│   ├── core/
│   │   ├── constants/    # App-wide constants
│   │   ├── router/       # GoRouter configuration
│   │   └── theme/        # Material theme
│   ├── models/           # Data models
│   ├── providers/        # Riverpod state management
│   ├── screens/          # All UI screens
│   │   ├── auth/         # Login, registration
│   │   ├── dashboards/   # Role-based home screens
│   │   ├── emergency/    # Fall detection emergency
│   │   ├── profile/      # Profile management
│   │   ├── appointments/ # Booking & management
│   │   ├── maps/         # Location-based discovery
│   │   └── medicine_*    # Medicine tracking & inventory
│   ├── services/         # Backend integration & utilities
│   ├── widgets/          # Reusable components
│   └── main.dart
├── backend/
│   ├── config/           # Database configuration
│   ├── controllers/      # API logic
│   ├── middleware/       # Auth & validation
│   ├── models/           # MongoDB schemas
│   ├── routes/           # API endpoints
│   ├── scripts/          # Seed data utilities
│   └── server.js         # Entry point
└── assets/
    └── images/           # App images & logos
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.35.3+
- Dart SDK 3.0+
- Node.js 16+
- MongoDB (local or Atlas)
- Android Studio / VS Code

### 1. Clone Repository
```bash
git clone <repository-url>
cd MediLinko
```

### 2. Backend Setup
```bash
cd backend
npm install
```

Create `.env` file in backend directory:
```env
MONGODB_URI=mongodb://localhost:27017/medilinko
JWT_SECRET=your_super_secret_jwt_key_change_this
JWT_EXPIRE=7d
PORT=3000
NODE_ENV=development
HOST=0.0.0.0
```

Start backend server:
```bash
npm run dev
```
Server runs on: `http://localhost:3000`

### 3. Flutter Setup
```bash
# Install dependencies
flutter pub get

# Run on Chrome (Web)
flutter run -d chrome

# Run on Android Emulator
flutter run

# Run on Physical Device (same Wi-Fi as backend)
flutter run --dart-define=API_URL=http://<YOUR_IP>:3000/api
```

**Note:** For physical device testing, find your computer's IP:
- Windows: `ipconfig`
- Mac/Linux: `ifconfig`

## 📡 Backend API Endpoints

### Authentication
```
POST   /api/auth/register     # Register new user
POST   /api/auth/login        # Login user
GET    /api/auth/me           # Get current user (Protected)
```

### Profile Management
```
GET    /api/profile           # Get user profile (Protected)
PUT    /api/profile           # Update complete profile (Protected)
PATCH  /api/profile/wizard    # Update wizard step (Protected)
```

### Users & Discovery
```
GET    /api/users/doctors              # Get all doctors
GET    /api/users/doctors/:id          # Get doctor by ID
GET    /api/users/pharmacies           # Get all pharmacies
GET    /api/users/pharmacies/:id       # Get pharmacy by ID
```

### Appointments
```
GET    /api/appointments               # Get user's appointments (Protected)
POST   /api/appointments               # Book appointment (Protected)
GET    /api/appointments/doctor        # Doctor's appointments (Protected)
PATCH  /api/appointments/:id/status    # Update status (Protected)
```

### Medicine Management
```
GET    /api/medicines/user             # User's medicines (Protected)
POST   /api/medicines/user             # Add medicine (Protected)
PATCH  /api/medicines/user/:id/dose    # Log dose (Protected)
GET    /api/medicines/stock            # Pharmacist stock (Protected)
POST   /api/medicines/stock            # Add to stock (Protected)
PATCH  /api/medicines/stock/:id        # Update stock (Protected)
```

### Notifications
```
GET    /api/notifications              # Get notifications (Protected)
PATCH  /api/notifications/:id/read     # Mark as read (Protected)
```

## 🔐 Authentication

The app uses JWT tokens for authentication:
1. Register or login to receive a token
2. Token is stored securely using `flutter_secure_storage`
3. Include token in Authorization header: `Bearer YOUR_JWT_TOKEN`

## 🚨 Fall Detection Setup

### Android Configuration
Ensure these permissions are in `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### How It Works
1. Accelerometer monitors device movement continuously
2. Detects sudden acceleration > 2.5G (fall threshold)
3. Shows immediate alert with 60-second countdown
4. User can cancel by pressing "I'm OK"
5. If no response, auto-navigates to emergency screen
6. Sends high-priority notification to emergency contacts

## 📱 Screen Flow

```
Splash Screen
    ↓
Onboarding Screen
    ↓
Role Selection (User/Doctor/Pharmacist)
    ↓
Registration → Login
    ↓
Profile Wizard (3-4 steps based on role)
    ↓
Dashboard (Role-specific features)
```

### User Wizard Steps
1. Personal Info (age, gender, city)
2. Health Info (blood group, allergies, conditions)
3. Emergency Contact

### Doctor Wizard Steps
1. Basic Info (experience, specialization)
2. Clinic Info (name, address, fee)
3. Verification (license upload)
4. Availability (days & time slots)

### Pharmacist Wizard Steps
1. Owner Info
2. Pharmacy Info (name, address, hours)
3. Verification (license, services, delivery radius)

## 🧪 Testing

### Fall Detection Testing
1. Enable fall detection by logging in as a User
2. Shake device vigorously to trigger detection
3. Wait 60 seconds or press "I'm OK" to cancel
4. Verify emergency screen shows patient information

### API Testing
Use Postman/Thunder Client to test backend endpoints.

Example login:
```bash
POST http://localhost:3000/api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

## 🔒 Security Features

- JWT token authentication with 7-day expiry
- Password hashing with bcrypt
- Helmet security headers
- CORS protection
- MongoDB injection prevention
- Secure local storage for tokens
- Input validation on all endpoints

## 🎯 Future Enhancements

- [ ] Real-time chat between users and doctors
- [ ] Video consultation integration
- [ ] Medicine reminder push notifications
- [ ] Payment gateway integration
- [ ] Prescription image OCR scanning
- [ ] Multi-language support
- [ ] Dark mode theme
- [ ] iOS support
- [ ] Web app optimization

## 🐛 Known Issues

- 24 deprecation warnings (non-critical, Flutter 3.35.3)
- Notification sound requires custom Android resource setup
- Fall detection sensitivity may need per-device calibration

## 📄 License

MIT License - feel free to use this project for learning or commercial purposes.

---

**Built with ❤️ using Flutter & Node.js**

For questions or contributions, please open an issue or pull request.
