const mongoose = require('mongoose');

const healthProfileSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  age: {
    type: Number,
    min: 0,
    max: 150
  },
  gender: {
    type: String,
    enum: ['Male', 'Female', 'Other', 'male', 'female', 'other']
  },
  bloodGroup: {
    type: String,
    enum: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']
  },
  allergies: [{
    type: String,
    trim: true
  }],
  medicalConditions: [{
    type: String,
    trim: true
  }],
  currentMedicines: [{
    type: String,
    trim: true
  }],
  emergencyContact: {
    name: {
      type: String,
      trim: true
    },
    phone: {
      type: String,
      match: [/^[0-9]{10}$/, 'Please provide a valid 10-digit phone number']
    }
  }
}, {
  timestamps: true
});

// Index for faster queries
healthProfileSchema.index({ userId: 1 });

module.exports = mongoose.model('HealthProfile', healthProfileSchema);
