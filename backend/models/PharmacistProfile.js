const mongoose = require('mongoose');

const pharmacistProfileSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    unique: true
  },
  storeName: {
    type: String,
    trim: true
  },
  storeAddress: {
    street: { type: String, trim: true },
    city: { type: String, trim: true },
    pincode: { type: String, trim: true },
    fullAddress: { type: String, trim: true }
  },
  operatingHours: {
    opening: { type: String },
    closing: { type: String }
  },
  licenseNumber: {
    type: String,
    unique: true,
    sparse: true,
    trim: true
  },
  servicesOffered: [{
    type: String
  }],
  deliveryRadius: {
    type: Number,
    min: 0
  },
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
    default: 0,
    min: 0,
    max: 5
  },
  totalRatings: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true
});

// Index for faster queries (userId and licenseNumber already indexed by unique: true)
pharmacistProfileSchema.index({ verificationStatus: 1 });

module.exports = mongoose.model('PharmacistProfile', pharmacistProfileSchema);
