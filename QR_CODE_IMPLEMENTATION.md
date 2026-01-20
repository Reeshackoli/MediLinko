# MediLinko Emergency QR Code Implementation

## ✅ What Was Implemented

Added QR code generation functionality to the MediLinko backend that generates QR codes pointing to the **Emergency Web Frontend** for easy viewing of emergency profiles.

## 🔧 Changes Made

### 1. Environment Variables (.env)
Added new environment variable for the web frontend URL:
```env
EMERGENCY_WEB_URL=https://medilinkoweb-emergency-frontend.onrender.com
```

### 2. Controller Updates (emergencySyncController.js)

#### Added Helper Function:
- `getEmergencyUserId()` - Fetches the emergency user ID (e.g., ML-USER-...) from emergencyMed backend

#### Updated Endpoints:
- `getQRUrl()` - Returns web profile URL
- `generateQRCode()` - Generates QR code as PNG image
- `getQRCodeDataUrl()` - Returns QR code as base64 data URL
- `displayQRCodePage()` - Displays beautiful HTML page with QR code

### 3. Routes (emergencySyncRoutes.js)
Added 3 new routes:
- `GET /api/emergency/qr-code` - PNG image
- `GET /api/emergency/qr-data` - JSON with base64 data URL
- `GET /api/emergency/qr-display` - HTML page

### 4. Dependencies
Installed `qrcode@^1.5.3` package

## 🎯 How It Works

### Flow:
1. User logs into MediLinko app
2. User syncs health profile (creates emergency profile in emergencyMed backend)
3. User requests QR code
4. MediLinko backend fetches emergency user ID from emergencyMed backend
5. Generates QR code with URL: `https://medilinkoweb-emergency-frontend.onrender.com/profile/ML-USER-...`
6. Returns QR code (as image, data URL, or HTML page)

### QR Code Points To:
```
https://medilinkoweb-emergency-frontend.onrender.com/profile/{emergencyUserId}
```

### Example Emergency User IDs:
- `ML-USER-1768849586515-qvzsv0ri8`
- `ML-USER-1768849743872-abc123xyz`

## 📱 API Usage Examples

### 1. Get QR URL (for Flutter app)
```bash
GET https://medilinko.onrender.com/api/emergency/qr-url
Authorization: Bearer <JWT_TOKEN>

Response:
{
  "success": true,
  "qrUrl": "https://medilinkoweb-emergency-frontend.onrender.com/profile/ML-USER-...",
  "emergencyUserId": "ML-USER-..."
}
```

### 2. Get QR Code as Base64 (for mobile apps)
```bash
GET https://medilinko.onrender.com/api/emergency/qr-data
Authorization: Bearer <JWT_TOKEN>

Response:
{
  "success": true,
  "qrCodeDataUrl": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA...",
  "emergencyUrl": "https://medilinkoweb-emergency-frontend.onrender.com/profile/ML-USER-...",
  "emergencyUserId": "ML-USER-..."
}
```

### 3. Get QR Code as PNG Image
```bash
GET https://medilinko.onrender.com/api/emergency/qr-code
Authorization: Bearer <JWT_TOKEN>

Response: PNG image (300x300px)
```

### 4. Display QR Code in Browser
```bash
GET https://medilinko.onrender.com/api/emergency/qr-display
Authorization: Bearer <JWT_TOKEN>

Response: Beautiful HTML page with QR code, download/print buttons
```

## 🚀 Deployment Steps

### For Render.com:

1. **Push Code to GitHub**
   ```bash
   git add .
   git commit -m "Add QR code generation with web frontend URLs"
   git push
   ```

2. **Set Environment Variable on Render**
   - Go to https://dashboard.render.com/
   - Select **medilinko** backend service
   - Click **Environment** tab
   - Add new variable:
     - Key: `EMERGENCY_WEB_URL`
     - Value: `https://medilinkoweb-emergency-frontend.onrender.com`
   - Click **Save Changes** (auto-redeploys)

3. **Wait for Deployment**
   - Render will automatically redeploy with new code
   - Takes ~2-3 minutes

4. **Test Endpoints**
   ```bash
   # Test QR URL endpoint
   curl -H "Authorization: Bearer YOUR_TOKEN" \
     https://medilinko.onrender.com/api/emergency/qr-url
   ```

## 🎨 HTML Page Features

The `/api/emergency/qr-display` endpoint shows a beautiful page with:
- 🏥 MediLinko branding
- 📱 QR code (400x400px, high quality)
- 📋 Copy URL button
- 🖨️ Print QR code button
- 💾 Download QR as PNG button
- 📝 Instructions for emergency responders
- 🔗 Direct emergency profile link

## 🔐 Security

All QR endpoints require JWT authentication:
- User must be logged in
- Valid JWT token required in Authorization header
- Only generates QR for authenticated user's emergency profile

## ⚠️ Important Notes

1. **User must sync health profile first**
   - QR generation requires emergency user ID
   - If not synced, returns 404 error with message to sync profile

2. **Environment Variables Required**
   - `EMERGENCY_MED_URL` - emergencyMed backend URL
   - `EMERGENCY_WEB_URL` - emergency web frontend URL

3. **Cross-Service Communication**
   - MediLinko backend → EmergencyMed backend (to get emergency user ID)
   - QR codes → Emergency Web Frontend (for viewing profiles)

## 🐛 Error Handling

### Profile Not Found (404)
```json
{
  "success": false,
  "message": "Emergency profile not found. Please sync your health profile first."
}
```

### Service Unavailable (500)
```json
{
  "success": false,
  "message": "Failed to generate QR code",
  "error": "Connection timeout"
}
```

## 📊 Testing Checklist

- [ ] Login with test user
- [ ] Sync health profile
- [ ] Test GET /api/emergency/qr-url
- [ ] Test GET /api/emergency/qr-data
- [ ] Test GET /api/emergency/qr-code
- [ ] Test GET /api/emergency/qr-display
- [ ] Scan QR code with phone
- [ ] Verify it opens web profile correctly
- [ ] Test print/download buttons on HTML page

## 🎯 Next Steps for Flutter App

To display QR codes in your Flutter app:

```dart
// Add to pubspec.yaml
dependencies:
  qr_flutter: ^4.1.0

// Fetch QR data URL
Future<void> fetchQRCode() async {
  final response = await http.get(
    Uri.parse('https://medilinko.onrender.com/api/emergency/qr-data'),
    headers: {'Authorization': 'Bearer $token'},
  );
  
  final data = jsonDecode(response.body);
  final qrDataUrl = data['qrCodeDataUrl'];
  final emergencyUrl = data['emergencyUrl'];
  
  // Display using Image.memory with base64 decoder
  // or use qr_flutter package to regenerate from emergencyUrl
}
```

## ✅ Summary

✅ QR codes now point to web frontend (https://medilinkoweb-emergency-frontend.onrender.com)  
✅ Multiple formats supported (PNG, base64, HTML)  
✅ Beautiful web interface for viewing/downloading QR codes  
✅ Proper error handling for missing profiles  
✅ JWT authentication required  
✅ Ready to deploy to Render  

---

**Created:** January 20, 2026  
**Backend:** https://medilinko.onrender.com  
**Web Frontend:** https://medilinkoweb-emergency-frontend.onrender.com  
**EmergencyMed Backend:** https://medilinko-emergency-backend.onrender.com
