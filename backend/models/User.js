const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  fullName: {
    type: String,
    required: [true, 'Please provide full name'],
    trim: true
  },
  email: {
    type: String,
    required: [true, 'Please provide email'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please provide a valid email']
  },
  phone: {
    type: String,
    required: [true, 'Please provide phone number'],
    match: [/^[0-9]{10}$/, 'Please provide a valid 10-digit phone number']
  },
  password: {
    type: String,
    required: [true, 'Please provide password'],
    minlength: 6,
    select: false
  },
  role: {
    type: String,
    enum: ['user', 'doctor', 'pharmacist'],
    required: true
  },
  isProfileComplete: {
    type: Boolean,
    default: false
  },
  fcmToken: {
    type: String,
    default: null
  },
  fcmTokens: [{
    token: String,
    device: String,
    updatedAt: {
      type: Date,
      default: Date.now
    }
  }],
  // Medicine reminders
  medicines: [{
    id: Number,
    name: String,
    dosage: String,
    time: String, // Format: "HH:mm"
    createdAt: {
      type: Date,
      default: Date.now
    }
  }],
  // Clinic location for doctors (used in map search)
  clinicLatitude: {
    type: Number,
    min: -90,
    max: 90
  },
  clinicLongitude: {
    type: Number,
    min: -180,
    max: 180
  },
  // Pharmacy location for pharmacists (used in map search)
  pharmacyLatitude: {
    type: Number,
    min: -90,
    max: 90
  },
  pharmacyLongitude: {
    type: Number,
    min: -180,
    max: 180
  },
  // GeoJSON Point for MongoDB geospatial queries
  location: {
    type: {
      type: String,
      enum: ['Point'],
      default: 'Point'
    },
    coordinates: {
      type: [Number], // [longitude, latitude]
      default: [0, 0]
    }
  }
}, {
  timestamps: true
});

// Create 2dsphere index for geospatial queries
userSchema.index({ location: '2dsphere' });

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) {
    return next();
  }
  
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

// Compare password method
userSchema.methods.comparePassword = async function(enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
