# Doctors Map - Setup Complete ✅

## What Was Done

### 1. ✅ Created 3 Sample Doctors in Database
**Location**: Belgaum, Karnataka (Pincode: 590016)

**Doctors Created**:
1. **Dr. Cardiologist Belgaum 1**
   - Specialization: Cardiologist
   - Clinic: Heart Care Belgaum
   - Location: 15.8497, 74.4977
   - Fee: ₹600
   - Available: Mon/Wed/Fri 9am-5pm
   - Email: doctor1.belgaum@medilinko.com
   - Password: Doctor@123

2. **Dr. Dentist Belgaum 2**
   - Specialization: Dentist
   - Clinic: Smile Dental Clinic
   - Location: 15.8551, 74.5050
   - Fee: ₹400
   - Available: Mon/Tue/Thu 10am-6pm, Sat 10am-2pm
   - Email: doctor2.belgaum@medilinko.com
   - Password: Doctor@123

3. **Dr. Pediatrician Belgaum 3**
   - Specialization: Pediatrician
   - Clinic: Kids Care Hospital
   - Location: 15.8395, 74.4920
   - Fee: ₹500
   - Available: Mon-Fri 8am-4pm
   - Email: doctor3.belgaum@medilinko.com
   - Password: Doctor@123

### 2. ✅ Fixed Map Screen Issues

**Changes Made**:
- Map now centers on Belgaum (15.8497, 74.4977) by default
- Added automatic fetch of all doctors on screen load
- Added **Refresh Button** (blue FAB) to manually reload doctors
- Added **Recenter Button** (white FAB) to go back to your location
- Both location-based and fallback doctor fetching enabled

**File Modified**: `lib/screens/maps/doctors_map_screen.dart`

### 3. ✅ Fixed Seed Script
**File Fixed**: `backend/scripts/seed-belgaum-doctors.js`
- Removed PowerShell syntax errors
- Fixed email and phone validation
- Now creates doctors successfully

## How to Use

### Step 1: Start Backend Server
```bash
cd backend
npm run dev
```
Backend will run on `http://localhost:3000`

### Step 2: Start Flutter App
```bash
cd ..
flutter run -d chrome
# Or for mobile: flutter run
```

### Step 3: View Doctors on Map
1. Login/Register as a User (patient)
2. Go to Dashboard → "Find Doctors"
3. Map will show 3 doctors in Belgaum area
4. If you don't see them:
   - Tap the **blue refresh button** (bottom right)
   - Or zoom out to see Belgaum area (Karnataka, India)

### Step 4: Book Appointments
1. Tap any doctor marker on map
2. View doctor profile card (bottom sheet)
3. Tap "Book Appointment" button
4. Select date and time
5. Add symptoms (optional)
6. Submit booking

### Step 5: Test Doctor Side (Optional)
1. Logout from patient account
2. Login as one of the doctors:
   - Email: doctor1.belgaum@medilinko.com
   - Password: Doctor@123
3. Go to Dashboard → "Manage Appointments"
4. View and approve/reject patient appointments

## Map Features

### Available Now ✅
- **Doctor Markers**: Blue pins for each doctor
- **Location Tracking**: Shows your current location (if permission granted)
- **Search Bar**: Search doctors by name or specialization
- **Specialty Filters**: Filter by Cardiologist, Dentist, Pediatrician
- **Doctor Info Card**: Tap marker to see details
- **Refresh Button**: Blue FAB to reload doctors from API
- **Recenter Button**: White FAB to return to your location
- **Doctor Count Badge**: Shows number of doctors found (top right)

### User Interface
- **Map Provider**: OpenStreetMap (no API key needed)
- **Zoom**: Pinch to zoom in/out
- **Pan**: Drag to move around map
- **Tap Marker**: Select doctor and show info card
- **Info Card**: Shows name, specialization, clinic, fee, "Book Appointment" button

## Troubleshooting

### No Doctors Showing?

