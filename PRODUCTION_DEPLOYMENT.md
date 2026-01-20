# 🚀 Production Deployment Guide - Emergency Integration

## Current Setup
- ✅ MediLinko Backend: Deployed on Render
- ⏳ EmergencyMed Web Service: To be deployed
- ⏳ Flutter App: To be updated with production URLs

---

## 📋 Step-by-Step Deployment

### Step 1: Deploy EmergencyMed Web Service

**Option A: Deploy to Render (Recommended - same as MediLinko)**

1. **Create new Web Service on Render:**
   - Go to https://render.com
   - Click "New" → "Web Service"
   - Connect your emergencyMed repository

2. **Configure Build Settings:**
   ```
   Build Command: npm install
   Start Command: npm start
   ```

3. **Set Environment Variables:**
   ```
   NODE_ENV=production
   PORT=10000  (Render assigns this automatically)
   MONGODB_URI=<your_mongodb_connection_string>
   ```

4. **Deploy and note the URL:**
   ```
   Example: https://emergency-med-xyz.onrender.com
   ```

**Option B: Other Hosting (Vercel, Railway, AWS, etc.)**
- Follow their deployment docs
- Ensure you get a public HTTPS URL
- Make sure CORS is configured to allow your MediLinko backend

---

### Step 2: Update MediLinko Backend on Render

1. **Go to your MediLinko backend service on Render**

2. **Navigate to Environment tab**

3. **Add/Update this variable:**
   ```
   Key: EMERGENCY_MED_URL
   Value: https://emergency-med-xyz.onrender.com
   ```
   (Replace with your actual emergencyMed URL)

4. **Click "Save Changes"**
   - Render will automatically redeploy your backend
   - Wait for deployment to complete

5. **Verify in logs:**
   ```
   Look for: Server running on port 3000
   No errors about EMERGENCY_MED_URL
   ```

---

### Step 3: Update Flutter App

1. **Open:** `lib/services/emergency_web_service.dart`

2. **Update the production URL:**
   ```dart
   static const String _baseUrl = kDebugMode 
       ? 'http://localhost:5000' 
       : 'https://emergency-med-xyz.onrender.com'; // YOUR ACTUAL URL
   ```

3. **Replace `https://emergency-med-xyz.onrender.com` with your real emergencyMed URL**

4. **Test locally first:**
   ```bash
   flutter run --release
   ```
   - Test emergency screen
   - Verify QR code shows web URL
   - Test profile updates

---

### Step 4: Update EmergencyMed CORS Settings

Your emergencyMed backend needs to allow requests from your deployed MediLinko backend.

**Update emergencyMed server.js:**

```javascript
const cors = require('cors');

// Production CORS configuration
const allowedOrigins = [
  'https://your-medilinko-backend.onrender.com',  // Your MediLinko backend
  'http://localhost:3000',  // Local development
];

app.use(cors({
  origin: function(origin, callback) {
    // Allow requests with no origin (mobile apps, Postman, etc.)
    if (!origin) return callback(null, true);
    
    if (allowedOrigins.indexOf(origin) === -1) {
      return callback(new Error('CORS policy violation'), false);
    }
    return callback(null, true);
  },
  credentials: true
}));
```

**Or simpler (less secure but works):**
```javascript
app.use(cors({ origin: '*' }));
```

---

### Step 5: Test Production Integration

1. **Test from Flutter App (in release mode):**
   ```bash
   flutter run --release
   ```

2. **Register a new test user**
   - Complete health profile
   - Check that data syncs to emergencyMed

3. **Check MediLinko backend logs on Render:**
   ```
   Should see: ✅ Emergency data synced for user <userId>
   ```

4. **Check EmergencyMed logs:**
   ```
   Should see: 📥 Received sync request from MediLinko
   ```

5. **Test QR Code:**
   - Open emergency screen
   - Verify QR shows web URL (production URL)
   - Scan QR with phone
   - Should open browser and show emergency profile

---

## 🔒 Security Checklist for Production

### EmergencyMed Service
- [ ] HTTPS enabled (automatically on Render)
- [ ] CORS configured properly
- [ ] Rate limiting implemented
- [ ] Input validation on all endpoints
- [ ] Environment variables secured (not in code)
- [ ] Database credentials secured

