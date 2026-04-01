# 🔗 MediLinko ↔️ EmergencyMed Integration Guide

## Overview

This guide explains how MediLinko (Flutter app + Node.js backend) integrates with your emergencyMed web service to provide QR code-based emergency medical information.

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     MediLinko Flutter App                       │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Emergency Screen                                         │  │
│  │  • Fetches QR URL from emergencyMed                      │  │
│  │  • Displays QR code with web URL                         │  │
│  │  • Falls back to static text if offline                  │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ↕️
┌─────────────────────────────────────────────────────────────────┐
│                   MediLinko Backend (Port 3000)                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Emergency Sync Controller                                │  │
│  │  • Syncs user health data to emergencyMed               │  │
│  │  • Retrieves QR URLs                                     │  │
│  │  • Monitors emergencyMed service health                 │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ↕️ HTTP Requests
┌─────────────────────────────────────────────────────────────────┐
│                 EmergencyMed Service (Port 5000)                │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  Web Interface                                            │  │
│  │  • Displays emergency medical info                       │  │
│  │  • Public access (no authentication needed)             │  │
│  │  • Provides QR URL endpoint                             │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

## 🔄 Data Flow

### 1. User Registration/Profile Update

```
1. User completes profile in MediLinko Flutter app
2. Profile data saved to MediLinko MongoDB
3. MediLinko backend automatically syncs emergency data to emergencyMed
4. EmergencyMed creates/updates user record in its database
```

**Flutter (Profile Wizard):**
```dart
// lib/providers/profile_wizard_provider.dart
await ProfileService.updateProfile(completeData);
await EmergencyWebService.syncEmergencyData(userId, emergencyData);
```

**MediLinko Backend:**
```javascript
// backend/controllers/profileController.js
// Auto-sync after profile update
await syncEmergencyData(userData, healthProfile);
```

### 2. Emergency QR Code Display

```
1. User triggers fall detection or opens emergency screen
2. Flutter app requests QR URL from emergencyMed service
3. QR code displayed with web URL
4. Anyone scanning QR code → opens web browser → sees emergency info
```

**Flutter:**
```dart
// lib/screens/emergency/emergency_screen.dart
final qrUrl = await EmergencyWebService.getQRCodeUrl();
// Displays: https://yourdomain.com/profile/ML-USER-123-xyz
```

## 📡 API Integration Points

### EmergencyMed Endpoints (You Need to Implement)

#### 1. Sync User Data from MediLinko
```
POST http://localhost:5000/api/users/sync-from-medilinko
```

**Request Body:**
```json
{
  "medilinkoUserId": "67890abcdef12345",
  "fullName": "John Doe",
  "email": "john@example.com",
  "phone": "9876543210",
  "role": "user",
  "bloodGroup": "O+",
  "allergies": ["Penicillin", "Peanuts"],
  "conditions": ["Diabetes"],
  "currentMedicines": ["Metformin"],
  "emergencyContactName": "Jane Doe",
  "emergencyContactRelationship": "Spouse",
  "emergencyContactPhone": "9876543211",
  "emergencyContactName2": "Dr. Smith",
  "emergencyContactRelationship2": "Doctor",
  "emergencyContactPhone2": "9876543212"
}
```

**Expected Response:**
```json
{
  "success": true,
  "userId": "ML-USER-1234567890-abc123",
  "message": "User synced successfully"
}
```

#### 2. Get QR URL for User
```
GET http://localhost:5000/api/users/:userId/qr-url
```

**Expected Response:**
```json
{
  "qrUrl": "http://localhost:3000/profile/ML-USER-1234567890-abc123"
}
```

#### 3. Health Check
```
GET http://localhost:5000/health
```

**Expected Response:**
```json
{
  "status": "ok"
}
```

### MediLinko Endpoints (Already Implemented)

#### 1. Sync Emergency Data
```
POST http://localhost:3000/api/emergency/sync
Authorization: Bearer <JWT_TOKEN>
```

**Request Body:**
```json
{
  "healthProfile": {
    "bloodGroup": "O+",
    "allergies": ["Penicillin"],
    // ... other health data
  }
}
```

#### 2. Get QR URL
```
GET http://localhost:3000/api/emergency/qr-url
Authorization: Bearer <JWT_TOKEN>
```

#### 3. Check EmergencyMed Service Status
```
GET http://localhost:3000/api/emergency/service-status
Authorization: Bearer <JWT_TOKEN>
```

## 🔧 Configuration

### MediLinko Backend (.env)
```env
# EmergencyMed Service Integration
EMERGENCY_MED_URL=http://localhost:5000

# In production:
# EMERGENCY_MED_URL=https://emergency.yourdomain.com
```

### MediLinko Flutter (emergency_web_service.dart)
```dart
static const String _baseUrl = 'http://localhost:5000'; // Development
// static const String _baseUrl = 'https://emergency.yourdomain.com'; // Production
```

## 📝 EmergencyMed Implementation Checklist

Your emergencyMed service needs to implement:

