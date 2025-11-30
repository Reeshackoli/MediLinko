const mongoose = require('mongoose');

const medicineStockSchema = new mongoose.Schema({
  pharmacistId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  medicineName: {
    type: String,
    required: [true, 'Medicine name is required'],
    trim: true
  },
  batchNumber: {
    type: String,
    required: [true, 'Batch number is required'],
    trim: true
  },
  expiryDate: {
    type: Date,
    required: [true, 'Expiry date is required']
  },
  quantity: {
    type: Number,
    required: [true, 'Quantity is required'],
    min: 0,
    default: 0
  },
  price: {
    type: Number,
    required: [true, 'Price is required'],
    min: 0
  },
  manufacturer: {
    type: String,
    trim: true
  },
  category: {
    type: String,
    enum: ['Tablet', 'Capsule', 'Syrup', 'Injection', 'Cream', 'Drops', 'Inhaler', 'Other'],
    default: 'Other'
  },
  lowStockLevel: {
    type: Number,
    default: 10,
    min: 0
  },
  lastExpiryAlertSent: {
    type: Date,
    default: null
  },
  lastLowStockAlertSent: {
    type: Date,
    default: null
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Virtual for checking if stock is low
medicineStockSchema.virtual('isLowStock').get(function() {
  return this.quantity <= this.lowStockLevel;
});

// Virtual for checking if medicine is expiring soon (within 30 days)
medicineStockSchema.virtual('isExpiringSoon').get(function() {
  const thirtyDaysFromNow = new Date();
  thirtyDaysFromNow.setDate(thirtyDaysFromNow.getDate() + 30);
  return this.expiryDate <= thirtyDaysFromNow;
});

// Virtual for days until expiry
medicineStockSchema.virtual('daysUntilExpiry').get(function() {
  const today = new Date();
  const expiry = new Date(this.expiryDate);
  const diffTime = expiry - today;
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
  return diffDays;
});

// Virtual for total value
medicineStockSchema.virtual('totalValue').get(function() {
  return this.quantity * this.price;
});

// Index for faster queries
medicineStockSchema.index({ pharmacistId: 1, medicineName: 1 });
medicineStockSchema.index({ expiryDate: 1 });
medicineStockSchema.index({ category: 1 });

module.exports = mongoose.model('MedicineStock', medicineStockSchema);
