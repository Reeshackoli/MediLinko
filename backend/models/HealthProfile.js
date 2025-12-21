const mongoose = require('mongoose');

const healthProfileSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  firstName: {
    type: String,
    trim: true
  },
  lastName: {
    type: String,
    trim: true
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
  city: {
    type: String,
    trim: true
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
  currentMedications: [{
    type: String,
    trim: true
  }],
  emergencyContactName: {
    type: String,
    trim: true
  },
  emergencyContactRelationship: {
    type: String,
    trim: true
  },
  emergencyContactPhone: {
    type: String,
    match: [/^[0-9]{10}$/, 'Please provide a valid 10-digit phone number']
  },
  emergencyContactName2: {
    type: String,
    trim: true
  },
  emergencyContactRelationship2: {
    type: String,
    trim: true
  },
  emergencyContactPhone2: {
    type: String,
    match: [/^[0-9]{10}$/, 'Please provide a valid 10-digit phone number']
  }
}, {
  timestamps: true
});

// userId already indexed by unique: true - no additional index needed

module.exports = mongoose.model('HealthProfile', healthProfileSchema);
