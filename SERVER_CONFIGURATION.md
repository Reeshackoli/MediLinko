# MediLinko - Server Configuration Guide 🌐

## Problem Solved ✅
**You no longer need to change IP addresses when switching WiFi networks!**

The app now has a **Settings screen** where you can dynamically configure the backend URL without changing any code.

---

## 🚀 Quick Start - 3 Easy Options

### **Option 1: Use Settings Screen (Recommended for Same WiFi)**
Perfect for physical devices on the same WiFi as your PC.

1. **Find your PC's IP address:**
   ```bash
   # Windows
   ipconfig
   
   # Look for "IPv4 Address" (e.g., 10.40.93.175)
   ```

2. **Run the backend server:**
   ```bash
   cd backend
   npm run dev
   ```

3. **Open the app and go to Settings:**
   - Tap the **⚙️ Settings icon** in the app bar
   - Tap on "Server Settings"
   - Enter: `http://YOUR_IP:3000/api` (e.g., `http://10.40.93.175:3000/api`)
   - Tap "Test URL Format" to validate
   - Tap "Save & Apply"

4. **Done!** The app will remember this URL even after restarting.

**When WiFi changes:** Just update the IP in Settings again (takes 10 seconds).

---

### **Option 2: Use Ngrok (Works Anywhere - Even Different WiFi)** ⭐
Perfect for sharing with testers or accessing from anywhere.

#### **Step 1: Install Ngrok**
```bash
# Windows (using Chocolatey)
choco install ngrok

# Or download from: https://ngrok.com/download
```

