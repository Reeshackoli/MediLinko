# ❓ Frequently Asked Questions (FAQ)

## General Questions

### Q: What is MediLinko?
**A:** MediLinko is a comprehensive healthcare management application built with Flutter and Node.js. It helps users manage medicines, book appointments with doctors, find nearby pharmacies, and receive timely reminders.

### Q: What technologies does MediLinko use?
**A:** 
- **Frontend**: Flutter (Dart), Riverpod, GoRouter
- **Backend**: Node.js, Express.js, MongoDB
- **Notifications**: Firebase Cloud Messaging
- **Authentication**: JWT tokens

### Q: Is MediLinko free to use?
**A:** Yes, this is an open-source project built as a mini project.

---

## Setup Questions

### Q: I cloned the repo. What do I do first?
**A:** Start with one of these guides:
- **Quick**: [QUICK_START.md](QUICK_START.md) - 15 minutes
- **Visual**: [SETUP_FLOWCHART.md](SETUP_FLOWCHART.md) - Flowchart
- **Detailed**: [FCM_SETUP_GUIDE.md](FCM_SETUP_GUIDE.md) - Complete guide
- **Checklist**: [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md) - Track progress

### Q: Do I need my own Firebase project?
**A:** Yes! Each developer needs either:
1. **Their own Firebase project** (recommended for learning/open-source)
2. **Access to a shared Firebase project** (for teams)

Firebase free tier is sufficient for development.

### Q: Which files do I need to download from Firebase?
**A:** You need:
1. `google-services.json` (Android) → Place in `android/app/`
2. `GoogleService-Info.plist` (iOS, if needed) → Place in `ios/Runner/`
3. Firebase service account JSON → Rename to `firebase-service-account.json` → Place in `backend/config/`

See: [FCM_SETUP_GUIDE.md](FCM_SETUP_GUIDE.md)

### Q: What is `flutterfire configure` and do I need to run it?
**A:** Yes! It's a command that automatically configures Firebase for your Flutter app. It generates `lib/firebase_options.dart` with your Firebase credentials.

```bash
# Install once
dart pub global activate flutterfire_cli

# Run in project root
flutterfire configure
```

### Q: Can I skip the Firebase setup?
**A:** No, Firebase is required for:
- Push notifications
- Medicine reminders
- Appointment notifications
- All real-time features

Without it, the app won't work properly.

### Q: How do I set up the backend .env file?
**A:**
```bash
# Copy template
cp backend/.env.example backend/.env

# Edit .env with your values:
# - MONGODB_URI (your MongoDB connection string)
# - JWT_SECRET (random secret key)
# - Other settings as needed
```

### Q: How do I generate a JWT secret?
**A:**
```bash
# Generate random secret
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Copy the output to JWT_SECRET in .env
```

---

## Firebase & Notifications

### Q: Notifications aren't working. What should I check?
**A:** Check in this order:
1. ✅ `google-services.json` in `android/app/`
2. ✅ `firebase-service-account.json` in `backend/config/`
3. ✅ Ran `flutterfire configure`
4. ✅ `lib/firebase_options.dart` exists
5. ✅ Backend `.env` has correct settings
6. ✅ FCM token saved in database
7. ✅ App has notification permissions
8. ✅ Backend server is running

