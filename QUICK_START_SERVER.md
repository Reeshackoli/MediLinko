# Quick Start: Server Configuration 🚀

## Problem
**Before:** Had to change IP address in code every time WiFi changed ❌

**Now:** Change IP in app Settings without touching any code ✅

---

## Solution 1: Settings Screen (Same WiFi) ⚙️

### Steps:
1. **Get your PC's IP:**
   ```bash
   ipconfig
   # Look for: IPv4 Address . . . : 10.40.93.175
   ```

2. **Start backend:**
   ```bash
   cd backend
   npm run dev
   ```

3. **Update in app:**
   - Open MediLinko app
   - Tap **⚙️ Settings** icon (top-right)
   - Enter: `http://10.40.93.175:3000/api` (use YOUR IP)
   - Tap **Save & Apply**

4. **Done!** App remembers your settings.

**When WiFi changes:** Just repeat step 3 with new IP (takes 10 seconds)

---

## Solution 2: Ngrok (Works Anywhere) 🌐

Perfect for different WiFi, mobile data, or sharing with others.

### One-time Setup:
```bash
# Install ngrok
choco install ngrok

# Get free account at ngrok.com
# Add your auth token
ngrok config add-authtoken YOUR_TOKEN
```

### Every Time You Run:
```bash
# Terminal 1: Start backend
cd backend
npm run dev

# Terminal 2: Start ngrok
ngrok http 3000

# Copy the HTTPS URL (e.g., https://abc123.ngrok-free.app)
```

### In App:
- Settings → Server Settings
- Enter: `https://abc123.ngrok-free.app/api`
- Save & Apply

**Benefits:**
- ✅ Works from ANY network
- ✅ Works on mobile data (4G/5G)
- ✅ Share with testers anywhere
- ✅ HTTPS secure
- ✅ No firewall issues

---

## For Other Developers/Testers

### Option A: Use Their Own IP
1. Get IP: `ipconfig` → IPv4 Address
2. Update Settings: `http://THEIR_IP:3000/api`

### Option B: Connect to Your Ngrok
1. You share ngrok URL: `https://xyz.ngrok-free.app/api`
2. They enter it in Settings
3. Everyone uses same backend!

---

## Technical Details

### Backend (`server.js`)
```javascript
const HOST = '0.0.0.0';  // ✅ Listens on ALL interfaces
const PORT = 3000;
```
✅ No changes needed when switching networks

### App Configuration
- **Settings Screen:** [server_settings_screen.dart](lib/screens/settings/server_settings_screen.dart)
- **API Config:** [api_config.dart](lib/core/constants/api_config.dart)
- **Storage Service:** [api_config_service.dart](lib/services/api_config_service.dart)

### URL Priority (High to Low)
1. User-set URL (from Settings) ⭐
2. Environment variable (`--dart-define=API_URL=...`)
3. Last known IP
4. Default IP (currently: `10.40.93.175`)
5. Fallback (`localhost`)

---

## Platform Notes

| Platform | Recommended URL |
|----------|----------------|
| Android Emulator | `http://10.0.2.2:3000/api` |
| iOS Simulator | `http://localhost:3000/api` |
| Physical Device (Same WiFi) | `http://YOUR_PC_IP:3000/api` |
| Physical Device (Any Network) | Ngrok URL |
| Web Browser | `http://localhost:3000/api` |

---

## Troubleshooting

**Can't connect?**
1. ✅ Backend running? (`npm run dev`)
2. ✅ Correct IP? (run `ipconfig`)
3. ✅ Same WiFi network?
4. ✅ Firewall allows port 3000?
5. 💡 Try ngrok instead!

**Invalid URL?**
- ✅ Must start with `http://` or `https://`
- ✅ Must end with `/api`
- ✅ Example: `http://192.168.1.100:3000/api`

---

## Summary

🎯 **Current IP:** `10.40.93.175`  
⚙️ **Change in:** Settings → Server Settings  
🌐 **For anywhere:** Use ngrok  
📖 **Full guide:** [SERVER_CONFIGURATION.md](SERVER_CONFIGURATION.md)

**No more code changes needed!** 🎉
