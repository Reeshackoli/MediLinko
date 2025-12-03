# Appointment Booking - Complete Guide ✅

## ✅ What Was Fixed

### Type Error Resolved
**Problem**: `DoctorLocationModel` from map couldn't be passed to `BookAppointmentScreen` which expected `DoctorInfo`

**Solution**: 
- Added `toDoctorInfoJson()` method to `DoctorLocationModel`
- Updated router to automatically convert between types
- Now booking works from map screen

### Files Modified
1. `lib/models/doctor_location_model.dart` - Added conversion method
2. `lib/core/router/app_router.dart` - Added type conversion logic

## 🎯 Complete Appointment Flow

### Step 1: Start Backend
```bash
cd backend
npm run dev
```
Server should show:
```
✅ Server running on port 3000
✅ Connected to MongoDB
```

### Step 2: Start Flutter App
```bash
flutter run -d chrome
# Or: flutter run (for mobile)
```

### Step 3: Patient Books Appointment

**As Patient User:**
1. **Login/Register** as User (patient role)
2. **Dashboard** → Tap "Find Doctors" card
3. **Map Screen**:
   - See 3 blue doctor markers in Belgaum
   - If not visible, tap blue refresh button (bottom right)
   - Tap any doctor marker
4. **Doctor Info Card** appears at bottom:
   - Shows doctor name, specialization, clinic, fee
   - Tap **"Book Appointment"** button
5. **Booking Screen**:
   - Tap date field → Select appointment date (up to 90 days ahead)
   - View available time slots (30-min intervals)
   - Tap time slot to select
   - (Optional) Enter symptoms/notes
   - Tap **"Book Appointment"** button
6. **Success!** 
   - Green snackbar shows "Appointment booked successfully!"
   - Automatically returns to previous screen

### Step 4: Patient Views Appointments

**From Dashboard:**
1. Dashboard → Tap **"Appointments"** card (orange icon)
2. **Appointments List**:
   - See all your appointments
   - Filter by status: All, Pending, Approved, Rejected, Cancelled
   - Pull down to refresh
   - Each card shows:
     - Doctor name & specialization
     - Clinic name
     - Date & time
     - Status badge (color-coded)
     - Symptoms (if entered)
   - **Cancel** button for pending appointments

### Step 5: Doctor Reviews Appointments

**As Doctor:**
1. **Logout** from patient account
2. **Login** as doctor:
   - Email: `doctor1.belgaum@medilinko.com`
   - Password: `Doctor@123`
3. **Doctor Dashboard**:
   - See real appointment count in "Appointments" card
   - Shows "Today's appointments" from API
   - Tap **"Manage Appointments"** button
4. **Doctor Appointments Screen**:
   - **Stats at Top**: Today, Pending, Approved counts
   - **Filter Tabs**: Pending, Approved, All
   - Each card shows:
     - Patient name & email
     - Date & time
     - Symptoms/notes from patient
     - Status badge
   - **For Pending Appointments**:
     - Green "Approve" button
     - Red "Reject" button
     - Confirmation dialog before action
5. **Approve/Reject**:
   - Tap Approve or Reject
   - Confirm in dialog
   - Green snackbar shows success
   - Status updates immediately
   - Stats refresh automatically

### Step 6: Patient Sees Status Update

**Back to Patient Account:**
1. Login as patient again
2. Dashboard → Appointments
3. See updated status:
   - Pending → Approved (green badge)
   - Or Pending → Rejected (red badge)
4. Can cancel any pending appointment

## 📱 Dashboard Integration

### User Dashboard
**Location**: `lib/screens/dashboards/user_dashboard.dart`

**Features**:
- "Appointments" quick action card (orange)
- Navigates to `/appointments`
- Shows all patient appointments

### Doctor Dashboard  
**Location**: `lib/screens/dashboards/doctor_dashboard.dart`

**Features**:
- Real-time appointment stats from API
- "Today's Appointments" count (not hardcoded)
- "Manage Appointments" action button
- Navigates to `/doctor/appointments`
- Shows pending, approved counts

## 🔄 Appointment Status Workflow

```
[Patient Books] 
    ↓
pending (yellow/orange)
    ↓
[Doctor Reviews]
    ↓
    ├─→ approved (green) ✅
    ├─→ rejected (red) ❌
    └─→ [Patient cancels] → cancelled (grey) 🚫
```

**Status Colors**:
- 🟡 Pending: Orange
- 🟢 Approved: Green
- 🔴 Rejected: Red
- ⚫ Cancelled: Grey

## 🧪 Test Scenarios

### Test 1: Complete Booking Flow
1. Login as patient
2. Find Doctors → Select doctor → Book appointment
3. Choose date tomorrow, 10:00 AM
4. Enter symptoms: "Regular checkup"
5. Submit → See success message
6. Go to Appointments → See pending appointment

### Test 2: Doctor Approval
1. Login as doctor (doctor1.belgaum@medilinko.com)
2. Manage Appointments → See pending tab
3. Find appointment from Test 1
4. Tap Approve → Confirm
5. See approved in "Approved" tab

