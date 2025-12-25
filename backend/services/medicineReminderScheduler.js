const { messaging } = require('../config/firebase');
const UserMedicine = require('../models/UserMedicine');
const MedicineDose = require('../models/MedicineDose');
const User = require('../models/User');

// Store active timers
const activeTimers = new Map();

/**
 * Calculate next reminder time for a medicine dose
 */
function getNextReminderTime(doseTime) {
  const now = new Date();
  
  // Parse the time - handle both 24-hour (HH:MM) and 12-hour (HH:MM AM/PM) formats
  let hours, minutes;
  
  try {
    if (doseTime.includes('AM') || doseTime.includes('PM') || doseTime.includes('am') || doseTime.includes('pm')) {
      // 12-hour format
      const parts = doseTime.trim().split(' ');
      const timePart = parts[0].split(':');
      const period = parts[1]?.toUpperCase();
      
      hours = parseInt(timePart[0]);
      minutes = parseInt(timePart[1]) || 0;
      
      if (isNaN(hours)) {
        console.error(`❌ Invalid time format: "${doseTime}"`);
        return null;
      }
      
      if (period === 'PM' && hours !== 12) {
        hours += 12;
      } else if (period === 'AM' && hours === 12) {
        hours = 0;
      }
    } else {
      // 24-hour format
      const parts = doseTime.split(':');
      hours = parseInt(parts[0]);
      minutes = parseInt(parts[1]) || 0;
      
      if (isNaN(hours)) {
        console.error(`❌ Invalid time format: "${doseTime}"`);
        return null;
      }
    }
  } catch (error) {
    console.error(`❌ Error parsing time "${doseTime}":`, error);
    return null;
  }
  
  const next = new Date();
  next.setHours(hours, minutes, 0, 0);
  
  console.log(`⏰ Parsing time "${doseTime}" -> ${hours}:${minutes} (${next.toLocaleTimeString()})`);
  console.log(`   Current time: ${now.toLocaleTimeString()}, Target time: ${next.toLocaleTimeString()}`);
  
  // If time has passed today, schedule for tomorrow
  if (next <= now) {
    next.setDate(next.getDate() + 1);
    console.log(`   ⏭️ Time passed, scheduling for tomorrow: ${next.toLocaleString()}`);
  } else {
    const delayMinutes = Math.floor((next.getTime() - now.getTime()) / 60000);
    console.log(`   ⏳ Scheduling in ${delayMinutes} minutes`);
  }
  
  return next;
}

/**
 * Send push notification for a medicine reminder
 */
async function sendMedicineReminder(medicine, dose) {
  try {
    const userId = medicine.userId.toString();
    
    // Get user's FCM token from User model
    const User = require('../models/User');
    const Notification = require('../models/Notification');
    
    const user = await User.findById(userId);
    
    if (!user || !user.fcmToken) {
      console.log(`No FCM token found for user ${userId}`);
      return;
    }

    const notificationTitle = '💊 Medicine Reminder';
    const notificationBody = `Time to take ${medicine.medicineName} - ${medicine.dosage}`;

    const message = {
      token: user.fcmToken,
      notification: {
        title: notificationTitle,
        body: notificationBody
      },
      data: {
        type: 'medicine_reminder',
        medicineId: medicine._id.toString(),
        medicineName: medicine.medicineName || '',
        dosage: medicine.dosage || '',
        time: dose.time || '',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK'
      },
      android: {
        priority: 'high',
        notification: {
          channelId: 'medicine_reminders',
          sound: 'default',
          priority: 'high'
        }
      },
      apns: {
        payload: {
          aps: {
            sound: 'default',
            badge: 1
          }
        }
      }
    };

    // Send FCM notification
    await messaging.send(message);
    console.log(`✅ Sent reminder for ${medicine.medicineName} at ${dose.time}`);

    // Save notification to database
    await Notification.create({
      userId: userId,
      type: 'medicine_reminder',
      title: notificationTitle,
      message: notificationBody,
      data: {
        medicineId: medicine._id.toString(),
        medicineName: medicine.medicineName,
        dosage: medicine.dosage,
        time: dose.time
      },
      read: false
    });
    console.log(`💾 Saved notification to database for ${medicine.medicineName}`);
  } catch (error) {
    console.error('Error sending medicine reminder:', error);
  }
}

/**
 * Schedule a single medicine dose reminder
 */
