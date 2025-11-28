# MediLinko Flutter Project Setup

## Project Overview
MediLinko is a role-based healthcare application built with Flutter, featuring authentication, profile wizards, and dashboards for Users, Doctors, and Pharmacists.

## ✅ Completed Steps
1. ✅ Created copilot-instructions.md file
2. ✅ Scaffolded Flutter project structure
3. ✅ Created models and enums (UserModel, UserRole)
4. ✅ Setup Riverpod state management
5. ✅ Created theme and constants
6. ✅ Created authentication screens (Onboarding, Role Selection, Login, Registration)
7. ✅ Created profile wizard screens (User, Doctor, Pharmacist wizards)
8. ✅ Created dashboard screens (User, Doctor, Pharmacist dashboards)
9. ✅ Setup navigation with GoRouter
10. ✅ Updated pubspec.yaml with dependencies
11. ✅ Updated README with comprehensive documentation
12. ✅ Project is ready to run

## Tech Stack
- **Framework**: Flutter SDK 3.35.3
- **State Management**: Riverpod (flutter_riverpod: ^2.6.1)
- **Navigation**: GoRouter (go_router: ^14.8.1)
- **UI**: Material 3 design
- **File Handling**: file_picker: ^8.3.7

## Design Theme
- **Primary**: Soft medical blue (#4C9AFF)
- **Secondary**: Light teal/green (#5FD4C4)
- **Background**: White (#FFFFFF)
- **UI Style**: Clean, minimal, hospital-like UI

## Project Structure
```
lib/
├── core/
│   ├── constants/app_constants.dart
│   ├── router/app_router.dart
│   └── theme/app_theme.dart
├── models/
│   ├── user_model.dart
│   └── user_role.dart
├── providers/
│   ├── auth_provider.dart
│   └── profile_wizard_provider.dart
├── screens/
│   ├── auth/ (4 screens)
│   ├── dashboards/ (3 screens)
│   └── profile_wizard/ (10 wizard steps)
└── main.dart
```

## Running the Project

### Install Dependencies
```bash
cd "d:\5 th sem notes\Mini Project\MediLinko_1"
flutter pub get
```

### Run on Android/iOS
```bash
flutter run
```

### Run on Web
```bash
flutter run -d chrome
```

### Analyze Code
```bash
flutter analyze
```

## Screen Flow
1. **Onboarding Screen** → App introduction with "Get Started" and "Login" buttons
2. **Role Selection** → Choose User, Doctor, or Pharmacist role
3. **Registration** → Sign up with role-specific fields
4. **Profile Wizard** → Complete multi-step profile (3-4 steps based on role)
5. **Dashboard** → Role-specific home screen with features

## Role-Specific Features

### User (3-step wizard)
- Personal info (age, gender, city)
- Health info (blood group, allergies, conditions, medicines)
- Emergency contact (name, relationship, phone)

### Doctor (4-step wizard)
- Basic info (gender, experience, specialization)
- Clinic info (name, address, city, pincode, fee)
- Verification (license number, document upload)
- Availability (days of week, time slots)

### Pharmacist (3-step wizard)
- Owner info (alternate phone)
- Pharmacy info (name, address, operating hours)
- Verification (license, services, delivery radius)

## Known Issues
- ⚠️ 24 deprecation warnings (non-critical) - related to Flutter 3.35.3
- All warnings are for `withOpacity` and `value` in form fields
- These are minor and don't affect functionality

## Next Steps for Development
1. Integrate with backend API (Firebase/REST API)
2. Implement actual authentication (Firebase Auth, JWT, etc.)
3. Add database integration (Firestore, SQLite, etc.)
4. Implement file upload functionality
5. Add appointment booking system
6. Add prescription management
7. Add chat functionality
8. Add payment integration
9. Implement push notifications
10. Add analytics and crash reporting

## Testing
```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage
```

## Building for Production
```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS
flutter build ios --release
```

## Notes
- Mock authentication is currently used for demonstration
- All UI screens are fully functional and navigable
- State management is properly set up with Riverpod
- Theme follows Material 3 design guidelines
- Code is well-structured and follows Flutter best practices
