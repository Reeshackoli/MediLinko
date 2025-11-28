# MediLinko - Quick Start Guide

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.0+ installed
- VS Code or Android Studio
- Android/iOS device or emulator

### Installation

1. **Navigate to project directory**
```bash
cd "d:\5 th sem notes\Mini Project\MediLinko_1"
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Run the app**
```bash
flutter run
```

## 📱 Testing the App

### Test Credentials (Mock Authentication)
Since the app uses mock authentication, you can login with any email:
- **User**: user@test.com
- **Doctor**: doctor@test.com
- **Pharmacist**: pharma@test.com
- **Password**: Any password (min 6 characters)

### Testing Flow

1. **First Time Users**
   - Open app → See onboarding screen
   - Click "Get Started"
   - Select a role (User/Doctor/Pharmacist)
   - Complete registration form
   - Complete profile wizard (3-4 steps)
   - Land on role-specific dashboard

2. **Existing Users**
   - Open app → See onboarding screen
   - Click "Already have an account? Login"
   - Enter email and password
   - Land on role-specific dashboard

## 🎨 Features to Explore

### User Role
1. View health profile card
2. Access quick actions (Find Doctors, Pharmacies, etc.)
3. Check emergency contact info
4. Navigate through clean UI

### Doctor Role
1. View clinic information
2. See today's appointments count
3. Manage availability
4. Access patient management features

### Pharmacist Role
1. View pharmacy details
2. Check opening hours
3. See services offered
4. Monitor orders and deliveries

## 🔧 Development Commands

### Analyze code
```bash
flutter analyze
```

### Run tests
```bash
flutter test
```

### Build APK
```bash
flutter build apk
```

### Clean build
```bash
flutter clean
flutter pub get
flutter run
```

## 📂 Key Files to Modify

### Add new screens
- Create in `lib/screens/`
- Add route in `lib/core/router/app_router.dart`

### Modify theme
- Edit `lib/core/theme/app_theme.dart`

### Add constants
- Update `lib/core/constants/app_constants.dart`

### Update models
- Modify `lib/models/user_model.dart`

### Change state management
- Update providers in `lib/providers/`

## 🐛 Troubleshooting

### Dependencies not found
```bash
flutter clean
flutter pub get
```

### Build errors
```bash
flutter doctor
flutter pub upgrade
```

### Hot reload not working
- Press 'R' in terminal to hot reload
- Press 'r' for hot restart

## 📝 Next Development Steps

1. **Backend Integration**
   - Replace mock auth with real API
   - Add user registration endpoint
   - Implement JWT authentication

2. **Database Setup**
   - Configure Firebase/Supabase
   - Create user collections
   - Setup data models

3. **File Upload**
   - Integrate cloud storage
   - Handle document uploads
   - Store file URLs in database

4. **Additional Features**
   - Appointment booking system
   - Chat functionality
   - Payment integration
   - Notifications

## 💡 Tips

- Use hot reload (r) for quick UI changes
- Run `flutter analyze` before committing
- Check `README.md` for detailed documentation
- All screens are connected and navigable
- Mock authentication works with any credentials

## 🎯 Project Status

✅ All screens created and functional
✅ Navigation working properly
✅ State management configured
✅ Theme applied consistently
✅ Ready for backend integration

---

Happy Coding! 🚀