#### **Step 2: Sign up & Add Auth Token** (Free)
1. Create account at [ngrok.com](https://ngrok.com)
2. Copy your auth token
3. Run:
   ```bash
   ngrok config add-authtoken YOUR_TOKEN
   ```

#### **Step 3: Start Backend**
```bash
cd backend
npm run dev
```

#### **Step 4: Create Ngrok Tunnel**
```bash
# In a NEW terminal
ngrok http 3000
```

You'll see output like:
```
Forwarding  https://abc123.ngrok-free.app -> http://localhost:3000
```

#### **Step 5: Update App Settings**
1. Copy the HTTPS URL (e.g., `https://abc123.ngrok-free.app`)
2. Open app → Settings → Server Settings
3. Enter: `https://abc123.ngrok-free.app/api`
4. Save & Apply

**Benefits:**
- ✅ Works from ANY WiFi network
- ✅ Works from mobile data (4G/5G)
- ✅ Share with friends/testers anywhere
- ✅ HTTPS secure connection
- ✅ No firewall issues

**Note:** Free ngrok URLs change when you restart. For permanent URLs, upgrade to ngrok paid plan.

---

### **Option 3: Use Environment Variable (For Developers)**
Set URL at runtime without changing code.

```bash
# Run with custom backend URL
flutter run --dart-define=API_URL=http://YOUR_IP:3000/api

# Examples:
flutter run --dart-define=API_URL=http://192.168.1.100:3000/api
flutter run --dart-define=API_URL=https://your-ngrok-url.ngrok-free.app/api
flutter run --dart-define=API_URL=http://localhost:3000/api
```

---

## 📱 Platform-Specific Notes

### **Android Emulator**
- Use `http://10.0.2.2:3000/api` (Android's alias for localhost)
- Or use your PC's IP if emulator is in bridged network mode

### **iOS Simulator**
- Use `http://localhost:3000/api` (shares network with macOS)

### **Physical Devices**
- MUST use PC's actual IP (not localhost)
- MUST be on same WiFi OR use ngrok
- Check firewall allows port 3000

### **Web (Chrome/Edge)**
- Use `http://localhost:3000/api` when running locally
- Or use ngrok for public access

---

## 🔧 Backend Configuration

The backend `server.js` is already configured correctly:

```javascript
const HOST = '0.0.0.0'; // ✅ Listens on ALL network interfaces
const PORT = 3000;
```

This means:
- ✅ Works on localhost (127.0.0.1)
- ✅ Works on WiFi IP (e.g., 192.168.x.x)
- ✅ Works on Ethernet IP
- ✅ No changes needed when switching networks

---

## 🎯 What Changed in the App?

### **New Features:**
1. **Settings Screen** - [server_settings_screen.dart](lib/screens/settings/server_settings_screen.dart)
   - Change backend URL dynamically
   - Test connection
   - Quick presets for common configurations
   - Persistent storage (remembers your choice)

2. **Smart API Config** - [api_config.dart](lib/core/constants/api_config.dart)
   - Checks user settings first
   - Falls back to environment variables
   - Uses sensible defaults

3. **Persistent Storage** - [api_config_service.dart](lib/services/api_config_service.dart)
   - Stores URL in SharedPreferences
   - Survives app restarts

---

## 🎨 How to Access Settings

1. **From any Dashboard:**
   - Look for the **⚙️ Settings icon** in the top-right app bar
   - Tap it → Opens Server Settings

2. **Direct navigation:**
   ```dart
   context.push('/settings/server');
   ```

---

## 💡 Common Use Cases

### **Scenario 1: Working from Home**
```
Today's WiFi IP: 192.168.1.100
1. Update Settings to: http://192.168.1.100:3000/api
2. Done!
```

### **Scenario 2: Working from Office**
```
Office WiFi IP: 10.40.93.175
1. Update Settings to: http://10.40.93.175:3000/api
2. Done!
```

### **Scenario 3: Demo to Client (Different Location)**
```
1. Start ngrok: ngrok http 3000
2. Copy URL: https://abc123.ngrok-free.app
3. Update Settings to: https://abc123.ngrok-free.app/api
4. Client can test from anywhere!
```

### **Scenario 4: Team Collaboration**
```
1. One person starts backend + ngrok
2. Share ngrok URL with team
3. Everyone updates their Settings
4. Whole team connected to same backend!
```

---

## 🐛 Troubleshooting

### **"Cannot connect to server"**
1. Check backend is running (`npm run dev`)
2. Check IP is correct (run `ipconfig`)
3. Check firewall allows port 3000
4. Check phone and PC are on same WiFi
5. Try using ngrok instead

### **"Invalid URL format"**
- URL must start with `http://` or `https://`
- Correct: `http://192.168.1.100:3000/api`
- Wrong: `192.168.1.100:3000/api` (missing http://)
- Wrong: `http://192.168.1.100:3000` (missing /api)

### **Works on emulator but not physical device**
- Emulator uses localhost
- Physical device needs your PC's IP or ngrok

### **Ngrok "Too Many Connections" (Free Tier)**
- Free tier has rate limits
- Wait 1 minute and retry
- Or upgrade to paid plan

---

## 🔒 Security Notes

### **Development (Current Setup)**
- ✅ CORS allows all origins (`*`)
- ✅ Perfect for testing
- ⚠️ NOT suitable for production

### **Production (Future)**
1. Deploy backend to cloud (AWS, Azure, Heroku, Railway)
2. Get proper domain name
3. Enable HTTPS
4. Restrict CORS to specific origins
5. Add rate limiting
6. Use environment variables for secrets

---

## 📊 Configuration Priority

The app checks URLs in this order:

1. **User Setting** (from Settings screen) ← **Highest Priority**
2. **Environment Variable** (`--dart-define=API_URL=...`)
3. **Last Known IP** (saved from previous session)
4. **Default IP** (currently: `10.40.93.175`)
5. **Fallback** (`http://localhost:3000/api`) ← **Lowest Priority**

---

## 🎓 For Other Developers

### **When cloning this project:**

1. **Start backend:**
   ```bash
   cd backend
   npm install
   npm run dev
   ```

2. **Find your IP:**
   ```bash
   ipconfig  # Windows
   ifconfig  # Mac/Linux
   ```

3. **Run Flutter app:**
   ```bash
   flutter pub get
   flutter run
   ```

4. **Configure backend URL:**
   - Open Settings in app
   - Enter `http://YOUR_IP:3000/api`
   - Or use ngrok for easier setup

### **Quick Ngrok Setup:**
```bash
# Terminal 1: Backend
cd backend && npm run dev

# Terminal 2: Ngrok
ngrok http 3000

# Copy the HTTPS URL and paste in app Settings
```

---

## 🚀 Production Deployment (Future)

When ready to deploy:

1. **Backend Options:**
   - Railway (easiest, free tier)
   - Render (free tier)
   - Heroku (paid)
   - AWS/Azure (most powerful)

2. **Update app:**
   - Set production URL as default in code
   - Or keep Settings feature for flexibility

3. **Example:**
   ```dart
   // api_config.dart
   static const String productionUrl = 'https://medilinko-api.railway.app/api';
   ```

---

## 📚 File Reference

| File | Purpose |
|------|---------|
| [server_settings_screen.dart](lib/screens/settings/server_settings_screen.dart) | UI to change backend URL |
| [api_config.dart](lib/core/constants/api_config.dart) | URL resolution logic |
| [api_config_service.dart](lib/services/api_config_service.dart) | Persistent storage |
| [app_router.dart](lib/core/router/app_router.dart) | Route: `/settings/server` |
| [server.js](backend/server.js) | Backend server (binds to 0.0.0.0) |

---

## ✨ Summary

**Problem:** Had to change code every time WiFi changed.

**Solution:** 
- ⚙️ Settings screen to change URL dynamically
- 🌐 Ngrok support for cross-network access
- 💾 Persistent storage remembers your choice
- 🔄 No more code changes needed!

**Result:** Change backend URL in 10 seconds without any coding!

---

Need help? Check the app's Settings screen for quick presets and instructions! 🎯
