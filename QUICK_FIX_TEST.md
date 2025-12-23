# Quick Fix Testing Guide

## Issues Fixed

### 1. Medicine Reminder ID Overflow ✅
**Problem**: Notification ID was too large (using milliseconds since epoch)
**Fix**: Use hash of medicine name + time, limited to 32-bit integer range

### 2. FCM Token Not Saving ✅
**Problem**: 
- Wrong API URL (hardcoded 10.0.2.2:5000)
- Token not saved immediately after getting it
- Missing detailed logging

**Fix**:
- Use ApiConfig.baseUrl
- Save token immediately on initialization
- Add comprehensive logging

### 3. Notification Channels ✅
**Problem**: Channel IDs mismatch between creation and usage
**Fix**: Verified channels are created correctly

## Test Steps

### Test 1: Medicine Reminders
1. Start backend: `cd backend && npm start`
2. Run app: `flutter run -d emulator-5556`
3. Login as user
4. Click on Medicine Reminders card
5. Click + to add medicine
6. Enter details:
   - Name: Paracetamol
   - Dosage: 1 pill
   - Time: Select a time 1-2 minutes from now
7. Click "Add Reminder"

**Expected Results**:
```
✅ Reminder set for Paracetamol
✅ Medicine also added to tracker
✅ Medicine reminder scheduled: Paracetamol at [time]
```

**Wait for notification time** - you should see notification in notification bar

### Test 2: FCM Notifications
1. Make sure backend is running
2. Login as Doctor on one device/emulator
3. Check logs for:
```
🔑 FCM Token: [token]
💾 Attempting to save FCM token to backend...
📤 Sending request to http://[ip]:3000/api/fcm/save-token
📥 Response status: 200
💾 FCM token saved to backend successfully
```

4. On another device/emulator, login as User
5. Book an appointment with the doctor
6. Check **backend** logs:
```
📱 Attempting to send FCM notification to doctor: [id]
👤 User found: [email]
📱 FCM Token: EXISTS
📨 Sending FCM message...
✅ FCM notification sent successfully
```

7. Check **doctor's device** - should see notification in notification bar

### Test 3: Cancelled Appointments
1. As user, book an appointment
2. Cancel the appointment
3. Check backend logs: `🗑️ Deleting cancelled appointment`
4. Refresh appointments list - cancelled appointment should be gone
5. Verify in database - appointment should be deleted

## Common Issues

### Issue: "Invalid argument (id)"
**Status**: ✅ FIXED
**Solution**: Using hash-based ID generation

### Issue: "No FCM token saved"
**Check**:
1. Backend logs show: `✅ FCM token saved for user: [email]`
2. Flutter logs show: `💾 FCM token saved to backend successfully`
3. If not, check:
   - Is backend running?
   - Is ApiConfig.baseUrl correct?
   - Is auth token valid?

### Issue: "Notification not received"
**Check**:
1. Notification permission granted?
2. App in foreground or background?
3. Check Flutter logs for scheduling confirmation
4. For FCM: Check backend has user's FCM token in database

### Issue: "Time zone issues"
**Check**: Notification service uses `Asia/Kolkata` timezone
**Solution**: Change in notification_service.dart if needed

## Backend Verification

### Check FCM Token in Database
```bash
# Connect to MongoDB
mongosh

# Use your database
use medilinko

# Check user's FCM token
db.users.findOne({ email: "doctor@example.com" }, { fcmToken: 1, fcmTokens: 1 })
```

Should show:
```json
{
  "_id": "...",
  "fcmToken": "eXaMpLe_ToKeN_123...",
  "fcmTokens": [
    {
      "token": "eXaMpLe_ToKeN_123...",
      "device": "android",
      "updatedAt": "2025-12-23T..."
    }
  ]
}
```

### Check Notifications in Database
```javascript
db.notifications.find({ userId: ObjectId("...") }).sort({ createdAt: -1 }).limit(5)
```

### Test FCM from Backend Console
```javascript
// In backend, create test file test-fcm.js:
const admin = require('./config/firebase').admin;

async function testFCM(token) {
  const message = {
    token: token,
    notification: {
      title: '🧪 Test Notification',
      body: 'This is a test from backend'
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'high_importance_channel',
        sound: 'default'
      }
    }
  };
  
  try {
    const response = await admin.messaging().send(message);
    console.log('✅ Test notification sent:', response);
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

// Get token from database and run
testFCM('YOUR_FCM_TOKEN_HERE');
```

## Quick Checks

### 1. Backend Health
```bash
curl http://localhost:3000/api/health
```
Should return: `{"success":true,"message":"MediLinko API is running",...}`

### 2. Firebase Config
Check file exists: `backend/config/firebase-service-account.json`

If not:
1. Go to Firebase Console
2. Project Settings → Service Accounts
3. Generate New Private Key
4. Save as `firebase-service-account.json`
5. Restart backend

### 3. Flutter Logs
Watch for these key messages:
```
✅ Notification service initialized with FCM
🔑 FCM Token: [token]
💾 FCM token saved to backend successfully
✅ Medicine reminder scheduled: [name] at [time]
```

### 4. Backend Logs
Watch for:
```
✅ Firebase Admin SDK initialized successfully
✅ FCM token saved for user: [email]
📱 Attempting to send FCM notification to doctor: [id]
✅ FCM notification sent successfully
```

## Still Not Working?

### Medicine Reminders
1. Check notification permission: Settings → Apps → MediLinko → Notifications
2. Check battery optimization isn't blocking app
3. Try scheduling for 1-2 minutes in future, not hours
4. Check Flutter logs for error messages

### FCM Notifications
1. Verify both devices have FCM tokens saved
2. Check Firebase project has correct package name
3. Verify google-services.json matches Firebase project
4. Check notification channels are created
5. Try sending test notification from Firebase Console

### Cancelled Appointments
1. Should work automatically
2. Check backend logs show deletion
3. Verify database doesn't have cancelled appointments
4. Try refreshing appointment list

## Success Indicators

✅ Medicine added without ID error
✅ Notification scheduled (check logs)
✅ FCM token saved (check backend logs)
✅ Doctor receives appointment notification
✅ Cancelled appointments deleted from database
✅ Medicine reminder fires at scheduled time
