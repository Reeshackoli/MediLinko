# MediLinko - Smart Healthcare Companion

A comprehensive Flutter application for managing healthcare interactions between users, doctors, and pharmacists.

## 🎯 Features

### Multi-Role Support
- **Users**: Book appointments, manage health records, track medications
- **Doctors**: Manage clinic, consultations, and patient appointments
- **Pharmacists**: Handle pharmacy operations, inventory, and deliveries

### Authentication & Onboarding
- Beautiful onboarding screen with app introduction
- Role-based registration and login
- Secure authentication flow

### Profile Wizard
Multi-step profile completion tailored to each role:

#### User Profile
- Personal information (age, gender, city)
- Health details (blood group, allergies, medical conditions)
- Emergency contact information

#### Doctor Profile
- Basic information (experience, specialization)
- Clinic details (name, address, consultation fee)
- License verification with document upload
- Availability management (days and time slots)

#### Pharmacist Profile
- Owner information
- Pharmacy details (name, address, operating hours)
- License verification
- Services offered and delivery radius

### Role-Based Dashboards
- **User Dashboard**: Quick access to doctors, pharmacies, appointments, and health records
- **Doctor Dashboard**: Today's appointments, patient management, clinic info
- **Pharmacist Dashboard**: Orders, inventory, deliveries, and services

## 🎨 Design

- **Primary Color**: Soft medical blue (#4C9AFF)
- **Secondary Color**: Light teal/green (#5FD4C4)
- **Theme**: Clean, minimal, hospital-like UI with Material 3 design
- **Components**: Rounded cards, soft gradients, proper spacing

## 🛠️ Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Riverpod
- **Navigation**: GoRouter
- **UI**: Material 3
- **File Handling**: file_picker

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart
│   ├── router/
│   │   └── app_router.dart
│   └── theme/
│       └── app_theme.dart
├── models/
│   ├── user_model.dart
│   └── user_role.dart
├── providers/
│   ├── auth_provider.dart
│   └── profile_wizard_provider.dart
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── onboarding_screen.dart
│   │   ├── registration_screen.dart
│   │   └── role_selection_screen.dart
│   ├── dashboards/
│   │   ├── doctor_dashboard.dart
│   │   ├── pharmacist_dashboard.dart
│   │   └── user_dashboard.dart
│   └── profile_wizard/
│       ├── doctor_profile/
│       ├── pharmacist_profile/
│       ├── user_profile/
│       └── profile_wizard_screen.dart
└── main.dart
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / VS Code with Flutter extensions

### Installation

1. Clone the repository

2. **Backend Setup:**
   ```bash
   cd backend
   npm install
   ```
   
   Create `.env` file:
   ```
   MONGODB_URI=your_mongodb_connection_string
   JWT_SECRET=your_jwt_secret
   NODE_ENV=development
   PORT=3000
   ```
   
   Start backend:
   ```bash
   npm run dev
   ```

3. **Flutter Setup:**
   ```bash
   flutter pub get
   ```

4. **Run the app:**

   **For Web (default):**
   ```bash
   flutter run -d chrome
   ```

   **For Android Emulator:**
   ```bash
   flutter run
   ```

   **For Physical Device:**
   Find your computer's IP with `ipconfig` (Windows) or `ifconfig` (Mac/Linux), then:
   ```bash
   flutter run --dart-define=API_URL=http://192.168.x.x:3000/api
   ```
   
   ⚠️ **Important:** Make sure backend `server.js` uses `HOST='0.0.0.0'` and both devices are on the same Wi-Fi.

## 📱 Screens Flow

1. **Onboarding** → Welcome screen with app introduction
2. **Role Selection** → Choose between User, Doctor, or Pharmacist
3. **Registration** → Sign up with role-specific fields
4. **Profile Wizard** → Complete multi-step profile based on role
5. **Dashboard** → Role-specific home screen

## 🔐 Authentication

Currently uses mock authentication for demonstration. In production:
- Implement backend API integration
- Add JWT token management
- Implement secure password hashing
- Add forgot password functionality

## 📝 State Management

Uses Riverpod for:
- Authentication state
- Profile wizard data management
- User session management
- Navigation state

## 📦 Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.5.1  # State management
  go_router: ^14.2.0        # Navigation
  file_picker: ^8.0.0+1     # File selection
  intl: ^0.19.0             # Internationalization
```

## 🎯 Future Enhancements

- Backend API integration
- Real-time appointment booking
- Chat functionality
- Prescription management
- Medicine delivery tracking
- Payment integration
- Push notifications
- Multi-language support
- Dark mode theme

## 📄 License

This project is licensed under the MIT License.

---

Built with ❤️ using Flutter