### Test 3: Patient Sees Approval
1. Login back as patient
2. Appointments → Filter "Approved"
3. See appointment with green "Approved" badge

### Test 4: Cancel Appointment
1. As patient, book another appointment
2. In appointments list, tap "Cancel Appointment"
3. Confirm cancellation
4. See grey "Cancelled" badge
5. Doctor can see cancelled appointments in "All" filter

### Test 5: Multiple Doctors
1. Book appointments with all 3 doctors:
   - Dr. Cardiologist (Heart Care)
   - Dr. Dentist (Smile Dental)
   - Dr. Pediatrician (Kids Care)
2. See all in appointments list
3. Login as each doctor to see their respective appointments

## 📊 API Endpoints Used

### Patient Side
- **POST** `/api/appointments/book` - Book new appointment
- **GET** `/api/appointments` - Get user's appointments
- **PATCH** `/api/appointments/:id/status` - Cancel appointment (status: 'cancelled')

### Doctor Side
- **GET** `/api/appointments/doctor` - Get doctor's appointments
- **GET** `/api/appointments/stats` - Get dashboard stats
- **PATCH** `/api/appointments/:id/status` - Approve/reject (status: 'approved'/'rejected')

### Shared
- **GET** `/api/appointments/slots?doctorId=X&date=Y` - Get available time slots
- **GET** `/api/appointments/:id` - Get single appointment details

## 🔐 Authentication

All appointment endpoints require JWT token:
- Token stored in `TokenService` 
- Automatically included in API requests
- User ID extracted from token on backend
- Role-based authorization enforced

## 🐛 Troubleshooting

### "No time slots available"
**Cause**: Doctor has no `availableTimings` or all slots booked
**Solution**: 
- Check `DoctorProfile` has `availableTimings` array
- Doctors seeded have Mon-Fri timings
- Try different date

### "Failed to book appointment"
**Possible Causes**:
1. Backend not running → Start with `npm run dev`
2. Token expired → Logout and login again
3. Invalid doctor ID → Use doctor from map/database
4. Time slot conflict → Another appointment at same time

**Check Backend Logs**:
```bash
cd backend
npm run dev
# Watch for errors in console
```

### Appointments not showing in dashboard
**Check**:
1. User is logged in (token exists)
2. Backend is running on port 3000
3. API base URL is `http://localhost:3000/api`
4. Browser console for API errors (F12)

**Quick Test**:
```bash
# In browser console (F12)
localStorage.getItem('token') // Should show JWT token
```

### Doctor can't approve appointments
**Verify**:
1. Logged in as doctor role (not patient)
2. Appointment exists and is pending
3. Appointment's doctorId matches logged-in doctor's ID
4. Backend logs for authorization errors

## 🎯 Success Indicators

✅ **Patient Side**:
- Can book appointments from map
- See all appointments in list
- Can filter by status
- Can cancel pending appointments
- See real-time status updates

✅ **Doctor Side**:
- Dashboard shows real appointment count
- Can view all appointments
- Can filter by status
- Can approve/reject pending appointments
- Stats update after actions

✅ **Backend**:
- All endpoints return 200 status
- Appointments saved to MongoDB
- Status updates persist
- Role-based auth working

## 🚀 Next Steps (Optional Enhancements)

1. **Push Notifications**: Notify patient when appointment approved/rejected
2. **Email Confirmations**: Send email after booking, approval
3. **Rescheduling**: Allow changing date/time of existing appointment
4. **Reminders**: Send reminder 1 day before appointment
5. **Video Consultation**: Add video call link for approved appointments
6. **Prescription Upload**: Doctor can upload prescription after appointment
7. **Rating System**: Patient can rate doctor after appointment
8. **Calendar Sync**: Export to Google Calendar, Apple Calendar

## 📝 Sample Data

### Test Patient
- Email: (register any email)
- Role: User
- Can book appointments

### Test Doctors (Belgaum)
```
Doctor 1 - Cardiologist
Email: doctor1.belgaum@medilinko.com
Password: Doctor@123
Clinic: Heart Care Belgaum
Fee: ₹600

Doctor 2 - Dentist
Email: doctor2.belgaum@medilinko.com
Password: Doctor@123
Clinic: Smile Dental Clinic
Fee: ₹400

Doctor 3 - Pediatrician
Email: doctor3.belgaum@medilinko.com
Password: Doctor@123
Clinic: Kids Care Hospital
Fee: ₹500
```

## ✨ Summary

**Complete Features**:
✅ Map-based doctor discovery
✅ Book appointment from map
✅ Date & time slot selection
✅ Patient appointment management
✅ Doctor approval/rejection workflow
✅ Real-time status updates
✅ Dashboard integration (both roles)
✅ Filter & search appointments
✅ Cancel appointments
✅ Role-based authorization
✅ Error handling & validation

**Everything works end-to-end!** 🎉

Just start backend + Flutter app, then follow the flow:
**Patient**: Find Doctors → Select → Book → View in Appointments
**Doctor**: Login → Manage Appointments → Approve/Reject

The complete appointment system is production-ready! 🚀
