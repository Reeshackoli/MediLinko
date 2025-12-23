# FCM Notification Debugging Guide

## Testing FCM Notifications for Appointment Booking

### Backend Setup
1. **Firebase Service Account**
   - Place `firebase-service-account.json` in `backend/config/` directory
   - Download from Firebase Console → Project Settings → Service Accounts

2. **Start Backend Server**
   ```bash
   cd backend
   npm start
   ```
   
   Look for these logs:
   - ✅ Firebase Admin SDK initialized successfully
   - 🚀 Server running on http://0.0.0.0:3000

### Flutter App Setup
1. **Check Firebase Configuration**
   - Ensure `google-services.json` exists in `android/app/`
   - Ensure `firebase_options.dart` is configured

2. **Run App**
   ```bash
   flutter run -d emulator-5556
   ```

### Testing Flow

#### 1. Login as User
- Login with a user account
- Check console for:
  - 🔑 FCM Token: [your-token]
  - 💾 Attempting to save FCM token to backend...
  - 📤 Sending request to http://[your-ip]:3000/api/fcm/save-token
  - 💾 FCM token saved to backend successfully

#### 2. Login as Doctor (on another device/emulator)
- Login with a doctor account
- Ensure doctor's FCM token is also saved

#### 3. User Books Appointment
- As user, book an appointment with the doctor
- **Backend logs** should show:
  ```
  📱 Attempting to send FCM notification to doctor: [doctor-id]
  👤 User found: [doctor-email]
  📱 FCM Token: EXISTS
  📨 Sending FCM message: { title: '🔔 New Appointment Request', ... }
  ✅ FCM notification sent successfully to user [doctor-id]
  ```

- **Doctor's Device** should receive notification:
  - Title: "🔔 New Appointment Request"
  - Body: "[Patient Name] has requested an appointment on [date] at [time]"

#### 4. Check Notifications Tab
- Doctor can also see the notification in the Notifications tab
- Even if FCM fails, notification is saved to database

### Common Issues & Solutions

#### Issue 1: No FCM Token
**Symptom**: `⚠️ No FCM token for user [user-id]`

**Solutions**:
1. Ensure user is logged in
2. Check app has notification permissions
3. Restart app to trigger FCM token refresh
4. Check Firebase is properly configured

#### Issue 2: FCM Token Not Saved to Backend
**Symptom**: Token logs show but backend doesn't have it

**Solutions**:
1. Check API endpoint: `http://[your-ip]:3000/api/fcm/save-token`
2. Verify auth token is valid
3. Check CORS settings in backend
4. Look for network errors in Flutter console

#### Issue 3: Notification Not Received
**Symptom**: Backend logs show success but no notification on device

**Solutions**:
1. Check notification channel is created (appointment_alerts)
2. Verify app is running or in background
3. Check device notification settings
4. Ensure Firebase project has correct package name
5. Check google-services.json matches Firebase project

#### Issue 4: Firebase Not Configured
**Symptom**: `📨 Mock notification sent (Firebase not configured)`

**Solutions**:
1. Download firebase-service-account.json from Firebase Console
2. Place in backend/config/ directory
3. Restart backend server

### Verify Database

```javascript
// Check user's FCM token in MongoDB
db.users.find({ email: "doctor@example.com" }, { fcmToken: 1, fcmTokens: 1 })

// Check notifications created
db.notifications.find({ userId: ObjectId("...") }).sort({ createdAt: -1 })

// Check appointments
db.appointments.find({ doctorId: ObjectId("...") }).sort({ createdAt: -1 })
```

### Medicine Reminders + Tracker Integration

#### How It Works Now
1. **Add via Reminders Card**: Medicine is saved to User.medicines[] AND UserMedicine collection
2. **Add via Medicine Tracker**: Medicine is saved to UserMedicine collection AND notifications are scheduled
3. **Notifications**: Scheduled for all medicines added either way

#### Testing
1. Add medicine via Reminders Card → Check notification is scheduled
2. Add medicine via Medicine Tracker → Check notification is scheduled
3. Delete medicine → Check notification is cancelled

### Cancelled Appointments

#### New Behavior
- Cancelled appointments are **deleted** from database
- They no longer occupy space
- Users won't see cancelled appointments in their list

#### Testing
1. Book an appointment
2. Cancel it (as user or doctor)
3. Check backend logs: `🗑️ Deleting cancelled appointment`
4. Verify appointment is removed from database and UI

### Quick Test Commands

```bash
# Check if backend is running
curl http://localhost:3000/api/health

# Check user's FCM token (requires auth token)
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:3000/api/users/me

# Test notification endpoint manually (requires auth token)
# This won't work from curl but shows the endpoint exists
curl -X POST http://localhost:3000/api/fcm/save-token \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"token":"test-token","device":"android"}'
```

### Success Indicators

✅ **Medicine Reminders Working**:
- Medicines show in Reminders Card
- Notifications scheduled (check Flutter logs)
- Reminders trigger at specified times

✅ **Appointment Notifications Working**:
- Doctor receives FCM notification
- Notification appears in Notifications tab
- Backend logs show FCM success

✅ **Cancelled Appointments Deleted**:
- Cancelled appointments don't appear in list
- Database doesn't contain cancelled appointments
- UI refreshes after cancellation

## Logs to Watch

### Backend
```
✅ Firebase Admin SDK initialized successfully
💾 FCM token saved for user: [email]
📱 Attempting to send FCM notification to doctor: [id]
✅ FCM notification sent successfully
🗑️ Deleting cancelled appointment
```

### Flutter
```
🔑 FCM Token: [token]
💾 FCM token saved to backend successfully
✅ Medicine also added to tracker
✅ Medicine reminder scheduled
```