**Solution 1: Tap Refresh Button**
- Look for blue circular button (bottom right)
- Has refresh icon
- Tap to reload doctors from server
- Shows count in snackbar

**Solution 2: Check Backend**
```bash
cd backend
npm run dev
```
Make sure it shows:
```
✅ Server running on port 3000
✅ Connected to MongoDB
```

**Solution 3: Check Database**
Run seed script again if needed:
```bash
cd backend
node scripts/seed-belgaum-doctors.js
```

**Solution 4: Zoom Out**
- Map default centers on Belgaum (Karnataka)
- Coordinates: 15.8497°N, 74.4977°E
- Zoom level: 14 (neighborhood view)
- Pinch out to see wider area

**Solution 5: Check Browser Console**
- Open DevTools (F12)
- Look for API errors in Console
- Should see: `🗺️ Fetching nearby doctors` or `✅ Found X nearby doctors`

### Location Permission Denied?
- Web browsers require HTTPS for geolocation (except localhost)
- If denied, map uses Belgaum as default center
- Doctors will still load via `fetchAllDoctors()`
- Use refresh button to ensure doctors are loaded

### API Connection Issues?
Check `lib/core/constants/api_config.dart`:
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

Make sure backend is running on port 3000.

## File Structure

```
Backend:
├── backend/scripts/seed-belgaum-doctors.js (✅ Fixed)
├── backend/controllers/userController.js (getDoctors, getNearbyDoctors)
├── backend/routes/userRoutes.js (GET /doctors, GET /doctors/nearby)

Frontend:
├── lib/screens/maps/doctors_map_screen.dart (✅ Updated)
├── lib/providers/map_provider.dart (fetchAllDoctors, fetchNearbyDoctors)
├── lib/services/map_service.dart (API calls)
├── lib/models/doctor_location_model.dart
├── lib/widgets/map/doctor_info_card.dart
```

## API Endpoints Used

1. **GET /api/users/doctors**
   - Fetches all doctors
   - Returns doctors with clinicLatitude/clinicLongitude

2. **GET /api/users/doctors/nearby**
   - Query params: lat, lng, radius
   - Returns doctors within specified radius
   - Uses MongoDB geospatial queries

## Next Steps (Optional)

### Add More Doctors
Edit `backend/scripts/seed-belgaum-doctors.js` and add more entries to the `belgaumDoctors` array, then run:
```bash
node scripts/seed-belgaum-doctors.js
```

### Add Doctors in Different Cities
Modify coordinates:
- Mumbai: 19.0760, 72.8777
- Delhi: 28.6139, 77.2090
- Bangalore: 12.9716, 77.5946
- Your city: (find coordinates on Google Maps)

### Enable Location on Web
- Deploy to HTTPS domain
- Or use localhost (already works)

## Database Collections

### Users Collection
```javascript
{
  role: 'doctor',
  fullName: 'Dr. Cardiologist Belgaum 1',
  email: 'doctor1.belgaum@medilinko.com',
  specialization: 'Cardiologist',
  clinicName: 'Heart Care Belgaum',
  clinicLatitude: 15.8497,
  clinicLongitude: 74.4977,
  location: {
    type: 'Point',
    coordinates: [74.4977, 15.8497] // [lng, lat] for GeoJSON
  }
}
```

### DoctorProfile Collection
```javascript
{
  userId: ObjectId,
  specialization: 'Cardiologist',
  experience: 15,
  consultationFee: 600,
  clinicName: 'Heart Care Belgaum',
  availableTimings: [
    { day: 'Monday', from: '09:00', to: '17:00' }
  ]
}
```

## Summary

✅ **3 doctors created** in Belgaum area  
✅ **Map centered** on Belgaum by default  
✅ **Auto-fetch** doctors on screen load  
✅ **Manual refresh** button added  
✅ **Appointment booking** integrated  
✅ **All features working** end-to-end  

**Everything is ready to use!** 🎉

Just start the backend and Flutter app, then navigate to "Find Doctors" from the user dashboard.