- [ ] **POST /api/users/sync-from-medilinko**
  - Accept MediLinko user data
  - Create or update user in emergencyMed database
  - Return emergencyMed userId

- [ ] **GET /api/users/:userId/qr-url**
  - Return web URL for user profile
  - Format: `http://yourdomain.com/profile/<userId>`

- [ ] **GET /health**
  - Simple health check endpoint

- [ ] **GET /profile/:userId** (public)
  - Display emergency medical info
  - No authentication required
  - Show: name, blood group, allergies, emergency contacts

## 🚀 Deployment Workflow

### Development Setup

1. **Start EmergencyMed Service:**
   ```bash
   cd emergencyMed/server
   npm start
   # Running on http://localhost:5000
   ```

2. **Start MediLinko Backend:**
   ```bash
   cd MediLinko/backend
   npm install  # Install axios if needed
   npm start
   # Running on http://localhost:3000
   ```

3. **Run Flutter App:**
   ```bash
   cd MediLinko
   flutter run
   ```

### Production Deployment

1. **Deploy EmergencyMed:**
   - Deploy to hosting service (Vercel, Netlify, AWS, etc.)
   - Note your production URL: `https://emergency.yourdomain.com`

2. **Update MediLinko Configuration:**
   ```env
   # backend/.env
   EMERGENCY_MED_URL=https://emergency.yourdomain.com
   ```
   
   ```dart
   // lib/services/emergency_web_service.dart
   static const String _baseUrl = 'https://emergency.yourdomain.com';
   ```

3. **Deploy MediLinko Backend:**
   - Deploy with updated environment variables

4. **Rebuild Flutter App:**
   ```bash
   flutter build apk --release
   ```

## 🔒 Security Considerations

### Current Implementation (Development)
- ✅ EmergencyMed endpoints are **public** (no auth required)
- ✅ MediLinko → EmergencyMed requests are **server-to-server**
- ⚠️ Anyone with QR URL can view emergency info (intentional for rescue scenarios)

### Production Recommendations

1. **Add Rate Limiting:**
   ```javascript
   // emergencyMed/server.js
   const rateLimit = require('express-rate-limit');
   
   app.use('/api/users', rateLimit({
     windowMs: 15 * 60 * 1000, // 15 minutes
     max: 100 // limit each IP to 100 requests per windowMs
   }));
   ```

2. **Use HTTPS:**
   - Never use HTTP in production
   - Get SSL certificate (Let's Encrypt is free)

3. **Add CORS Restrictions:**
   ```javascript
   // emergencyMed/server.js
   app.use(cors({
     origin: ['https://medilinko.yourdomain.com'],
     credentials: true
   }));
   ```

4. **Add API Key for Sync Endpoint:**
   ```javascript
   // emergencyMed - verify request is from MediLinko
   const API_KEY = process.env.MEDILINKO_API_KEY;
   
   app.post('/api/users/sync-from-medilinko', (req, res) => {
     if (req.headers['x-api-key'] !== API_KEY) {
       return res.status(401).json({ error: 'Unauthorized' });
     }
     // ... rest of handler
   });
   ```

## 📊 Testing

### Test Emergency Sync

1. **Register a test user in MediLinko:**
   ```
   Name: Test User
   Email: test@example.com
   Role: User
   ```

2. **Complete health profile:**
   - Blood group: O+
   - Allergies: Penicillin
   - Emergency contact: Jane Doe (9876543210)

3. **Verify sync:**
   ```bash
   # Check emergencyMed database
   # User should exist with MediLinko data
   ```

### Test QR Code

1. **Trigger fall detection or open emergency screen**

2. **Verify QR code displays web URL badge**

3. **Scan QR code with phone camera**

4. **Should open browser and show emergency profile**

## 🐛 Troubleshooting

### QR Code Shows Static Text Instead of URL

**Cause:** EmergencyMed service not responding

**Check:**
```bash
# Test emergencyMed health endpoint
curl http://localhost:5000/health

# Check MediLinko logs
# Should see: "⚠️ EmergencyMed service unavailable"
```

**Fix:** Ensure emergencyMed service is running

### Emergency Data Not Syncing

**Check MediLinko Backend Logs:**
```
❌ Error syncing emergency data: connect ECONNREFUSED
```

**Fix:** Verify EMERGENCY_MED_URL in .env

### CORS Errors in Browser

**Fix emergencyMed server.js:**
```javascript
app.use(cors({
  origin: '*', // Or specific domains
  credentials: true
}));
```

## 📞 Support

- **MediLinko Issues:** Check [MediLinko README](README.md)
- **Integration Issues:** Review this guide
- **EmergencyMed Issues:** Check your emergencyMed documentation

## 🎯 Future Enhancements

Potential improvements to consider:

- [ ] Add doctor notification when QR is scanned
- [ ] Add GPS location logging
- [ ] Add SMS alerts to emergency contacts
- [ ] Add one-time access tokens for QR URLs
- [ ] Add scan analytics dashboard
- [ ] Add multi-language support
- [ ] Add offline PWA for emergencyMed web interface

---

**Built with ❤️ for emergency medical response**
