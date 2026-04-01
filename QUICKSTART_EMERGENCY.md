# 🚀 Quick Start - Emergency Integration

## 📋 Prerequisites Checklist

- [ ] EmergencyMed project exists at: `C:\Users\SushilSC\Desktop\emergencyMed`
- [ ] MediLinko project at: `C:\Users\SushilSC\MediLinko`
- [ ] Node.js installed
- [ ] Flutter SDK installed

---

## ⚡ Quick Setup (5 Minutes)

### Terminal 1: Start EmergencyMed
```powershell
cd C:\Users\SushilSC\Desktop\emergencyMed\server
npm start
```
**Expected:** Server running on http://localhost:5000

### Terminal 2: Start MediLinko Backend
```powershell
cd C:\Users\SushilSC\MediLinko\backend
npm install  # First time only (installs axios)
npm start
```
**Expected:** Server running on http://localhost:3000

### Terminal 3: Run Flutter App
```powershell
cd C:\Users\SushilSC\MediLinko
flutter run
```
**Expected:** App launches on device/emulator

---

## ✅ Quick Test

1. **Register new user in app**
   - Choose "User" role
   - Complete profile wizard
   - Add: Blood type, allergies, emergency contact

2. **Check sync worked**
   - Look at EmergencyMed logs
   - Should see: `📥 Received sync request from MediLinko`

3. **Test QR code**
   - Open Emergency Screen (or trigger fall detection)
   - Should see "WEB" badge on QR
   - Scan QR with phone camera
   - Should open browser with emergency profile

---

## 🔧 Configuration Files

### MediLinko Backend
**File:** `backend/.env`
```env
EMERGENCY_MED_URL=http://localhost:5000
```

### Flutter App
**File:** `lib/services/emergency_web_service.dart`
```dart
static const String _baseUrl = 'http://localhost:5000';
```

---

## 🔌 API Endpoints

### EmergencyMed (You need to implement)
```
POST /api/users/sync-from-medilinko  - Receive user data
GET  /api/users/:userId/qr-url       - Get QR URL  
GET  /health                          - Health check
```

**Template:** See `EMERGENCY_MED_ENDPOINTS_TEMPLATE.js`

### MediLinko (Already done)
```
POST /api/emergency/sync          - Sync emergency data
GET  /api/emergency/qr-url        - Get QR URL
GET  /api/emergency/service-status - Check service
```

---

## 🐛 Troubleshooting

### QR shows static text instead of URL?
**Fix:** Start emergencyMed service (Terminal 1)

### "Error syncing emergency data"?
**Check:** `.env` has `EMERGENCY_MED_URL=http://localhost:5000`

### CORS error in browser?
**Fix emergencyMed:** Add `app.use(cors({ origin: '*' }))`

---

## 📚 Full Documentation

- **Integration Guide:** `EMERGENCY_INTEGRATION.md`
- **Implementation Summary:** `INTEGRATION_SUMMARY.md`
- **Endpoint Template:** `EMERGENCY_MED_ENDPOINTS_TEMPLATE.js`
- **Setup Script:** `setup-emergency-integration.ps1`

---

## 🎯 What Happens

```
User completes profile
    ↓
MediLinko saves to MongoDB
    ↓
MediLinko syncs to EmergencyMed
    ↓
EmergencyMed stores emergency data
    ↓
QR code shows web URL
    ↓
Anyone can scan QR → See emergency info
```

---

**Need help?** Read `EMERGENCY_INTEGRATION.md`
