const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  pharmacistId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  type: {
    type: String,
    required: [true, 'Notification type is required'],
    enum: ['medicine-reminder', 'stock-expiry', 'low-stock', 'appointment-update', 'order-update']
  },
  title: {
    type: String,
    required: [true, 'Title is required'],
    trim: true
  },
  message: {
    type: String,
    required: [true, 'Message is required'],
    trim: true
  },
  meta: {
    medicineName: {
      type: String,
      trim: true
    },
    batchNumber: {
      type: String,
      trim: true
    },
    expiryDate: {
      type: String
    },
    scheduleTime: {
      type: String
    },
    orderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Order'
    },
    appointmentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Appointment'
    }
  },
  read: {
    type: Boolean,
    default: false
  }
}, {
  timestamps: true
});

// Indexes for faster queries
notificationSchema.index({ userId: 1, read: 1 });
notificationSchema.index({ pharmacistId: 1, read: 1 });
notificationSchema.index({ type: 1 });
notificationSchema.index({ createdAt: -1 });

module.exports = mongoose.model('Notification', notificationSchema);