function scheduleDoseReminder(medicine, dose) {
  const nextTime = getNextReminderTime(dose.time);
  
  // Skip if time parsing failed
  if (!nextTime) {
    console.error(`⚠️ Skipping ${medicine.medicineName} at ${dose.time} - invalid time format`);
    return;
  }
  
  const delay = nextTime.getTime() - Date.now();
  
  // Validate delay (must be at least 1 second in the future)
  if (delay < 1000) {
    console.warn(`⚠️ Skipping ${medicine.medicineName} at ${dose.time} - time already passed (delay: ${delay}ms)`);
    return;
  }
  
  const timerId = `${medicine._id}_${dose.time}`;
  
  // Clear existing timer if any
  if (activeTimers.has(timerId)) {
    clearTimeout(activeTimers.get(timerId));
  }
  
  // Schedule the reminder
  const timer = setTimeout(async () => {
    await sendMedicineReminder(medicine, dose);
    
    // Remove from active timers
    activeTimers.delete(timerId);
  }, delay);
  
  activeTimers.set(timerId, timer);
  
  const delayMinutes = Math.floor(delay / 60000);
  console.log(`📅 Scheduled ${medicine.medicineName} at ${dose.time} - Next: ${nextTime.toLocaleString()} (in ${delayMinutes} minutes)`);
}

/**
 * Schedule reminders for a specific medicine
 */
async function scheduleMedicineReminders(medicine) {
  const now = new Date();
  const today = now.toISOString().split('T')[0];
  
  // Check if medicine is active today
  if (medicine.startDate && new Date(medicine.startDate) > now) {
    console.log(`Medicine ${medicine.medicineName} starts in future, skipping`);
    return;
  }
  
  if (medicine.endDate && new Date(medicine.endDate) < new Date(today)) {
    console.log(`Medicine ${medicine.medicineName} has ended, skipping`);
    return;
  }
  
  // Get doses for this medicine
  const doses = await MedicineDose.find({ userMedicineId: medicine._id });
  
  if (!doses || doses.length === 0) {
    console.log(`No doses found for medicine ${medicine.medicineName}`);
    return;
  }
  
  // Schedule each dose
  doses.forEach(dose => {
    scheduleDoseReminder(medicine, dose);
  });
}

/**
 * Clear all reminders for a medicine
 */
function clearMedicineReminders(medicineId) {
  const pattern = new RegExp(`^${medicineId}_`);
  
  for (const [timerId, timer] of activeTimers.entries()) {
    if (pattern.test(timerId)) {
      clearTimeout(timer);
      activeTimers.delete(timerId);
      console.log(`🗑️ Cleared timer: ${timerId}`);
    }
  }
}

/**
 * Reschedule reminders for a specific user (called when user's medicines change)
 */
async function rescheduleUserReminders(userId) {
  try {
    console.log(`🔄 Rescheduling reminders for user ${userId}...`);
    
    // Clear existing timers for this user
    const userPattern = new RegExp(`^[a-f0-9]{24}_`);
    const userMedicines = await UserMedicine.find({ userId });
    const medicineIds = userMedicines.map(m => m._id.toString());
    
    for (const [timerId, timer] of activeTimers.entries()) {
      const medicineId = timerId.split('_')[0];
      if (medicineIds.includes(medicineId)) {
        clearTimeout(timer);
        activeTimers.delete(timerId);
      }
    }
    
    // Schedule new reminders for this user
    for (const medicine of userMedicines) {
      await scheduleMedicineReminders(medicine);
    }
    
    console.log(`✅ Rescheduled reminders for user ${userId}`);
  } catch (error) {
    console.error('Error rescheduling user reminders:', error);
  }
}

/**
 * Reschedule all medicine reminders (called on app start and data changes)
 */
async function rescheduleAllReminders() {
  try {
    console.log('🔄 Rescheduling all medicine reminders...');
    
    // Clear all existing timers
    activeTimers.forEach(timer => clearTimeout(timer));
    activeTimers.clear();
    
    // Get all active medicines (only those not yet ended)
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    const medicines = await UserMedicine.find({
      isActive: true,
      $or: [
        { endDate: { $gte: today } },
        { endDate: null }
      ]
    }).populate('userId', 'email name');
    
    console.log(`Found ${medicines.length} active medicines`);
    
    // Schedule reminders for each medicine (using for...of for async)
    for (const medicine of medicines) {
      const userEmail = medicine.userId?.email || 'unknown';
      console.log(`📋 Processing: ${medicine.medicineName} for ${userEmail}`);
      await scheduleMedicineReminders(medicine);
    }
    
    console.log(`✅ Scheduled reminders for ${activeTimers.size} doses`);
  } catch (error) {
    console.error('❌ Error rescheduling all reminders:', error);
  }
}

/**
 * Start the medicine reminder scheduler
 */
async function startScheduler() {
  console.log('🚀 Medicine Reminder Scheduler starting...');
  
  await rescheduleAllReminders();
  
  // Reschedule all reminders once a day at midnight
  const midnightScheduler = setInterval(async () => {
    const now = new Date();
    if (now.getHours() === 0 && now.getMinutes() === 0) {
      await rescheduleAllReminders();
    }
  }, 60000); // Check every minute for midnight
  
  console.log('✅ Medicine Reminder Scheduler started');
}

module.exports = {
  startScheduler,
  rescheduleAllReminders,
  rescheduleUserReminders,
  scheduleMedicineReminders,
  clearMedicineReminders
};
