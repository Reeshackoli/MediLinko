const mongoose = require('mongoose');

const medicineDoseSchema = new mongoose.Schema({
  userMedicineId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'UserMedicine',
    required: true,
  },
  time: {
    type: String,
    required: [true, 'Dose time is required'],
    trim: true, // e.g. "09:00 AM"
  },
  instruction: {
    type: String,
    trim: true, // e.g. "After food", "Before food", "With water"
  },
  frequency: {
    type: String,
    enum: ['daily', 'weekly'],
    default: 'daily',
  },
  // daysOfWeek: optional array of numbers 0 (Sunday) - 6 (Saturday)
  daysOfWeek: [{
    type: Number,
    min: 0,
    max: 6
  }]
}, {
  timestamps: true
});

medicineDoseSchema.index({ userMedicineId: 1 });

module.exports = mongoose.model('MedicineDose', medicineDoseSchema);