### MediLinko Backend
- [ ] EMERGENCY_MED_URL uses HTTPS
- [ ] Environment variable set on Render (not in .env file)
- [ ] Axios timeout configured (already done)
- [ ] Error handling for emergencyMed downtime (already done)

---

## 📝 Environment Variables Reference

### MediLinko Backend (Render)
```
MONGODB_URI=mongodb+srv://...
JWT_SECRET=your-secret-key
PORT=10000
NODE_ENV=production
EMERGENCY_MED_URL=https://emergency-med-xyz.onrender.com  ← ADD THIS
```

### EmergencyMed Backend (Render)
```
MONGODB_URI=mongodb+srv://...  (if using MongoDB)
NODE_ENV=production
PORT=10000
PUBLIC_URL=https://emergency-med-xyz.onrender.com  (for QR URLs)
```

### Flutter App (Code)
```dart
// lib/services/emergency_web_service.dart
static const String _baseUrl = kDebugMode 
    ? 'http://localhost:5000' 
    : 'https://emergency-med-xyz.onrender.com';
```

---

## 🐛 Troubleshooting Production Issues

### Issue 1: "Emergency service unavailable"

**Check:**
1. Is emergencyMed service running on Render?
2. Is the URL correct in MediLinko backend environment?
3. Check MediLinko backend logs for connection errors

**Test:**
```bash
curl https://emergency-med-xyz.onrender.com/health
# Should return: {"status":"ok"}
```

### Issue 2: CORS errors

**Symptoms:**
- Browser console shows CORS error
- Requests from MediLinko backend fail

**Fix:**
Add your MediLinko backend URL to emergencyMed CORS config

### Issue 3: QR shows static text in production

**Cause:** Flutter app not updated with production URL

**Fix:**
1. Update `emergency_web_service.dart` with production URL
2. Rebuild app: `flutter build apk --release`
3. Reinstall on device

### Issue 4: Data not syncing

**Check MediLinko backend logs on Render:**
```
Look for errors in emergency sync
Check network connectivity to emergencyMed
```

**Check EmergencyMed logs:**
```
Verify it's receiving requests
Check database connection
```

---

## 🔄 Update Workflow

When you update emergencyMed code:

1. Push to Git repository
2. Render auto-deploys (if connected to Git)
3. No changes needed in MediLinko (URL stays same)
4. No rebuild needed for Flutter app

When you update MediLinko backend:

1. Push to Git repository
2. Render auto-deploys
3. No changes needed in emergencyMed
4. No rebuild needed for Flutter app

When you update Flutter app:

1. Update code
2. Rebuild: `flutter build apk --release`
3. Distribute new APK to users

---

## 📊 Monitoring in Production

### MediLinko Backend (Render Logs)
Monitor for:
- `✅ Emergency data synced successfully`
- `❌ Error syncing emergency data`
- `⚠️ EmergencyMed service unavailable`

### EmergencyMed (Render Logs)
Monitor for:
- `📥 Received sync request from MediLinko`
- `✅ User synced successfully`
- Any error messages

### Set up alerts (optional):
- Render can send email alerts for downtime
- Set up uptime monitoring (e.g., UptimeRobot)
- Monitor error rates

---

## 🚀 Quick Reference

### URLs You'll Need:

1. **MediLinko Backend (Render):**
   ```
   https://your-medilinko-backend.onrender.com
   ```

2. **EmergencyMed Service (After deployment):**
   ```
   https://emergency-med-xyz.onrender.com
   ```

3. **Update these locations:**
   - Render: MediLinko backend environment variable
   - Code: `lib/services/emergency_web_service.dart`
   - Code: emergencyMed CORS settings

---

## ✅ Deployment Checklist

- [ ] Deploy emergencyMed to Render (or other host)
- [ ] Note the production URL
- [ ] Add EMERGENCY_MED_URL to MediLinko backend on Render
- [ ] Update Flutter app with production URL
- [ ] Configure CORS on emergencyMed
- [ ] Test sync from Flutter app
- [ ] Test QR code generation
- [ ] Test QR code scanning
- [ ] Verify web interface shows correct data
- [ ] Set up monitoring/alerts
- [ ] Document production URLs

---

**Deployment Guide Version:** 1.0  
**Last Updated:** January 20, 2026  
**Status:** Ready for production deployment
