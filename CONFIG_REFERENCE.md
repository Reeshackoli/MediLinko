# 🔧 Configuration Quick Reference

## 📍 Where to Update URLs

### 1️⃣ After Deploying EmergencyMed

```
Example deployed URL: https://emergency-med-abc123.onrender.com
```

### 2️⃣ Update MediLinko Backend (Render Dashboard)

**Location:** Render Dashboard → MediLinko Backend Service → Environment

```
Variable Name:  EMERGENCY_MED_URL
Value:          https://emergency-med-abc123.onrender.com
```

**⚠️ Important:** Click "Save Changes" - Render will auto-redeploy

---

### 3️⃣ Update Flutter App (Code)

**File:** `lib/services/emergency_web_service.dart`

**Line 10-12:**

```dart
static const String _baseUrl = kDebugMode 
    ? 'http://localhost:5000' 
    : 'https://emergency-med-abc123.onrender.com'; // ← UPDATE THIS
```

**Replace** `https://emergency-med-abc123.onrender.com` with your actual URL

---

### 4️⃣ Update EmergencyMed CORS (Code)

**File:** `emergencyMed/server/server.js` (or similar)

```javascript
const cors = require('cors');

app.use(cors({
  origin: [
    'https://your-medilinko-backend.onrender.com', // ← Your MediLinko backend URL
    'http://localhost:3000'  // Keep for local dev
  ],
  credentials: true
}));
```

---

## 🔄 Development vs Production

### Development (Current)
```
Flutter App → http://localhost:3000 (MediLinko Backend)
                  ↓
            http://localhost:5000 (EmergencyMed)
```

### Production (After Deployment)
```
Flutter App → https://medilinko-backend.onrender.com
                  ↓
            https://emergency-med.onrender.com
```

---

## 🚀 Deployment Steps Summary

1. **Deploy EmergencyMed** → Get URL
2. **Update Render** → Add environment variable
3. **Update Flutter** → Change production URL
4. **Update CORS** → Allow MediLinko backend
5. **Rebuild Flutter** → `flutter build apk --release`
6. **Test** → Register user, check QR code

---

## ✅ Testing Commands

### Test EmergencyMed is Live
```bash
curl https://emergency-med-abc123.onrender.com/health
# Expected: {"status":"ok"}
```

### Test MediLinko Can Reach EmergencyMed
Check MediLinko backend logs on Render after user registration:
```
✅ Emergency data synced successfully
```

### Test QR Code
1. Open emergency screen in app
2. Should see "WEB" badge
3. Scan QR → Opens browser
4. Browser shows: `https://emergency-med-abc123.onrender.com/profile/ML-USER-...`

---

## 📝 Checklist

- [ ] EmergencyMed deployed
- [ ] Got production URL: `_______________________________`
- [ ] Updated Render environment variable
- [ ] Updated `emergency_web_service.dart`
- [ ] Updated emergencyMed CORS
- [ ] Rebuilt Flutter app
- [ ] Tested end-to-end
- [ ] QR code works in production

---

**Quick Reference Version:** 1.0
