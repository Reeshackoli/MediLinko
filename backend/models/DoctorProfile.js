const mongoose = require('mongoose');

const doctorProfileSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  gender: {
    type: String,
    enum: ['Male', 'Female', 'Other', 'male', 'female', 'other']
  },
  specialization: {
    type: String,
    trim: true
  },
  experience: {
    type: Number,
    min: 0
  },
  clinicName: {
    type: String,
    trim: true
  },
  clinicAddress: {
    street: { type: String, trim: true },
    city: { type: String, trim: true },
    pincode: { type: String, trim: true },
    fullAddress: { type: String, trim: true }
  },
  consultationFee: {
    type: Number,
    min: 0
  },
  availableTimings: [{
    day: {
      type: String,
      enum: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
    },
    from: {
      type: String
    },
    to: {
      type: String
    }
  }],
  documents: [{
    type: String
  }],
  verificationStatus: {
    type: String,
    enum: ['pending', 'approved', 'rejected'],
    default: 'pending'
  },
  rating: {
    type: Number,
    default: 4.5,
    min: 0,
    max: 5
  }
}, {
  timestamps: true
});

// Index for faster queries (userId already indexed by unique: true)
doctorProfileSchema.index({ specialization: 1 });
doctorProfileSchema.index({ verificationStatus: 1 });

module.exports = mongoose.model('DoctorProfile', doctorProfileSchema);