See: [FCM_SETUP_GUIDE.md - Troubleshooting](FCM_SETUP_GUIDE.md#-troubleshooting)

### Q: Where do I get the Firebase service account key?
**A:** 
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Click ⚙️ Settings → **Service accounts**
4. Click **"Generate new private key"**
5. Download the JSON file
6. Rename to `firebase-service-account.json`
7. Place in `backend/config/`

### Q: Can I test notifications without setting up the backend?
**A:** Yes, you can send test notifications from Firebase Console:
1. Firebase Console → **Engage** → **Messaging**
2. Click **"Create your first campaign"**
3. Fill in notification details
4. Send to your app

But for full functionality (medicine reminders, appointment notifications), you need the backend.

### Q: What's the difference between `google-services.json` and `firebase-service-account.json`?
**A:**
- **`google-services.json`**: Used by Android app to connect to Firebase
- **`firebase-service-account.json`**: Used by backend to send notifications via Firebase Admin SDK

Both are required but serve different purposes.

---

## Database Questions

### Q: Do I need to install MongoDB locally?
**A:** No, you have two options:
1. **Local MongoDB** - Install and run on your machine
2. **MongoDB Atlas** - Free cloud database (recommended)

For Atlas: https://www.mongodb.com/cloud/atlas

### Q: How do I connect to MongoDB Atlas?
**A:**
1. Create free cluster at [MongoDB Atlas](https://www.mongodb.com/cloud/atlas)
2. Get connection string
3. Update `MONGODB_URI` in `backend/.env`:
```env
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/medilinko?retryWrites=true&w=majority
```

### Q: What database name should I use?
**A:** Use `medilinko` (already configured in the connection string and models).

---

## Development Questions

### Q: How do I run the app?
**A:**
```bash
# Start backend (Terminal 1)
cd backend
npm start

# Start Flutter app (Terminal 2)
flutter run

# Or press F5 in VS Code
```

### Q: Which port does the backend use?
**A:** Port 3000 by default (configurable in `backend/.env` with `PORT=3000`)

### Q: How do I run on a specific device?
**A:**
```bash
# List devices
flutter devices

# Run on specific device
flutter run -d <device-id>

# Examples:
flutter run -d android        # Android emulator/device
flutter run -d chrome         # Web browser
flutter run -d ios            # iOS simulator/device
```

### Q: Can I run the app on web?
**A:** Yes, but Firebase needs additional web configuration. Run:
```bash
flutter run -d chrome
```

Then follow any Firebase web setup prompts.

### Q: The app builds but crashes immediately. What's wrong?
**A:** Common causes:
1. Firebase not initialized → Check `firebase_options.dart` exists
2. Missing dependencies → Run `flutter pub get`
3. Build cache issues → Run `flutter clean` then rebuild
4. Android/iOS config issues → Check `google-services.json` is in place

---

## Error Messages

### Q: "Default FirebaseApp is not initialized"
**A:** You need to configure Firebase:
```bash
flutterfire configure
```

This generates `lib/firebase_options.dart` which initializes Firebase.

### Q: "google-services.json not found"
**A:** 
1. Download from Firebase Console (Android app settings)
2. Place in `android/app/google-services.json`
3. Run `flutter clean` and rebuild

### Q: "Firebase service account not found" (backend)
**A:**
1. Download service account key from Firebase Console
2. Place in `backend/config/firebase-service-account.json`
3. Check `.env` has: `FIREBASE_SERVICE_ACCOUNT_PATH=./config/firebase-service-account.json`

### Q: "Cannot connect to MongoDB"
**A:**
1. Check MongoDB is running (local) or Atlas cluster is active
2. Verify `MONGODB_URI` in `backend/.env` is correct
3. Check network connectivity
4. For Atlas: Whitelist your IP address in Atlas dashboard

### Q: Build errors with "pub get failed"
**A:**
```bash
# Clear cache and retry
flutter clean
flutter pub get

# If still fails, delete pubspec.lock
rm pubspec.lock
flutter pub get
```

### Q: Android build fails with Gradle error
**A:**
```bash
# Clean Android build
cd android
./gradlew clean
cd ..

# Clean Flutter and rebuild
flutter clean
flutter pub get
flutter run
```

---

## Security Questions

### Q: Which files should I NOT commit to Git?
**A:** These files are already in `.gitignore`:
- ❌ `google-services.json`
- ❌ `firebase-service-account.json`
- ❌ `.env` files
- ❌ `node_modules/`

**Never** remove them from `.gitignore` or commit them!

### Q: How do I share Firebase credentials with my team?
**A:** **NEVER via Git!** Use:
1. Encrypted messaging (Signal, WhatsApp)
2. Secure file sharing (Google Drive with restricted access)
3. Password manager with sharing (1Password, LastPass)
4. Add team members to Firebase Console instead

### Q: Is it safe to commit `firebase_options.dart`?
**A:** For public projects, it's better to regenerate it per developer using `flutterfire configure`. For private repos with a team, it can be committed, but each developer should still run `flutterfire configure` to ensure it matches their Firebase project.

---

## Testing Questions

### Q: How do I test push notifications?
**A:** Three ways:

**1. Firebase Console** (easiest)
- Firebase Console → Messaging → New campaign

**2. Backend API** (realistic)
- Use Postman to call `/api/notifications/send`

**3. Add Medicine Reminder** (full flow)
- Add medicine in app → Wait for reminder time

See: [FCM_SETUP_GUIDE.md - Step 10](FCM_SETUP_GUIDE.md#step-10-test-push-notifications)

### Q: How can I see backend logs?
**A:** Check the terminal where you ran `npm start`. All logs appear there.

### Q: How do I view the database?
**A:**
- **Local MongoDB**: Use MongoDB Compass or `mongo` shell
- **MongoDB Atlas**: Use Atlas web interface

---

## Platform-Specific Questions

### Q: Do I need a Mac to develop for iOS?
**A:** Yes, iOS development requires:
- macOS
- Xcode
- Apple Developer account (for real device testing)

Android development works on Windows, Mac, and Linux.

### Q: How do I enable push notifications on iOS?
**A:** Additional iOS setup required:
1. Enable Push Notifications capability in Xcode
2. Enable Background Modes in Xcode
3. Upload APNs authentication key to Firebase Console

See: [FCM_SETUP_GUIDE.md - iOS Section](FCM_SETUP_GUIDE.md#ios-additional-configuration)

### Q: Can I test on a real Android device?
**A:** Yes:
1. Enable Developer Options on Android device
2. Enable USB Debugging
3. Connect via USB
4. Run `flutter devices` to verify
5. Run `flutter run`

---

## Contributing Questions

### Q: How can I contribute to MediLinko?
**A:** 
1. Read [CONTRIBUTING.md](CONTRIBUTING.md)
2. Fork the repository
3. Create a feature branch
4. Make your changes
5. Submit a Pull Request

### Q: What's the code style guide?
**A:** 
- **Flutter**: Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- **Backend**: JavaScript Standard Style
- Run `flutter analyze` before committing
- Use conventional commit messages

See: [CONTRIBUTING.md](CONTRIBUTING.md)

### Q: Where can I find good first issues?
**A:** Look for issues tagged:
- `good first issue`
- `beginner friendly`
- `documentation`
- `bug`

---

## Performance Questions

### Q: The app is slow. How can I improve performance?
**A:**
- Use `flutter run --release` for production builds
- Avoid debug mode for performance testing
- Optimize images and assets
- Use const constructors where possible
- Profile with DevTools: `flutter run --profile`

### Q: Backend is slow. What should I check?
**A:**
- Check MongoDB indexes
- Review database queries
- Check network latency
- Monitor memory usage
- Add caching if needed

---

## Deployment Questions

### Q: How do I build for production?
**A:**

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle (for Play Store):**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

### Q: How do I deploy the backend?
**A:** You can deploy to:
- **Heroku**
- **DigitalOcean**
- **AWS EC2**
- **Google Cloud Run**
- **Azure App Service**

Ensure environment variables are set in production.

### Q: What environment variables do I need in production?
**A:**
```env
MONGODB_URI=<production-mongodb-uri>
JWT_SECRET=<strong-random-secret>
NODE_ENV=production
PORT=3000
FIREBASE_SERVICE_ACCOUNT_PATH=./config/firebase-service-account.json
```

---

## Common Pitfalls

### Q: I forgot to run `flutter pub get` after cloning. Now what?
**A:**
```bash
flutter pub get
# Then rebuild
flutter run
```

### Q: I accidentally committed sensitive files. What do I do?
**A:**
1. **Immediately** remove from Git:
```bash
git rm --cached google-services.json
git rm --cached backend/config/firebase-service-account.json
git rm --cached backend/.env
git commit -m "Remove sensitive files"
git push
```

2. **Rotate credentials**:
- Generate new Firebase service account key
- Change JWT secret
- Update MongoDB credentials if exposed

3. **Verify** files are in `.gitignore`

### Q: I can't find a specific feature in the docs
**A:** Check:
1. Main [README.md](README.md)
2. Search all markdown files
3. Check code comments
4. Ask in issues/discussions

---

## Getting Help

### Q: I'm still stuck. Where can I get help?
**A:**

1. **Check documentation**:
   - [README.md](README.md)
   - [QUICK_START.md](QUICK_START.md)
   - [FCM_SETUP_GUIDE.md](FCM_SETUP_GUIDE.md)
   - [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md)

2. **Search existing issues**:
   - Someone might have had the same problem

3. **Create a new issue**:
   - Provide error messages
   - Describe what you tried
   - Include relevant logs

4. **Check Flutter/Firebase docs**:
   - [Flutter Docs](https://flutter.dev/docs)
   - [Firebase Docs](https://firebase.google.com/docs)

### Q: How do I report a bug?
**A:** Create an issue with:
- Description of the bug
- Steps to reproduce
- Expected vs actual behavior
- Screenshots (if applicable)
- Environment details (OS, Flutter version, etc.)

See: [CONTRIBUTING.md - Bug Reports](CONTRIBUTING.md#-reporting-bugs)

---

## Quick Reference

### Essential Commands
```bash
# Flutter
flutter pub get              # Install dependencies
flutter run                  # Run app
flutter clean                # Clean build
flutter analyze              # Check code
dart format .                # Format code

# Backend
npm install                  # Install dependencies
npm start                    # Start server
npm run dev                  # Start with auto-reload

# Firebase
flutterfire configure        # Configure Firebase
```

### Important File Locations
```
MediLinko/
├── lib/firebase_options.dart              ← Generated by flutterfire
├── android/app/google-services.json       ← From Firebase
├── backend/.env                           ← Your config
└── backend/config/
    └── firebase-service-account.json      ← From Firebase
```

### Documentation Index
- 🚀 [QUICK_START.md](QUICK_START.md) - Fast setup
- 🔔 [FCM_SETUP_GUIDE.md](FCM_SETUP_GUIDE.md) - Firebase setup
- ✅ [SETUP_CHECKLIST.md](SETUP_CHECKLIST.md) - Progress tracker
- 🗺️ [SETUP_FLOWCHART.md](SETUP_FLOWCHART.md) - Visual guide
- 📦 [REPO_SETUP_SUMMARY.md](REPO_SETUP_SUMMARY.md) - Repo overview
- 🤝 [CONTRIBUTING.md](CONTRIBUTING.md) - Contribute
- 📖 [README.md](README.md) - Main docs

---

**Still have questions? Open an issue or check the documentation! 📚**
