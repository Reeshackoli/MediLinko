const mongoose = require('mongoose');

const medicineTrackerSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  medicineName: {
    type: String,
    required: [true, 'Medicine name is required'],
    trim: true
  },
  dosage: {
    type: String,
    required: [true, 'Dosage is required'],
    trim: true
  },
  schedule: [{
    type: String,
    required: true
  }],
  startDate: {
    type: String,
    required: [true, 'Start date is required']
  },
  endDate: {
    type: String,
    required: [true, 'End date is required']
  },
  isActive: {
    type: Boolean,
    default: true
  },
  lastReminderSent: {
    type: Date,
    default: null
  },
  notes: {
    type: String,
    trim: true
  }
}, {
  timestamps: true
});

// Indexes for faster queries
medicineTrackerSchema.index({ userId: 1 });
medicineTrackerSchema.index({ isActive: 1 });
medicineTrackerSchema.index({ startDate: 1, endDate: 1 });

module.exports = mongoose.model('MedicineTracker', medicineTrackerSchema);
