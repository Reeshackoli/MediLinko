const Notification = require('../models/Notification');
const { sendPushNotification } = require('./fcmService');

/**
 * Send low stock alert to pharmacist
 */
async function sendLowStockAlert(userId, medicine) {
  try {
    // Create in-app notification
    const notification = await Notification.create({
      userId,
      title: 'Low Stock Alert',
      message: `${medicine.medicineName} - Only ${medicine.quantity} units left (Batch: ${medicine.batchNumber})`,
      type: 'low_stock_alert',
      relatedId: medicine._id,
      relatedModel: 'MedicineStock',
      data: { priority: 'high', quantity: medicine.quantity }
    });

    // Send push notification
    await sendPushNotification({
      userId,
      title: '⚠️ Low Stock Alert',
      body: `${medicine.medicineName} - Only ${medicine.quantity} units left (Batch: ${medicine.batchNumber}). Reorder soon!`,
      data: {
        type: 'low_stock_alert',
        medicineId: medicine._id.toString(),
        screen: 'medicine_stock',
        quantity: medicine.quantity.toString()
      }
    });

    return notification;
  } catch (error) {
    console.error('Error sending low stock alert:', error);
    throw error;
  }
}

/**
 * Send expiry alert to pharmacist
 */
async function sendExpiryAlert(userId, medicine) {
  try {
    const daysUntilExpiry = Math.ceil((medicine.expiryDate - new Date()) / (1000 * 60 * 60 * 24));
    const isExpired = daysUntilExpiry < 0;

    // Create in-app notification
    const notification = await Notification.create({
      userId,
      title: isExpired ? 'Medicine Expired' : 'Medicine Expiring Soon',
      message: isExpired 
        ? `${medicine.medicineName} (Batch: ${medicine.batchNumber}) has expired - ${medicine.quantity} units in stock`
        : `${medicine.medicineName} expires in ${daysUntilExpiry} days - ${medicine.quantity} units in stock (Batch: ${medicine.batchNumber})`,
      type: 'expiry_alert',
      relatedId: medicine._id,
      relatedModel: 'MedicineStock',
      data: { priority: isExpired ? 'urgent' : 'high', quantity: medicine.quantity, daysUntilExpiry }
    });

    // Send push notification
    await sendPushNotification({
      userId,
      title: isExpired ? '🚫 Medicine Expired' : '⏰ Expiry Alert',
      body: isExpired
        ? `${medicine.medicineName} has expired - ${medicine.quantity} units. Remove from stock immediately!`
        : `${medicine.medicineName} expires in ${daysUntilExpiry} days - ${medicine.quantity} units left (Batch: ${medicine.batchNumber})`,
      data: {
        type: 'expiry_alert',
        medicineId: medicine._id.toString(),
        screen: 'medicine_stock',
        isExpired: isExpired.toString(),
        quantity: medicine.quantity.toString(),
        daysUntilExpiry: daysUntilExpiry.toString()
      }
    });

    return notification;
  } catch (error) {
    console.error('Error sending expiry alert:', error);
    throw error;
  }
}

/**
 * Check and send alerts for all medicines (scheduled job)
 */
async function checkMedicineAlerts() {
  try {
    const MedicineStock = require('../models/MedicineStock');
    const User = require('../models/User');

    // Get all pharmacists
    const pharmacists = await User.find({ role: 'pharmacist' });

    for (const pharmacist of pharmacists) {
      const medicines = await MedicineStock.find({ pharmacistId: pharmacist._id });

      for (const medicine of medicines) {
        // Check low stock (send alert once per day)
        if (medicine.isLowStock) {
          const shouldSendLowStock = !medicine.lastLowStockAlertSent || 
            (new Date() - medicine.lastLowStockAlertSent) > 24 * 60 * 60 * 1000;

          if (shouldSendLowStock) {
            await sendLowStockAlert(pharmacist._id, medicine);
            medicine.lastLowStockAlertSent = new Date();
            await medicine.save();
          }
        }

        // Check expiry (send alert once per day)
        const isExpired = medicine.expiryDate < new Date();
        const isExpiringSoon = medicine.isExpiringSoon;

        if (isExpired || isExpiringSoon) {
          const shouldSendExpiry = !medicine.lastExpiryAlertSent || 
            (new Date() - medicine.lastExpiryAlertSent) > 24 * 60 * 60 * 1000;

          if (shouldSendExpiry) {
            await sendExpiryAlert(pharmacist._id, medicine);
            medicine.lastExpiryAlertSent = new Date();
            await medicine.save();
          }
        }
      }
    }

    console.log('✅ Medicine alerts check completed');
  } catch (error) {
    console.error('❌ Error checking medicine alerts:', error);
  }
}

module.exports = {
  sendLowStockAlert,
  sendExpiryAlert,
  checkMedicineAlerts
};
